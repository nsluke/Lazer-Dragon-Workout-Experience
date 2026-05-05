import HealthKit
import Foundation

/// Saves completed workouts to Apple Health.
/// Authorization is requested lazily the first time the session screen appears.
@MainActor
final class HealthKitManager {

    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    private(set) var authorizationRequested = false

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { return }
        // Skip the system permission sheet during UI tests — it blocks the workflow.
        if ProcessInfo.processInfo.arguments.contains("-UITesting") { return }
        let share: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]
        let read: Set<HKObjectType> = [
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKQuantityType(.bodyMass),
        ]
        do {
            try await store.requestAuthorization(toShare: share, read: read)
            authorizationRequested = true
        } catch {
            print("[LDWE] HealthKit authorization failed: \(error.localizedDescription)")
        }
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
            print("[LDWE] HealthKit save failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Enriched Save

    /// Saves a workout with exercise segment markers and volume metadata.
    /// Uses body mass from HealthKit when available for more accurate calorie estimation.
    func saveEnrichedWorkout(type: WorkoutType, start: Date, end: Date, setLogs: [SetLog]) async {
        guard isAvailable else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = type.hkActivityType

        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())

        do {
            try await builder.beginCollection(at: start)

            // Read body mass from HealthKit for accurate calorie calc
            let weightKg = await fetchBodyMass() ?? 70.0
            let calories = type.met * weightKg * (end.timeIntervalSince(start) / 3600.0)

            let energySample = HKQuantitySample(
                type: HKQuantityType(.activeEnergyBurned),
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                start: start,
                end: end
            )
            try await builder.addSamples([energySample])

            // Build segment events from set logs grouped by exerciseIndex
            let segments = buildSegmentEvents(from: setLogs, workoutStart: start, workoutEnd: end)
            if !segments.isEmpty {
                try await builder.addWorkoutEvents(segments)
            }

            // Calculate total volume for metadata
            let totalVolume = setLogs.reduce(0.0) { sum, log in
                let w = log.weight ?? 0
                let r = Double(log.reps ?? 0)
                return sum + (w * r)
            }

            try await builder.addMetadata([
                "LDWETotalVolumeKg": totalVolume
            ])

            try await builder.endCollection(at: end)
            _ = try await builder.finishWorkout()
        } catch {
            print("[LDWE] HealthKit enriched save failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Rough MET-based estimate using an 70 kg reference body weight.
    private func estimatedCalories(type: WorkoutType, duration: TimeInterval) -> Double {
        let weightKg = 70.0
        return type.met * weightKg * (duration / 3600.0)
    }

    /// Reads the most recent body mass sample from HealthKit.
    private func fetchBodyMass() async -> Double? {
        let massType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: massType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }

    /// Groups set logs by exerciseIndex and builds HKWorkoutEvent segment markers.
    private func buildSegmentEvents(from setLogs: [SetLog], workoutStart: Date, workoutEnd: Date) -> [HKWorkoutEvent] {
        let grouped = Dictionary(grouping: setLogs, by: \.exerciseIndex)
        var events: [HKWorkoutEvent] = []

        for (_, logs) in grouped.sorted(by: { $0.key < $1.key }) {
            let sortedLogs = logs.sorted { $0.date < $1.date }
            guard let firstDate = sortedLogs.first?.date,
                  let lastDate = sortedLogs.last?.date else { continue }

            // Use log dates as segment boundaries, clamped to the workout window.
            // SetLog timestamps frequently collapse (single log per exercise, or
            // logs committed in rapid succession), so guarantee a non-zero span
            // by extending the end at least 1s past the start when needed.
            let segStart = max(firstDate, workoutStart)
            let rawEnd = min(lastDate, workoutEnd)
            let segEnd = max(rawEnd, min(segStart.addingTimeInterval(1), workoutEnd))
            guard segEnd > segStart else { continue }

            let dateInterval = DateInterval(start: segStart, end: segEnd)
            let event = HKWorkoutEvent(type: .segment, dateInterval: dateInterval, metadata: nil)
            events.append(event)
        }

        return events
    }
}

// MARK: - WorkoutType + HealthKit

extension WorkoutType {
    var hkActivityType: HKWorkoutActivityType {
        switch self {
        case .hiit:     return .highIntensityIntervalTraining
        case .run:      return .running
        case .cycling:  return .cycling
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
        case .cycling:  return 7.5
        case .yoga:     return 3.0
        case .strength: return 5.0
        case .custom:   return 6.0
        }
    }
}
