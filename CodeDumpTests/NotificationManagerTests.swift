import XCTest
@testable import CodeDump

// MARK: - Mock

final class MockNotificationScheduler: NotificationScheduling {
    private(set) var didRequestAuthorization = false
    private(set) var scheduledHour: Int?
    private(set) var scheduledMinute: Int?
    private(set) var didCancel = false
    private(set) var scheduleCallCount = 0
    private(set) var cancelCallCount = 0

    var authorizationGranted = true
    var stubbedStatus: UNAuthorizationStatus = .authorized

    func requestAuthorization() async -> Bool {
        didRequestAuthorization = true
        return authorizationGranted
    }

    func scheduleReminder(hour: Int, minute: Int) async {
        scheduledHour = hour
        scheduledMinute = minute
        scheduleCallCount += 1
    }

    func cancelReminder() async {
        didCancel = true
        cancelCallCount += 1
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        stubbedStatus
    }
}

// MARK: - Tests

@MainActor
final class NotificationManagerTests: XCTestCase {

    // MARK: - Identifier

    func testReminderIdentifierIsStable() {
        XCTAssertEqual(NotificationManager.shared.reminderIdentifier, "com.ldwe.daily-reminder")
    }

    // MARK: - Mock scheduler behavior

    func testScheduleRecordsHourAndMinute() async {
        let mock = MockNotificationScheduler()
        await mock.scheduleReminder(hour: 7, minute: 30)
        XCTAssertEqual(mock.scheduledHour, 7)
        XCTAssertEqual(mock.scheduledMinute, 30)
    }

    func testCancelSetsFlag() async {
        let mock = MockNotificationScheduler()
        await mock.cancelReminder()
        XCTAssertTrue(mock.didCancel)
    }

    func testRequestAuthorizationSetsFlag() async {
        let mock = MockNotificationScheduler()
        let granted = await mock.requestAuthorization()
        XCTAssertTrue(mock.didRequestAuthorization)
        XCTAssertTrue(granted)
    }

    func testRequestAuthorizationDenied() async {
        let mock = MockNotificationScheduler()
        mock.authorizationGranted = false
        let granted = await mock.requestAuthorization()
        XCTAssertFalse(granted)
    }

    func testScheduleCalledOnce() async {
        let mock = MockNotificationScheduler()
        await mock.scheduleReminder(hour: 18, minute: 0)
        XCTAssertEqual(mock.scheduleCallCount, 1)
    }

    func testCancelCalledOnce() async {
        let mock = MockNotificationScheduler()
        await mock.cancelReminder()
        XCTAssertEqual(mock.cancelCallCount, 1)
    }

    func testDifferentTimesScheduledCorrectly() async {
        let mock = MockNotificationScheduler()
        let cases: [(Int, Int)] = [(6, 0), (9, 30), (12, 15), (21, 45)]
        for (hour, minute) in cases {
            await mock.scheduleReminder(hour: hour, minute: minute)
            XCTAssertEqual(mock.scheduledHour, hour)
            XCTAssertEqual(mock.scheduledMinute, minute)
        }
    }

    func testAuthorizationStatusReturnsStubbed() async {
        let mock = MockNotificationScheduler()
        mock.stubbedStatus = .denied
        let status = await mock.authorizationStatus()
        XCTAssertEqual(status, .denied)
    }
}
