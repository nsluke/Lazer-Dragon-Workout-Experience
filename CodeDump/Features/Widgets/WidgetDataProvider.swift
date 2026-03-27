import Foundation
import SwiftData
import WidgetKit

// MARK: - Shared Codable Types (mirrored in LDWELiveActivity/WidgetData.swift)

struct NextWorkoutData: Codable {
    let workoutName: String
    let muscleGroups: [String]
    let exerciseCount: Int
    let setCount: Int
    let isRestDay: Bool
    let programName: String?
    let updatedAt: Date
}

struct WeeklyStreakData: Codable {
    let sessionsThisWeek: Int
    let targetSessions: Int
    let currentStreakDays: Int
    let updatedAt: Date
}

struct MuscleHeatmapData: Codable {
    let muscleActivity: [String: Int]
    let updatedAt: Date
}

struct PRCelebrationData: Codable {
    let exerciseName: String
    let prType: PRType
    let displayValue: String
    let achievedAt: Date

    enum PRType: String, Codable {
        case weight
        case reps
        case duration
    }
}

struct ProgramProgressData: Codable {
    let programName: String
    let currentWeek: Int
    let totalWeeks: Int
    let completedDays: Int
    let totalDays: Int
    let percentage: Double
    let updatedAt: Date
}

// MARK: - Widget Data Provider

/// Bridges SwiftData models to the shared App Group UserDefaults
/// so that widgets can display up-to-date workout information.
///
/// Call `refreshAll(context:)` after significant data changes:
/// - Workout session completed
/// - Program enrollment/day completion
/// - Set log saved (for PR detection)
@MainActor
final class WidgetDataProvider {

    static let shared = WidgetDataProvider()
    private init() {}

    // MARK: - App Group

    private let suiteName = "group.com.Solomon.Lazer-Dragon"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Refresh All

    // MARK: - Widget Kind Constants

    static let nextWorkoutKind     = "NextWorkoutWidget"
    static let weeklyStreakKind    = "WeeklyStreakWidget"
    static let muscleHeatmapKind  = "MuscleHeatmapWidget"
    static let prCelebrationKind  = "PRCelebrationWidget"
    static let programProgressKind = "ProgramProgressWidget"

