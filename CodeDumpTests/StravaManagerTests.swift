import XCTest
import SwiftData
@testable import Lazer_Dragon

// MARK: - Mock Token Store

final class MockTokenStore: StravaTokenStore, @unchecked Sendable {
    private var storage: [String: String] = [:]

    func read(key: String) -> String? { storage[key] }
    func save(key: String, value: String) { storage[key] = value }
    func delete(key: String) { storage.removeValue(forKey: key) }
}

// MARK: - Mock Network Client

final class MockNetworkClient: StravaNetworkClient, @unchecked Sendable {
    var responses: [(Data, URLResponse)] = []
    var capturedRequests: [URLRequest] = []
    var error: Error?
    private var callIndex = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequests.append(request)
        if let error { throw error }
        guard callIndex < responses.count else {
            throw URLError(.badServerResponse)
        }
        let response = responses[callIndex]
        callIndex += 1
        return response
    }

    func reset() {
        responses = []
        capturedRequests = []
        error = nil
        callIndex = 0
    }
}

// MARK: - Helpers

private func httpResponse(statusCode: Int, url: String = "https://www.strava.com") -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: url)!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private func tokenJSON(
    accessToken: String = "access_123",
    refreshToken: String = "refresh_456",
    expiresAt: Int = Int(Date().addingTimeInterval(3600).timeIntervalSince1970),
    firstname: String? = "Jane",
    lastname: String? = "Doe"
) -> Data {
    var json: [String: Any] = [
        "access_token": accessToken,
        "refresh_token": refreshToken,
        "expires_at": expiresAt
    ]
    if firstname != nil || lastname != nil {
        var athlete: [String: Any] = [:]
        if let f = firstname { athlete["firstname"] = f }
        if let l = lastname { athlete["lastname"] = l }
        json["athlete"] = athlete
    }
    return try! JSONSerialization.data(withJSONObject: json)
}

// MARK: - Tests

@MainActor
final class StravaManagerTests: XCTestCase {

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

    // MARK: - isConnected

    func testIsConnectedFalseByDefault() {
        XCTAssertFalse(sut.isConnected)
    }

    func testIsConnectedTrueWhenAccessTokenStored() {
        store.save(key: "strava_access_token", value: "tok")
        XCTAssertTrue(sut.isConnected)
    }

    // MARK: - disconnect

    func testDisconnectClearsAllTokens() {
        store.save(key: "strava_access_token", value: "a")
        store.save(key: "strava_refresh_token", value: "r")
        store.save(key: "strava_token_expiry", value: "123456")
        store.save(key: "strava_athlete_name", value: "Jane")
        sut.uploadResult = .success

        sut.disconnect()

        XCTAssertNil(store.read(key: "strava_access_token"))
        XCTAssertNil(store.read(key: "strava_refresh_token"))
        XCTAssertNil(store.read(key: "strava_token_expiry"))
        XCTAssertNil(store.read(key: "strava_athlete_name"))
        XCTAssertNil(sut.uploadResult)
        XCTAssertFalse(sut.isConnected)
    }

    // MARK: - connectedAthleteName

    func testConnectedAthleteNameReadsFromStore() {
        XCTAssertNil(sut.connectedAthleteName)
        store.save(key: "strava_athlete_name", value: "Jane Doe")
        XCTAssertEqual(sut.connectedAthleteName, "Jane Doe")
    }

    // MARK: - Token Storage Properties

    func testAccessTokenRoundTrips() {
        XCTAssertNil(sut.accessToken)
        sut.accessToken = "tok123"
        XCTAssertEqual(sut.accessToken, "tok123")
        XCTAssertEqual(store.read(key: "strava_access_token"), "tok123")
    }

    func testAccessTokenSetNilDeletes() {
        sut.accessToken = "tok"
        sut.accessToken = nil
        XCTAssertNil(store.read(key: "strava_access_token"))
    }

    func testRefreshTokenRoundTrips() {
        XCTAssertNil(sut.refreshToken)
        sut.refreshToken = "ref456"
        XCTAssertEqual(sut.refreshToken, "ref456")
    }

    func testTokenExpiryRoundTrips() {
        XCTAssertNil(sut.tokenExpiry)
        let date = Date(timeIntervalSince1970: 1700000000)
        sut.tokenExpiry = date
        XCTAssertEqual(sut.tokenExpiry?.timeIntervalSince1970, 1700000000, accuracy: 1)
    }

