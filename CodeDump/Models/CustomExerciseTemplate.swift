import SwiftData
import Foundation

@Model
final class CustomExerciseTemplate {
    var id: String = UUID().uuidString
    var name: String = ""
    var targetMuscleGroupsRaw: String = ""
    var equipmentRaw: String = "bodyweight"
    var instructions: String = ""
    var defaultDuration: Int = 30
    var defaultReps: Int = 0
    var createdAt: Date = Date()

    init(
        name: String,
        muscleGroups: [MuscleGroup] = [],
        equipment: Equipment = .bodyweight,
        instructions: String = "",
        defaultDuration: Int = 30,
        defaultReps: Int = 0
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.targetMuscleGroupsRaw = muscleGroups.map(\.rawValue).joined(separator: ",")
        self.equipmentRaw = equipment.rawValue
        self.instructions = instructions
        self.defaultDuration = defaultDuration
        self.defaultReps = defaultReps
        self.createdAt = Date()
    }

    var muscleGroups: [MuscleGroup] {
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
