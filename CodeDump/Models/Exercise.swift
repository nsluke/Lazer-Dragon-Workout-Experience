import SwiftData
import Foundation

@Model
final class Exercise {
    var order: Int
    var name: String
    var splitLength: Int
    var reps: Int
    var workout: Workout?

    init(order: Int, name: String, splitLength: Int = 30, reps: Int = 0) {
        self.order = order
        self.name = name
        self.splitLength = splitLength
        self.reps = reps
    }
}
