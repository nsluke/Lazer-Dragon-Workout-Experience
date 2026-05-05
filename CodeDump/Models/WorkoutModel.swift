import SwiftData
import Foundation

// MARK: - WorkoutType

enum WorkoutType: String, CaseIterable, Codable {
    case hiit     = "HIIT"
    case run      = "Run"
    case cycling  = "Cycling"
    case yoga     = "Yoga"
    case strength = "Strength"
    case custom   = "Custom"

    var usesGPS: Bool {
        self == .run || self == .cycling
    }
}

// MARK: - Workout

@Model
final class Workout {
    var name: String = ""
    var type: String = WorkoutType.custom.rawValue
    var warmupLength: Int = 0
    var intervalLength: Int = 30
    var restLength: Int = 15
    var numberOfIntervals: Int = 5
    var numberOfSets: Int = 1
    var restBetweenSetLength: Int = 60
    var cooldownLength: Int = 0
    var createdAt: Date = Date()

    // CloudKit requires to-many relationships to be optional.
    @Relationship(deleteRule: .cascade, inverse: \Exercise.workout)
    var exercises: [Exercise]? = []

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.workout)
    var sessions: [WorkoutSession]? = []

    init(
        name: String,
        type: WorkoutType = .custom,
        warmupLength: Int = 0,
        intervalLength: Int = 30,
        restLength: Int = 15,
        numberOfIntervals: Int = 5,
        numberOfSets: Int = 1,
        restBetweenSetLength: Int = 60,
        cooldownLength: Int = 0
    ) {
        self.name = name
        self.type = type.rawValue
        self.warmupLength = warmupLength
        self.intervalLength = intervalLength
        self.restLength = restLength
        self.numberOfIntervals = numberOfIntervals
        self.numberOfSets = numberOfSets
        self.restBetweenSetLength = restBetweenSetLength
        self.cooldownLength = cooldownLength
        self.createdAt = Date()
    }

    var workoutType: WorkoutType {
        WorkoutType(rawValue: type) ?? .custom
    }

    var sortedExercises: [Exercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }

    var exerciseCount: Int { exercises?.count ?? 0 }
    var sessionCount: Int { sessions?.count ?? 0 }

    var totalDurationEstimate: Int {
        let warmup = warmupLength
        let intervalPerSet = intervalLength * numberOfIntervals
        let restPerSet = restLength * max(0, numberOfIntervals - 1)
        let sets = (intervalPerSet + restPerSet) * numberOfSets
        let setBetween = restBetweenSetLength * max(0, numberOfSets - 1)
        let cooldown = cooldownLength
        return warmup + sets + setBetween + cooldown
    }
}
