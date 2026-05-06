import XCTest
import SwiftData
@testable import Lazer_Dragon

@MainActor
final class StrengthScoreEngineTests: XCTestCase {

    // MARK: - Setup

    private var anchorDate: Date!

    override func setUp() async throws {
        // Pin "now" to a fixed date so trend windows are deterministic
        // regardless of when the suite runs.
        anchorDate = Date(timeIntervalSince1970: 1_720_000_000)
    }

    // MARK: - Empty state

    func testEmptyHistoryReturnsZeroScoreAndUnknownTrend() {
        let score = StrengthScoreEngine.score(sessions: [], setLogs: [], asOf: anchorDate)
        XCTAssertEqual(score.total, 0)
        XCTAssertEqual(score.strengthComponent, 0)
        XCTAssertEqual(score.volumeComponent, 0)
        XCTAssertEqual(score.frequencyComponent, 0)
        XCTAssertFalse(score.hasData)
        XCTAssertEqual(score.trend, .unknown)
    }

    // MARK: - Components

    func testFrequencyCountsSessionsInWindow() {
        let inWindow = [
            session(daysAgo: 1),
            session(daysAgo: 7),
            session(daysAgo: 27)
        ]
        let outside = [session(daysAgo: 40), session(daysAgo: 60)]
        let score = StrengthScoreEngine.score(
            sessions: inWindow + outside,
            setLogs: [],
            asOf: anchorDate
        )
        XCTAssertEqual(score.frequencyComponent, 3)
        XCTAssertEqual(score.total, 300, "frequency * 100 should land 3 sessions at 300")
    }

    func testVolumeSumsWeightTimesRepsForSetsInWindow() {
        let logs = [
            log(daysAgo: 2, weight: 100, reps: 10), // 1000
            log(daysAgo: 5, weight: 50, reps: 20),  // 1000
            log(daysAgo: 40, weight: 200, reps: 10) // outside window
        ]
        let score = StrengthScoreEngine.score(sessions: [], setLogs: logs, asOf: anchorDate)
        XCTAssertEqual(score.volumeComponent, 2_000, accuracy: 0.001)
    }

    func testStrengthSumsBest1RMPerExercise() {
        // Two exercises, multiple logs each — strength = sum of best 1RM each
        // bench: max e1RM is 100 * (1 + 5/30) = 116.66...
        // squat: max e1RM is 200 * (1 + 5/30) = 233.33...
        let logs = [
            log(daysAgo: 1, weight: 80, reps: 10, templateID: "bench"),  // 80*(1+10/30) = 106.66
            log(daysAgo: 2, weight: 100, reps: 5, templateID: "bench"),  // 100*(1+5/30) = 116.66
            log(daysAgo: 3, weight: 180, reps: 8, templateID: "squat"),  // 180*(1+8/30) = 228
            log(daysAgo: 4, weight: 200, reps: 5, templateID: "squat")   // 200*(1+5/30) = 233.33
        ]
        let score = StrengthScoreEngine.score(sessions: [], setLogs: logs, asOf: anchorDate)
        XCTAssertEqual(score.strengthComponent, 116.666_67 + 233.333_33, accuracy: 0.01)
    }

    func testStrengthFallsBackToExerciseNameWhenTemplateIDMissing() {
        let logs = [
            log(daysAgo: 1, weight: 100, reps: 1, templateID: nil, name: "Push Press")
        ]
        let score = StrengthScoreEngine.score(sessions: [], setLogs: logs, asOf: anchorDate)
        // Epley at 100 lbs × 1 rep = 100 * (1 + 1/30) = 103.333…
        XCTAssertEqual(score.strengthComponent, 103.333, accuracy: 0.01)
    }

    func testZeroRepsTreatedAsRawWeight() {
        // duration-based exercises log without reps; e1RM should equal weight
        let logs = [log(daysAgo: 1, weight: 50, reps: 0, templateID: "plank")]
        let score = StrengthScoreEngine.score(sessions: [], setLogs: logs, asOf: anchorDate)
        XCTAssertEqual(score.strengthComponent, 50, accuracy: 0.01)
    }

    func testWeightlessLogsExcludedFromStrengthAndVolume() {
        let logs = [
            log(daysAgo: 1, weight: nil, reps: 10),
            log(daysAgo: 2, weight: 0, reps: 10)
        ]
        let score = StrengthScoreEngine.score(sessions: [], setLogs: logs, asOf: anchorDate)
        XCTAssertEqual(score.strengthComponent, 0)
        XCTAssertEqual(score.volumeComponent, 0)
    }

