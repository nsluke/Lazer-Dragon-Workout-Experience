import Foundation

/// Pure-logic engine for adaptive scheduling and deload detection.
/// No UI, no SwiftData — works on raw data passed in.
struct ProgramAdaptiveEngine {

    // MARK: - Adaptation Result

    enum Adaptation {
        /// Shift today's workout to the missed day's template, push remaining forward.
        case shift(adaptedSchedule: [Int: String], message: String)
        /// Combine two missed days into one catch-up workout.
        case merge(exerciseTemplateIDs: [String], message: String)
        /// Skip missed days entirely and resume from default schedule.
        case drop(message: String)
        /// No adaptation needed.
        case none
    }

    // MARK: - Missed Day Handling

    /// Analyzes missed workout days and returns an adaptation strategy.
    /// - Parameters:
    ///   - program: The active training program enrollment.
    ///   - today: The current ISO weekday (1=Mon..7=Sun). Defaults to today.
    /// - Returns: An Adaptation describing what action to take.
    static func adaptForMissedDays(
        program: TrainingProgram,
        today: Int? = nil
    ) -> Adaptation {
        guard let template = program.programTemplate else { return .none }

        let currentWeekday = today ?? isoWeekday()
        let weekIndex = program.currentWeek - 1
        let grid = program.completionGrid
        guard weekIndex >= 0, weekIndex < grid.count else { return .none }

        let weekData = grid[weekIndex]
        let schedule = program.effectiveSchedule

        // Find consecutive missed days before today
        let missedDays = countConsecutiveMissedDays(
            weekData: weekData,
            schedule: schedule,
            currentWeekday: currentWeekday
        )

        guard missedDays > 0 else { return .none }

        if missedDays == 1 {
            return shiftSchedule(
                template: template,
                originalSchedule: schedule,
                currentWeekday: currentWeekday
            )
        } else if missedDays == 2 {
            return mergeWorkouts(
                template: template,
                schedule: schedule,
                currentWeekday: currentWeekday,
                missedCount: missedDays
            )
        } else {
            return .drop(message: "Welcome back! Picking up where you left off.")
        }
    }

    // MARK: - Deload Detection

    struct DeloadResult {
        let shouldDeload: Bool
        let fatigueScore: Double
        let message: String?
    }

    /// Evaluates whether a deload week should be suggested.
    /// - Parameters:
    ///   - program: The active program enrollment.
    ///   - recentLogs: SetLogs from the last 2-3 weeks.
    ///   - recoveryScore: Optional recovery score (0-1) from HealthKit data.
    ///   - analyzer: MuscleAnalyzer instance for progression detection.
    static func evaluateDeload(
        program: TrainingProgram,
        recentLogs: [SetLog],
        recoveryScore: Double?,
        analyzer: MuscleAnalyzer = MuscleAnalyzer()
    ) -> DeloadResult {
        guard let template = program.programTemplate else {
            return DeloadResult(shouldDeload: false, fatigueScore: 0, message: nil)
        }

        // Don't suggest deload if user had one recently
        if let lastDeload = program.lastDeloadWeek,
           program.currentWeek - lastDeload < 3 {
            return DeloadResult(shouldDeload: false, fatigueScore: 0, message: nil)
        }

        // Calculate average RPE from recent logs
        let rpeLogs = recentLogs.compactMap(\.rpe)
        let avgRPE = rpeLogs.isEmpty ? 5.0 : Double(rpeLogs.reduce(0, +)) / Double(rpeLogs.count)

        // Find max progression weeks across all exercises in the program
        var maxProgressionWeeks = 0
        let allTemplateIDs = Set(template.dayTemplates.flatMap(\.exerciseTemplateIDs))
        for templateID in allTemplateIDs {
            let weeks = analyzer.consecutiveProgressionWeeks(
                exerciseTemplateID: templateID,
                logs: recentLogs
            )
            maxProgressionWeeks = max(maxProgressionWeeks, weeks)
        }

        // Recovery penalty (0 = fully recovered, 0.5 = max penalty)
        let recoveryPenalty: Double
        if let score = recoveryScore {
            recoveryPenalty = max(0, (1.0 - score) * 0.5)
        } else {
            recoveryPenalty = 0
        }

        let fatigueScore = (avgRPE / 10.0) * Double(max(1, maxProgressionWeeks)) + recoveryPenalty

        let shouldDeload = fatigueScore >= 3.5 || maxProgressionWeeks >= 4

        let message: String?
        if shouldDeload {
            if maxProgressionWeeks >= 4 {
                message = "\(maxProgressionWeeks) weeks of progression. Time for a deload!"
            } else {
                message = "High fatigue detected. Consider a lighter week."
            }
        } else {
            message = nil
        }

        return DeloadResult(
            shouldDeload: shouldDeload,
            fatigueScore: fatigueScore,
            message: message
        )
    }

