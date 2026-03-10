import ActivityKit
import Foundation

/// Shared between the app target and the Live Activity widget extension.
/// Add this file to BOTH targets in Xcode.
struct WorkoutActivityAttributes: ActivityAttributes {

    /// Static data — set once when the activity starts, never changes.
    struct ContentState: Codable, Hashable {
        var phaseTitle: String       // "BURPEE", "REST", "WARMUP" …
        var setLabel: String         // "SET 2 / 3"
        var splitTimeRemaining: Int  // seconds
        var splitDuration: Int       // seconds (for progress ring)
        var totalElapsed: Int        // seconds
        var isRunning: Bool
    }

    var workoutName: String
}
