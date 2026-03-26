import XCTest
@testable import Lazer_Dragon

/// Error injection tests — verify graceful handling of hostile network
/// conditions: timeouts, partial responses, malformed JSON, SSL errors,
/// HTTP edge cases, and server error codes.
@MainActor
final class StravaErrorInjectionTests: XCTestCase {

    private var store: MockTokenStore!
    private var network: MockNetworkClient!
    private var sut: StravaManager!

    override func setUp() async throws {
        store = MockTokenStore()
        network = MockNetworkClient()
        sut = StravaManager(tokenStore: store, networkClient: network)
        connectStrava()
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

    private func upload() async {
        await sut.uploadWorkout(
            name: "Test", workoutType: .strength, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )
    }

    private func assertUploadFailed(containing substring: String? = nil,
                                     file: StaticString = #filePath, line: UInt = #line) {
        guard case .error(let msg) = sut.uploadResult else {
            XCTFail("Expected error result, got \(String(describing: sut.uploadResult))", file: file, line: line)
            return
        }
        if let substring {
            XCTAssertTrue(msg.contains(substring),
                          "Error '\(msg)' should contain '\(substring)'", file: file, line: line)
        }
        XCTAssertFalse(sut.isUploading, file: file, line: line)
    }

    // MARK: - Network Errors

    func testTimeout() async {
        network.error = URLError(.timedOut)
        await upload()
        assertUploadFailed()
    }

    func testConnectionLost() async {
        network.error = URLError(.networkConnectionLost)
        await upload()
        assertUploadFailed()
    }

    func testNotConnectedToInternet() async {
        network.error = URLError(.notConnectedToInternet)
        await upload()
        assertUploadFailed()
    }

    func testDNSLookupFailed() async {
        network.error = URLError(.cannotFindHost)
        await upload()
        assertUploadFailed()
    }

    func testCannotConnectToHost() async {
        network.error = URLError(.cannotConnectToHost)
        await upload()
        assertUploadFailed()
    }

    // MARK: - SSL/TLS Errors

    func testSSLHandshakeFailed() async {
        network.error = URLError(.secureConnectionFailed)
        await upload()
        assertUploadFailed()
    }

    func testServerCertificateUntrusted() async {
        network.error = URLError(.serverCertificateUntrusted)
        await upload()
        assertUploadFailed()
    }

    func testServerCertificateExpired() async {
        network.error = URLError(.serverCertificateHasBadDate)
        await upload()
        assertUploadFailed()
    }

    // MARK: - HTTP Status Codes

    func testBadRequest_400() async {
        network.responses.append((Data(), httpResponse(400)))
        await upload()
        assertUploadFailed(containing: "400")
    }

    func testUnauthorized_401_WithFailedRefresh() async {
        // 401 triggers refresh, but refresh also fails
        network.responses.append((Data(), httpResponse(401)))
        network.responses.append((Data(), httpResponse(401))) // refresh fails
        await upload()
        assertUploadFailed()
    }

    func testForbidden_403() async {
        network.responses.append((Data(), httpResponse(403)))
        await upload()
        assertUploadFailed(containing: "403")
    }

    func testNotFound_404() async {
        network.responses.append((Data(), httpResponse(404)))
        await upload()
        assertUploadFailed(containing: "404")
    }

    func testRateLimited_429() async {
        network.responses.append((Data(), httpResponse(429)))
        await upload()
        assertUploadFailed(containing: "429")
    }

    func testInternalServerError_500() async {
        network.responses.append((Data(), httpResponse(500)))
        await upload()
        assertUploadFailed(containing: "500")
    }

    func testBadGateway_502() async {
        network.responses.append((Data(), httpResponse(502)))
        await upload()
        assertUploadFailed(containing: "502")
    }

    func testServiceUnavailable_503() async {
        network.responses.append((Data(), httpResponse(503)))
        await upload()
        assertUploadFailed(containing: "503")
    }

    func testGatewayTimeout_504() async {
        network.responses.append((Data(), httpResponse(504)))
        await upload()
        assertUploadFailed(containing: "504")
    }

    // MARK: - Malformed Responses

    func testEmptyResponseBody_SuccessCode() async {
        // Server returns 201 with empty body — should still be treated as success
        network.responses.append((Data(), httpResponse(201)))
        await upload()
        XCTAssertEqual(sut.uploadResult, .success)
    }

    func testGarbageResponseBody() async {
        // Server returns 201 with garbage — should still be success (we don't parse the response body)
        network.responses.append(("not json at all 🗑️".data(using: .utf8)!, httpResponse(201)))
        await upload()
        XCTAssertEqual(sut.uploadResult, .success)
    }

    func testHTMLErrorPage() async {
        let html = "<html><body><h1>502 Bad Gateway</h1></body></html>".data(using: .utf8)!
        network.responses.append((html, httpResponse(502)))
        await upload()
        assertUploadFailed(containing: "502")
    }

    // MARK: - Malformed Token Responses

    func testTokenExchange_MalformedJSON() async {
        network.responses.append(("not json".data(using: .utf8)!, httpResponse(200)))

        await sut.exchangeCode("code")

        if case .error(let msg) = sut.uploadResult {
            XCTAssertTrue(msg.contains("Token exchange failed"), "Got: \(msg)")
        } else {
            XCTFail("Expected error for malformed token JSON")
        }
    }

    func testTokenExchange_EmptyJSON() async {
        network.responses.append(("{}".data(using: .utf8)!, httpResponse(200)))

        await sut.exchangeCode("code")

        // Missing required fields should cause decoding error
        if case .error(let msg) = sut.uploadResult {
            XCTAssertTrue(msg.contains("Token exchange failed"), "Got: \(msg)")
        } else {
            XCTFail("Expected error for empty JSON token response")
        }
    }

    func testTokenExchange_WrongTypes() async {
        // access_token as number instead of string
        let json = #"{"access_token": 12345, "refresh_token": "r", "expires_at": 100}"#
        network.responses.append((json.data(using: .utf8)!, httpResponse(200)))

        await sut.exchangeCode("code")

        if case .error = sut.uploadResult {
            // Expected — type mismatch
        } else {
            XCTFail("Expected decoding error for wrong types")
        }
    }

    func testTokenExchange_NullValues() async {
        let json = #"{"access_token": null, "refresh_token": null, "expires_at": null}"#
        network.responses.append((json.data(using: .utf8)!, httpResponse(200)))

        await sut.exchangeCode("code")

        if case .error = sut.uploadResult {
            // Expected
        } else {
            XCTFail("Expected error for null token values")
        }
    }

    // MARK: - Token Refresh Failures

    func testTokenRefresh_ServerDown() async {
        // Expire the token
        store.save(key: "strava_token_expiry",
                   value: String(Date().addingTimeInterval(-60).timeIntervalSince1970))

        // Refresh request fails with network error
        network.error = URLError(.cannotConnectToHost)

        await upload()
        assertUploadFailed()
    }

    func testTokenRefresh_ReturnsMalformedJSON() async {
        store.save(key: "strava_token_expiry",
                   value: String(Date().addingTimeInterval(-60).timeIntervalSince1970))

        network.responses.append(("broken".data(using: .utf8)!, httpResponse(200)))

        await upload()
        assertUploadFailed()
    }

    func testTokenRefresh_Returns200ButInvalidToken() async {
        store.save(key: "strava_token_expiry",
                   value: String(Date().addingTimeInterval(-60).timeIntervalSince1970))

        // Valid JSON but missing fields
        network.responses.append(("{}".data(using: .utf8)!, httpResponse(200)))

        await upload()
        assertUploadFailed()
    }

    // MARK: - Edge Cases

    func testUploadWithEmptyName() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        // We send it as-is — Strava may reject it, but we shouldn't crash
        XCTAssertFalse(sut.isUploading)
        XCTAssertNotNil(sut.uploadResult)
    }