    func testTokenExpiryNilForInvalidString() {
        store.save(key: "strava_token_expiry", value: "not_a_number")
        XCTAssertNil(sut.tokenExpiry)
    }

    func testAthleteNameRoundTrips() {
        sut.athleteName = "Test User"
        XCTAssertEqual(sut.athleteName, "Test User")
        sut.athleteName = nil
        XCTAssertNil(sut.athleteName)
    }

    // MARK: - storeTokens

    func testStoreTokensSavesAllFields() {
        let response = StravaTokenResponse(
            access_token: "acc",
            refresh_token: "ref",
            expires_at: 1700000000,
            athlete: .init(firstname: "Jane", lastname: "Doe")
        )
        sut.storeTokens(response)

        XCTAssertEqual(sut.accessToken, "acc")
        XCTAssertEqual(sut.refreshToken, "ref")
        XCTAssertEqual(sut.tokenExpiry?.timeIntervalSince1970, 1700000000, accuracy: 1)
        XCTAssertEqual(sut.athleteName, "Jane Doe")
    }

    func testStoreTokensWithFirstnameOnly() {
        let response = StravaTokenResponse(
            access_token: "a", refresh_token: "r", expires_at: 100,
            athlete: .init(firstname: "Jane", lastname: nil)
        )
        sut.storeTokens(response)
        XCTAssertEqual(sut.athleteName, "Jane")
    }

    func testStoreTokensWithNoAthlete() {
        let response = StravaTokenResponse(
            access_token: "a", refresh_token: "r", expires_at: 100,
            athlete: nil
        )
        sut.storeTokens(response)
        XCTAssertNil(sut.athleteName)
    }

    // MARK: - StravaTokenResponse Decoding

    func testTokenResponseDecodesFullJSON() throws {
        let json = tokenJSON(accessToken: "a", refreshToken: "r", expiresAt: 999, firstname: "John", lastname: "Smith")
        let decoded = try JSONDecoder().decode(StravaTokenResponse.self, from: json)
        XCTAssertEqual(decoded.access_token, "a")
        XCTAssertEqual(decoded.refresh_token, "r")
        XCTAssertEqual(decoded.expires_at, 999)
        XCTAssertEqual(decoded.athlete?.firstname, "John")
        XCTAssertEqual(decoded.athlete?.lastname, "Smith")
    }

    func testTokenResponseDecodesWithoutAthlete() throws {
        let json = try JSONSerialization.data(withJSONObject: [
            "access_token": "a", "refresh_token": "r", "expires_at": 100
        ])
        let decoded = try JSONDecoder().decode(StravaTokenResponse.self, from: json)
        XCTAssertNil(decoded.athlete)
    }

    // MARK: - Activity Type Mapping

    func testStravaActivityTypeMapping() {
        XCTAssertEqual(sut.stravaActivityType(for: .strength), "WeightTraining")
        XCTAssertEqual(sut.stravaActivityType(for: .hiit), "Workout")
        XCTAssertEqual(sut.stravaActivityType(for: .run), "Run")
        XCTAssertEqual(sut.stravaActivityType(for: .yoga), "Yoga")
        XCTAssertEqual(sut.stravaActivityType(for: .custom), "Workout")
    }

    func testStravaSportTypeMapping() {
        XCTAssertEqual(sut.stravaSportType(for: .strength), "WeightTraining")
        XCTAssertEqual(sut.stravaSportType(for: .hiit), "HIIT")
        XCTAssertEqual(sut.stravaSportType(for: .run), "Run")
        XCTAssertEqual(sut.stravaSportType(for: .yoga), "Yoga")
        XCTAssertEqual(sut.stravaSportType(for: .custom), "Workout")
    }

    // MARK: - validAccessToken

