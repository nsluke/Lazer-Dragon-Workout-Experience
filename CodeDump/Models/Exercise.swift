import SwiftData
import Foundation

@Model
final class Exercise {
    var order: Int = 0
    var name: String = ""
    var splitLength: Int = 30
    var reps: Int = 0

    // Phase 1: Exercise Intelligence
    var targetMuscleGroupsRaw: String = ""
    var equipmentRaw: String = "bodyweight"
    var exerciseModeRaw: String = "repBased"
    var mediaURL: String?
    var templateID: String?
    var supersetGroupID: String?

    var workout: Workout?

    init(
        order: Int,
        name: String,
        splitLength: Int = 30,
        reps: Int = 0,
        targetMuscleGroupsRaw: String = "",
        equipmentRaw: String = "bodyweight",
        exerciseModeRaw: String = "repBased",
        mediaURL: String? = nil,
        templateID: String? = nil,
        supersetGroupID: String? = nil
    ) {
        self.order = order
        self.name = name
        self.splitLength = splitLength
        self.reps = reps
        self.targetMuscleGroupsRaw = targetMuscleGroupsRaw
        self.equipmentRaw = equipmentRaw
        self.exerciseModeRaw = exerciseModeRaw
        self.mediaURL = mediaURL
        self.templateID = templateID
        self.supersetGroupID = supersetGroupID
    }

    var targetMuscleGroups: [MuscleGroup] {
        get {
            targetMuscleGroupsRaw
                .split(separator: ",")
                .compactMap { MuscleGroup(rawValue: String($0)) }
        }
        set {
            targetMuscleGroupsRaw = newValue.map(\.rawValue).joined(separator: ",")
        }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .bodyweight }
        set { equipmentRaw = newValue.rawValue }
    }

    var exerciseMode: ExerciseMode {
        get { ExerciseMode(rawValue: exerciseModeRaw) ?? .repBased }
        set { exerciseModeRaw = newValue.rawValue }
    }
}
