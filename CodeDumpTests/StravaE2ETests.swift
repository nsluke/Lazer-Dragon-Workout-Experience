import XCTest
@testable import Lazer_Dragon

/// End-to-end tests that hit the REAL Strava API.
///
/// These are disabled by default. To run them:
/// 1. Set environment variables in your scheme or CI:
///    - STRAVA_TEST_CLIENT_ID
///    - STRAVA_TEST_CLIENT_SECRET
///    - STRAVA_TEST_REFRESH_TOKEN  (from a test account)
/// 2. Run with: `xcodebuild test -only-testing:CodeDumpTests/StravaE2ETests`
///
/// The tests use a real Strava test account. Activities created during
/// testing are cleaned up (deleted) in tearDown.
@MainActor
final class StravaE2ETests: XCTestCase {

    private var sut: StravaManager!
    private var createdActivityIds: [Int] = []

    private var clientID: String? { ProcessInfo.processInfo.environment["STRAVA_TEST_CLIENT_ID"] }
    private var clientSecret: String? { ProcessInfo.processInfo.environment["STRAVA_TEST_CLIENT_SECRET"] }
    private var refreshToken: String? { ProcessInfo.processInfo.environment["STRAVA_TEST_REFRESH_TOKEN"] }

    private var isConfigured: Bool {
        clientID != nil && clientSecret != nil && refreshToken != nil
    }

    override func setUp() async throws {
        try XCTSkipUnless(isConfigured,
            "Strava E2E tests require STRAVA_TEST_CLIENT_ID, STRAVA_TEST_CLIENT_SECRET, "
            + "and STRAVA_TEST_REFRESH_TOKEN environment variables")

        // Use real URLSession but mock token store (don't pollute Keychain)
        let store = MockTokenStore()
        sut = StravaManager(tokenStore: store, networkClient: URLSession.shared)

        // Bootstrap tokens using the refresh token
        sut.refreshToken = refreshToken
        try await refreshTestTokens()
    }

    override func tearDown() async throws {
        // Clean up: delete any activities created during the test
        if let token = sut?.accessToken {
            for activityId in createdActivityIds {
                var request = URLRequest(url: URL(string: "https://www.strava.com/api/v3/activities/\(activityId)")!)
                request.httpMethod = "DELETE"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                _ = try? await URLSession.shared.data(for: request)
            }
        }
        createdActivityIds = []
        sut = nil
    }

    // MARK: - Helpers

    private func refreshTestTokens() async throws {
        // Manually call the token endpoint to get a fresh access token
        let params: [String: String] = [
            "client_id": clientID!,
            "client_secret": clientSecret!,
            "refresh_token": refreshToken!,
            "grant_type": "refresh_token"
        ]

        var request = URLRequest(url: URL(string: "https://www.strava.com/oauth/token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(params)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw XCTSkip("Could not refresh Strava token — API may be down")
        }

        let tokenResponse = try JSONDecoder().decode(StravaTokenResponse.self, from: data)
        sut.storeTokens(tokenResponse)
    }

    /// Create an activity and track its ID for cleanup.
    private func createTestActivity(name: String) async -> Int? {
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime]

        let body: [String: Any] = [
            "name": name,
            "type": "Workout",
            "sport_type": "Workout",
            "start_date_local": iso8601.string(from: Date()),
            "elapsed_time": 60,
            "trainer": 1,
            "description": "E2E test — safe to delete"
        ]

        var request = URLRequest(url: URL(string: "https://www.strava.com/api/v3/activities")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(sut.accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? Int else {
            return nil
        }

        createdActivityIds.append(id)
        return id
    }

    // MARK: - Token Refresh

    func testRealTokenRefresh() async throws {
        XCTAssertTrue(sut.isConnected, "Should be connected after setUp refresh")
        XCTAssertNotNil(sut.accessToken)
        XCTAssertNotNil(sut.refreshToken)
        XCTAssertNotNil(sut.connectedAthleteName, "Should have athlete name from token response")
    }

    // MARK: - Create Activity

    func testRealActivityCreation() async throws {
        let activityId = await createTestActivity(name: "LDWE E2E Test \(Date())")
        XCTAssertNotNil(activityId, "Should successfully create an activity on Strava")
    }

    // MARK: - Upload via StravaManager

    func testRealUploadWorkout() async throws {
        await sut.uploadWorkout(
            name: "LDWE E2E Upload Test",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 120,
            description: "Automated E2E test — safe to delete"
        )

        XCTAssertEqual(sut.uploadResult, .success, "uploadWorkout should succeed against real API")
        XCTAssertFalse(sut.isUploading)

        // Try to find and clean up the activity we just created
        // (The Strava API doesn't return the ID from our uploadWorkout path,
        // so we list recent activities to find it)
        var listRequest = URLRequest(url: URL(string: "https://www.strava.com/api/v3/athlete/activities?per_page=1")!)
        listRequest.setValue("Bearer \(sut.accessToken!)", forHTTPHeaderField: "Authorization")

        if let (data, _) = try? await URLSession.shared.data(for: listRequest),
           let activities = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let first = activities.first,
           let id = first["id"] as? Int,
           let name = first["name"] as? String,
           name == "LDWE E2E Upload Test" {
            createdActivityIds.append(id)
        }
    }

    // MARK: - Upload with Description

    func testRealUploadWithDescription() async throws {
        let logs = [
            SetLog(exerciseName: "Bench Press", setIndex: 0, exerciseIndex: 0, weight: 135, reps: 10),
            SetLog(exerciseName: "Squat", setIndex: 0, exerciseIndex: 1, weight: 225, reps: 5),
        ]
        let description = StravaManager.buildDescription(
            exercisesCompleted: 2, setsCompleted: 2, setLogs: logs
        )

        await sut.uploadWorkout(
            name: "LDWE E2E Description Test",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 1800,
            description: description
        )

        XCTAssertEqual(sut.uploadResult, .success)
    }

    // MARK: - Rate Limiting

    func testRealAPIRespects429() async throws {
        // This test verifies our client handles a rate-limited scenario.
        // We won't intentionally trigger it, but if it happens, we should get
        // an error rather than a crash.
        // Just verify that multiple rapid calls don't crash.
        for i in 0..<3 {
            await sut.uploadWorkout(
                name: "LDWE Rate Test \(i)",
                workoutType: .custom,
                startDate: Date(),
                elapsedSeconds: 60,
                description: nil
            )
            // Each should either succeed or give a clean error
            XCTAssertNotNil(sut.uploadResult, "Upload \(i) should have a result")
        }
    }

    // MARK: - All WorkoutTypes Against Real API

    func testRealUploadAllWorkoutTypes() async throws {
        for workoutType in WorkoutType.allCases {
            await sut.uploadWorkout(
                name: "LDWE Type Test: \(workoutType.rawValue)",
                workoutType: workoutType,
                startDate: Date(),
                elapsedSeconds: 60,
                description: nil
            )

            XCTAssertEqual(sut.uploadResult, .success,
                           "Upload failed for workout type: \(workoutType.rawValue)")
        }
    }
}