    func testValidAccessTokenThrowsWhenNotConnected() async {
        do {
            _ = try await sut.validAccessToken()
            XCTFail("Should have thrown")
        } catch let error as StravaError {
            XCTAssertEqual(error, .notConnected)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testValidAccessTokenReturnsTokenWhenNotExpired() async throws {
        sut.accessToken = "valid_tok"
        sut.tokenExpiry = Date().addingTimeInterval(3600) // 1 hour from now
        let token = try await sut.validAccessToken()
        XCTAssertEqual(token, "valid_tok")
    }

    func testValidAccessTokenReturnsTokenWhenNoExpiry() async throws {
        sut.accessToken = "tok"
        // No expiry set — should still return token
        let token = try await sut.validAccessToken()
        XCTAssertEqual(token, "tok")
    }

    func testValidAccessTokenRefreshesWhenExpired() async throws {
        sut.accessToken = "old_tok"
        sut.refreshToken = "ref_tok"
        sut.tokenExpiry = Date().addingTimeInterval(-60) // Expired 1 min ago

        // Mock the token refresh response
        network.responses.append((
            tokenJSON(accessToken: "new_tok", refreshToken: "new_ref"),
            httpResponse(statusCode: 200)
        ))

        let token = try await sut.validAccessToken()
        XCTAssertEqual(token, "new_tok")
    }

    // MARK: - refreshAccessToken

    func testRefreshAccessTokenThrowsWhenNoRefreshToken() async {
        do {
            try await sut.refreshAccessToken()
            XCTFail("Should have thrown")
        } catch let error as StravaError {
            XCTAssertEqual(error, .notConnected)
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testRefreshAccessTokenUpdatesTokens() async throws {
        sut.refreshToken = "old_ref"
        network.responses.append((
            tokenJSON(accessToken: "new_access", refreshToken: "new_refresh", expiresAt: 9999999999),
            httpResponse(statusCode: 200)
        ))

        try await sut.refreshAccessToken()

        XCTAssertEqual(sut.accessToken, "new_access")
        XCTAssertEqual(sut.refreshToken, "new_refresh")
    }

    // MARK: - requestToken

    func testRequestTokenSendsCorrectRequest() async throws {
        network.responses.append((
            tokenJSON(),
            httpResponse(statusCode: 200)
        ))

        _ = try await sut.requestToken(params: ["grant_type": "authorization_code", "code": "abc"])

        XCTAssertEqual(network.capturedRequests.count, 1)
        let request = network.capturedRequests[0]
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.url?.absoluteString, StravaManager.tokenURL)
    }

    func testRequestTokenThrowsOnNon200() async {
        network.responses.append((Data(), httpResponse(statusCode: 401)))

        do {
            _ = try await sut.requestToken(params: [:])
            XCTFail("Should have thrown")
        } catch let error as StravaError {
            XCTAssertEqual(error, .tokenFailed)
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testRequestTokenThrowsOnNetworkError() async {
        network.error = URLError(.notConnectedToInternet)

        do {
            _ = try await sut.requestToken(params: [:])
            XCTFail("Should have thrown")
        } catch is URLError {
            // Expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - exchangeCode

    func testExchangeCodeStoresTokensOnSuccess() async {
        network.responses.append((
            tokenJSON(accessToken: "exc_tok", refreshToken: "exc_ref", firstname: "Luke", lastname: nil),
            httpResponse(statusCode: 200)
        ))

        await sut.exchangeCode("auth_code_123")

        XCTAssertEqual(sut.accessToken, "exc_tok")
        XCTAssertEqual(sut.refreshToken, "exc_ref")
        XCTAssertEqual(sut.athleteName, "Luke")
        XCTAssertNil(sut.uploadResult) // No error
    }

    func testExchangeCodeSetsErrorOnFailure() async {
        network.error = URLError(.timedOut)

        await sut.exchangeCode("bad_code")

        if case .error(let msg) = sut.uploadResult {
            XCTAssertTrue(msg.contains("Token exchange failed"))
        } else {
            XCTFail("Expected error result, got \(String(describing: sut.uploadResult))")
        }
    }

    // MARK: - uploadWorkout (success)

    func testUploadWorkoutSucceeds() async {
        sut.accessToken = "tok"
        sut.tokenExpiry = Date().addingTimeInterval(3600)

        network.responses.append((
            Data("{}".utf8),
            httpResponse(statusCode: 201)
        ))

        await sut.uploadWorkout(
            name: "Test Workout",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 3600,
            description: "A great workout"
        )

        XCTAssertEqual(sut.uploadResult, .success)
        XCTAssertFalse(sut.isUploading)
    }

    func testUploadWorkoutSendsCorrectBody() async {
        sut.accessToken = "tok"
        sut.tokenExpiry = Date().addingTimeInterval(3600)

        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        let date = Date()
        await sut.uploadWorkout(
            name: "Leg Day",
            workoutType: .strength,
            startDate: date,
            elapsedSeconds: 1800,
            description: "Squats and deadlifts"
        )

        let request = network.capturedRequests[0]
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer tok")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(request.url?.absoluteString, StravaManager.activitiesURL)

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        XCTAssertEqual(body["name"] as? String, "Leg Day")
        XCTAssertEqual(body["type"] as? String, "WeightTraining")
        XCTAssertEqual(body["sport_type"] as? String, "WeightTraining")
        XCTAssertEqual(body["elapsed_time"] as? Int, 1800)
        XCTAssertEqual(body["trainer"] as? Int, 1)
        XCTAssertEqual(body["description"] as? String, "Squats and deadlifts")
    }

    func testUploadWorkoutOmitsDescriptionWhenNil() async {
        sut.accessToken = "tok"
        sut.tokenExpiry = Date().addingTimeInterval(3600)

        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 600,
            description: nil
        )

        let body = try! JSONSerialization.jsonObject(with: network.capturedRequests[0].httpBody!) as! [String: Any]
        XCTAssertNil(body["description"])
    }

    // MARK: - uploadWorkout (failure cases)

    func testUploadWorkoutFailsWhenNotConnected() async {
        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        XCTAssertEqual(sut.uploadResult, .error(StravaError.notConnected.message))
        XCTAssertFalse(sut.isUploading)
    }

    func testUploadWorkoutFailsOnServerError() async {
        sut.accessToken = "tok"
        sut.tokenExpiry = Date().addingTimeInterval(3600)

        network.responses.append((Data(), httpResponse(statusCode: 500)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        XCTAssertEqual(sut.uploadResult, .error("Upload failed: Status 500"))
    }

    func testUploadWorkoutFailsOnNetworkError() async {
        sut.accessToken = "tok"
        sut.tokenExpiry = Date().addingTimeInterval(3600)
        network.error = URLError(.networkConnectionLost)

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        if case .error(let msg) = sut.uploadResult {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("Expected error")
        }
    }

    func testUploadWorkoutResetsStateBeforeStarting() async {
        sut.accessToken = "tok"
        sut.tokenExpiry = Date().addingTimeInterval(3600)
        sut.uploadResult = .error("old error")

        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        // Old error should be replaced with success
        XCTAssertEqual(sut.uploadResult, .success)
    }

    // MARK: - uploadWorkout with 401 retry

    func testUploadWorkoutRetriesOn401() async {
        sut.accessToken = "old_tok"
        sut.refreshToken = "ref_tok"
        sut.tokenExpiry = Date().addingTimeInterval(3600)

        // First call: 401
        network.responses.append((Data(), httpResponse(statusCode: 401)))
        // Token refresh call
        network.responses.append((
            tokenJSON(accessToken: "new_tok", refreshToken: "new_ref"),
            httpResponse(statusCode: 200)
        ))
        // Retry upload call
        network.responses.append((Data("{}".utf8), httpResponse(statusCode: 201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        XCTAssertEqual(sut.uploadResult, .success)
        // Should have made 3 network calls: original + refresh + retry
        XCTAssertEqual(network.capturedRequests.count, 3)
    }

    // MARK: - StravaError

    func testStravaErrorMessages() {
        XCTAssertEqual(StravaError.notConnected.message, "Not connected to Strava. Please connect first.")
        XCTAssertEqual(StravaError.tokenFailed.message, "Failed to authenticate with Strava.")
        XCTAssertEqual(StravaError.uploadFailed("timeout").message, "Upload failed: timeout")
    }

    func testStravaErrorEquality() {
        XCTAssertEqual(StravaError.notConnected, StravaError.notConnected)
        XCTAssertEqual(StravaError.tokenFailed, StravaError.tokenFailed)
        XCTAssertEqual(StravaError.uploadFailed("a"), StravaError.uploadFailed("a"))
        XCTAssertNotEqual(StravaError.uploadFailed("a"), StravaError.uploadFailed("b"))
        XCTAssertNotEqual(StravaError.notConnected, StravaError.tokenFailed)
    }

    // MARK: - UploadResult

    func testUploadResultEquality() {
        XCTAssertEqual(StravaManager.UploadResult.success, .success)
        XCTAssertEqual(StravaManager.UploadResult.error("x"), .error("x"))
        XCTAssertNotEqual(StravaManager.UploadResult.success, .error("x"))
        XCTAssertNotEqual(StravaManager.UploadResult.error("a"), .error("b"))
    }

    // MARK: - buildDescription

    func testBuildDescriptionWithNoLogs() {
        let desc = StravaManager.buildDescription(
            exercisesCompleted: 3,
            setsCompleted: 9,
            setLogs: []
        )
        XCTAssertTrue(desc.contains("3 exercises, 9 sets"))
        XCTAssertTrue(desc.contains("Lazer Dragon"))
    }

    func testBuildDescriptionWithWeightAndReps() {
        let log1 = SetLog(exerciseName: "Bench Press", setIndex: 0, exerciseIndex: 0, weight: 135, reps: 10)
        let log2 = SetLog(exerciseName: "Bench Press", setIndex: 1, exerciseIndex: 0, weight: 155, reps: 8)
        let log3 = SetLog(exerciseName: "Squat", setIndex: 0, exerciseIndex: 1, weight: 225, reps: 5)

        let desc = StravaManager.buildDescription(
            exercisesCompleted: 2,
            setsCompleted: 3,
            setLogs: [log1, log2, log3]
        )

        XCTAssertTrue(desc.contains("2 exercises, 3 sets"))
        XCTAssertTrue(desc.contains("Bench Press: 135lbsx10reps, 155lbsx8reps"))
        XCTAssertTrue(desc.contains("Squat: 225lbsx5reps"))
        XCTAssertTrue(desc.contains("Lazer Dragon"))
    }

    func testBuildDescriptionWithWeightOnly() {
        let log = SetLog(exerciseName: "Deadlift", setIndex: 0, exerciseIndex: 0, weight: 315, reps: nil)

        let desc = StravaManager.buildDescription(
            exercisesCompleted: 1,
            setsCompleted: 1,
            setLogs: [log]
        )

        XCTAssertTrue(desc.contains("Deadlift: 315lbs"))
        XCTAssertFalse(desc.contains("reps"))
    }

    func testBuildDescriptionWithRepsOnly() {
        let log = SetLog(exerciseName: "Pull-up", setIndex: 0, exerciseIndex: 0, weight: nil, reps: 12)

        let desc = StravaManager.buildDescription(
            exercisesCompleted: 1,
            setsCompleted: 1,
            setLogs: [log]
        )

        XCTAssertTrue(desc.contains("Pull-up: 12reps"))
        XCTAssertFalse(desc.contains("lbs"))
    }

    func testBuildDescriptionGroupsExercisesAlphabetically() {
        let logZ = SetLog(exerciseName: "Zottman Curl", setIndex: 0, exerciseIndex: 1, weight: 25, reps: 10)
        let logA = SetLog(exerciseName: "Arnold Press", setIndex: 0, exerciseIndex: 0, weight: 40, reps: 8)

        let desc = StravaManager.buildDescription(
            exercisesCompleted: 2,
            setsCompleted: 2,
            setLogs: [logZ, logA]
        )

        // Arnold Press should come before Zottman Curl
        let arnoldRange = desc.range(of: "Arnold Press")!
        let zottmanRange = desc.range(of: "Zottman Curl")!
        XCTAssertTrue(arnoldRange.lowerBound < zottmanRange.lowerBound)
    }

    func testBuildDescriptionWithNoWeightOrReps() {
        let log = SetLog(exerciseName: "Plank", setIndex: 0, exerciseIndex: 0, weight: nil, reps: nil)

        let desc = StravaManager.buildDescription(
            exercisesCompleted: 1,
            setsCompleted: 1,
            setLogs: [log]
        )

        // Should still list the exercise, just with empty set description
        XCTAssertTrue(desc.contains("Plank: "))
    }

    // MARK: - WorkoutType mapping covers all cases

    func testAllWorkoutTypesHaveActivityMapping() {
        for type in WorkoutType.allCases {
            let activity = sut.stravaActivityType(for: type)
            let sport = sut.stravaSportType(for: type)
            XCTAssertFalse(activity.isEmpty, "Missing activity type for \(type)")
            XCTAssertFalse(sport.isEmpty, "Missing sport type for \(type)")
        }
    }
}
