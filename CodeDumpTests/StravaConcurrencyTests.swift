import XCTest
@testable import CodeDump

/// Concurrency and stress tests — verify thread safety, race conditions,
/// and behavior under rapid repeated operations.
@MainActor
final class StravaConcurrencyTests: XCTestCase {

    private var store: MockTokenStore!
    private var network: MockNetworkClient!
    private var sut: StravaManager!

    override func setUp() async throws {
        store = MockTokenStore()
        network = MockNetworkClient()
        sut = StravaManager(tokenStore: store, networkClient: network)
    }

    override func tearDown() async throws {
        store = nil
        network = nil
        sut = nil
    }

    // MARK: - Helpers

    private func httpResponse(_ code: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://www.strava.com")!,
                        statusCode: code, httpVersion: nil, headerFields: nil)!
    }

    private func connectStrava() {
        store.save(key: "strava_access_token", value: "tok")
        store.save(key: "strava_refresh_token", value: "ref")
        store.save(key: "strava_token_expiry",
                   value: String(Date().addingTimeInterval(3600).timeIntervalSince1970))
    }

    // MARK: - Rapid Sequential Uploads

    func testRapidSequentialUploads_AllComplete() async {
        connectStrava()

        for i in 0..<10 {
            network.responses.append((Data("{}".utf8), httpResponse(201)))

            await sut.uploadWorkout(
                name: "Rapid \(i)",
                workoutType: .strength,
                startDate: Date(),
                elapsedSeconds: 60,
                description: nil
            )

            XCTAssertEqual(sut.uploadResult, .success, "Upload \(i) should succeed")
            XCTAssertFalse(sut.isUploading, "Should not be uploading after completion \(i)")
        }

        XCTAssertEqual(network.capturedRequests.count, 10)
    }

    // MARK: - Concurrent Upload Attempts

    func testConcurrentUploadAttempts_DoNotCrash() async {
        connectStrava()

        // Queue up enough responses for all concurrent attempts
        for _ in 0..<20 {
            network.responses.append((Data("{}".utf8), httpResponse(201)))
        }

        // Fire multiple uploads concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask { @MainActor in
                    await self.sut.uploadWorkout(
                        name: "Concurrent \(i)",
                        workoutType: .strength,
                        startDate: Date(),
                        elapsedSeconds: 60,
                        description: nil
                    )
                }
            }
        }

        // After all finish, state should be consistent
        XCTAssertFalse(sut.isUploading, "Should not be uploading after all concurrent tasks finish")
        XCTAssertNotNil(sut.uploadResult, "Should have a final result")
    }

    // MARK: - Disconnect During Upload

    func testDisconnectDuringUpload_HandledGracefully() async {
        connectStrava()

        // Use a slow network client that introduces a delay
        let slowNetwork = SlowMockNetworkClient(
            response: (Data("{}".utf8), httpResponse(201)),
            delay: 0.5
        )
        let slowSut = StravaManager(tokenStore: store, networkClient: slowNetwork)

        // Start upload in background
        let uploadTask = Task { @MainActor in
            await slowSut.uploadWorkout(
                name: "Interrupted",
                workoutType: .strength,
                startDate: Date(),
                elapsedSeconds: 60,
                description: nil
            )
        }

        // Disconnect immediately while upload is in flight
        try? await Task.sleep(for: .milliseconds(50))
        slowSut.disconnect()

        // Wait for upload to complete
        await uploadTask.value

        // Should have completed without crash — result could be success or error
        XCTAssertFalse(slowSut.isUploading)
    }

    // MARK: - Rapid Connect/Disconnect Cycling

    func testRapidConnectDisconnectCycling() async {
        for i in 0..<20 {
            // Connect
            store.save(key: "strava_access_token", value: "tok_\(i)")
            store.save(key: "strava_refresh_token", value: "ref_\(i)")
            XCTAssertTrue(sut.isConnected, "Should be connected at cycle \(i)")

            // Disconnect
            sut.disconnect()
            XCTAssertFalse(sut.isConnected, "Should be disconnected at cycle \(i)")
            XCTAssertNil(sut.accessToken)
            XCTAssertNil(sut.refreshToken)
        }
    }

    // MARK: - Token Refresh Race

    func testConcurrentTokenRefreshes_DoNotCorrupt() async {
        store.save(key: "strava_access_token", value: "old")
        store.save(key: "strava_refresh_token", value: "ref")
        store.save(key: "strava_token_expiry",
                   value: String(Date().addingTimeInterval(-60).timeIntervalSince1970))

        // Queue up multiple token refresh responses
        for i in 0..<5 {
            let json = try! JSONSerialization.data(withJSONObject: [
                "access_token": "tok_\(i)",
                "refresh_token": "ref_\(i)",
                "expires_at": Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
            ])
            network.responses.append((json, httpResponse(200)))
            // And the upload response
            network.responses.append((Data("{}".utf8), httpResponse(201)))
        }

        // Run multiple uploads that all need token refresh
        for i in 0..<3 {
            // Reset expiry so each sees it as expired
            store.save(key: "strava_token_expiry",
                       value: String(Date().addingTimeInterval(-60).timeIntervalSince1970))

            await sut.uploadWorkout(
                name: "Refresh Race \(i)",
                workoutType: .strength,
                startDate: Date(),
                elapsedSeconds: 60,
                description: nil
            )
        }

        // After all complete, tokens should be valid
        XCTAssertTrue(sut.isConnected)
        XCTAssertNotNil(sut.accessToken)
    }

    // MARK: - Upload Result Overwrite

    func testUploadResultOverwrittenBySubsequentUpload() async {
        connectStrava()

        // First upload fails
        network.responses.append((Data(), httpResponse(500)))
        await sut.uploadWorkout(
            name: "Fail",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )
        XCTAssertNotEqual(sut.uploadResult, .success)

        // Second upload succeeds
        network.responses.append((Data("{}".utf8), httpResponse(201)))
        await sut.uploadWorkout(
            name: "Pass",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )
        XCTAssertEqual(sut.uploadResult, .success, "Second upload should overwrite first result")
    }

    // MARK: - isUploading State Consistency

    func testIsUploadingFalseAfterSuccess() async {
        connectStrava()
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )

        XCTAssertFalse(sut.isUploading)
    }

    func testIsUploadingFalseAfterError() async {
        connectStrava()
        network.responses.append((Data(), httpResponse(500)))

        await sut.uploadWorkout(
            name: "Test", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )

        XCTAssertFalse(sut.isUploading)
    }

    func testIsUploadingFalseAfterNetworkError() async {
        connectStrava()
        network.error = URLError(.notConnectedToInternet)

        await sut.uploadWorkout(
            name: "Test", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )

        XCTAssertFalse(sut.isUploading)
    }

    func testIsUploadingFalseWhenNotConnected() async {
        // Don't connect — should immediately fail
        await sut.uploadWorkout(
            name: "Test", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )

        XCTAssertFalse(sut.isUploading)
    }

    // MARK: - Stress: Many Rapid Store Operations

    func testRapidTokenStoreOperations() {
        for i in 0..<100 {
            sut.accessToken = "tok_\(i)"
            XCTAssertEqual(sut.accessToken, "tok_\(i)")
            sut.refreshToken = "ref_\(i)"
            sut.tokenExpiry = Date().addingTimeInterval(TimeInterval(i))
            sut.athleteName = "User \(i)"
        }

        // Final state should reflect last write
        XCTAssertEqual(sut.accessToken, "tok_99")
        XCTAssertEqual(sut.refreshToken, "ref_99")
        XCTAssertEqual(sut.athleteName, "User 99")
    }
}

// MARK: - Slow Mock Network Client

final class SlowMockNetworkClient: StravaNetworkClient, @unchecked Sendable {
    let response: (Data, URLResponse)
    let delay: TimeInterval

    init(response: (Data, URLResponse), delay: TimeInterval) {
        self.response = response
        self.delay = delay
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await Task.sleep(for: .seconds(delay))
        return response
    }
}
