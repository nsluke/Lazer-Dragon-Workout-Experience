#if os(iOS)
import Foundation
import AuthenticationServices

// MARK: - Protocols for Testability

protocol StravaTokenStore: Sendable {
    func read(key: String) -> String?
    func save(key: String, value: String)
    func delete(key: String)
}

protocol StravaNetworkClient: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - Default Implementations

extension URLSession: StravaNetworkClient {}

struct KeychainTokenStore: StravaTokenStore {
    private static let service = "com.lazerdragon.ldwe.strava"

    func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Self.service
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Self.service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Self.service
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Token Response

struct StravaTokenResponse: Decodable {
    let access_token: String
    let refresh_token: String
    let expires_at: Int
    let athlete: Athlete?

    struct Athlete: Decodable {
        let firstname: String?
        let lastname: String?
    }
}

// MARK: - Error

enum StravaError: Error, Equatable {
    case notConnected
    case tokenFailed
    case uploadFailed(String)

    var message: String {
        switch self {
        case .notConnected: return "Not connected to Strava. Please connect first."
        case .tokenFailed: return "Failed to authenticate with Strava."
        case .uploadFailed(let detail): return "Upload failed: \(detail)"
        }
    }
}

// MARK: - StravaManager

@Observable
@MainActor
final class StravaManager: NSObject {
    static let shared = StravaManager()

    // MARK: - Configuration
    // Register your app at https://www.strava.com/settings/api
    // Set the callback domain to match your app's URL scheme
    static let clientID = "YOUR_STRAVA_CLIENT_ID"
    static let clientSecret = "YOUR_STRAVA_CLIENT_SECRET"
    static let callbackScheme = "ldwe"
    static let redirectURI = "ldwe://strava/callback"

    static let authorizeURL = "https://www.strava.com/oauth/mobile/authorize"
    static let tokenURL = "https://www.strava.com/oauth/token"
    static let activitiesURL = "https://www.strava.com/api/v3/activities"

    // MARK: - Dependencies

    let tokenStore: StravaTokenStore
    let networkClient: StravaNetworkClient

    // MARK: - State

    var isConnected: Bool { accessToken != nil }
    var isUploading = false
    var uploadResult: UploadResult?

    enum UploadResult: Equatable {
        case success
        case error(String)
    }

    // MARK: - Init

    init(tokenStore: StravaTokenStore = KeychainTokenStore(),
         networkClient: StravaNetworkClient = URLSession.shared) {
        self.tokenStore = tokenStore
        self.networkClient = networkClient
    }

    // MARK: - Tokens (Store-backed)

    var accessToken: String? {
        get { tokenStore.read(key: "strava_access_token") }
        set {
            if let newValue {
                tokenStore.save(key: "strava_access_token", value: newValue)
            } else {
                tokenStore.delete(key: "strava_access_token")
            }
        }
    }

    var refreshToken: String? {
        get { tokenStore.read(key: "strava_refresh_token") }
        set {
            if let newValue {
                tokenStore.save(key: "strava_refresh_token", value: newValue)
            } else {
                tokenStore.delete(key: "strava_refresh_token")
            }
        }
    }

    var tokenExpiry: Date? {
        get {
            guard let str = tokenStore.read(key: "strava_token_expiry"),
                  let interval = TimeInterval(str) else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            if let newValue {
                tokenStore.save(key: "strava_token_expiry", value: String(newValue.timeIntervalSince1970))
            } else {
                tokenStore.delete(key: "strava_token_expiry")
            }
        }
    }

    var athleteName: String? {
        get { tokenStore.read(key: "strava_athlete_name") }
        set {
            if let newValue {
                tokenStore.save(key: "strava_athlete_name", value: newValue)
            } else {
                tokenStore.delete(key: "strava_athlete_name")
            }
        }
    }

    var connectedAthleteName: String? { athleteName }

    // MARK: - OAuth

    func authorize() {
        var components = URLComponents(string: Self.authorizeURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Self.clientID),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "approval_prompt", value: "auto"),
            URLQueryItem(name: "scope", value: "activity:write,read")
        ]

