import XCTest
import Security
@testable import Lazer_Dragon

/// Keychain integration tests — exercise the REAL KeychainTokenStore
/// against the actual iOS/macOS Keychain.
///
/// These tests require Keychain entitlements and should be run on a
/// real device or simulator (not just `swift test`).
///
/// They use a unique test service prefix to avoid polluting production data.
@MainActor
final class StravaKeychainTests: XCTestCase {

    private var store: KeychainTokenStore!
    private let testPrefix = "test_\(UUID().uuidString.prefix(8))_"

    override func setUp() async throws {
        store = KeychainTokenStore()
        // Clean up any leftover test data
        cleanupTestKeys()
    }

    override func tearDown() async throws {
        cleanupTestKeys()
        store = nil
    }

    private var testKeys: [String] {
        [
            testPrefix + "access_token",
            testPrefix + "refresh_token",
            testPrefix + "expiry",
            testPrefix + "athlete",
            testPrefix + "unicode",
            testPrefix + "empty",
            testPrefix + "long",
            testPrefix + "special",
            testPrefix + "overwrite",
        ]
    }

    private func cleanupTestKeys() {
        for key in testKeys {
            store.delete(key: key)
        }
    }

    // MARK: - Basic CRUD

    func testSaveAndRead() {
        let key = testPrefix + "access_token"
        store.save(key: key, value: "test_token_123")
        XCTAssertEqual(store.read(key: key), "test_token_123")
    }

    func testReadNonexistentKey_ReturnsNil() {
        XCTAssertNil(store.read(key: testPrefix + "nonexistent_key_\(UUID())"))
    }

    func testDelete() {
        let key = testPrefix + "access_token"
        store.save(key: key, value: "to_delete")
        XCTAssertNotNil(store.read(key: key))

        store.delete(key: key)
        XCTAssertNil(store.read(key: key))
    }

    func testDeleteNonexistentKey_DoesNotCrash() {
        // Should not throw or crash
        store.delete(key: testPrefix + "never_existed_\(UUID())")
    }

    // MARK: - Overwrite

    func testOverwriteExistingValue() {
        let key = testPrefix + "overwrite"
        store.save(key: key, value: "first")
        XCTAssertEqual(store.read(key: key), "first")

        store.save(key: key, value: "second")
        XCTAssertEqual(store.read(key: key), "second")
    }

    func testOverwriteWithDifferentLength() {
        let key = testPrefix + "overwrite"
        store.save(key: key, value: "short")
        store.save(key: key, value: String(repeating: "x", count: 1000))
        XCTAssertEqual(store.read(key: key)?.count, 1000)

        store.save(key: key, value: "short_again")
        XCTAssertEqual(store.read(key: key), "short_again")
    }

    // MARK: - Value Types

    func testUnicodeValues() {
        let key = testPrefix + "unicode"
        let values = [
            "光線竜",
            "émojis 🐉🔥💪",
            "مرحبا",
            "Ü ö ä ñ",
            "🏋️‍♀️ Workout Complete 🎉",
        ]

        for value in values {
            store.save(key: key, value: value)
            XCTAssertEqual(store.read(key: key), value, "Failed for: \(value)")
        }
    }

    func testEmptyStringValue() {
        let key = testPrefix + "empty"
        store.save(key: key, value: "")
        XCTAssertEqual(store.read(key: key), "")
    }

    func testLongValue() {
        let key = testPrefix + "long"
        let longValue = String(repeating: "A", count: 10_000)
        store.save(key: key, value: longValue)
        XCTAssertEqual(store.read(key: key), longValue)
    }

    func testSpecialCharacters() {
        let key = testPrefix + "special"
        let values = [
            "token with spaces",
            "token\nwith\nnewlines",
            "token\twith\ttabs",
            "token/with/slashes",
            "token=with=equals&and&ampersands",
            #"token"with"quotes"#,
            "token\\with\\backslashes",
        ]

        for value in values {
            store.save(key: key, value: value)
            XCTAssertEqual(store.read(key: key), value, "Failed for: \(value)")
        }
    }

    // MARK: - Multiple Keys

    func testMultipleKeysIndependent() {
        let key1 = testPrefix + "access_token"
        let key2 = testPrefix + "refresh_token"
        let key3 = testPrefix + "expiry"

        store.save(key: key1, value: "access")
        store.save(key: key2, value: "refresh")
        store.save(key: key3, value: "12345")

        XCTAssertEqual(store.read(key: key1), "access")
        XCTAssertEqual(store.read(key: key2), "refresh")
        XCTAssertEqual(store.read(key: key3), "12345")

        // Delete one shouldn't affect others
        store.delete(key: key2)
        XCTAssertEqual(store.read(key: key1), "access")
        XCTAssertNil(store.read(key: key2))
        XCTAssertEqual(store.read(key: key3), "12345")
    }

    // MARK: - StravaManager Integration with Real Keychain

    func testStravaManagerUsesRealKeychain() {
        // Use real KeychainTokenStore (default)
        let manager = StravaManager() // Uses KeychainTokenStore by default
        let uniqueToken = "test_\(UUID().uuidString)"

        // Save
        manager.accessToken = uniqueToken
        XCTAssertEqual(manager.accessToken, uniqueToken)
        XCTAssertTrue(manager.isConnected)

        // Clean up
        manager.disconnect()
        XCTAssertNil(manager.accessToken)
        XCTAssertFalse(manager.isConnected)
    }

    func testStravaManagerTokenPersistsBetweenInstances() {
        let token = "persist_test_\(UUID().uuidString)"

        // Instance 1: save token
        let manager1 = StravaManager()
        manager1.accessToken = token

        // Instance 2: should read the same token
        let manager2 = StravaManager()
        XCTAssertEqual(manager2.accessToken, token)
        XCTAssertTrue(manager2.isConnected)

        // Clean up
        manager2.disconnect()
    }

    func testStravaManagerDisconnectClearsAllKeychainKeys() {
        let manager = StravaManager()
        manager.accessToken = "access_\(UUID().uuidString)"
        manager.refreshToken = "refresh_\(UUID().uuidString)"
        manager.tokenExpiry = Date()
        manager.athleteName = "Test User"

        manager.disconnect()

        // All should be nil — verify via a fresh instance
        let fresh = StravaManager()
        XCTAssertNil(fresh.accessToken)
        XCTAssertNil(fresh.refreshToken)
        XCTAssertNil(fresh.tokenExpiry)
        XCTAssertNil(fresh.athleteName)
    }

    // MARK: - Rapid Operations

    func testRapidSaveReadCycles() {
        let key = testPrefix + "access_token"

        for i in 0..<50 {
            let value = "token_\(i)"
            store.save(key: key, value: value)
            XCTAssertEqual(store.read(key: key), value)
        }
    }

    func testRapidSaveDeleteCycles() {
        let key = testPrefix + "access_token"

        for i in 0..<50 {
            store.save(key: key, value: "token_\(i)")
            store.delete(key: key)
            XCTAssertNil(store.read(key: key))
        }
    }

    // MARK: - Token Expiry Storage Fidelity

    func testTokenExpiryRoundTripsViaKeychain() {
        let manager = StravaManager()
        let date = Date(timeIntervalSince1970: 1700000000)
        manager.tokenExpiry = date

        // Read via a fresh instance
        let fresh = StravaManager()
        XCTAssertNotNil(fresh.tokenExpiry)
        XCTAssertEqual(fresh.tokenExpiry!.timeIntervalSince1970, 1700000000, accuracy: 1)

        // Clean up
        manager.disconnect()
    }
}
