import HealthKit
import Foundation

/// Saves completed workouts to Apple Health.
/// Authorization is requested lazily the first time the session screen appears.
@MainActor
final class HealthKitManager {

    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { return }
        let share: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]
        try? await store.requestAuthorization(toShare: share, read: [])
    }

    // MARK: - Save

    func saveWorkout(type: WorkoutType, start: Date, end: Date) async {
        guard isAvailable else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = type.hkActivityType

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())

        do {
            try await builder.beginCollection(at: start)

            let calories = estimatedCalories(type: type, duration: end.timeIntervalSince(start))
            let energySample = HKQuantitySample(
                type: HKQuantityType(.activeEnergyBurned),
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                start: start,
                end: end
            )
            try await builder.addSamples([energySample])
            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            // Silently fail — Health access may be denied or unavailable
        }
    }

    // MARK: - Helpers

    /// Rough MET-based estimate using an 70 kg reference body weight.
    private func estimatedCalories(type: WorkoutType, duration: TimeInterval) -> Double {
        let weightKg = 70.0
        return type.met * weightKg * (duration / 3600.0)
    }
}

// MARK: - WorkoutType + HealthKit

extension WorkoutType {
    var hkActivityType: HKWorkoutActivityType {
        switch self {
        case .hiit:     return .highIntensityIntervalTraining
        case .run:      return .running
        case .yoga:     return .yoga
        case .strength: return .traditionalStrengthTraining
        case .custom:   return .functionalStrengthTraining
        }
    }

    /// Metabolic Equivalent of Task — used for calorie estimation.
    var met: Double {
        switch self {
        case .hiit:     return 8.0
        case .run:      return 9.0
        case .yoga:     return 3.0
        case .strength: return 5.0
        case .custom:   return 6.0
        }
    }
}