    // MARK: - Total formula

    func testTotalIsStrengthPlusScaledVolumePlusFrequency() {
        let sessions = [session(daysAgo: 1), session(daysAgo: 5)]
        let logs = [
            log(daysAgo: 1, weight: 100, reps: 10, templateID: "bench"),
            log(daysAgo: 5, weight: 100, reps: 5, templateID: "bench")
        ]
        let score = StrengthScoreEngine.score(sessions: sessions, setLogs: logs, asOf: anchorDate)
        // Best e1RM for bench: max(133.33, 116.66) = 133.33
        // Volume: 1000 + 500 = 1500. /50 = 30
        // Frequency: 2 * 100 = 200
        // Total: 133 (rounded) + 30 + 200 = 363
        XCTAssertEqual(score.total, 363)
    }

    // MARK: - Trend / delta

    func testTrendIsUpWhenCurrentExceedsPrevious() {
        // Previous 28-day window had 2 sessions; current window has 4.
        let sessions = [
            session(daysAgo: 5),
            session(daysAgo: 10),
            session(daysAgo: 15),
            session(daysAgo: 20),
            session(daysAgo: 35),
            session(daysAgo: 40)
        ]
        let score = StrengthScoreEngine.score(sessions: sessions, setLogs: [], asOf: anchorDate)
        if case .up(let delta) = score.trend {
            XCTAssertEqual(delta, 200) // current 4*100 - previous 2*100
        } else {
            XCTFail("Expected .up trend, got \(score.trend)")
        }
    }

    func testTrendIsDownWhenCurrentBelowPrevious() {
        let sessions = [
            session(daysAgo: 35),
            session(daysAgo: 40),
            session(daysAgo: 45)
        ]
        let score = StrengthScoreEngine.score(sessions: sessions, setLogs: [], asOf: anchorDate)
        if case .down(let delta) = score.trend {
            XCTAssertEqual(delta, 300) // 0 - 3*100 = -300, magnitude 300
        } else {
            XCTFail("Expected .down trend, got \(score.trend)")
        }
    }

    func testTrendIsFlatWhenIdentical() {
        // Same one session in both windows? Place one each side at exact -28
        // boundary. Actually easier: two sessions positioned symmetrically.
        let sessions = [
            session(daysAgo: 14),
            session(daysAgo: 42)
        ]
        let score = StrengthScoreEngine.score(sessions: sessions, setLogs: [], asOf: anchorDate)
        XCTAssertEqual(score.trend, .flat)
    }

    // MARK: - Trend points

    func testTrendReturnsRequestedNumberOfWeeklyPoints() {
        let points = StrengthScoreEngine.trend(
            sessions: [],
            setLogs: [],
            asOf: anchorDate,
            weeks: 12
        )
        XCTAssertEqual(points.count, 12)
        // Points should be sorted oldest first
        for (a, b) in zip(points, points.dropFirst()) {
            XCTAssertLessThan(a.date, b.date)
        }
    }

    func testTrendReflectsGrowthOverTime() {
        // Add one session per week over 12 weeks. Each week's window picks
        // up one more session than the previous.
        var sessions: [WorkoutSession] = []
        for offset in 0..<12 {
            sessions.append(session(daysAgo: offset * 7))
        }
        let points = StrengthScoreEngine.trend(
            sessions: sessions,
            setLogs: [],
            asOf: anchorDate,
            weeks: 12
        )
        // The most recent point should have the highest score (most sessions
        // in the trailing 28-day window).
        let scores = points.map(\.score)
        XCTAssertGreaterThan(scores.last!, scores.first!)
    }

    // MARK: - Helpers

    private func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: anchorDate)!
    }

    private func session(daysAgo: Int) -> WorkoutSession {
        // The engine only reads session.date; other fields are irrelevant.
        WorkoutSession(
            date: date(daysAgo: daysAgo),
            totalElapsed: 0,
            exercisesCompleted: 0,
            setsCompleted: 0
        )
    }

    private func log(
        daysAgo: Int,
        weight: Double?,
        reps: Int,
        templateID: String? = "default-id",
        name: String = "Default"
    ) -> SetLog {
        let log = SetLog(
            exerciseName: name,
            exerciseTemplateID: templateID,
            setIndex: 0,
            exerciseIndex: 0,
            weight: weight,
            reps: reps
        )
        // SetLog.init always sets date = .now; override for the test.
        log.date = date(daysAgo: daysAgo)
        return log
    }
}
