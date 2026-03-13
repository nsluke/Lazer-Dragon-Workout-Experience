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
        var templateID: String? = nil
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
                templateID: $0.templateID
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

    private func makeExercise(from draft: DraftExercise, order: Int) -> Exercise {
        Exercise(
            order: order,
            name: draft.name.trimmingCharacters(in: .whitespaces),
            splitLength: draft.splitLength,
            reps: draft.reps,
            targetMuscleGroupsRaw: draft.targetMuscleGroups.map(\.rawValue).joined(separator: ","),
            equipmentRaw: draft.equipment.rawValue,
            templateID: draft.templateID
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
        for ex in workout.exercises { context.delete(ex) }
        workout.exercises = []

        for (index, draft) in exercises.enumerated() {
            let ex = makeExercise(from: draft, order: index)
            ex.workout = workout
            workout.exercises.append(ex)
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
            workout.exercises.append(ex)
            context.insert(ex)
        }
    }
}
