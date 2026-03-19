import Foundation

// MARK: - Equipment Profile

/// Manages the user's available equipment selection, persisted via @AppStorage.
/// Storage format: comma-separated Equipment rawValues (e.g. "bodyweight,dumbbells,band").
struct EquipmentProfile {

    // MARK: Presets

    enum Preset: String, CaseIterable, Identifiable {
        case homeGym       = "Home Gym"
        case commercialGym = "Commercial Gym"
        case custom        = "Custom"

        var id: String { rawValue }
    }

    static let homeGymEquipment: Set<Equipment> = [
        .bodyweight, .dumbbells, .band, .pullupBar
    ]

    static let commercialGymEquipment: Set<Equipment> = Set(Equipment.allCases)

    static func equipment(for preset: Preset) -> Set<Equipment> {
        switch preset {
        case .homeGym:       return homeGymEquipment
        case .commercialGym: return commercialGymEquipment
        case .custom:        return homeGymEquipment          // sensible default
        }
    }

    // MARK: Encode / Decode (CSV rawValues)

    static func encode(_ equipment: Set<Equipment>) -> String {
        equipment.map(\.rawValue).sorted().joined(separator: ",")
    }

    static func decode(_ raw: String) -> Set<Equipment> {
        guard !raw.isEmpty else { return commercialGymEquipment }
        return Set(
            raw.split(separator: ",")
               .compactMap { Equipment(rawValue: String($0)) }
        )
    }

    // MARK: Preset Inference

    /// Determines which preset matches the given equipment set, if any.
    static func inferPreset(from equipment: Set<Equipment>) -> Preset {
        if equipment == commercialGymEquipment { return .commercialGym }
        if equipment == homeGymEquipment       { return .homeGym }
        return .custom
    }

    // MARK: Library Filtering

    /// Returns the number of exercises in the built-in library that match the equipment set.
    static func availableExerciseCount(for equipment: Set<Equipment>) -> Int {
        ExerciseTemplate.library.filter { equipment.contains($0.equipment) }.count
    }
}
