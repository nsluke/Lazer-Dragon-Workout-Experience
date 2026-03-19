import SwiftData
import Foundation

@Model
final class SetLog {
    var exerciseName: String = ""
    var exerciseTemplateID: String?
    var setIndex: Int = 0
    var exerciseIndex: Int = 0
    var weight: Double?
    var reps: Int?
    var rpe: Int?
    var duration: Int?
    var date: Date = Date()

    var session: WorkoutSession?

    init(
        exerciseName: String,
        exerciseTemplateID: String? = nil,
        setIndex: Int,
        exerciseIndex: Int,
        weight: Double? = nil,
        reps: Int? = nil,
        rpe: Int? = nil,
        duration: Int? = nil
    ) {
        self.exerciseName = exerciseName
        self.exerciseTemplateID = exerciseTemplateID
        self.setIndex = setIndex
        self.exerciseIndex = exerciseIndex
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.duration = duration
        self.date = Date()
    }
}
