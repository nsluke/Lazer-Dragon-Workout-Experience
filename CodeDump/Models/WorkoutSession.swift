import SwiftData
import Foundation

@Model
final class WorkoutSession {
    var date: Date
    var totalElapsed: Int      // seconds
    var exercisesCompleted: Int
    var setsCompleted: Int

    var workout: Workout?

    init(date: Date = .now, totalElapsed: Int, exercisesCompleted: Int, setsCompleted: Int) {
        self.date = date
        self.totalElapsed = totalElapsed
        self.exercisesCompleted = exercisesCompleted
        self.setsCompleted = setsCompleted
    }
}