    /// Refreshes all widget data from the current SwiftData context.
    func refreshAll(context: ModelContext) {
        refreshNextWorkout(context: context)
        refreshWeeklyStreak(context: context)
        refreshMuscleHeatmap(context: context)
        refreshPRCelebration(context: context)
        refreshProgramProgress(context: context)

        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Refreshes only workout-completion-relevant widgets (streak, heatmap, PR, program).
    func refreshAfterWorkout(context: ModelContext) {
        refreshWeeklyStreak(context: context)
        refreshMuscleHeatmap(context: context)
        refreshPRCelebration(context: context)
        refreshProgramProgress(context: context)

        WidgetCenter.shared.reloadTimelines(ofKind: Self.weeklyStreakKind)
        WidgetCenter.shared.reloadTimelines(ofKind: Self.muscleHeatmapKind)
        WidgetCenter.shared.reloadTimelines(ofKind: Self.prCelebrationKind)
        WidgetCenter.shared.reloadTimelines(ofKind: Self.programProgressKind)
    }

    /// Refreshes only program-related widgets (next workout, program progress).
    func refreshAfterProgramChange(context: ModelContext) {
        refreshNextWorkout(context: context)
        refreshProgramProgress(context: context)

        WidgetCenter.shared.reloadTimelines(ofKind: Self.nextWorkoutKind)
        WidgetCenter.shared.reloadTimelines(ofKind: Self.programProgressKind)
    }

    // MARK: - Next Workout

    func refreshNextWorkout(context: ModelContext) {
        let descriptor = FetchDescriptor<TrainingProgram>(
            predicate: #Predicate { $0.isActive }
        )
        let programs = (try? context.fetch(descriptor)) ?? []

        guard let program = programs.first else {
            // No active program — show generic placeholder
            let data = NextWorkoutData(
                workoutName: "No Program",
                muscleGroups: [],
                exerciseCount: 0,
                setCount: 0,
                isRestDay: true,
                programName: nil,
                updatedAt: .now
            )
            write(data, forKey: "widget.nextWorkout")
            return
        }

        // Look up the program template
        guard let template = ProgramTemplate.find(program.programTemplateID) else {
            return
        }

        let todayDay = program.todaysDayTemplate

        if let dayTemplate = todayDay {
            // Resolve exercise template IDs to muscle groups
            let exerciseLookup = Dictionary(
                uniqueKeysWithValues: ExerciseTemplate.library.map { ($0.id, $0) }
            )
            let muscles = dayTemplate.exerciseTemplateIDs
                .compactMap { exerciseLookup[$0] }
                .flatMap(\.muscles)
            let uniqueMuscles = Array(Set(muscles)).map(\.displayName).sorted()

            let data = NextWorkoutData(
                workoutName: dayTemplate.label,
                muscleGroups: uniqueMuscles,
                exerciseCount: dayTemplate.exerciseTemplateIDs.count,
                setCount: dayTemplate.numberOfSets,
                isRestDay: false,
                programName: template.name,
                updatedAt: .now
            )
            write(data, forKey: "widget.nextWorkout")
        } else {
            let data = NextWorkoutData(
                workoutName: "Rest",
                muscleGroups: [],
                exerciseCount: 0,
                setCount: 0,
                isRestDay: true,
                programName: template.name,
                updatedAt: .now
            )
            write(data, forKey: "widget.nextWorkout")
        }
    }

    // MARK: - Weekly Streak

    func refreshWeeklyStreak(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date.now

        // Get start of this week (Monday)
        var startOfWeek = now
        var interval: TimeInterval = 0
        calendar.dateInterval(of: .weekOfYear, start: &startOfWeek, interval: &interval, for: now)

        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allSessions = (try? context.fetch(descriptor)) ?? []

        // Sessions this week
        let sessionsThisWeek = allSessions.filter { $0.date >= startOfWeek }.count

        // Calculate streak: consecutive days with at least one session
        var streakDays = 0
        var checkDate = calendar.startOfDay(for: now)

        while true {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let hasSession = allSessions.contains {
                $0.date >= checkDate && $0.date < dayEnd
            }

            if hasSession {
                streakDays += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if checkDate == calendar.startOfDay(for: now) {
                // Today might not have a session yet — check yesterday
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }

        let data = WeeklyStreakData(
            sessionsThisWeek: sessionsThisWeek,
            targetSessions: 5, // Default target — could be user-configurable later
            currentStreakDays: streakDays,
            updatedAt: .now
        )
        write(data, forKey: "widget.weeklyStreak")
    }

    // MARK: - Muscle Heatmap

    func refreshMuscleHeatmap(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date.now

        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let sessions = (try? context.fetch(descriptor)) ?? []

        let analyzer = MuscleAnalyzer()
        let lastTrained = analyzer.muscleLastTrained(sessions: sessions)

        var muscleActivity: [String: Int] = [:]
        for (muscle, date) in lastTrained {
            let days = max(0, calendar.dateComponents([.day], from: date, to: now).day ?? 0)
            muscleActivity[muscle.rawValue] = days
        }

        let data = MuscleHeatmapData(
            muscleActivity: muscleActivity,
            updatedAt: .now
        )
        write(data, forKey: "widget.muscleHeatmap")
    }

    // MARK: - PR Celebration

    func refreshPRCelebration(context: ModelContext) {
        let descriptor = FetchDescriptor<SetLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allLogs = (try? context.fetch(descriptor)) ?? []

        guard !allLogs.isEmpty else { return }

        // Group logs by exercise template ID and find PRs
        var bestWeights: [String: (weight: Double, name: String, date: Date)] = [:]

        for log in allLogs {
            guard let templateID = log.exerciseTemplateID,
                  let weight = log.weight else { continue }

            if let existing = bestWeights[templateID] {
                if weight > existing.weight {
                    bestWeights[templateID] = (weight, log.exerciseName, log.date)
                }
            } else {
                bestWeights[templateID] = (weight, log.exerciseName, log.date)
            }
        }

        // Find the most recently achieved PR
        // A PR is the most recent "best weight" entry
        guard let latestPR = bestWeights.values
            .sorted(by: { $0.date > $1.date })
            .first else { return }

        // Check if this PR was achieved in the last 7 days (keep it fresh)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        guard latestPR.date >= sevenDaysAgo else {
            // Clear stale PR data
            defaults?.removeObject(forKey: "widget.prCelebration")
            return
        }

        let data = PRCelebrationData(
            exerciseName: latestPR.name,
            prType: .weight,
            displayValue: "\(Int(latestPR.weight)) lbs",
            achievedAt: latestPR.date
        )
        write(data, forKey: "widget.prCelebration")
    }

    // MARK: - Program Progress

    func refreshProgramProgress(context: ModelContext) {
        let descriptor = FetchDescriptor<TrainingProgram>(
            predicate: #Predicate { $0.isActive }
        )
        let programs = (try? context.fetch(descriptor)) ?? []

        guard let program = programs.first,
              let template = ProgramTemplate.find(program.programTemplateID) else {
            defaults?.removeObject(forKey: "widget.programProgress")
            return
        }

        let grid = program.completionGrid
        let totalDays = template.daysPerWeek * template.durationWeeks
        let completedDays = grid.flatMap { $0 }.filter { $0 }.count

        let data = ProgramProgressData(
            programName: template.name,
            currentWeek: program.currentWeek,
            totalWeeks: template.durationWeeks,
            completedDays: completedDays,
            totalDays: totalDays,
            percentage: totalDays > 0 ? Double(completedDays) / Double(totalDays) * 100 : 0,
            updatedAt: .now
        )
        write(data, forKey: "widget.programProgress")
    }

    // MARK: - Private Helpers

    private func write<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults?.set(data, forKey: key)
    }
}
