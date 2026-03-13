import Foundation

// MARK: - Muscle Analyzer

/// Pure-logic engine that computes muscle freshness scores, volume tracking,
/// and progression detection from workout history. No UI, Foundation-only.
struct MuscleAnalyzer {

    /// Lookup from exercise template ID → muscle groups.
    /// Built once from ExerciseTemplate.library + any custom templates.
    let templateLookup: [String: [MuscleGroup]]

    // MARK: - Init

    /// Build the analyzer with a pre-computed template lookup.
    /// Call `MuscleAnalyzer.buildLookup(customTemplates:)` to create one.
    init(templateLookup: [String: [MuscleGroup]] = MuscleAnalyzer.defaultLookup()) {
        self.templateLookup = templateLookup
    }

    /// Builds a lookup dictionary from the built-in library.
    static func defaultLookup() -> [String: [MuscleGroup]] {
        var lookup: [String: [MuscleGroup]] = [:]
        for template in ExerciseTemplate.library {
            lookup[template.id] = template.muscles
        }
        return lookup
    }

    /// Builds a lookup dictionary including custom templates.
    static func buildLookup(customMuscles: [String: [MuscleGroup]] = [:]) -> [String: [MuscleGroup]] {
        var lookup = defaultLookup()
        for (id, muscles) in customMuscles {
            lookup[id] = muscles
        }
        return lookup
    }

    // MARK: - Muscle Last Trained

    /// Returns the most recent date each muscle group was trained.
    func muscleLastTrained(sessions: [WorkoutSession]) -> [MuscleGroup: Date] {
        var lastTrained: [MuscleGroup: Date] = [:]

        for session in sessions {
            for log in session.setLogs {
                let muscles = resolveMuscles(for: log)
                for muscle in muscles {
                    if let existing = lastTrained[muscle] {
                        if session.date > existing {
                            lastTrained[muscle] = session.date
                        }
                    } else {
                        lastTrained[muscle] = session.date
                    }
                }
            }
        }

        return lastTrained
    }

    // MARK: - Volume in Window

    /// Counts total sets per muscle group within a trailing window of `days`.
    func muscleSetsInWindow(sessions: [WorkoutSession], days: Int = 7) -> [MuscleGroup: Int] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
        var counts: [MuscleGroup: Int] = [:]

        for session in sessions where session.date >= cutoff {
            for log in session.setLogs {
                let muscles = resolveMuscles(for: log)
                for muscle in muscles {
                    counts[muscle, default: 0] += 1
                }
            }
        }

