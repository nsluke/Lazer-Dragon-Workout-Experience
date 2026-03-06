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

    struct DraftExercise: Identifiable {
        let id = UUID()
        var name: String = ""
        var splitLength: Int = 30
        var reps: Int = 0
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func addExercise() {
        exercises.append(DraftExercise())
    }

    func removeExercises(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    func moveExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }

    func save(in context: ModelContext) {
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
            let ex = Exercise(
                order: index,
                name: draft.name.trimmingCharacters(in: .whitespaces),
                splitLength: draft.splitLength,
                reps: draft.reps
            )
            ex.workout = workout
            workout.exercises.append(ex)
            context.insert(ex)
        }
        try? context.save()
    }
}
