import ActivityKit
import Foundation

/// Manages the lifecycle of the workout Live Activity.
/// Called from WorkoutSessionViewModel on the MainActor.
@MainActor
final class LiveActivityManager {

    private var activity: Activity<WorkoutActivityAttributes>?

    // MARK: - Start

    func start(workoutName: String, state: WorkoutActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = WorkoutActivityAttributes(workoutName: workoutName)
        let content = ActivityContent(state: state, staleDate: nil)

        activity = try? Activity.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    // MARK: - Update

    func update(state: WorkoutActivityAttributes.ContentState) {
        guard let activity else { return }
        let content = ActivityContent(state: state, staleDate: nil)
        Task { await activity.update(content) }
    }

    // MARK: - End

    func end(finalState: WorkoutActivityAttributes.ContentState) {
        guard let activity else { return }
        let content = ActivityContent(state: finalState, staleDate: nil)
        Task { await activity.end(content, dismissalPolicy: .after(.now + 4)) }
        self.activity = nil
    }
}
