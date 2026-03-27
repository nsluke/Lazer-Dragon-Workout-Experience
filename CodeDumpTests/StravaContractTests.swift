import XCTest
@testable import Lazer_Dragon

/// Contract tests — validate that our request/response shapes conform to
/// the Strava API v3 specification. These catch breaking changes in our
/// serialization before they reach production.
///
/// Reference: https://developers.strava.com/docs/reference/
@MainActor
final class StravaContractTests: XCTestCase {

    private var store: MockTokenStore!
    private var network: MockNetworkClient!
    private var sut: StravaManager!

    override func setUp() async throws {
        store = MockTokenStore()
        network = MockNetworkClient()
        sut = StravaManager(tokenStore: store, networkClient: network)
        // Pre-connect so upload calls work
        store.save(key: "strava_access_token", value: "test_token")
        store.save(key: "strava_token_expiry",
                   value: String(Date().addingTimeInterval(3600).timeIntervalSince1970))
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

    private func capturedBody() -> [String: Any]? {
        guard let data = network.capturedRequests.last?.httpBody else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    // MARK: - Create Activity Request Contract

    /// POST /api/v3/activities must include all required fields per Strava docs.
    /// Required: name (String), sport_type (String), start_date_local (ISO8601), elapsed_time (Int)
    func testCreateActivityRequest_ContainsRequiredFields() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 3600,
            description: nil
        )

        let body = capturedBody()!
        // Required fields per Strava API v3
        XCTAssertNotNil(body["name"] as? String, "Missing required field: name")
        XCTAssertNotNil(body["sport_type"] as? String, "Missing required field: sport_type")
        XCTAssertNotNil(body["start_date_local"] as? String, "Missing required field: start_date_local")
        XCTAssertNotNil(body["elapsed_time"] as? Int, "Missing required field: elapsed_time")
    }

