import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Custom UTType

extension UTType {
    static let ldweWorkout = UTType(exportedAs: "com.lazerdragon.workout")
}

// MARK: - Codable Export Structs

struct ExerciseExport: Codable {
    let order: Int
    let name: String
    let splitLength: Int
    let reps: Int
    let targetMuscleGroupsRaw: String
    let equipmentRaw: String
    let exerciseModeRaw: String?
    let templateID: String?
    let supersetGroupID: String?

    init(from exercise: Exercise) {
        self.order = exercise.order
        self.name = exercise.name
        self.splitLength = exercise.splitLength
        self.reps = exercise.reps
        self.targetMuscleGroupsRaw = exercise.targetMuscleGroupsRaw
        self.equipmentRaw = exercise.equipmentRaw
        self.exerciseModeRaw = exercise.exerciseModeRaw
        self.templateID = exercise.templateID
        self.supersetGroupID = exercise.supersetGroupID
    }
}

struct WorkoutExport: Codable {
    let version: Int
    let name: String
    let type: String
    let warmupLength: Int
    let intervalLength: Int
    let restLength: Int
    let numberOfIntervals: Int
    let numberOfSets: Int
    let restBetweenSetLength: Int
    let cooldownLength: Int
    let exercises: [ExerciseExport]

    init(from workout: Workout) {
        self.version = 2
        self.name = workout.name
        self.type = workout.type
        self.warmupLength = workout.warmupLength
        self.intervalLength = workout.intervalLength
        self.restLength = workout.restLength
        self.numberOfIntervals = workout.numberOfIntervals
        self.numberOfSets = workout.numberOfSets
        self.restBetweenSetLength = workout.restBetweenSetLength
        self.cooldownLength = workout.cooldownLength
        self.exercises = workout.sortedExercises.map { ExerciseExport(from: $0) }
    }

    /// Creates a Workout + Exercise entities from this export in the given context.
    @discardableResult
    func createWorkout(in context: ModelContext) -> Workout {
        let workout = Workout(
            name: name,
            type: WorkoutType(rawValue: type) ?? .strength,
            warmupLength: warmupLength,
            intervalLength: intervalLength,
            restLength: restLength,
            numberOfIntervals: numberOfIntervals,
            numberOfSets: numberOfSets,
            restBetweenSetLength: restBetweenSetLength,
            cooldownLength: cooldownLength
        )
        context.insert(workout)

        for item in exercises {
            let exercise = Exercise(
                order: item.order,
                name: item.name,
                splitLength: item.splitLength,
                reps: item.reps,
                targetMuscleGroupsRaw: item.targetMuscleGroupsRaw,
                equipmentRaw: item.equipmentRaw,
                exerciseModeRaw: item.exerciseModeRaw ?? "repBased",
                templateID: item.templateID,
                supersetGroupID: item.supersetGroupID
            )
            exercise.workout = workout
            workout.exercises.append(exercise)
            context.insert(exercise)
        }

        try? context.save()
        return workout
    }

    /// Encode to JSON Data for file export.
    var jsonData: Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    /// Decode from JSON Data.
    static func decode(from data: Data) -> WorkoutExport? {
        try? JSONDecoder().decode(WorkoutExport.self, from: data)
    }
}

// MARK: - Transferable

#if os(iOS)
import SwiftUI
import CoreTransferable

extension WorkoutExport: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .ldweWorkout)
    }
}
#endif
