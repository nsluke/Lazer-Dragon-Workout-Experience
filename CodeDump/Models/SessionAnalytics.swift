import Foundation

// MARK: - Session Analytics

/// Pure-logic engine that computes workout completion statistics:
/// PR detection, volume tracking, per-exercise summaries, and muscle groups trained.
/// No UI, Foundation-only. Consumed by WorkoutCompletedView and WorkoutCalendarView.
enum SessionAnalytics {

    // MARK: - Data Structures

    struct ExercisePR {
        let exerciseName: String
        let exerciseTemplateID: String?
        let sessionBestWeight: Double
        let sessionBestReps: Int
        let previousBestWeight: Double?
        let previousBestReps: Int?
        let isWeightPR: Bool   // weight exceeded all-time best
        let isRepPR: Bool      // same weight, more reps than previous best at that weight
        var isPR: Bool { isWeightPR || isRepPR }
    }

    struct ExerciseSummary: Identifiable {
        let id = UUID()
        let exerciseName: String
        let exerciseTemplateID: String?
        let sets: [SetLog]
        let bestSet: SetLog?       // highest weight in this session
        let volume: Double         // sum of weight * reps for this exercise
        let pr: ExercisePR?
        let muscleGroups: [MuscleGroup]
    }

    struct SessionSummary {
        let exerciseSummaries: [ExerciseSummary]
        let totalVolume: Double
        let previousSessionVolume: Double?
        let volumeDeltaPercent: Double?
        let prCount: Int
        let muscleGroupsHit: [MuscleGroup]
        let totalSets: Int
        let totalExercises: Int
    }

    // MARK: - Analysis

    /// Analyzes a completed workout session against historical data.
    ///
    /// - Parameters:
    ///   - sessionLogs: SetLogs from the just-completed session
    ///   - allHistoricalLogs: All SetLogs in the database (for PR comparison)
    ///   - workout: The Workout that was completed (for volume delta vs. last session)
    ///   - allSessions: All WorkoutSessions (for finding previous session of same workout)
    /// - Returns: A SessionSummary with PRs, volume, and exercise breakdowns
    static func analyze(
        sessionLogs: [SetLog],
        allHistoricalLogs: [SetLog],
        workout: Workout?,
        allSessions: [WorkoutSession]
    ) -> SessionSummary {
        let analyzer = MuscleAnalyzer()
        let startOfToday = Calendar.current.startOfDay(for: .now)

        // Historical logs excluding today (to compare against previous bests)
        let historicalLogs = allHistoricalLogs.filter { $0.date < startOfToday }

        // Group session logs by exercise (preserving first-appearance order)
        let exerciseGroups = groupByExercise(sessionLogs)

        // Build per-exercise summaries
        var summaries: [ExerciseSummary] = []
        var allMuscles: Set<MuscleGroup> = []
        var prCount = 0

        for (exerciseName, logs) in exerciseGroups {
            let templateID = logs.first?.exerciseTemplateID

            // Best set by weight (tiebreak: most reps)
            let bestSet = logs
                .filter { $0.weight != nil }
                .max { a, b in
                    let wa = a.weight ?? 0, wb = b.weight ?? 0
                    if wa != wb { return wa < wb }
                    return (a.reps ?? 0) < (b.reps ?? 0)
                }

            // Volume for this exercise
            let exerciseVolume = logs.reduce(0.0) { sum, log in
                sum + (log.weight ?? 0) * Double(log.reps ?? 0)
            }

            // PR detection
            let pr = detectPR(
                exerciseName: exerciseName,
                templateID: templateID,
                sessionBestSet: bestSet,
                historicalLogs: historicalLogs
            )
            if pr?.isPR == true { prCount += 1 }

            // Muscle groups
            let muscles: [MuscleGroup]
            if let first = logs.first {
                muscles = analyzer.musclesForLog(first)
            } else {
                muscles = []
            }
            allMuscles.formUnion(muscles)

            summaries.append(ExerciseSummary(
                exerciseName: exerciseName,
                exerciseTemplateID: templateID,
                sets: logs,
                bestSet: bestSet,
                volume: exerciseVolume,
                pr: pr,
                muscleGroups: muscles
            ))
        }

        // Total session volume
        let totalVolume = summaries.reduce(0.0) { $0 + $1.volume }

        // Previous session volume for the same workout
        let previousVolume = findPreviousSessionVolume(workout: workout, allSessions: allSessions)

        // Volume delta
        let volumeDelta: Double?
        if let prev = previousVolume, prev > 0 {
            volumeDelta = ((totalVolume - prev) / prev) * 100
        } else {
            volumeDelta = nil
        }

        // Sort muscle groups for consistent display
        let sortedMuscles = MuscleGroup.allCases.filter { allMuscles.contains($0) }

        return SessionSummary(
            exerciseSummaries: summaries,
            totalVolume: totalVolume,
            previousSessionVolume: previousVolume,
            volumeDeltaPercent: volumeDelta,
            prCount: prCount,
            muscleGroupsHit: sortedMuscles,
            totalSets: sessionLogs.count,
            totalExercises: summaries.count
        )
    }