        return counts
    }

    // MARK: - Freshness Score

    /// Returns all muscle groups sorted by freshness (highest score = most fresh = train next).
    ///
    /// Algorithm:
    /// ```
    /// freshnessScore = daysSinceLastTrained × (1.0 / volumeFactor)
    /// volumeFactor   = clamp(setsInLast7Days / 6.0, 0.5, 1.5)
    /// Never trained  → score = 1000
    /// ```
    func muscleFreshness(sessions: [WorkoutSession]) -> [(muscle: MuscleGroup, score: Double)] {
        let lastTrained = muscleLastTrained(sessions: sessions)
        let volume = muscleSetsInWindow(sessions: sessions, days: 7)
        let now = Date.now

        var results: [(MuscleGroup, Double)] = []

        for muscle in MuscleGroup.allCases {
            guard let trainedDate = lastTrained[muscle] else {
                // Never trained — highest priority
                results.append((muscle, 1000.0))
                continue
            }

            let daysSince = max(1, Calendar.current.dateComponents([.day], from: trainedDate, to: now).day ?? 1)
            let sets = Double(volume[muscle] ?? 0)
            let volumeFactor = min(1.5, max(0.5, sets / 6.0))
            let score = Double(daysSince) * (1.0 / volumeFactor)
            results.append((muscle, score))
        }

        return results.sorted { $0.1 > $1.1 }
    }

    // MARK: - Consecutive Progression Weeks

    /// Counts how many consecutive calendar weeks the user has increased weight
    /// or reps for a given exercise. Used for deload detection.
    /// Returns 0 if fewer than 2 weeks of data.
    func consecutiveProgressionWeeks(exerciseTemplateID: String, logs: [SetLog]) -> Int {
        // Filter to this exercise, with weight data, sorted by date ascending
        let relevant = logs
            .filter { $0.exerciseTemplateID == exerciseTemplateID && $0.weight != nil }
            .sorted { $0.date < $1.date }

        guard relevant.count >= 2 else { return 0 }

        // Group by calendar week (year + weekOfYear)
        let calendar = Calendar.current
        var weeklyBests: [(week: Int, year: Int, weight: Double, reps: Int)] = []
        var groupedByWeek: [String: [SetLog]] = [:]

        for log in relevant {
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
            let key = "\(components.yearForWeekOfYear ?? 0)-\(components.weekOfYear ?? 0)"
            groupedByWeek[key, default: []].append(log)
        }

        // For each week, take the best set (highest weight, then highest reps)
        for (_, weekLogs) in groupedByWeek {
            guard let best = weekLogs.max(by: { a, b in
                let wa = a.weight ?? 0
                let wb = b.weight ?? 0
                if wa != wb { return wa < wb }
                return (a.reps ?? 0) < (b.reps ?? 0)
            }) else { continue }

            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: best.date)
            weeklyBests.append((
                week: components.weekOfYear ?? 0,
                year: components.yearForWeekOfYear ?? 0,
                weight: best.weight ?? 0,
                reps: best.reps ?? 0
            ))
        }

        // Sort by year then week
        weeklyBests.sort {
            if $0.year != $1.year { return $0.year < $1.year }
            return $0.week < $1.week
        }

        guard weeklyBests.count >= 2 else { return 0 }

        // Count consecutive weeks of progression from most recent backward
        var streak = 0
        for i in stride(from: weeklyBests.count - 1, through: 1, by: -1) {
            let current = weeklyBests[i]
            let previous = weeklyBests[i - 1]

            let progressed = current.weight > previous.weight
                || (current.weight == previous.weight && current.reps > previous.reps)

            if progressed {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Last Performance

    /// Returns the most recent weight and reps for a given exercise template,
    /// excluding logs from today (current session). Returns nil if no history.
    func lastPerformance(
        exerciseTemplateID: String,
        setIndex: Int? = nil,
        allLogs: [SetLog]
    ) -> (weight: Double, reps: Int, rpe: Int?)? {
        let startOfToday = Calendar.current.startOfDay(for: .now)

        let matching = allLogs
            .filter { log in
                log.exerciseTemplateID == exerciseTemplateID
                && log.weight != nil
                && log.date < startOfToday
            }
            .sorted { $0.date > $1.date }

        // Prefer same set index, but fall back to any recent set
        if let setIdx = setIndex,
           let match = matching.first(where: { $0.setIndex == setIdx }) {
            return (match.weight!, match.reps ?? 0, match.rpe)
        }

        guard let best = matching.first else { return nil }
        return (best.weight!, best.reps ?? 0, best.rpe)
    }

    // MARK: - Public Accessors

    /// Returns the muscle groups trained by a given SetLog.
    func musclesForLog(_ log: SetLog) -> [MuscleGroup] {
        resolveMuscles(for: log)
    }

    // MARK: - Private Helpers

    /// Resolves the muscle groups for a SetLog by looking up its template ID.
    private func resolveMuscles(for log: SetLog) -> [MuscleGroup] {
        if let id = log.exerciseTemplateID, let muscles = templateLookup[id] {
            return muscles
        }
        // Fallback: try fuzzy match by name
        if let template = ExerciseTemplate.library.first(where: {
            $0.name.localizedCaseInsensitiveCompare(log.exerciseName) == .orderedSame
        }) {
            return template.muscles
        }
        return []
    }
}
