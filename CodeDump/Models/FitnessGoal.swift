import SwiftData
import Foundation

// MARK: - Goal Type

enum GoalType: String, CaseIterable, Codable, Identifiable {
    case weightTarget
    case repTarget
    case volumeTarget
    case frequencyTarget
    case bodyWeight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weightTarget:    return "Weight Target"
        case .repTarget:       return "Rep Target"
        case .volumeTarget:    return "Volume Target"
        case .frequencyTarget: return "Frequency Target"
        case .bodyWeight:      return "Body Weight"
        }
    }

    var icon: String {
        switch self {
        case .weightTarget:    return "scalemass.fill"
        case .repTarget:       return "repeat"
        case .volumeTarget:    return "chart.bar.fill"
        case .frequencyTarget: return "calendar.badge.clock"
        case .bodyWeight:      return "figure.stand"
        }
    }

    var unit: String {
        switch self {
        case .weightTarget:    return "lbs"
        case .repTarget:       return "reps"
        case .volumeTarget:    return "lbs"
        case .frequencyTarget: return "/week"
        case .bodyWeight:      return "lbs"
        }
    }

    /// Whether this goal type can auto-track from SetLog history.
    var isAutoTracked: Bool {
        switch self {
        case .weightTarget, .repTarget, .volumeTarget, .frequencyTarget: return true
        case .bodyWeight: return false
        }
    }

    /// Whether this goal needs an exercise selection.
    var needsExercise: Bool {
        switch self {
        case .weightTarget, .repTarget: return true
        default: return false
        }
    }
}

// MARK: - Fitness Goal

@Model
final class FitnessGoal {
    var id: String = UUID().uuidString
    var title: String = ""
    var goalTypeRaw: String = GoalType.weightTarget.rawValue
    var targetValue: Double = 0
    var currentValue: Double = 0
    var exerciseTemplateID: String?
    var deadline: Date?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?

    init(
        title: String,
        type: GoalType,
        targetValue: Double,
        currentValue: Double = 0,
        exerciseTemplateID: String? = nil,
        deadline: Date? = nil
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.goalTypeRaw = type.rawValue
        self.targetValue = targetValue
        self.currentValue = currentValue
        self.exerciseTemplateID = exerciseTemplateID
        self.deadline = deadline
        self.isCompleted = false
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    var goalType: GoalType {
        get { GoalType(rawValue: goalTypeRaw) ?? .weightTarget }
        set { goalTypeRaw = newValue.rawValue }
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, currentValue / targetValue)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var isOverdue: Bool {
        guard let deadline, !isCompleted else { return false }
        return deadline < Date.now
    }

    var daysRemaining: Int? {
        guard let deadline, !isCompleted else { return nil }
        return max(0, Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? 0)
    }

    var exerciseName: String? {
        guard let tid = exerciseTemplateID else { return nil }
        return ExerciseTemplate.library.first(where: { $0.id == tid })?.name
    }

    // MARK: - Auto-tracking

    /// Updates currentValue from workout history. Call periodically on active goals.
    func autoUpdate(sessions: [WorkoutSession], setLogs: [SetLog]) {
        switch goalType {
        case .weightTarget:
            guard let tid = exerciseTemplateID else { return }
            let best = setLogs
                .filter { $0.exerciseTemplateID == tid && $0.weight != nil }
                .compactMap(\.weight)
                .max()
            if let w = best { currentValue = w }

        case .repTarget:
            guard let tid = exerciseTemplateID else { return }
            let best = setLogs
                .filter { $0.exerciseTemplateID == tid && $0.reps != nil }
                .compactMap(\.reps)
                .max()
            if let r = best { currentValue = Double(r) }

        case .volumeTarget:
            let calendar = Calendar.current
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return }
            var volume: Double = 0
            for log in setLogs where log.date >= weekInterval.start && log.date < weekInterval.end {
                let w: Double = log.weight ?? 0
                let r: Double = Double(log.reps ?? 0)
                volume += w * r
            }
            currentValue = volume

        case .frequencyTarget:
            let calendar = Calendar.current
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return }
            let count = sessions.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }.count
            currentValue = Double(count)

        case .bodyWeight:
            break // Manual only
        }

        // Auto-complete
        if currentValue >= targetValue && !isCompleted {
            isCompleted = true
            completedAt = Date()
        }
    }
}