    // MARK: - Formatting

    /// Formats a volume number with K/M suffixes for display.
    static func formatVolume(_ vol: Double) -> String {
        if vol >= 1_000_000 {
            return String(format: "%.1fM", vol / 1_000_000)
        } else if vol >= 1_000 {
            return String(format: "%.0fK", vol / 1_000)
        } else {
            return "\(Int(vol))"
        }
    }

    /// Returns a human-readable volume delta message.
    static func volumeDeltaMessage(percent: Double) -> String {
        let abs = Int(abs(percent))
        if percent > 0 {
            return "+\(abs)% VOLUME"
        } else if percent < 0 {
            return "-\(abs)% VOLUME"
        } else {
            return "SAME VOLUME"
        }
    }

    // MARK: - Private Helpers

    /// Groups SetLogs by exercise name, preserving first-appearance order.
    private static func groupByExercise(_ logs: [SetLog]) -> [(String, [SetLog])] {
        var order: [String] = []
        var groups: [String: [SetLog]] = [:]

        for log in logs {
            if groups[log.exerciseName] == nil {
                order.append(log.exerciseName)
            }
            groups[log.exerciseName, default: []].append(log)
        }

        return order.compactMap { name in
            guard let logs = groups[name] else { return nil }
            return (name, logs)
        }
    }

    /// Detects whether the session's best set for an exercise is a PR.
    private static func detectPR(
        exerciseName: String,
        templateID: String?,
        sessionBestSet: SetLog?,
        historicalLogs: [SetLog]
    ) -> ExercisePR? {
        guard let best = sessionBestSet,
              let sessionWeight = best.weight else { return nil }

        let sessionReps = best.reps ?? 0

        // Find historical best for this exercise
        let exerciseHistory: [SetLog]
        if let tid = templateID {
            exerciseHistory = historicalLogs.filter {
                $0.exerciseTemplateID == tid && $0.weight != nil
            }
        } else {
            exerciseHistory = historicalLogs.filter {
                $0.exerciseName == exerciseName && $0.weight != nil
            }
        }

        // Historical best weight (and best reps at that weight)
        let historicalBest = exerciseHistory
            .max { a, b in
                let wa = a.weight ?? 0, wb = b.weight ?? 0
                if wa != wb { return wa < wb }
                return (a.reps ?? 0) < (b.reps ?? 0)
            }

        let prevWeight = historicalBest?.weight
        let prevReps = historicalBest?.reps ?? 0

        let isWeightPR: Bool
        let isRepPR: Bool

        if let pw = prevWeight {
            isWeightPR = sessionWeight > pw
            isRepPR = !isWeightPR && sessionWeight == pw && sessionReps > prevReps
        } else {
            // No history — first time logging weight counts as a PR
            isWeightPR = true
            isRepPR = false
        }

        return ExercisePR(
            exerciseName: exerciseName,
            exerciseTemplateID: templateID,
            sessionBestWeight: sessionWeight,
            sessionBestReps: sessionReps,
            previousBestWeight: prevWeight,
            previousBestReps: prevWeight != nil ? prevReps : nil,
            isWeightPR: isWeightPR,
            isRepPR: isRepPR
        )
    }

    /// Finds the total volume of the most recent previous session for the same workout.
    private static func findPreviousSessionVolume(
        workout: Workout?,
        allSessions: [WorkoutSession]
    ) -> Double? {
        guard let workout else { return nil }

        // Find the most recent session for this workout (excluding today)
        let startOfToday = Calendar.current.startOfDay(for: .now)
        let previousSession = workout.sessions
            .filter { $0.date < startOfToday }
            .sorted { $0.date > $1.date }
            .first

        guard let session = previousSession else { return nil }

        let volume = session.setLogs.reduce(0.0) { sum, log in
            sum + (log.weight ?? 0) * Double(log.reps ?? 0)
        }

        return volume > 0 ? volume : nil
    }
}
