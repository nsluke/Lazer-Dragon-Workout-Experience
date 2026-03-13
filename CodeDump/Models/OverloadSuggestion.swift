import Foundation

// MARK: - Overload Suggestion

/// A progressive overload or deload recommendation for a specific exercise.
struct OverloadSuggestion {
    let lastWeight: Double
    let lastReps: Int
    let suggestedWeight: Double
    let suggestedReps: Int
    let isDeloadSuggested: Bool
    let deloadWeight: Double?
    let message: String

    // MARK: - Suggest

    /// Generates a progressive overload suggestion for an exercise based on history.
    /// Returns `nil` if there is no prior performance data.
    ///
    /// - Parameters:
    ///   - exerciseTemplateID: The template ID of the exercise.
    ///   - currentSetIndex: The current set index (0-based).
    ///   - allLogs: All historical SetLog entries (will be filtered internally).
    ///   - analyzer: A MuscleAnalyzer instance (for progression week detection).
    static func suggest(
        for exerciseTemplateID: String,
        currentSetIndex: Int,
        allLogs: [SetLog],
        analyzer: MuscleAnalyzer = MuscleAnalyzer()
    ) -> OverloadSuggestion? {
        // 1. Find last performance for this exercise
        guard let last = analyzer.lastPerformance(
            exerciseTemplateID: exerciseTemplateID,
            setIndex: currentSetIndex,
            allLogs: allLogs
        ) else { return nil }

        let prevWeight = last.weight
        let prevReps = last.reps
        let prevRPE = last.rpe ?? 5  // assume moderate if not logged

        // 2. Check for deload (4+ consecutive progression weeks)
        let progressionWeeks = analyzer.consecutiveProgressionWeeks(
            exerciseTemplateID: exerciseTemplateID,
            logs: allLogs
        )

        if progressionWeeks >= 4 {
            let deload = roundToNearest5(prevWeight * 0.85)
            return OverloadSuggestion(
                lastWeight: prevWeight,
                lastReps: prevReps,
                suggestedWeight: deload,
                suggestedReps: prevReps,
                isDeloadSuggested: true,
                deloadWeight: deload,
                message: "\(progressionWeeks) weeks progressing! Deload: \(formatWeight(deload))×\(prevReps)"
            )
        }

        // 3. Progressive overload based on RPE
        let increment = weightIncrement(for: prevWeight)

        if prevRPE <= 7 {
            // Room to grow — increase weight
            let newWeight = prevWeight + increment
            return OverloadSuggestion(
                lastWeight: prevWeight,
                lastReps: prevReps,
                suggestedWeight: newWeight,
                suggestedReps: prevReps,
                isDeloadSuggested: false,
                deloadWeight: nil,
                message: "Last: \(formatWeight(prevWeight))×\(prevReps). Try \(formatWeight(newWeight))×\(prevReps)"
            )
        } else if prevRPE == 8 {
            // At target — offer weight OR rep increase
            let newWeight = prevWeight + increment
            let newReps = prevReps + 2
            return OverloadSuggestion(
                lastWeight: prevWeight,
                lastReps: prevReps,
                suggestedWeight: newWeight,
                suggestedReps: prevReps,
                isDeloadSuggested: false,
                deloadWeight: nil,
                message: "Last: \(formatWeight(prevWeight))×\(prevReps). Try \(formatWeight(newWeight))×\(prevReps) or \(formatWeight(prevWeight))×\(newReps)"
            )
        } else {
            // RPE >= 9 — near failure, keep weight, add 1 rep
            let newReps = prevReps + 1
            return OverloadSuggestion(
                lastWeight: prevWeight,
                lastReps: prevReps,
                suggestedWeight: prevWeight,
                suggestedReps: newReps,
                isDeloadSuggested: false,
                deloadWeight: nil,
                message: "Last set was tough. Try \(formatWeight(prevWeight))×\(newReps)"
            )
        }
    }

    // MARK: - Private Helpers

    /// Weight increment based on current load.
    private static func weightIncrement(for weight: Double) -> Double {
        weight <= 135 ? 5.0 : 10.0
    }

    /// Rounds to the nearest 5 (common plate increment).
    private static func roundToNearest5(_ value: Double) -> Double {
        (value / 5.0).rounded() * 5.0
    }

    /// Formats weight for display: "135" if whole, "137.5" if fractional.
    private static func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
    }
}
