import XCTest
import SwiftData
@testable import CodeDump

@MainActor
final class WorkoutSessionViewModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Workout.self, Exercise.self, configurations: config)
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - Helpers

    private func makeWorkout(
        warmup: Int = 0,
        interval: Int = 30,
        rest: Int = 10,
        intervals: Int = 3,
        sets: Int = 1,
        restBetweenSets: Int = 0,
        cooldown: Int = 0
    ) -> Workout {
        let w = Workout(
            name: "Test",
            warmupLength: warmup,
            intervalLength: interval,
            restLength: rest,
            numberOfIntervals: intervals,
            numberOfSets: sets,
            restBetweenSetLength: restBetweenSets,
            cooldownLength: cooldown
        )
        context.insert(w)
        return w
    }

    // MARK: - Initial State

    func testInitialPhaseIsIdle() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout())
        XCTAssertEqual(vm.phase, .idle)
    }

    func testInitialIsRunningFalse() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout())
        XCTAssertFalse(vm.isRunning)
    }

    // MARK: - Start

    func testStartWithoutWarmupGoesToFirstInterval() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(warmup: 0))
        vm.startWorkout()
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 0, setIndex: 0))
        XCTAssertTrue(vm.isRunning)
    }

    func testStartWithWarmupGoesToWarmup() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(warmup: 30))
        vm.startWorkout()
        XCTAssertEqual(vm.phase, .warmup)
        XCTAssertTrue(vm.isRunning)
    }

    // MARK: - Skip Forward (state machine)

    func testWarmupAdvancesToFirstInterval() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(warmup: 30, rest: 0))
        vm.startWorkout()
        vm.skipForward()
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 0, setIndex: 0))
    }

    func testIntervalGoesToRestWhenRestEnabled() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 10, intervals: 3))
        vm.startWorkout()
        vm.skipForward()
        XCTAssertEqual(vm.phase, .rest(nextExerciseIndex: 1, setIndex: 0))
    }

    func testIntervalSkipsRestWhenRestIsZero() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 3))
        vm.startWorkout()
        vm.skipForward()
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 1, setIndex: 0))
    }

    func testRestAdvancesToNextInterval() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 10, intervals: 3))
        vm.startWorkout()        // .interval(0, 0)
        vm.skipForward()         // .rest(1, 0)
        vm.skipForward()         // .interval(1, 0)
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 1, setIndex: 0))
    }

    func testLastIntervalLastSetNoCooldownCompletes() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 1, sets: 1, cooldown: 0))
        vm.startWorkout()
        vm.skipForward()
        XCTAssertEqual(vm.phase, .completed)
        XCTAssertFalse(vm.isRunning)
    }

    func testLastIntervalLastSetWithCooldownGoesCooldown() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 1, sets: 1, cooldown: 30))
        vm.startWorkout()
        vm.skipForward()
        XCTAssertEqual(vm.phase, .cooldown)
    }

    func testCooldownAdvancesToCompleted() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 1, sets: 1, cooldown: 30))
        vm.startWorkout()
        vm.skipForward() // → .cooldown
        vm.skipForward() // → .completed
        XCTAssertEqual(vm.phase, .completed)
        XCTAssertFalse(vm.isRunning)
    }

    func testLastIntervalMultipleSetsGoesToRestBetweenSets() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 1, sets: 3, restBetweenSets: 60))
        vm.startWorkout()
        vm.skipForward()
        XCTAssertEqual(vm.phase, .restBetweenSets(nextSetIndex: 1))
    }

    func testLastIntervalMultipleSetsSkipsRestBetweenSetsWhenZero() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 1, sets: 3, restBetweenSets: 0))
        vm.startWorkout()
        vm.skipForward()
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 0, setIndex: 1))
    }

    func testRestBetweenSetsAdvancesToNextSet() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 1, sets: 3, restBetweenSets: 60))
        vm.startWorkout()
        vm.skipForward() // → .restBetweenSets(1)
        vm.skipForward() // → .interval(0, 1)
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 0, setIndex: 1))
    }

    func testFullWorkoutCompletesAfterAllSets() {
        // 2 intervals, 2 sets, no rests or warmup/cooldown
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 2, sets: 2, restBetweenSets: 0))
        vm.startWorkout()           // .interval(0, 0)
        vm.skipForward()            // .interval(1, 0)
        vm.skipForward()            // .interval(0, 1)
        vm.skipForward()            // .interval(1, 1)
        vm.skipForward()            // .completed
        XCTAssertEqual(vm.phase, .completed)
    }

    // MARK: - Skip Backward

    func testSkipBackwardFromRestGoesToCurrentInterval() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 10, intervals: 3))
        vm.startWorkout()   // .interval(0, 0)
        vm.skipForward()    // .rest(1, 0)
        vm.skipBackward()   // back to .interval(0, 0)
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 0, setIndex: 0))
    }

    func testSkipBackwardFromIntervalGoesToPreviousInterval() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 3))
        vm.startWorkout()   // .interval(0, 0)
        vm.skipForward()    // .interval(1, 0)
        vm.skipBackward()   // .interval(0, 0)
        XCTAssertEqual(vm.phase, .interval(exerciseIndex: 0, setIndex: 0))
    }

    // MARK: - Pause / Resume

    func testPauseSetsIsRunningFalse() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout())
        vm.startWorkout()
        vm.pause()
        XCTAssertFalse(vm.isRunning)
    }

    func testResumeSetsIsRunningTrue() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout())
        vm.startWorkout()
        vm.pause()
        vm.resume()
        XCTAssertTrue(vm.isRunning)
    }

    func testPlayPauseToggles() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout())
        vm.startWorkout()
        vm.playPause() // → pause
        XCTAssertFalse(vm.isRunning)
        vm.playPause() // → resume
        XCTAssertTrue(vm.isRunning)
    }

    func testResumeDoesNothingWhenIdle() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout())
        vm.resume()
        XCTAssertFalse(vm.isRunning)
    }

    func testResumeDoesNothingWhenCompleted() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 1, sets: 1))
        vm.startWorkout()
        vm.endWorkout()
        vm.resume()
        XCTAssertFalse(vm.isRunning)
    }

    // MARK: - End Workout

    func testEndWorkoutTransitionsToCompleted() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout())
        vm.startWorkout()
        vm.endWorkout()
        XCTAssertEqual(vm.phase, .completed)
        XCTAssertFalse(vm.isRunning)
    }

    // MARK: - Split Duration

    func testSplitDurationReflectsWarmup() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(warmup: 60))
        vm.startWorkout()
        XCTAssertEqual(vm.splitDuration, 60)
    }

    func testSplitDurationReflectsIntervalLength() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(warmup: 0, interval: 45))
        vm.startWorkout()
        XCTAssertEqual(vm.splitDuration, 45)
    }

    func testSplitDurationReflectsRestLength() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 20, intervals: 2))
        vm.startWorkout()
        vm.skipForward()
        XCTAssertEqual(vm.splitDuration, 20)
    }

    func testSplitTimeRemainingEqualsSpltDurationAfterTransition() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(interval: 30))
        vm.startWorkout()
        XCTAssertEqual(vm.splitTimeRemaining, vm.splitDuration)
    }

    // MARK: - Computed Properties

    func testPhaseTitleIsReadyWhenIdle() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout())
        XCTAssertEqual(vm.phaseTitle, "READY")
    }

    func testPhaseTitleIsWarmupDuringWarmup() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(warmup: 30))
        vm.startWorkout()
        XCTAssertEqual(vm.phaseTitle, "WARMUP")
    }

    func testPhaseTitleIsRestDuringRest() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 10, intervals: 2))
        vm.startWorkout()
        vm.skipForward()
        XCTAssertEqual(vm.phaseTitle, "REST")
    }

    func testProgressRingIsOneRightAfterTransition() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout())
        vm.startWorkout()
        XCTAssertEqual(vm.progressRing, 1.0, accuracy: 0.01)
    }

    func testSetLabelShowsSetNumberDuringInterval() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(sets: 3))
        vm.startWorkout()
        XCTAssertEqual(vm.setLabel, "SET 1 / 3")
    }

    func testExercisesCompletedIncrementOnSkip() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 3))
        vm.startWorkout()
        vm.skipForward() // completes interval 0
        XCTAssertEqual(vm.exercisesCompleted, 1)
    }

    func testSetsCompletedIncrementAfterLastIntervalInSet() {
        let vm = WorkoutSessionViewModel(workout: makeWorkout(rest: 0, intervals: 1, sets: 2, restBetweenSets: 0))
        vm.startWorkout()
        vm.skipForward() // completes set 0
        XCTAssertEqual(vm.setsCompleted, 1)
    }
}
