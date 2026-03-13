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
    var mediaURL: String?
    var templateID: String?

    var workout: Workout?

    init(
        order: Int,
        name: String,
        splitLength: Int = 30,
        reps: Int = 0,
        targetMuscleGroupsRaw: String = "",
        equipmentRaw: String = "bodyweight",
        mediaURL: String? = nil,
        templateID: String? = nil
    ) {
        self.order = order
        self.name = name
        self.splitLength = splitLength
        self.reps = reps
        self.targetMuscleGroupsRaw = targetMuscleGroupsRaw
        self.equipmentRaw = equipmentRaw
        self.mediaURL = mediaURL
        self.templateID = templateID
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
}
