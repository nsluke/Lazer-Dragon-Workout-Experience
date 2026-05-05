import SwiftData
import Foundation

@Observable
final class WorkoutBuilderViewModel {
    var name: String = ""
    var type: WorkoutType = .custom
    var warmupLength: Int = 0
    var intervalLength: Int = 30
    var restLength: Int = 15
    var numberOfIntervals: Int = 5
    var numberOfSets: Int = 1
    var restBetweenSetLength: Int = 60
    var cooldownLength: Int = 0
    var exercises: [DraftExercise] = []

    private let editingWorkout: Workout?

    struct DraftExercise: Identifiable {
        let id = UUID()
        var name: String = ""
        var splitLength: Int = 30
        var reps: Int = 0
        var targetMuscleGroups: [MuscleGroup] = []
        var equipment: Equipment = .bodyweight
        var exerciseMode: ExerciseMode = .repBased
        var templateID: String? = nil
        var supersetGroupID: String? = nil
    }

    init(editing workout: Workout? = nil) {
        self.editingWorkout = workout
        guard let workout else { return }

        name                = workout.name
        type                = workout.workoutType
        warmupLength        = workout.warmupLength
        intervalLength      = workout.intervalLength
        restLength          = workout.restLength
        numberOfIntervals   = workout.numberOfIntervals
        numberOfSets        = workout.numberOfSets
        restBetweenSetLength = workout.restBetweenSetLength
        cooldownLength      = workout.cooldownLength
        exercises = workout.sortedExercises.map {
            DraftExercise(
                name: $0.name,
                splitLength: $0.splitLength,
                reps: $0.reps,
                targetMuscleGroups: $0.targetMuscleGroups,
                equipment: $0.equipment,
                exerciseMode: $0.exerciseMode,
                templateID: $0.templateID,
                supersetGroupID: $0.supersetGroupID
            )
        }
    }

    var isEditing: Bool { editingWorkout != nil }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func addExercise() {
        exercises.append(DraftExercise())
    }

    func addExercise(from item: ExercisePickerItem) {
        exercises.append(DraftExercise(
            name: item.name,
            splitLength: item.defaultDuration,
            reps: item.defaultReps,
            targetMuscleGroups: item.muscles,
            equipment: item.equipment,
            exerciseMode: item.exerciseMode,
            templateID: item.id
        ))
    }

    func removeExercises(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    func moveExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }

    func save(in context: ModelContext) {
        if let existing = editingWorkout {
            updateExisting(existing, in: context)
        } else {
            insertNew(in: context)
        }
        try? context.save()
    }

    // MARK: - Private

    // MARK: - Superset Grouping

    /// Groups contiguous exercises at the given indices into a superset.
    func groupAsSuperset(indices: [Int]) {
        let sorted = indices.sorted()
        guard sorted.count >= 2, sorted.count <= 4 else { return }
        // Verify contiguous
        for i in 1..<sorted.count {
            guard sorted[i] == sorted[i - 1] + 1 else { return }
        }
        let groupID = UUID().uuidString
        for i in sorted {
            exercises[i].supersetGroupID = groupID
        }
    }

    /// Removes an exercise from its superset group. Dissolves the group if fewer than 2 remain.
    func removeFromSuperset(at index: Int) {
        guard let groupID = exercises[index].supersetGroupID else { return }
        exercises[index].supersetGroupID = nil
        let remaining = exercises.indices.filter { exercises[$0].supersetGroupID == groupID }
        if remaining.count < 2 {
            for i in remaining { exercises[i].supersetGroupID = nil }
        }
    }

    /// Returns the superset group label for a given exercise index (e.g., "SUPERSET" or "CIRCUIT").
    func supersetLabel(at index: Int) -> String? {
        guard let groupID = exercises[index].supersetGroupID else { return nil }
        let count = exercises.filter { $0.supersetGroupID == groupID }.count
        return count <= 2 ? "SUPERSET" : "CIRCUIT"
    }

    /// Returns true if this exercise is the first in its superset group (for rendering headers).
    func isSupersetStart(at index: Int) -> Bool {
        guard exercises[index].supersetGroupID != nil else { return false }
        if index == 0 { return true }
        return exercises[index].supersetGroupID != exercises[index - 1].supersetGroupID
    }

    /// Returns true if this exercise is the last in its superset group.
    func isSupersetEnd(at index: Int) -> Bool {
        guard exercises[index].supersetGroupID != nil else { return false }
        if index == exercises.count - 1 { return true }
        return exercises[index].supersetGroupID != exercises[index + 1].supersetGroupID
    }

    // MARK: - Private

    private func makeExercise(from draft: DraftExercise, order: Int) -> Exercise {
        Exercise(
            order: order,
            name: draft.name.trimmingCharacters(in: .whitespaces),
            splitLength: draft.splitLength,
            reps: draft.reps,
            targetMuscleGroupsRaw: draft.targetMuscleGroups.map(\.rawValue).joined(separator: ","),
            equipmentRaw: draft.equipment.rawValue,
            exerciseModeRaw: draft.exerciseMode.rawValue,
            templateID: draft.templateID,
            supersetGroupID: draft.supersetGroupID
        )
    }

    private func updateExisting(_ workout: Workout, in context: ModelContext) {
        workout.name                 = name.trimmingCharacters(in: .whitespaces)
        workout.type                 = type.rawValue
        workout.warmupLength         = warmupLength
        workout.intervalLength       = intervalLength
        workout.restLength           = restLength
        workout.numberOfIntervals    = max(numberOfIntervals, exercises.count)
        workout.numberOfSets         = numberOfSets
        workout.restBetweenSetLength = restBetweenSetLength
        workout.cooldownLength       = cooldownLength

        // Replace all exercises
        for ex in workout.exercises ?? [] { context.delete(ex) }
        workout.exercises = []

        for (index, draft) in exercises.enumerated() {
            let ex = makeExercise(from: draft, order: index)
            ex.workout = workout
            workout.exercises?.append(ex)
            context.insert(ex)
        }
    }

    private func insertNew(in context: ModelContext) {
        let workout = Workout(
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            warmupLength: warmupLength,
            intervalLength: intervalLength,
            restLength: restLength,
            numberOfIntervals: max(numberOfIntervals, exercises.count),
            numberOfSets: numberOfSets,
            restBetweenSetLength: restBetweenSetLength,
            cooldownLength: cooldownLength
        )
        context.insert(workout)

        for (index, draft) in exercises.enumerated() {
            let ex = makeExercise(from: draft, order: index)
            ex.workout = workout
            workout.exercises?.append(ex)
            context.insert(ex)
        }
    }
}
