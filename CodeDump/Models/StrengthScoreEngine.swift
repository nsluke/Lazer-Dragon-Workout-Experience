import Foundation

// MARK: - Strength Score Engine

/// Pure-logic engine that computes a single trending fitness number from
/// existing workout history. Mirrors the shape of MuscleAnalyzer and
/// RecoveryAnalyzer — Foundation-only, no UI, deterministic output for a
/// given input.
///
/// The score blends three components evaluated over a trailing window:
/// - **Strength**: sum of the user's best estimated-1RM (Epley) per unique
///   exercise template they trained.
/// - **Volume**: total weight × reps performed.
/// - **Frequency**: number of distinct workout sessions completed.
///
/// The total is `strength + volume/50 + frequency*100`, which lands a
/// regularly training intermediate lifter in the ~2,000-5,000 range and
/// keeps the components on similar order of magnitude. The score is
/// intentionally not normalized to 0-100 — it's meant to grow as the user
/// grows, the way Fitbod's Fitness Level does.
struct StrengthScoreEngine {

    static let windowDays = 28

    // MARK: - Public types

    struct StrengthScore: Equatable {
        let total: Int
        let strengthComponent: Double
        let volumeComponent: Double
        let frequencyComponent: Int
        let computedAt: Date
        let trend: ScoreTrend

        var hasData: Bool { strengthComponent > 0 || volumeComponent > 0 || frequencyComponent > 0 }
    }

    enum ScoreTrend: Equatable {
        case up(delta: Int)
        case down(delta: Int)
        case flat
        case unknown

        var deltaText: String? {
            switch self {
            case .up(let d):   return "▲ +\(d)"
            case .down(let d): return "▼ -\(d)"
            case .flat:        return "→ 0"
            case .unknown:     return nil
            }
        }
    }

    struct TrendPoint: Identifiable, Equatable {
        let date: Date
        let score: Int
        var id: Date { date }
    }

    // MARK: - Score (current)

    /// Computes the strength score over the trailing `windowDays` ending at
    /// `asOf`, plus a delta versus the prior equally-sized window.
    static func score(
        sessions: [WorkoutSession],
        setLogs: [SetLog],
        asOf: Date = .now
    ) -> StrengthScore {
        let current = rawScore(sessions: sessions, setLogs: setLogs, endingAt: asOf)
        let previous = rawScore(
            sessions: sessions,
            setLogs: setLogs,
            endingAt: Calendar.current.date(byAdding: .day, value: -windowDays, to: asOf) ?? asOf
        )

        let trend: ScoreTrend
        if previous.total == 0 && current.total == 0 {
            trend = .unknown
        } else if previous.total == 0 {
            trend = .up(delta: current.total)
        } else {
            let delta = current.total - previous.total
            switch delta {
            case 0:                      trend = .flat
            case ..<0:                   trend = .down(delta: -delta)
            default:                     trend = .up(delta: delta)
            }
        }

        return StrengthScore(
            total: current.total,
            strengthComponent: current.strength,
            volumeComponent: current.volume,
            frequencyComponent: current.frequency,
            computedAt: asOf,
            trend: trend
        )
    }

    // MARK: - Trend (historical)

    /// Returns one TrendPoint per week for the last `weeks` weeks, oldest
    /// first. Each point's score reflects the trailing-window calculation
    /// as of that week's end, so the curve is smooth rather than jagged.
    static func trend(
        sessions: [WorkoutSession],
        setLogs: [SetLog],
        asOf: Date = .now,
        weeks: Int = 12
    ) -> [TrendPoint] {
        guard weeks > 0 else { return [] }
        let calendar = Calendar.current
        var points: [TrendPoint] = []

        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let endDate = calendar.date(byAdding: .day, value: -offset * 7, to: asOf) else { continue }
            let raw = rawScore(sessions: sessions, setLogs: setLogs, endingAt: endDate)
            points.append(TrendPoint(date: endDate, score: raw.total))
        }

        return points
    }

    // MARK: - Internals

    private struct Raw {
        let total: Int
        let strength: Double
        let volume: Double
        let frequency: Int
    }

    private static func rawScore(
        sessions: [WorkoutSession],
        setLogs: [SetLog],
        endingAt: Date
    ) -> Raw {
        guard let windowStart = Calendar.current.date(byAdding: .day, value: -windowDays, to: endingAt) else {
            return Raw(total: 0, strength: 0, volume: 0, frequency: 0)
        }

        let frequency = sessions.filter { $0.date > windowStart && $0.date <= endingAt }.count

        let logsInWindow = setLogs.filter { $0.date > windowStart && $0.date <= endingAt && ($0.weight ?? 0) > 0 }

        var volume: Double = 0
        var bestE1RMByKey: [String: Double] = [:]

        for log in logsInWindow {
            let w = log.weight ?? 0
            let r = log.reps ?? 0
            volume += w * Double(r)

            let key = log.exerciseTemplateID ?? log.exerciseName
            guard !key.isEmpty else { continue }
            // Epley formula, identical to ExerciseProgressChartView's metric.
            let e1RM = r > 0 ? w * (1 + Double(r) / 30.0) : w
            if e1RM > (bestE1RMByKey[key] ?? 0) {
                bestE1RMByKey[key] = e1RM
            }
        }

        let strength = bestE1RMByKey.values.reduce(0, +)
        let total = Int(strength.rounded()) + Int((volume / 50).rounded()) + (frequency * 100)

        return Raw(total: total, strength: strength, volume: volume, frequency: frequency)
    }
}
