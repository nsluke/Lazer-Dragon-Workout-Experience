import SwiftUI
import WidgetKit

@main
struct LDWEWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Live Activity (existing)
        WorkoutLiveActivityWidget()

        // Home Screen Widgets
        NextWorkoutWidget()
        WeeklyStreakWidget()
        MuscleHeatmapWidget()
        PRCelebrationWidget()
    }
}
