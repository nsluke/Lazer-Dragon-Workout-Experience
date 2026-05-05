import XCTest
import SwiftData
@testable import Lazer_Dragon

@MainActor
final class WorkoutModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        container = try ModelContainer(for: Workout.self, Exercise.self, WorkoutSession.self, SetLog.self, CustomExerciseTemplate.self, TrainingProgram.self, FitnessGoal.self, configurations: config)
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - WorkoutType

    func testWorkoutTypeRoundTrips() {
        for type_ in WorkoutType.allCases {
            let w = Workout(name: "Test", type: type_)
            XCTAssertEqual(w.workoutType, type_)
        }
    }

    func testWorkoutTypeDefaultsToCustomForUnknownRawValue() {
        let w = Workout(name: "Test")
        w.type = "unknown_garbage"
        XCTAssertEqual(w.workoutType, .custom)
    }

    // MARK: - sortedExercises

    func testSortedExercisesReturnsInOrder() {
        let w = Workout(name: "Test")
        context.insert(w)

        let e2 = Exercise(order: 2, name: "Third")
        let e0 = Exercise(order: 0, name: "First")
        let e1 = Exercise(order: 1, name: "Second")
        for e in [e2, e0, e1] { e.workout = w; w.exercises?.append(e); context.insert(e) }

        let sorted = w.sortedExercises
        XCTAssertEqual(sorted.map(\.name), ["First", "Second", "Third"])
    }

    func testSortedExercisesEmptyForNoExercises() {
        let w = Workout(name: "Test")
        XCTAssertTrue(w.sortedExercises.isEmpty)
    }

    // MARK: - totalDurationEstimate

    func testDurationNoWarmupOrCooldown() {
        // 3 intervals × 30s + 2 rests × 15s = 90 + 30 = 120
        let w = Workout(
            name: "Test",
            warmupLength: 0,
            intervalLength: 30,
            restLength: 15,
            numberOfIntervals: 3,
            numberOfSets: 1,
            restBetweenSetLength: 0,
            cooldownLength: 0
        )
        XCTAssertEqual(w.totalDurationEstimate, 120)
    }

    func testDurationWithWarmupAndCooldown() {
        // warmup 60 + 1 interval 30 + cooldown 60 = 150
        let w = Workout(
            name: "Test",
            warmupLength: 60,
            intervalLength: 30,
            restLength: 0,
            numberOfIntervals: 1,
            numberOfSets: 1,
            restBetweenSetLength: 0,
            cooldownLength: 60
        )
        XCTAssertEqual(w.totalDurationEstimate, 150)
    }

    func testDurationMultipleSets() {
        // 1 interval × 30s, 2 sets, rest-between-sets 60s → (30 * 2) + 60 = 120
        let w = Workout(
            name: "Test",
            warmupLength: 0,
            intervalLength: 30,
            restLength: 0,
            numberOfIntervals: 1,
            numberOfSets: 2,
            restBetweenSetLength: 60,
            cooldownLength: 0
        )
        XCTAssertEqual(w.totalDurationEstimate, 120)
    }

    func testDurationZeroForSingleIntervalNoExtras() {
        let w = Workout(
            name: "Test",
            warmupLength: 0,
            intervalLength: 45,
            restLength: 0,
            numberOfIntervals: 1,
            numberOfSets: 1,
            restBetweenSetLength: 0,
            cooldownLength: 0
        )
        XCTAssertEqual(w.totalDurationEstimate, 45)
    }

    // MARK: - Exercise

    func testExerciseDefaultSplitLength() {
        let e = Exercise(order: 0, name: "Push-up")
        XCTAssertEqual(e.splitLength, 30)
        XCTAssertEqual(e.reps, 0)
    }

    func testExerciseCustomValues() {
        let e = Exercise(order: 2, name: "Squat", splitLength: 45, reps: 12)
        XCTAssertEqual(e.order, 2)
        XCTAssertEqual(e.name, "Squat")
        XCTAssertEqual(e.splitLength, 45)
        XCTAssertEqual(e.reps, 12)
    }

    // MARK: - Cascade Delete

    func testDeletingWorkoutDeletesExercises() throws {
        let w = Workout(name: "Test")
        context.insert(w)
        let e = Exercise(order: 0, name: "Burpee")
        e.workout = w
        w.exercises?.append(e)
        context.insert(e)
        try context.save()

        context.delete(w)
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        XCTAssertTrue(exercises.isEmpty)
    }
}