    /// The `name` field must be a non-empty string.
    func testCreateActivityRequest_NameIsNonEmpty() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Leg Day",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 1800,
            description: nil
        )

        let name = capturedBody()?["name"] as? String
        XCTAssertNotNil(name)
        XCTAssertFalse(name!.isEmpty, "name must not be empty")
    }

    /// `elapsed_time` must be a positive integer (seconds).
    func testCreateActivityRequest_ElapsedTimeIsPositiveInt() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 2700,
            description: nil
        )

        let elapsed = capturedBody()?["elapsed_time"] as? Int
        XCTAssertNotNil(elapsed)
        XCTAssertGreaterThan(elapsed!, 0)
    }

    /// `start_date_local` must be a valid ISO 8601 date string.
    func testCreateActivityRequest_StartDateIsISO8601() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(timeIntervalSince1970: 1700000000),
            elapsedSeconds: 600,
            description: nil
        )

        let dateStr = capturedBody()?["start_date_local"] as? String
        XCTAssertNotNil(dateStr)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        XCTAssertNotNil(formatter.date(from: dateStr!),
                        "'\(dateStr!)' is not valid ISO 8601")
    }

    /// `type` must be one of Strava's accepted activity types.
    func testCreateActivityRequest_TypeIsValidStravaType() async {
        let validTypes: Set<String> = [
            "AlpineSki", "BackcountrySki", "Canoeing", "Crossfit", "EBikeRide",
            "Elliptical", "Golf", "Handcycle", "Hike", "IceSkate", "InlineSkate",
            "Kayaking", "Kitesurf", "NordicSki", "Ride", "RockClimbing",
            "RollerSki", "Rowing", "Run", "Sail", "Skateboard", "Snowboard",
            "Snowshoe", "Soccer", "StairStepper", "StandUpPaddling", "Surfing",
            "Swim", "Velomobile", "VirtualRide", "VirtualRun", "Walk",
            "WeightTraining", "Wheelchair", "Windsurf", "Workout", "Yoga"
        ]

        for workoutType in WorkoutType.allCases {
            network.responses.append((Data("{}".utf8), httpResponse(201)))

            await sut.uploadWorkout(
                name: "Test",
                workoutType: workoutType,
                startDate: Date(),
                elapsedSeconds: 60,
                description: nil
            )

            let type = capturedBody()?["type"] as? String
            XCTAssertNotNil(type, "Missing type for \(workoutType)")
            XCTAssertTrue(validTypes.contains(type!),
                          "'\(type!)' is not a valid Strava activity type (for \(workoutType))")
        }
    }

    /// `sport_type` must be one of Strava's accepted sport types.
    func testCreateActivityRequest_SportTypeIsValidStravaSportType() async {
        let validSportTypes: Set<String> = [
            "AlpineSki", "BackcountrySki", "Badminton", "Canoeing", "Crossfit",
            "EBikeRide", "Elliptical", "EMountainBikeRide", "Golf", "GravelRide",
            "Handcycle", "HighIntensityIntervalTraining", "HIIT", "Hike",
            "IceSkate", "InlineSkate", "Kayaking", "Kitesurf", "MountainBikeRide",
            "NordicSki", "Pickleball", "Pilates", "Racquetball", "Ride",
            "RockClimbing", "RollerSki", "Rowing", "Run", "Sail", "Skateboard",
            "Snowboard", "Snowshoe", "Soccer", "Squash", "StairStepper",
            "StandUpPaddling", "Surfing", "Swim", "TableTennis", "Tennis",
            "TrailRun", "Velomobile", "VirtualRide", "VirtualRow", "VirtualRun",
            "Walk", "WeightTraining", "Wheelchair", "Windsurf", "Workout", "Yoga"
        ]

        for workoutType in WorkoutType.allCases {
            network.responses.append((Data("{}".utf8), httpResponse(201)))

            await sut.uploadWorkout(
                name: "Test",
                workoutType: workoutType,
                startDate: Date(),
                elapsedSeconds: 60,
                description: nil
            )

            let sportType = capturedBody()?["sport_type"] as? String
            XCTAssertNotNil(sportType, "Missing sport_type for \(workoutType)")
            XCTAssertTrue(validSportTypes.contains(sportType!),
                          "'\(sportType!)' is not a valid Strava sport_type (for \(workoutType))")
        }
    }

    /// `trainer` must be 0 or 1 (Strava boolean flag for indoor activity).
    func testCreateActivityRequest_TrainerIsZeroOrOne() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        let trainer = capturedBody()?["trainer"] as? Int
        XCTAssertNotNil(trainer)
        XCTAssertTrue(trainer == 0 || trainer == 1, "trainer must be 0 or 1, got \(trainer!)")
    }

    /// `description` is optional — when provided, must be a string.
    func testCreateActivityRequest_DescriptionIsStringWhenPresent() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 60,
            description: "A great workout"
        )

        let desc = capturedBody()?["description"]
        XCTAssertNotNil(desc)
        XCTAssertTrue(desc is String, "description must be a String, got \(type(of: desc!))")
    }

    /// When description is nil, it must not appear in the request body.
    func testCreateActivityRequest_DescriptionAbsentWhenNil() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        let body = capturedBody()!
        XCTAssertNil(body["description"], "description key should be absent when nil")
    }

    /// No unexpected fields should leak into the request.
    func testCreateActivityRequest_NoUnexpectedFields() async {
        let allowedKeys: Set<String> = [
            "name", "type", "sport_type", "start_date_local",
            "elapsed_time", "trainer", "description"
        ]

        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .strength,
            startDate: Date(),
            elapsedSeconds: 60,
            description: "desc"
        )

        let body = capturedBody()!
        let extraKeys = Set(body.keys).subtracting(allowedKeys)
        XCTAssertTrue(extraKeys.isEmpty, "Unexpected fields in request: \(extraKeys)")
    }

    // MARK: - Authorization Header Contract

    /// Upload requests must use Bearer token authentication.
    func testUploadRequest_UsesBearerAuth() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        let auth = network.capturedRequests.last?.value(forHTTPHeaderField: "Authorization")
        XCTAssertNotNil(auth)
        XCTAssertTrue(auth!.hasPrefix("Bearer "), "Auth header must start with 'Bearer '")
        XCTAssertGreaterThan(auth!.count, 7, "Bearer token must not be empty")
    }

    /// Content-Type must be application/json.
    func testUploadRequest_ContentTypeIsJSON() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        let contentType = network.capturedRequests.last?.value(forHTTPHeaderField: "Content-Type")
        XCTAssertEqual(contentType, "application/json")
    }

    /// Request method must be POST.
    func testUploadRequest_MethodIsPOST() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        XCTAssertEqual(network.capturedRequests.last?.httpMethod, "POST")
    }

    /// Upload URL must be the correct Strava API endpoint.
    func testUploadRequest_CorrectEndpoint() async {
        network.responses.append((Data("{}".utf8), httpResponse(201)))

        await sut.uploadWorkout(
            name: "Test",
            workoutType: .custom,
            startDate: Date(),
            elapsedSeconds: 60,
            description: nil
        )

        XCTAssertEqual(
            network.capturedRequests.last?.url?.absoluteString,
            "https://www.strava.com/api/v3/activities"
        )
    }

    // MARK: - Token Exchange Request Contract

    /// Token exchange must POST to /oauth/token with correct fields.
    func testTokenExchangeRequest_ContainsRequiredFields() async {
        network.responses.append((
            tokenJSON(),
            httpResponse(200)
        ))

        await sut.exchangeCode("test_auth_code")

        let request = network.capturedRequests.first!
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://www.strava.com/oauth/token")

        let body = try! JSONSerialization.jsonObject(with: request.httpBody!) as! [String: String]
        XCTAssertEqual(body["grant_type"], "authorization_code")
        XCTAssertNotNil(body["client_id"])
        XCTAssertNotNil(body["client_secret"])
        XCTAssertEqual(body["code"], "test_auth_code")
    }

    // MARK: - Token Response Contract

    /// We must correctly decode a realistic Strava token response.
    func testTokenResponse_DecodesRealisticPayload() throws {
        let json = """
        {
            "token_type": "Bearer",
            "expires_at": 1700000000,
            "expires_in": 21600,
            "refresh_token": "abc123refresh",
            "access_token": "xyz789access",
            "athlete": {
                "id": 12345678,
                "username": "lazerdragon",
                "resource_state": 2,
                "firstname": "Luke",
                "lastname": "Dragon",
                "bio": "",
                "city": "Portland",
                "state": "Oregon",
                "country": "United States",
                "sex": "M",
                "premium": true,
                "summit": true,
                "created_at": "2020-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
                "badge_type_id": 1,
                "weight": 80.0,
                "profile_medium": "https://example.com/medium.jpg",
                "profile": "https://example.com/large.jpg"
            }
        }
        """.data(using: .utf8)!

        // Must decode without error despite extra fields (Strava sends many we don't use)
        let response = try JSONDecoder().decode(StravaTokenResponse.self, from: json)
        XCTAssertEqual(response.access_token, "xyz789access")
        XCTAssertEqual(response.refresh_token, "abc123refresh")
        XCTAssertEqual(response.expires_at, 1700000000)
        XCTAssertEqual(response.athlete?.firstname, "Luke")
        XCTAssertEqual(response.athlete?.lastname, "Dragon")
    }

    /// Token response must decode even with minimal fields (no athlete).
    func testTokenResponse_DecodesMinimalPayload() throws {
        let json = """
        {
            "access_token": "tok",
            "refresh_token": "ref",
            "expires_at": 100
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StravaTokenResponse.self, from: json)
        XCTAssertEqual(response.access_token, "tok")
        XCTAssertNil(response.athlete)
    }

    /// Token response must fail gracefully if required fields are missing.
    func testTokenResponse_FailsOnMissingRequiredFields() {
        let incompleteJSONs = [
            #"{"refresh_token":"r","expires_at":1}"#, // missing access_token
            #"{"access_token":"a","expires_at":1}"#,  // missing refresh_token
            #"{"access_token":"a","refresh_token":"r"}"#, // missing expires_at
        ]

        for json in incompleteJSONs {
            let data = json.data(using: .utf8)!
            XCTAssertThrowsError(
                try JSONDecoder().decode(StravaTokenResponse.self, from: data),
                "Should fail to decode: \(json)"
            )
        }
    }

    // MARK: - Helpers

    private func tokenJSON() -> Data {
        try! JSONSerialization.data(withJSONObject: [
            "access_token": "a", "refresh_token": "r", "expires_at": 9999999999
        ])
    }
}