    // MARK: - Private Helpers

    private static func countConsecutiveMissedDays(
        weekData: [Bool],
        schedule: [Int: String],
        currentWeekday: Int
    ) -> Int {
        var count = 0
        // Walk backward from yesterday
        var day = currentWeekday - 1
        while day >= 1 {
            // Only count scheduled workout days that weren't completed
            if schedule[day] != nil {
                let dayIndex = day - 1
                if dayIndex >= 0, dayIndex < weekData.count, !weekData[dayIndex] {
                    count += 1
                } else {
                    break // Found a completed day, stop counting
                }
            }
            day -= 1
        }
        return count
    }

    private static func shiftSchedule(
        template: ProgramTemplate,
        originalSchedule: [Int: String],
        currentWeekday: Int
    ) -> Adaptation {
        // Find the missed day's template (yesterday's or earlier)
        var missedDay = currentWeekday - 1
        while missedDay >= 1 {
            if let templateID = originalSchedule[missedDay] {
                // Build adapted schedule: put the missed day's template on today,
                // shift remaining days forward by 1 (rest days absorb overflow)
                var adapted = originalSchedule
                adapted.removeValue(forKey: missedDay)

                // Shift days from today onward forward by 1
                let daysToShift = originalSchedule.keys.filter { $0 >= currentWeekday }.sorted()
                for day in daysToShift.reversed() {
                    if let val = adapted[day] {
                        adapted.removeValue(forKey: day)
                        let newDay = day + 1
                        if newDay <= 7 {
                            adapted[newDay] = val
                        }
                        // If it goes past Sunday, it's dropped (absorbed by the week boundary)
                    }
                }

                // Put the missed workout on today
                adapted[currentWeekday] = templateID

                let dayLabel = template.dayTemplate(for: templateID)?.label ?? "Workout"
                return .shift(
                    adaptedSchedule: adapted,
                    message: "Shifted schedule: \(dayLabel) moved to today."
                )
            }
            missedDay -= 1
        }
        return .none
    }

    private static func mergeWorkouts(
        template: ProgramTemplate,
        schedule: [Int: String],
        currentWeekday: Int,
        missedCount: Int
    ) -> Adaptation {
        // Collect exercise IDs from the missed days
        var allExerciseIDs: [String] = []
        var day = currentWeekday - 1
        var collected = 0
        while day >= 1, collected < missedCount {
            if let templateID = schedule[day],
               let dayTemplate = template.dayTemplate(for: templateID) {
                allExerciseIDs.append(contentsOf: dayTemplate.exerciseTemplateIDs)
                collected += 1
            }
            day -= 1
        }

        guard !allExerciseIDs.isEmpty else { return .none }

        // Take first 4 exercises from each missed day (compounds are listed first in templates)
        // Deduplicate
        var seen = Set<String>()
        var merged: [String] = []
        for id in allExerciseIDs {
            if !seen.contains(id), merged.count < 8 {
                merged.append(id)
                seen.insert(id)
            }
        }

        return .merge(
            exerciseTemplateIDs: merged,
            message: "Combined \(missedCount) missed days into one catch-up workout."
        )
    }

    private static func isoWeekday() -> Int {
        let dow = Calendar.current.component(.weekday, from: .now)
        return dow == 1 ? 7 : dow - 1
    }
}