        let session = ASWebAuthenticationSession(
            url: components.url!,
            callbackURLScheme: Self.callbackScheme
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        return // User cancelled — not an error
                    }
                    self.uploadResult = .error("Authorization failed: \(error.localizedDescription)")
                    return
                }
                guard let callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "code" })?.value else {
                    self.uploadResult = .error("No authorization code received.")
                    return
                }
                await self.exchangeCode(code)
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }

    func disconnect() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        athleteName = nil
        uploadResult = nil
    }

    // MARK: - Token Exchange

    func exchangeCode(_ code: String) async {
        do {
            let tokenData = try await requestToken(params: [
                "client_id": Self.clientID,
                "client_secret": Self.clientSecret,
                "code": code,
                "grant_type": "authorization_code"
            ])
            storeTokens(tokenData)
        } catch {
            uploadResult = .error("Token exchange failed: \(error.localizedDescription)")
        }
    }

    func refreshAccessToken() async throws {
        guard let refresh = refreshToken else {
            throw StravaError.notConnected
        }
        let tokenData = try await requestToken(params: [
            "client_id": Self.clientID,
            "client_secret": Self.clientSecret,
            "refresh_token": refresh,
            "grant_type": "refresh_token"
        ])
        storeTokens(tokenData)
    }

    func requestToken(params: [String: String]) async throws -> StravaTokenResponse {
        var request = URLRequest(url: URL(string: Self.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(params)

        let (data, response) = try await networkClient.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw StravaError.tokenFailed
        }
        return try JSONDecoder().decode(StravaTokenResponse.self, from: data)
    }

    func storeTokens(_ response: StravaTokenResponse) {
        accessToken = response.access_token
        refreshToken = response.refresh_token
        tokenExpiry = Date(timeIntervalSince1970: TimeInterval(response.expires_at))
        if let athlete = response.athlete {
            athleteName = [athlete.firstname, athlete.lastname]
                .compactMap { $0 }
                .joined(separator: " ")
        }
    }

    // MARK: - Ensure Valid Token

    func validAccessToken() async throws -> String {
        guard let token = accessToken else { throw StravaError.notConnected }
        if let expiry = tokenExpiry, expiry < Date() {
            try await refreshAccessToken()
            guard let refreshed = accessToken else { throw StravaError.tokenFailed }
            return refreshed
        }
        return token
    }

    // MARK: - Create Activity

    func uploadWorkout(
        name: String,
        workoutType: WorkoutType,
        startDate: Date,
        elapsedSeconds: Int,
        description: String?
    ) async {
        isUploading = true
        uploadResult = nil
        defer { isUploading = false }

        do {
            let token = try await validAccessToken()

            let iso8601 = ISO8601DateFormatter()
            iso8601.formatOptions = [.withInternetDateTime]

            var body: [String: Any] = [
                "name": name,
                "type": stravaActivityType(for: workoutType),
                "sport_type": stravaSportType(for: workoutType),
                "start_date_local": iso8601.string(from: startDate),
                "elapsed_time": elapsedSeconds,
                "trainer": 1 // Indoor activity
            ]
            if let description {
                body["description"] = description
            }

            var request = URLRequest(url: URL(string: Self.activitiesURL)!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await networkClient.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw StravaError.uploadFailed("No response")
            }

            if http.statusCode == 401 {
                // Token expired mid-request, refresh and retry once
                try await refreshAccessToken()
                let newToken = try await validAccessToken()
                request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (_, retryResponse) = try await networkClient.data(for: request)
                guard let retryHttp = retryResponse as? HTTPURLResponse,
                      (200...299).contains(retryHttp.statusCode) else {
                    throw StravaError.uploadFailed("Upload failed after token refresh")
                }
            } else if !(200...299).contains(http.statusCode) {
                throw StravaError.uploadFailed("Status \(http.statusCode)")
            }

            uploadResult = .success
        } catch let error as StravaError {
            uploadResult = .error(error.message)
        } catch {
            uploadResult = .error(error.localizedDescription)
        }
    }

    // MARK: - Strava Activity Type Mapping

    func stravaActivityType(for type: WorkoutType) -> String {
        switch type {
        case .strength: return "WeightTraining"
        case .hiit:     return "Workout"
        case .run:      return "Run"
        case .yoga:     return "Yoga"
        case .custom:   return "Workout"
        }
    }

    func stravaSportType(for type: WorkoutType) -> String {
        switch type {
        case .strength: return "WeightTraining"
        case .hiit:     return "HIIT"
        case .run:      return "Run"
        case .yoga:     return "Yoga"
        case .custom:   return "Workout"
        }
    }

    // MARK: - Build Description

    static func buildDescription(
        exercisesCompleted: Int,
        setsCompleted: Int,
        setLogs: [SetLog]
    ) -> String {
        var lines: [String] = []
        lines.append("\(exercisesCompleted) exercises, \(setsCompleted) sets")

        // Group logs by exercise name
        let grouped = Dictionary(grouping: setLogs) { $0.exerciseName }
        for (name, logs) in grouped.sorted(by: { $0.key < $1.key }) {
            let setDescriptions = logs.enumerated().map { index, log -> String in
                var parts: [String] = []
                if let w = log.weight { parts.append("\(Int(w))lbs") }
                if let r = log.reps { parts.append("\(r)reps") }
                return parts.joined(separator: "x")
            }
            lines.append("\(name): \(setDescriptions.joined(separator: ", "))")
        }

        lines.append("\nLogged with Lazer Dragon Workout Experience")
        return lines.joined(separator: "\n")
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension StravaManager: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }
    }
}
#endif
