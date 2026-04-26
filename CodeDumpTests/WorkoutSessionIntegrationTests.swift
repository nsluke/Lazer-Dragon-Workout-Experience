import XCTest
import SwiftData
@testable import Lazer_Dragon

/// Integration tests — exercise multiple components together:
/// the full state machine, completion stats, and SwiftData persistence.
@MainActor
final class WorkoutSessionIntegrationTests: XCTestCase {

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

    // MARK: - Helpers

    private func makeWorkout(
        warmup: Int = 0, interval: Int = 30, rest: Int = 0,
        intervals: Int = 3, sets: Int = 1,
        restBetweenSets: Int = 0, cooldown: Int = 0,
        seedExercises: Bool = true
    ) -> Workout {
        let w = Workout(
            name: "Integration Test",
            warmupLength: warmup, intervalLength: interval, restLength: rest,
            numberOfIntervals: intervals, numberOfSets: sets,
            restBetweenSetLength: restBetweenSets, cooldownLength: cooldown
        )
        context.insert(w)
        // Seed `intervals` exercises so the state machine's
        // `exercisesPerSet = min(numberOfIntervals, sortedExercises.count)` cap matches the
        // configured interval count. Pass seedExercises: false for tests that add their own.
        if seedExercises {
            addExercises(w, count: intervals)
        }
        return w
    }

    private func addExercises(_ workout: Workout, count: Int) {
        for i in 0..<count {
            let ex = Exercise(order: i, name: "Exercise \(i + 1)", splitLength: 30)
            ex.workout = workout
            workout.exercises.append(ex)
            context.insert(ex)
        }
    }

    /// Advance through all phases to completion by calling skipForward repeatedly.
    private func runToCompletion(_ vm: WorkoutSessionViewModel) {
        var guard_ = 0
        while vm.phase != .completed && guard_ < 200 {
            vm.skipForward()
            guard_ += 1
        }
    }

    // MARK: - Full Cycle: Simple

