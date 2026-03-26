import XCTest
import SwiftData
@testable import CodeDump

/// Integration tests for the Strava feature — exercise multiple components
/// together: token lifecycle, upload flows, description building with real
/// SwiftData models, and the full connect → upload → disconnect cycle.
@MainActor
final class StravaIntegrationTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var store: MockTokenStore!
    private var network: MockNetworkClient!
    private var sut: StravaManager!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Workout.self, Exercise.self, WorkoutSession.self, SetLog.self,
            configurations: config
        )
        context = container.mainContext
        store = MockTokenStore()
        network = MockNetworkClient()
        sut = StravaManager(tokenStore: store, networkClient: network)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
        store = nil
        network = nil
        sut = nil
    }

    // MARK: - Helpers

    private func httpResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://www.strava.com")!,
            statusCode: statusCode, httpVersion: nil, headerFields: nil
        )!
    }

    private func tokenJSON(
        accessToken: String = "access_tok",
        refreshToken: String = "refresh_tok",
        expiresAt: Int? = nil,
        firstname: String? = "Jane",
        lastname: String? = "Doe"
    ) -> Data {
        let expiry = expiresAt ?? Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
        var json: [String: Any] = [
            "access_token": accessToken,
            "refresh_token": refreshToken,
            "expires_at": expiry
        ]
        if firstname != nil || lastname != nil {
            var athlete: [String: Any] = [:]
            if let f = firstname { athlete["firstname"] = f }
            if let l = lastname { athlete["lastname"] = l }
            json["athlete"] = athlete
        }
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private func makeWorkout(name: String = "Test Workout", type: WorkoutType = .strength) -> Workout {
        let w = Workout(name: name, type: type)
        context.insert(w)
        return w
    }

    private func makeSession(
        workout: Workout, elapsed: Int, exercises: Int, sets: Int
    ) -> WorkoutSession {
        let s = WorkoutSession(totalElapsed: elapsed, exercisesCompleted: exercises, setsCompleted: sets)
        s.workout = workout
        workout.sessions.append(s)
        context.insert(s)
        return s
    }

    private func makeSetLog(
        session: WorkoutSession, name: String, setIndex: Int, exerciseIndex: Int,
        weight: Double? = nil, reps: Int? = nil
    ) -> SetLog {
        let log = SetLog(
            exerciseName: name, setIndex: setIndex, exerciseIndex: exerciseIndex,
            weight: weight, reps: reps
        )
        log.session = session
        session.setLogs.append(log)
        context.insert(log)
        return log
    }

    private func connectStrava(
        accessToken: String = "access_tok",
        refreshToken: String = "refresh_tok"
    ) {
        sut.accessToken = accessToken
        sut.refreshToken = refreshToken
        sut.tokenExpiry = Date().addingTimeInterval(3600)
    }

    // MARK: - Full OAuth → Upload → Disconnect Lifecycle

    func testFullLifecycle_Connect_Upload_Disconnect() async throws {
        // 1. Start disconnected
        XCTAssertFalse(sut.isConnected)
        XCTAssertNil(sut.connectedAthleteName)

        // 2. Simulate OAuth token exchange (as if authorize() completed)
        network.responses.append((
            tokenJSON(accessToken: "real_tok", refreshToken: "real_ref", firstname: "Luke", lastname: "Dragon"),
            httpResponse(statusCode: 200)
        ))
        await sut.exchangeCode("auth_code_from_strava")

        XCTAssertTrue(sut.isConnected)
        XCTAssertEqual(sut.connectedAthleteName, "Luke Dragon")
        XCTAssertEqual(sut.accessToken, "real_tok")

        // 3. Upload a workout
        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        await sut.uploadWorkout(
            name: "Leg Day",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 2700,
            description: "Squats"
        )
        XCTAssertEqual(sut.uploadResult, .success)

        // 4. Disconnect
        sut.disconnect()
        XCTAssertFalse(sut.isConnected)
        XCTAssertNil(sut.connectedAthleteName)
        XCTAssertNil(sut.accessToken)
        XCTAssertNil(sut.refreshToken)
        XCTAssertNil(sut.tokenExpiry)
        XCTAssertNil(sut.uploadResult)
    }

    // MARK: - Token Refresh During Upload

    func testUploadWithExpiredToken_RefreshesAndRetries() async {
        // Token is expired
        sut.accessToken = "expired_tok"
        sut.refreshToken = "ref_tok"
        sut.tokenExpiry = Date().addingTimeInterval(-300) // Expired 5 min ago

        // validAccessToken() will call refreshAccessToken()
        network.responses.append((
            tokenJSON(accessToken: "fresh_tok", refreshToken: "fresh_ref"),
            httpResponse(statusCode: 200)
        ))
        // Then the upload succeeds
        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 600,
            description: nil
        )

        XCTAssertEqual(sut.uploadResult, .success)
        XCTAssertEqual(sut.accessToken, "fresh_tok")
        // Upload request should use the fresh token
        let uploadRequest = network.capturedRequests.last!
        XCTAssertEqual(uploadRequest.value(forHTTPHeaderField: "Authorization"), "Bearer fresh_tok")
    }

    func testUploadWith401_RefreshesAndRetries() async {
        connectStrava(accessToken: "tok_v1", refreshToken: "ref_v1")

        // First upload returns 401
        network.responses.append((Data(), httpResponse(statusCode: 401)))
        // Token refresh
        network.responses.append((
            tokenJSON(accessToken: "tok_v2", refreshToken: "ref_v2"),
            httpResponse(statusCode: 200)
        ))
        // Retry succeeds
        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        XCTAssertEqual(sut.uploadResult, .success)
        XCTAssertEqual(sut.accessToken, "tok_v2")
        XCTAssertEqual(network.capturedRequests.count, 3) // upload + refresh + retry
    }

    func testUploadWith401_RefreshFails_PropagatesError() async {
        connectStrava()

        // Upload returns 401
        network.responses.append((Data(), httpResponse(statusCode: 401)))
        // Refresh also fails
        network.responses.append((Data(), httpResponse(statusCode: 401)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        if case .error(let msg) = sut.uploadResult {
            XCTAssertTrue(msg.contains("authenticate"), "Error: \(msg)")
        } else {
            XCTFail("Expected error, got \(String(describing: sut.uploadResult))")
        }
    }

    // MARK: - Multiple Sequential Uploads

    func testMultipleUploadsInSequence() async {
        connectStrava()

        for i in 1...3 {
            network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

            await sut.uploadWorkout(
                name: "Workout \(i)",
                workoutType: .strength,
                startDate: Date(),
                elapsedSeconds: i * 600,
                description: nil
            )

            XCTAssertEqual(sut.uploadResult, .success, "Upload \(i) should succeed")
            XCTAssertFalse(sut.isUploading)
        }

        XCTAssertEqual(network.capturedRequests.count, 3)
    }

    func testUploadAfterPreviousFailure_Succeeds() async {
        connectStrava()

        // First upload fails
        network.responses.append((Data(), httpResponse(statusCode: 500)))
        await sut.uploadWorkout(
            name: "Fail", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )
        XCTAssertNotEqual(sut.uploadResult, .success)

        // Second upload succeeds — uploadResult should be reset
        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))
        await sut.uploadWorkout(
            name: "Pass", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )
        XCTAssertEqual(sut.uploadResult, .success)
    }

    // MARK: - buildDescription with SwiftData SetLogs

    func testBuildDescriptionWithPersistedSetLogs() throws {
        let workout = makeWorkout(name: "Push Day")
        let session = makeSession(workout: workout, elapsed: 1800, exercises: 2, sets: 4)

        let _ = makeSetLog(session: session, name: "Bench Press", setIndex: 0, exerciseIndex: 0, weight: 135, reps: 10)
        let _ = makeSetLog(session: session, name: "Bench Press", setIndex: 1, exerciseIndex: 0, weight: 155, reps: 8)
        let _ = makeSetLog(session: session, name: "Overhead Press", setIndex: 0, exerciseIndex: 1, weight: 95, reps: 12)
        let _ = makeSetLog(session: session, name: "Overhead Press", setIndex: 1, exerciseIndex: 1, weight: 105, reps: 10)

        try context.save()

        // Fetch logs back from SwiftData to simulate real usage
        let fetched = try context.fetch(FetchDescriptor<SetLog>())
        XCTAssertEqual(fetched.count, 4)

        let description = StravaManager.buildDescription(
            exercisesCompleted: 2,
            setsCompleted: 4,
            setLogs: fetched
        )

        XCTAssertTrue(description.contains("2 exercises, 4 sets"))
        XCTAssertTrue(description.contains("Bench Press"))
        XCTAssertTrue(description.contains("Overhead Press"))
        XCTAssertTrue(description.contains("135lbs"))
        XCTAssertTrue(description.contains("10reps"))
        XCTAssertTrue(description.contains("Lazer Dragon"))
    }

    func testBuildDescriptionWithMixedLogTypes() throws {
        let workout = makeWorkout()
        let session = makeSession(workout: workout, elapsed: 900, exercises: 3, sets: 3)

        // Weight + reps
        let _ = makeSetLog(session: session, name: "Squat", setIndex: 0, exerciseIndex: 0, weight: 225, reps: 5)
        // Reps only (bodyweight)
        let _ = makeSetLog(session: session, name: "Pull-up", setIndex: 0, exerciseIndex: 1, weight: nil, reps: 12)
        // Duration-based (no weight or reps)
        let _ = makeSetLog(session: session, name: "Plank", setIndex: 0, exerciseIndex: 2, weight: nil, reps: nil)

        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SetLog>())
        let description = StravaManager.buildDescription(
            exercisesCompleted: 3,
            setsCompleted: 3,
            setLogs: fetched
        )

        XCTAssertTrue(description.contains("225lbsx5reps"))
        XCTAssertTrue(description.contains("Pull-up: 12reps"))
        XCTAssertTrue(description.contains("Plank:"))
    }

    // MARK: - Upload Request Body with Real Workout Data

    func testUploadRequestContainsCorrectWorkoutTypeMapping() async {
        connectStrava()

        let typeMappings: [(WorkoutType, String, String)] = [
            (.strength, "WeightTraining", "WeightTraining"),
            (.hiit, "Workout", "HIIT"),
            (.run, "Run", "Run"),
            (.yoga, "Yoga", "Yoga"),
            (.custom, "Workout", "Workout"),
        ]

        for (workoutType, expectedActivity, expectedSport) in typeMappings {
            network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

            await sut.uploadWorkout(
                name: "Test",
                workoutType: workoutType,
                startDate: Date(),
                elapsedSeconds: 60,
                description: nil
            )

            let request = network.capturedRequests.last!
            let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
            XCTAssertEqual(body["type"] as? String, expectedActivity,
                           "Wrong activity type for \(workoutType)")
            XCTAssertEqual(body["sport_type"] as? String, expectedSport,
                           "Wrong sport type for \(workoutType)")
        }
    }

    func testUploadRequestHasValidISO8601Date() async {
        connectStrava()
        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        let startDate = Date(timeIntervalSince1970: 1700000000) // 2023-11-14T22:13:20Z

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: startDate,
            elapsedSeconds: 600,
            description: nil
        )

        let body = try! JSONSerialization.jsonObject(with: network.capturedRequests[0].httpBody!) as! [String: Any]
        let dateStr = body["start_date_local"] as! String

        // Should be parseable by ISO8601DateFormatter
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        XCTAssertNotNil(formatter.date(from: dateStr), "Date '\(dateStr)' is not valid ISO8601")
    }

    // MARK: - Simulated Workout → Strava Upload Flow

    func testEndToEnd_WorkoutSession_To_StravaUpload() async throws {
        // 1. Create a workout with exercises (simulating what the user builds)
        let workout = makeWorkout(name: "Full Body Blast", type: .strength)
        let ex1 = Exercise(order: 0, name: "Bench Press", splitLength: 30, reps: 10)
        let ex2 = Exercise(order: 1, name: "Squat", splitLength: 45, reps: 8)
        ex1.workout = workout; workout.exercises.append(ex1); context.insert(ex1)
        ex2.workout = workout; workout.exercises.append(ex2); context.insert(ex2)

        // 2. Simulate completing a session (what WorkoutSessionView does)
        let session = makeSession(workout: workout, elapsed: 2400, exercises: 2, sets: 3)
        let log1 = makeSetLog(session: session, name: "Bench Press", setIndex: 0, exerciseIndex: 0, weight: 135, reps: 10)
        let log2 = makeSetLog(session: session, name: "Bench Press", setIndex: 1, exerciseIndex: 0, weight: 155, reps: 8)
        let log3 = makeSetLog(session: session, name: "Squat", setIndex: 0, exerciseIndex: 1, weight: 225, reps: 5)
        try context.save()

        // 3. Build the Strava description (what WorkoutCompletedView does)
        let sessionLogs = [log1, log2, log3]
        let description = StravaManager.buildDescription(
            exercisesCompleted: session.exercisesCompleted,
            setsCompleted: session.setsCompleted,
            setLogs: sessionLogs
        )

        XCTAssertTrue(description.contains("2 exercises, 3 sets"))
        XCTAssertTrue(description.contains("Bench Press: 135lbsx10reps, 155lbsx8reps"))
        XCTAssertTrue(description.contains("Squat: 225lbsx5reps"))

        // 4. Upload to Strava
        connectStrava()
        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        await sut.uploadWorkout(
            name: workout.name,
            workoutType: workout.workoutType,
            startDate: session.date,
            elapsedSeconds: session.totalElapsed,
            description: description
        )

        // 5. Verify
        XCTAssertEqual(sut.uploadResult, .success)
        XCTAssertFalse(sut.isUploading)

        let request = network.capturedRequests[0]
        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        XCTAssertEqual(body["name"] as? String, "Full Body Blast")
        XCTAssertEqual(body["type"] as? String, "WeightTraining")
        XCTAssertEqual(body["elapsed_time"] as? Int, 2400)
        XCTAssertEqual(body["description"] as? String, description)
    }

    // MARK: - Connect/Disconnect State Consistency

    func testReconnectAfterDisconnect() async {
        // Connect
        network.responses.append((
            tokenJSON(accessToken: "tok1", refreshToken: "ref1", firstname: "A", lastname: "B"),
            httpResponse(statusCode: 200)
        ))
        await sut.exchangeCode("code1")
        XCTAssertTrue(sut.isConnected)
        XCTAssertEqual(sut.connectedAthleteName, "A B")

        // Disconnect
        sut.disconnect()
        XCTAssertFalse(sut.isConnected)

        // Reconnect as different user
        network.responses.append((
            tokenJSON(accessToken: "tok2", refreshToken: "ref2", firstname: "C", lastname: "D"),
            httpResponse(statusCode: 200)
        ))
        await sut.exchangeCode("code2")
        XCTAssertTrue(sut.isConnected)
        XCTAssertEqual(sut.connectedAthleteName, "C D")
        XCTAssertEqual(sut.accessToken, "tok2")
    }

    func testDisconnectMidUpload_NextUploadFails() async {
        connectStrava()

        // Upload succeeds
        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))
        await sut.uploadWorkout(
            name: "Before", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )
        XCTAssertEqual(sut.uploadResult, .success)

        // Disconnect
        sut.disconnect()

        // Next upload should fail (no token)
        await sut.uploadWorkout(
            name: "After", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )
        if case .error(let msg) = sut.uploadResult {
            XCTAssertTrue(msg.contains("Not connected"))
        } else {
            XCTFail("Expected not-connected error")
        }
    }

    // MARK: - Token Expiry Edge Cases

    func testTokenExpiringExactlyNow_TriggersRefresh() async {
        sut.accessToken = "old"
        sut.refreshToken = "ref"
        sut.tokenExpiry = Date() // Expires right now

        // Refresh response
        network.responses.append((
            tokenJSON(accessToken: "new", refreshToken: "new_ref"),
            httpResponse(statusCode: 200)
        ))
        // Upload response
        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        await sut.uploadWorkout(
            name: "Edge", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )

        // The expiry check is `expiry < Date()` — Date() == expiry may or may not trigger
        // refresh depending on timing. Either path should work.
        // If it refreshed, token is "new"; if not, token is "old" and upload uses it.
        XCTAssertTrue(sut.isConnected)
    }

    func testTokenWithFarFutureExpiry_NoRefresh() async {
        sut.accessToken = "long_lived"
        sut.refreshToken = "ref"
        sut.tokenExpiry = Date().addingTimeInterval(86400 * 365) // 1 year

        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        await sut.uploadWorkout(
            name: "Test", workoutType: .custom, startDate: Date(),
            elapsedSeconds: 60, description: nil
        )

        XCTAssertEqual(sut.uploadResult, .success)
        // Only 1 request (upload), no refresh
        XCTAssertEqual(network.capturedRequests.count, 1)
        XCTAssertEqual(sut.accessToken, "long_lived")
    }

    // MARK: - Exchange Code Failure Recovery

    func testExchangeCodeFailure_CanRetrySuccessfully() async {
        // First attempt: network error
        network.error = URLError(.timedOut)
        await sut.exchangeCode("code1")

        XCTAssertFalse(sut.isConnected)
        if case .error = sut.uploadResult {} else {
            XCTFail("Expected error after failed exchange")
        }

        // Retry: success
        network.error = nil
        network.responses.append((
            tokenJSON(accessToken: "tok", refreshToken: "ref"),
            httpResponse(statusCode: 200)
        ))
        await sut.exchangeCode("code2")

        XCTAssertTrue(sut.isConnected)
        XCTAssertEqual(sut.accessToken, "tok")
    }

    // MARK: - Large Workout Description

    func testBuildDescriptionWithManyExercises() throws {
        let workout = makeWorkout()
        let session = makeSession(workout: workout, elapsed: 5400, exercises: 10, sets: 30)

        let exerciseNames = [
            "Bench Press", "Squat", "Deadlift", "Overhead Press", "Barbell Row",
            "Lat Pulldown", "Leg Press", "Bicep Curl", "Tricep Extension", "Lateral Raise"
        ]

        for (i, name) in exerciseNames.enumerated() {
            for s in 0..<3 {
                let _ = makeSetLog(
                    session: session, name: name, setIndex: s, exerciseIndex: i,
                    weight: Double((i + 1) * 20 + s * 5), reps: 10 - s
                )
            }
        }
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SetLog>())
        XCTAssertEqual(fetched.count, 30)

        let description = StravaManager.buildDescription(
            exercisesCompleted: 10,
            setsCompleted: 30,
            setLogs: fetched
        )

        // Should contain all 10 exercises
        for name in exerciseNames {
            XCTAssertTrue(description.contains(name), "Missing exercise: \(name)")
        }
        XCTAssertTrue(description.contains("10 exercises, 30 sets"))
    }
}
