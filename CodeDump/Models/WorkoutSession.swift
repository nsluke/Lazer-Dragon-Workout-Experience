import SwiftData
import Foundation

@Model
final class WorkoutSession {
    var date: Date = Date()
    var totalElapsed: Int = 0      // seconds
    var exercisesCompleted: Int = 0
    var setsCompleted: Int = 0

    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.session)
    var setLogs: [SetLog] = []

    init(date: Date = .now, totalElapsed: Int, exercisesCompleted: Int, setsCompleted: Int) {
        self.date = date
        self.totalElapsed = totalElapsed
        self.exercisesCompleted = exercisesCompleted
        self.setsCompleted = setsCompleted
    }
}
