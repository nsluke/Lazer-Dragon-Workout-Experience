import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity Widget

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen / StandBy banner
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded (long press)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.setLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(context.state.phaseTitle)
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.splitTimeRemaining.activityFormattedTime)
                        .font(.system(size: 32, weight: .thin, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(
                        value: Double(context.state.splitTimeRemaining),
                        total: Double(max(1, context.state.splitDuration))
                    )
                    .tint(.cyan)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
            } compactLeading: {
                // Compact left — phase name truncated
                Text(context.state.phaseTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.yellow)
                    .lineLimit(1)
            } compactTrailing: {
                // Compact right — countdown
                Text(context.state.splitTimeRemaining.activityFormattedTime)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.cyan)
            } minimal: {
                // Minimal (two apps competing) — just the countdown
                Text(context.state.splitTimeRemaining.activityFormattedTime)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.cyan)
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Left: workout name + set
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.workoutName.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(context.state.phaseTitle)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.yellow)
                Text(context.state.setLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Right: countdown + ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 4)
                Circle()
                    .trim(
                        from: 0,
                        to: Double(context.state.splitTimeRemaining) / Double(max(1, context.state.splitDuration))
                    )
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(context.state.splitTimeRemaining.activityFormattedTime)
                    .font(.system(size: 18, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 72, height: 72)
        }
        .padding(16)
        .background(Color(red: 13/255, green: 2/255, blue: 33/255))
    }
}

// MARK: - Helpers

private extension Int {
    var activityFormattedTime: String {
        let m = self / 60
        let s = self % 60
        return String(format: "%d:%02d", m, s)
    }
}
