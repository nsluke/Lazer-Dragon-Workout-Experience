#if os(iOS)
import HealthKit
import Foundation

// MARK: - Recovery Score

struct RecoveryScore {
    let overall: Double         // 0.0 (very fatigued) to 1.0 (fully recovered)
    let sleepComponent: Double? // nil if HealthKit unavailable/denied
    let hrvComponent: Double?   // nil if HealthKit unavailable/denied
    let rpeComponent: Double    // always available from SetLogs

    var displayPercentage: Int { Int(overall * 100) }
}

// MARK: - Recovery Analyzer

/// Reads sleep and HRV data from HealthKit and computes a composite recovery score.
/// Falls back gracefully when HealthKit is unavailable or denied.
struct RecoveryAnalyzer {

    private static let store = HKHealthStore()

    // MARK: - Authorization

    /// Requests read authorization for sleep and HRV. Call this only on program enrollment.
    static func requestRecoveryAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let readTypes: Set<HKObjectType> = [
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.heartRateVariabilitySDNN),
        ]
        try? await store.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - Data Fetching

    /// Returns total sleep hours from last night (most recent sleep analysis sample).
    static func fetchSleepHours() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        let sleepType = HKCategoryType(.sleepAnalysis)
        let startOfYesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: .now))!
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: .now, options: .strictStartDate)
        let sortDescriptor = SortDescriptor<HKCategorySample>(\.startDate, order: .reverse)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [sortDescriptor],
            limit: 100
        )

        guard let samples = try? await descriptor.result(for: store) else { return nil }

        // Sum asleep categories (InBed is too broad)
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue,
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
        ]

        var totalSeconds: TimeInterval = 0
        for sample in samples where asleepValues.contains(sample.value) {
            totalSeconds += sample.endDate.timeIntervalSince(sample.startDate)
        }

        return totalSeconds > 0 ? totalSeconds / 3600.0 : nil
    }

    /// Returns the most recent HRV (SDNN) value from the last 24 hours.
    static func fetchRecentHRV() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        let predicate = HKQuery.predicateForSamples(withStart: oneDayAgo, end: .now, options: .strictStartDate)
        let sortDescriptor = SortDescriptor<HKQuantitySample>(\.startDate, order: .reverse)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrvType, predicate: predicate)],
            sortDescriptors: [sortDescriptor],
            limit: 1
        )

        guard let samples = try? await descriptor.result(for: store),
              let latest = samples.first else { return nil }

        return latest.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
    }

    /// Returns the user's 14-day average HRV for baseline comparison.
    static func fetchBaselineHRV() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
        let predicate = HKQuery.predicateForSamples(withStart: fourteenDaysAgo, end: .now, options: .strictStartDate)
        let sortDescriptor = SortDescriptor<HKQuantitySample>(\.startDate, order: .reverse)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: hrvType, predicate: predicate)],
            sortDescriptors: [sortDescriptor],
            limit: 100
        )

        guard let samples = try? await descriptor.result(for: store),
              !samples.isEmpty else { return nil }

        let total = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }
        return total / Double(samples.count)
    }

    // MARK: - Composite Recovery Score

    /// Computes a composite recovery score combining sleep, HRV, and RPE data.
    static func computeRecovery(
        sleepHours: Double?,
        recentHRV: Double?,
        baselineHRV: Double?,
        recentRPEs: [Int],
        daysSinceLastWorkout: Int
    ) -> RecoveryScore {
        // Sleep score
        let sleepScore: Double?
        if let hours = sleepHours {
            if hours >= 7.5       { sleepScore = 1.0 }
            else if hours >= 6.5  { sleepScore = 0.7 }
            else if hours >= 5.5  { sleepScore = 0.4 }
            else                  { sleepScore = 0.2 }
        } else {
            sleepScore = nil
        }

        // HRV score (compared to baseline)
        let hrvScore: Double?
        if let hrv = recentHRV, let baseline = baselineHRV, baseline > 0 {
            let ratio = hrv / baseline
            if ratio >= 1.0       { hrvScore = 1.0 }
            else if ratio >= 0.9  { hrvScore = 0.7 }
            else if ratio >= 0.8  { hrvScore = 0.4 }
            else                  { hrvScore = 0.2 }
        } else {
            hrvScore = nil
        }

        // RPE score
        let rpeScore: Double
        if recentRPEs.isEmpty {
            rpeScore = 0.7 // neutral when no data
        } else {
            let avgRPE = Double(recentRPEs.reduce(0, +)) / Double(recentRPEs.count)
            if avgRPE <= 6       { rpeScore = 1.0 }
            else if avgRPE <= 7  { rpeScore = 0.7 }
            else if avgRPE <= 8  { rpeScore = 0.5 }
            else if avgRPE <= 9  { rpeScore = 0.3 }
            else                 { rpeScore = 0.1 }
        }

        // Weighted average — HealthKit components use 0.5 (neutral) when unavailable
        let effectiveSleep = sleepScore ?? 0.5
        let effectiveHRV = hrvScore ?? 0.5
        let overall = effectiveSleep * 0.3 + effectiveHRV * 0.3 + rpeScore * 0.4

        return RecoveryScore(
            overall: overall,
            sleepComponent: sleepScore,
            hrvComponent: hrvScore,
            rpeComponent: rpeScore
        )
    }
}

#endif
