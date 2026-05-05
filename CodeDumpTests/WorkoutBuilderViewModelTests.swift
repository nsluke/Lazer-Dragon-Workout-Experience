import XCTest
import SwiftData
@testable import Lazer_Dragon

@MainActor
final class WorkoutBuilderViewModelTests: XCTestCase {

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

    // MARK: - Validation

    func testIsValidFalseForEmptyName() {
        let vm = WorkoutBuilderViewModel()
        vm.name = ""
        XCTAssertFalse(vm.isValid)
    }

    func testIsValidFalseForWhitespaceName() {
        let vm = WorkoutBuilderViewModel()
        vm.name = "   "
        XCTAssertFalse(vm.isValid)
    }

    func testIsValidTrueForNonEmptyName() {
        let vm = WorkoutBuilderViewModel()
        vm.name = "Power Circuit"
        XCTAssertTrue(vm.isValid)
    }

    // MARK: - Edit Mode

    func testIsEditingFalseForNewWorkout() {
        XCTAssertFalse(WorkoutBuilderViewModel().isEditing)
    }

    func testIsEditingTrueForExistingWorkout() {
        let workout = Workout(name: "Existing")
        context.insert(workout)
        XCTAssertTrue(WorkoutBuilderViewModel(editing: workout).isEditing)
    }

    func testEditModePrePopulatesAllFields() {
        let workout = Workout(
            name: "Power",
            type: .hiit,
            warmupLength: 30,
            intervalLength: 45,
            restLength: 15,
            numberOfIntervals: 4,
            numberOfSets: 3,
            restBetweenSetLength: 90,
            cooldownLength: 60
        )
        context.insert(workout)

        let vm = WorkoutBuilderViewModel(editing: workout)
        XCTAssertEqual(vm.name, "Power")
        XCTAssertEqual(vm.type, .hiit)
        XCTAssertEqual(vm.warmupLength, 30)
        XCTAssertEqual(vm.intervalLength, 45)
        XCTAssertEqual(vm.restLength, 15)
        XCTAssertEqual(vm.numberOfIntervals, 4)
        XCTAssertEqual(vm.numberOfSets, 3)
        XCTAssertEqual(vm.restBetweenSetLength, 90)
        XCTAssertEqual(vm.cooldownLength, 60)
    }

    func testEditModePrePopulatesExercises() {
        let workout = Workout(name: "Test")
        context.insert(workout)
        let ex = Exercise(order: 0, name: "Burpee", splitLength: 40, reps: 10)
        ex.workout = workout
        workout.exercises?.append(ex)
        context.insert(ex)

        let vm = WorkoutBuilderViewModel(editing: workout)
        XCTAssertEqual(vm.exercises.count, 1)
        XCTAssertEqual(vm.exercises[0].name, "Burpee")
        XCTAssertEqual(vm.exercises[0].splitLength, 40)
        XCTAssertEqual(vm.exercises[0].reps, 10)
    }

    // MARK: - Insert New

    func testInsertNewCreatesWorkout() throws {
        let vm = WorkoutBuilderViewModel()
        vm.name = "New Workout"
        vm.intervalLength = 20
        vm.save(in: context)

        let workouts = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(workouts.count, 1)
        XCTAssertEqual(workouts[0].name, "New Workout")
        XCTAssertEqual(workouts[0].intervalLength, 20)
    }

    func testInsertNewTrimsWhitespace() throws {
        let vm = WorkoutBuilderViewModel()
        vm.name = "  My Workout  "
        vm.save(in: context)

        let workouts = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(workouts[0].name, "My Workout")
    }

    func testInsertNewWithExercises() throws {
        let vm = WorkoutBuilderViewModel()
        vm.name = "Circuit"
        vm.addExercise()
        vm.exercises[0].name = "Squat"
        vm.exercises[0].splitLength = 40
        vm.save(in: context)

        let workouts = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(workouts[0].exerciseCount, 1)
        XCTAssertEqual(workouts[0].sortedExercises[0].name, "Squat")
        XCTAssertEqual(workouts[0].sortedExercises[0].splitLength, 40)
    }

    func testInsertNewSetsCorrectExerciseOrder() throws {
        let vm = WorkoutBuilderViewModel()
        vm.name = "Circuit"
        vm.addExercise()
        vm.addExercise()
        vm.exercises[0].name = "First"
        vm.exercises[1].name = "Second"
        vm.save(in: context)

        let workouts = try context.fetch(FetchDescriptor<Workout>())
        let sorted = workouts[0].sortedExercises
        XCTAssertEqual(sorted[0].name, "First")
        XCTAssertEqual(sorted[1].name, "Second")
    }

    // MARK: - Update Existing

    func testUpdateExistingModifiesName() throws {
        let workout = Workout(name: "Old Name")
        context.insert(workout)

        let vm = WorkoutBuilderViewModel(editing: workout)
        vm.name = "New Name"
        vm.save(in: context)

        XCTAssertEqual(workout.name, "New Name")
    }

    func testUpdateExistingModifiesIntervalLength() throws {
        let workout = Workout(name: "Test", intervalLength: 20)
        context.insert(workout)

        let vm = WorkoutBuilderViewModel(editing: workout)
        vm.intervalLength = 40
        vm.save(in: context)

        XCTAssertEqual(workout.intervalLength, 40)
    }

    func testUpdateExistingReplacesExercises() throws {
        let workout = Workout(name: "Test")
        context.insert(workout)
        let old = Exercise(order: 0, name: "Old Exercise", splitLength: 30, reps: 0)
        old.workout = workout
        workout.exercises?.append(old)
        context.insert(old)

        let vm = WorkoutBuilderViewModel(editing: workout)
        vm.exercises = []
        vm.addExercise()
        vm.exercises[0].name = "New Exercise"
        vm.save(in: context)

        XCTAssertEqual(workout.exerciseCount, 1)
        XCTAssertEqual(workout.sortedExercises[0].name, "New Exercise")
    }

    func testUpdateDoesNotCreateDuplicateWorkout() throws {
        let workout = Workout(name: "Original")
        context.insert(workout)

        let vm = WorkoutBuilderViewModel(editing: workout)
        vm.name = "Updated"
        vm.save(in: context)

        let workouts = try context.fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(workouts.count, 1)
    }

    // MARK: - Exercise Management

    func testAddExerciseAppendsEntry() {
        let vm = WorkoutBuilderViewModel()
        XCTAssertEqual(vm.exercises.count, 0)
        vm.addExercise()
        XCTAssertEqual(vm.exercises.count, 1)
    }

    func testRemoveExerciseDeletesEntry() {
        let vm = WorkoutBuilderViewModel()
        vm.addExercise()
        vm.addExercise()
        vm.removeExercises(at: IndexSet(integer: 0))
        XCTAssertEqual(vm.exercises.count, 1)
    }

    func testMoveExercisesReordersEntries() {
        let vm = WorkoutBuilderViewModel()
        vm.addExercise()
        vm.addExercise()
        vm.exercises[0].name = "Alpha"
        vm.exercises[1].name = "Beta"
        vm.moveExercises(from: IndexSet(integer: 0), to: 2)
        XCTAssertEqual(vm.exercises[0].name, "Beta")
        XCTAssertEqual(vm.exercises[1].name, "Alpha")
    }
}