    func testSimpleWorkoutReachesCompleted() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(intervals: 3))
        vm.startWorkout()
        runToCompletion(vm)
        XCTAssertEqual(vm.phase, .completed)
    }

    func testSimpleWorkoutExercisesCompletedCount() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(intervals: 4))
        vm.startWorkout()
        runToCompletion(vm)
        XCTAssertEqual(vm.exercisesCompleted, 4)
    }

    func testSimpleWorkoutSetsCompletedCount() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(intervals: 3, sets: 1))
        vm.startWorkout()
        runToCompletion(vm)
        XCTAssertEqual(vm.setsCompleted, 1)
    }

    // MARK: - Full Cycle: With All Phases

    func testFullCycleAllPhases() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(
            warmup: 30, interval: 30, rest: 10,
            intervals: 3, sets: 2, restBetweenSets: 60, cooldown: 30
        ))
        vm.startWorkout()
        XCTAssertEqual(vm.phase, .warmup, "Should start in warmup")
        runToCompletion(vm)
        XCTAssertEqual(vm.phase, .completed)
        XCTAssertFalse(vm.isRunning)
    }

    func testFullCycleExercisesCompletedWithMultipleSets() {
        // 3 intervals × 2 sets = 6 total
        let vm = WorkoutSessionViewModel(workout: makeWorkout(intervals: 3, sets: 2, restBetweenSets: 60))
        vm.startWorkout()
        runToCompletion(vm)
        XCTAssertEqual(vm.exercisesCompleted, 6)
        XCTAssertEqual(vm.setsCompleted, 2)
    }

    func testFullCycleWithCooldownSetsCompletedCorrectly() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(
            intervals: 2, sets: 3, restBetweenSets: 0, cooldown: 30
        ))
        vm.startWorkout()
        runToCompletion(vm)
        // setsCompleted is set to numberOfSets in the cooldown path
        XCTAssertEqual(vm.setsCompleted, 3)
    }

    // MARK: - Full Cycle: With Named Exercises

    func testExercisesPerSetLimitedByExerciseCount() {
        let workout = makeWorkout(intervals: 5, seedExercises: false) // 5 intervals configured
        addExercises(workout, count: 3)                                // but only 3 exercises added
        let vm = WorkoutSessionViewModel(workout: workout)
        vm.startWorkout()
        runToCompletion(vm)
        // Should complete only 3 exercises (capped by sortedExercises.count)
        XCTAssertEqual(vm.exercisesCompleted, 3)
    }

    func testNamedExercisesUsedInPhaseTitle() {
        let workout = makeWorkout(seedExercises: false)
        let ex = Exercise(order: 0, name: "Burpee", splitLength: 30)
        ex.workout = workout
        workout.exercises.append(ex)
        context.insert(ex)

        let vm = WorkoutSessionViewModel(workout: workout)
        vm.startWorkout() // interval(0, 0)
        XCTAssertEqual(vm.phaseTitle, "BURPEE")
    }

    // MARK: - Rest Skip Integration

    func testTappingSkipDuringRestAdvancesPhase() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 15, intervals: 3))
        vm.startWorkout()          // .interval(0, 0)
        vm.skipForward()           // .rest(1, 0)

        guard case .rest = vm.phase else {
            XCTFail("Expected .rest phase"); return
        }

        vm.skipForward()           // simulates tap-to-skip
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 1, setIndex: 0))
    }

    func testTappingSkipDuringRestBetweenSetsAdvancesPhase() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(intervals: 1, sets: 3, restBetweenSets: 60))
        vm.startWorkout()
        vm.skipForward()           // .restBetweenSets(1)

        guard case .restBetweenSets = vm.phase else {
            XCTFail("Expected .restBetweenSets phase"); return
        }

        vm.skipForward()
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 0, setIndex: 1))
    }

    // MARK: - SwiftData Persistence

    func testWorkoutSessionCanBeSavedAndFetched() throws {
        let workout = makeWorkout()
        let session = WorkoutSession(totalElapsed: 420, exercisesCompleted: 9, setsCompleted: 3)
        session.workout = workout
        workout.sessions.append(session)
        context.insert(session)
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].totalElapsed, 420)
        XCTAssertEqual(sessions[0].exercisesCompleted, 9)
        XCTAssertEqual(sessions[0].setsCompleted, 3)
    }

    func testMultipleSessionsSavedForSameWorkout() throws {
        let workout = makeWorkout()
        for i in 1...5 {
            let session = WorkoutSession(totalElapsed: i * 60, exercisesCompleted: i, setsCompleted: 1)
            session.workout = workout
            workout.sessions.append(session)
            context.insert(session)
        }
        try context.save()

        XCTAssertEqual(workout.sessions.count, 5)
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertEqual(sessions.count, 5)
    }

    func testDeletingWorkoutCascadesToSessions() throws {
        let workout = makeWorkout()
        let session = WorkoutSession(totalElapsed: 300, exercisesCompleted: 3, setsCompleted: 1)
        session.workout = workout
        workout.sessions.append(session)
        context.insert(session)
        try context.save()

        context.delete(workout)
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertTrue(sessions.isEmpty)
    }

    func testSessionDateDefaultsToNow() {
        let before = Date.now
        let session = WorkoutSession(totalElapsed: 100, exercisesCompleted: 1, setsCompleted: 1)
        let after = Date.now
        XCTAssertGreaterThanOrEqual(session.date, before)
        XCTAssertLessThanOrEqual(session.date, after)
    }

    func testSessionsAreSortableByDateDescending() throws {
        let workout = makeWorkout()
        let dates = [
            Date.now.addingTimeInterval(-3600),
            Date.now.addingTimeInterval(-1800),
            Date.now
        ]
        for (i, date) in dates.enumerated() {
            let session = WorkoutSession(date: date, totalElapsed: i * 100, exercisesCompleted: i, setsCompleted: 1)
            session.workout = workout
            workout.sessions.append(session)
            context.insert(session)
        }
        try context.save()

        let sorted = workout.sessions.sorted { $0.date > $1.date }
        XCTAssertEqual(sorted[0].totalElapsed, 200) // most recent
        XCTAssertEqual(sorted[2].totalElapsed, 0)   // oldest
    }

    // MARK: - Workout Model Integration

    func testTotalDurationEstimateMatchesManualCalculation() {
        // warmup(60) + 3 intervals(30) + 2 rests(15) + cooldown(60) = 60+90+30+60 = 240
        let w = makeWorkout(warmup: 60, interval: 30, rest: 15, intervals: 3, cooldown: 60)
        XCTAssertEqual(w.totalDurationEstimate, 240)
    }

    func testExercisesAreSortedByOrderAfterFetch() throws {
        let workout = makeWorkout(seedExercises: false)
        addExercises(workout, count: 5)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Workout>())
        let sorted = fetched[0].sortedExercises
        for (i, ex) in sorted.enumerated() {
            XCTAssertEqual(ex.order, i)
        }
    }
}