    func testUploadWithZeroElapsedTime() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Zero Time",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 0,
            description: nil
        )

        XCTAssertFalse(sut.isUploading)
        XCTAssertNotNil(sut.uploadResult)
    }

    func testUploadWithVeryLongDescription() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        let longDescription = String(repeating: "A", count: 10_000)
        await sut.uploadWorkout(
            name: "Long Desc",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 60,
            description: longDescription
        )

        // Should not crash; may succeed or fail depending on Strava limits
        XCTAssertFalse(sut.isUploading)
        XCTAssertNotNil(sut.uploadResult)
    }

    func testUploadWithUnicodeCharacters() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "光線竜 Workout 🐉",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 60,
            description: "Bench Press: 60kg × 10回 🏋️"
        )

        XCTAssertEqual(sut.uploadResult, .success)
        // Verify the JSON was valid
        let body = try! JSONSerialization.jsonObject(with: network.capturedRequests[0].httpBody!) as! [String: Any]
        XCTAssertEqual(body["name"] as? String, "光線竜 Workout 🐉")
        XCTAssertEqual(body["description"] as? String, "Bench Press: 60kg × 10回 🏋️")
    }

    func testUploadWithDistantPastDate() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Old Workout",
            workoutType: .custom,
            startDate: Date(timeIntervalSince1970: 0), // 1970-01-01
            elapsedSeconds: 60,
            description: nil
        )

        XCTAssertFalse(sut.isUploading)
        // Verify the date was serialized
        let body = try! JSONSerialization.jsonObject(with: network.capturedRequests[0].httpBody!) as! [String: Any]
        let dateStr = body["start_date_local"] as! String
        XCTAssertTrue(dateStr.contains("1970"), "Should contain 1970: \(dateStr)")
    }

    func testUploadWithFutureDate() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Future Workout",
            workoutType: .custom,
            startDate: Date().addingTimeInterval(86400 * 365), // 1 year from now
            elapsedSeconds: 60,
            description: nil
        )

        XCTAssertFalse(sut.isUploading)
        XCTAssertNotNil(sut.uploadResult)
    }

    // MARK: - Recovery After Error

    func testCanUploadSuccessfullyAfterNetworkError() async {
        // First: network error
        network.error = URLError(.timedOut)
        await upload()
        assertUploadFailed()

        // Second: success
        network.error = nil
        network.responses.append((Data("{}".utf8), httpResponse(201)))
        await upload()
        XCTAssertEqual(sut.uploadResult, .success)
    }

    func testCanUploadSuccessfullyAfterServerError() async {
        // First: 500
        network.responses.append((Data(), httpResponse(500)))
        await upload()
        assertUploadFailed()

        // Second: success
        network.responses.append((Data("{}".utf8), httpResponse(201)))
        await upload()
        XCTAssertEqual(sut.uploadResult, .success)
    }

    func testCanUploadAfterMalformedTokenRefresh() async {
        // Expire token
        store.save(key: "strava_token_expiry",
                   value: String(Date().addingTimeInterval(-60).timeIntervalSince1970))
        // Malformed refresh response
        network.responses.append(("broken".data(using: .utf8)!, httpResponse(200)))
        await upload()
        assertUploadFailed()

        // Fix token and retry
        store.save(key: "strava_token_expiry",
                   value: String(Date().addingTimeInterval(3600).timeIntervalSince1970))
        network.responses.append((Data("{}".utf8), httpResponse(201)))
        await upload()
        XCTAssertEqual(sut.uploadResult, .success)
    }
}
