import SwiftUI
import SwiftData

// MARK: - Time Range

enum AnalyticsRange: String, CaseIterable, Identifiable {
    case oneWeek  = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case all = "ALL"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .oneWeek:      return 7
        case .oneMonth:     return 30
        case .threeMonths:  return 90
        case .all:          return nil
        }
    }
}

// MARK: - Chart Data Points

struct WeeklyVolume: Identifiable {
    let id = UUID()
    let weekStart: Date
    let volume: Double
    let sets: Int
    let sessions: Int
}

struct ExercisePRPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let reps: Int
    let exerciseName: String
}

struct MuscleDistribution: Identifiable {
    let id = UUID()
    let muscle: MuscleGroup
    let sets: Int
    let percentage: Double
}

// MARK: - View Model

@Observable
@MainActor
final class AnalyticsViewModel {
    var range: AnalyticsRange = .oneMonth

    var weeklyVolumes: [WeeklyVolume] = []
    var muscleDistribution: [MuscleDistribution] = []
    var exerciseNames: [String] = []
    var selectedExerciseID: String?
    var exercisePRTimeline: [ExercisePRPoint] = []

    var totalSessions: Int = 0
    var totalVolume: Double = 0
    var totalPRs: Int = 0
    var currentStreak: Int = 0

    private let analyzer = MuscleAnalyzer()

    func refresh(sessions: [WorkoutSession], allLogs: [SetLog]) {
        let cutoff = cutoffDate
        let filtered = sessions.filter { cutoff == nil || $0.date >= cutoff! }
        let filteredLogs = allLogs.filter { cutoff == nil || $0.date >= cutoff! }

        computeStats(sessions: filtered, logs: filteredLogs)
        computeWeeklyVolumes(sessions: filtered)
        computeMuscleDistribution(logs: filteredLogs)
        computeExerciseList(logs: filteredLogs)

        if let selected = selectedExerciseID {
            computeExercisePRTimeline(exerciseTemplateID: selected, allLogs: allLogs)
        }

        computeStreak(sessions: sessions)
    }

    var cutoffDate: Date? {
        guard let days = range.days else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: .now)
    }

    // MARK: - Stats

    private func computeStats(sessions: [WorkoutSession], logs: [SetLog]) {
        totalSessions = sessions.count
        totalVolume = logs.reduce(0.0) { $0 + ($1.weight ?? 0) * Double($1.reps ?? 0) }

        // Count PRs by finding max weight per exercise template across time
        var prCount = 0
        let byExercise = Dictionary(grouping: logs.filter { $0.weight != nil }) { $0.exerciseTemplateID ?? $0.exerciseName }
        for (_, exerciseLogs) in byExercise {
            let sorted = exerciseLogs.sorted { $0.date < $1.date }
            var maxWeight: Double = 0
            for log in sorted {
                let w = log.weight ?? 0
                if w > maxWeight {
                    if maxWeight > 0 { prCount += 1 }
                    maxWeight = w
                }
            }
        }
        totalPRs = prCount
    }

    // MARK: - Weekly Volume

    private func computeWeeklyVolumes(sessions: [WorkoutSession]) {
        let calendar = Calendar.current

        var weekMap: [Date: (volume: Double, sets: Int, sessions: Int)] = [:]
        for session in sessions {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: session.date)) ?? session.date
            var entry = weekMap[weekStart] ?? (0, 0, 0)
            for log in session.setLogs ?? [] {
                entry.volume += (log.weight ?? 0) * Double(log.reps ?? 0)
                entry.sets += 1
            }
            entry.sessions += 1
            weekMap[weekStart] = entry
        }

        weeklyVolumes = weekMap
            .map { WeeklyVolume(weekStart: $0.key, volume: $0.value.volume, sets: $0.value.sets, sessions: $0.value.sessions) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    // MARK: - Muscle Distribution

    private func computeMuscleDistribution(logs: [SetLog]) {
        var counts: [MuscleGroup: Int] = [:]
        for log in logs {
            for muscle in analyzer.musclesForLog(log) {
                counts[muscle, default: 0] += 1
            }
        }
        let total = max(1, counts.values.reduce(0, +))
        muscleDistribution = counts
            .map { MuscleDistribution(muscle: $0.key, sets: $0.value, percentage: Double($0.value) / Double(total) * 100) }
            .sorted { $0.sets > $1.sets }
    }

    // MARK: - Exercise List

    private func computeExerciseList(logs: [SetLog]) {
        var seen: Set<String> = []
        var names: [(name: String, id: String)] = []
        for log in logs {
            let id = log.exerciseTemplateID ?? log.exerciseName
            if !seen.contains(id) {
                seen.insert(id)
                names.append((log.exerciseName, id))
            }
        }
        exerciseNames = names.map(\.name)
        if selectedExerciseID == nil, let first = names.first {
            selectedExerciseID = first.id
        }
    }

    // MARK: - Exercise PR Timeline

    func computeExercisePRTimeline(exerciseTemplateID: String, allLogs: [SetLog]) {
        let relevant = allLogs
            .filter { ($0.exerciseTemplateID ?? $0.exerciseName) == exerciseTemplateID && $0.weight != nil }
            .sorted { $0.date < $1.date }

        var timeline: [ExercisePRPoint] = []
        var maxWeight: Double = 0

        for log in relevant {
            let w = log.weight ?? 0
            if w >= maxWeight {
                maxWeight = w
                timeline.append(ExercisePRPoint(
                    date: log.date,
                    weight: w,
                    reps: log.reps ?? 0,
                    exerciseName: log.exerciseName
                ))
            }
        }

        exercisePRTimeline = timeline
    }

    // MARK: - Streak

    private func computeStreak(sessions: [WorkoutSession]) {
        let calendar = Calendar.current
        let sortedDays = Set(sessions.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)
        guard let mostRecent = sortedDays.first else {
            currentStreak = 0
            return
        }

        // Only count streak if most recent session was today or yesterday
        let daysSinceLast = calendar.dateComponents([.day], from: mostRecent, to: calendar.startOfDay(for: .now)).day ?? 0
        guard daysSinceLast <= 1 else {
            currentStreak = 0
            return
        }

        var streak = 1
        for i in 1..<sortedDays.count {
            let gap = calendar.dateComponents([.day], from: sortedDays[i], to: sortedDays[i - 1]).day ?? 0
            if gap <= 1 {
                streak += 1
            } else {
                break
            }
        }
        currentStreak = streak
    }

    // MARK: - Exercise Picker Helpers

    func exerciseID(forName name: String, logs: [SetLog]) -> String? {
        logs.first { $0.exerciseName == name }?.exerciseTemplateID ?? name
    }
}
