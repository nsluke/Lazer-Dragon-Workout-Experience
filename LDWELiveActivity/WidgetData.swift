import Foundation

// MARK: - App Group

/// Shared App Group identifier used by the main app and widget extension.
let ldweAppGroup = "group.com.Observatory.CodeDump"

/// Convenience accessor for the shared App Group UserDefaults.
enum WidgetStore {
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: ldweAppGroup)
    }

    // MARK: - Keys

    static let nextWorkoutKey   = "widget.nextWorkout"
    static let weeklyStreakKey  = "widget.weeklyStreak"
    static let muscleHeatmapKey = "widget.muscleHeatmap"
    static let prCelebrationKey = "widget.prCelebration"

    // MARK: - Read Helpers

    static func read<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func write<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults?.set(data, forKey: key)
    }
}

// MARK: - Next Workout Data

struct NextWorkoutData: Codable {
    let workoutName: String
    let muscleGroups: [String]
    let exerciseCount: Int
    let setCount: Int
    let isRestDay: Bool
    let programName: String?
    let updatedAt: Date

    static let placeholder = NextWorkoutData(
        workoutName: "Upper Body Blast",
        muscleGroups: ["Chest", "Shoulders", "Triceps"],
        exerciseCount: 5,
        setCount: 4,
        isRestDay: false,
        programName: "PPL Program",
        updatedAt: .now
    )
}

// MARK: - Weekly Streak Data

struct WeeklyStreakData: Codable {
    let sessionsThisWeek: Int
    let targetSessions: Int
    let currentStreakDays: Int
    let updatedAt: Date

    var progress: Double {
        guard targetSessions > 0 else { return 0 }
        return min(1.0, Double(sessionsThisWeek) / Double(targetSessions))
    }

    static let placeholder = WeeklyStreakData(
        sessionsThisWeek: 3,
        targetSessions: 5,
        currentStreakDays: 7,
        updatedAt: .now
    )
}

// MARK: - Muscle Heatmap Data

struct MuscleHeatmapData: Codable {
    /// Maps muscle group raw values to days since last trained.
    /// Lower = more recently trained = "hotter".
    /// Missing key = never trained.
    let muscleActivity: [String: Int]
    let updatedAt: Date

    /// Returns a heat level (0.0–1.0) where 1.0 = trained today, 0.0 = 7+ days ago.
    func heatLevel(for muscle: String) -> Double {
        guard let days = muscleActivity[muscle] else { return 0 }
        return max(0, 1.0 - Double(days) / 7.0)
    }

    static let placeholder = MuscleHeatmapData(
        muscleActivity: [
            "chest": 1, "back": 3, "shoulders": 2,
            "biceps": 3, "triceps": 1, "quads": 5,
            "hamstrings": 5, "glutes": 4, "core": 2
        ],
        updatedAt: .now
    )
}

// MARK: - PR Celebration Data

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

    static let placeholder = PRCelebrationData(
        exerciseName: "Bench Press",
        prType: .weight,
        displayValue: "185 lbs",
        achievedAt: .now
    )
}
