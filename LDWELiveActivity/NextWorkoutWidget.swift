import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct NextWorkoutProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextWorkoutEntry {
        NextWorkoutEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextWorkoutEntry) -> Void) {
        let data = WidgetStore.read(NextWorkoutData.self, forKey: WidgetStore.nextWorkoutKey)
        completion(NextWorkoutEntry(date: .now, data: data ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextWorkoutEntry>) -> Void) {
        let data = WidgetStore.read(NextWorkoutData.self, forKey: WidgetStore.nextWorkoutKey)
        let entry = NextWorkoutEntry(date: .now, data: data ?? .placeholder)

        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Entry

struct NextWorkoutEntry: TimelineEntry {
    let date: Date
    let data: NextWorkoutData
}

// MARK: - Widget

struct NextWorkoutWidget: Widget {
    let kind = "NextWorkoutWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextWorkoutProvider()) { entry in
            NextWorkoutWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    OutrunWidgetBackground()
                }
        }
        .configurationDisplayName("Next Workout")
        .description("See your next scheduled workout at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Views

struct NextWorkoutWidgetView: View {
    let entry: NextWorkoutEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        default:
            mediumView
        }
    }

    // MARK: Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let program = entry.data.programName {
                Text(program.uppercased())
                    .font(.widgetOutrun(8))
                    .foregroundColor(.widgetCyan.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            if entry.data.isRestDay {
                restDayContent
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.data.workoutName.uppercased())
                        .font(.widgetOutrun(13))
                        .foregroundColor(.widgetYellow)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text("\(entry.data.exerciseCount) exercises")
                        .font(.widgetOutrun(9))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(2)
    }

    // MARK: Medium

    private var mediumView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                if let program = entry.data.programName {
                    Text(program.uppercased())
                        .font(.widgetOutrun(9))
                        .foregroundColor(.widgetCyan.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                if entry.data.isRestDay {
                    restDayContent
                } else {
                    Text(entry.data.workoutName.uppercased())
                        .font(.widgetOutrun(16))
                        .foregroundColor(.widgetYellow)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 8) {
                        Label("\(entry.data.exerciseCount)", systemImage: "dumbbell.fill")
                        Label("\(entry.data.setCount) sets", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .font(.widgetOutrun(9))
                    .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            if !entry.data.isRestDay {
                muscleChips
            }
        }
        .padding(2)
    }

    // MARK: Components

    private var restDayContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 24))
                .foregroundColor(.widgetPurple)
                .neonGlow(.widgetPurple, radius: 8)

            Text("REST DAY")
                .font(.widgetOutrun(16))
                .foregroundColor(.widgetPurple)

            Text("Recovery time")
                .font(.widgetOutrun(9))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    private var muscleChips: some View {
        VStack(alignment: .trailing, spacing: 4) {
            ForEach(entry.data.muscleGroups.prefix(4), id: \.self) { muscle in
                Text(muscle.uppercased())
                    .font(.widgetOutrun(8))
                    .foregroundColor(.widgetCyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.widgetCyan.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    NextWorkoutWidget()
} timeline: {
    NextWorkoutEntry(date: .now, data: .placeholder)
    NextWorkoutEntry(date: .now, data: NextWorkoutData(
        workoutName: "Rest",
        muscleGroups: [],
        exerciseCount: 0,
        setCount: 0,
        isRestDay: true,
        programName: "PPL Program",
        updatedAt: .now
    ))
}

#Preview("Medium", as: .systemMedium) {
    NextWorkoutWidget()
} timeline: {
    NextWorkoutEntry(date: .now, data: .placeholder)
}
