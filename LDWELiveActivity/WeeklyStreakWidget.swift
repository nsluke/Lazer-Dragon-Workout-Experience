import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct WeeklyStreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeeklyStreakEntry {
        WeeklyStreakEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeeklyStreakEntry) -> Void) {
        let data = WidgetStore.read(WeeklyStreakData.self, forKey: WidgetStore.weeklyStreakKey)
        completion(WeeklyStreakEntry(date: .now, data: data ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklyStreakEntry>) -> Void) {
        let data = WidgetStore.read(WeeklyStreakData.self, forKey: WidgetStore.weeklyStreakKey)
        let entry = WeeklyStreakEntry(date: .now, data: data ?? .placeholder)

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Entry

struct WeeklyStreakEntry: TimelineEntry {
    let date: Date
    let data: WeeklyStreakData
}

// MARK: - Widget

struct WeeklyStreakWidget: Widget {
    let kind = "WeeklyStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyStreakProvider()) { entry in
            WeeklyStreakWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    OutrunWidgetBackground()
                }
        }
        .configurationDisplayName("Weekly Streak")
        .description("Track your workout sessions this week.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Views

struct WeeklyStreakWidgetView: View {
    let entry: WeeklyStreakEntry

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
        VStack(spacing: 8) {
            progressRing(size: 72, lineWidth: 6)

            if entry.data.currentStreakDays > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.widgetOrange)
                    Text("\(entry.data.currentStreakDays)d")
                        .font(.widgetOutrun(9))
                        .foregroundColor(.widgetOrange)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(2)
    }

    // MARK: Medium

    private var mediumView: some View {
        HStack(spacing: 20) {
            progressRing(size: 90, lineWidth: 7)

            VStack(alignment: .leading, spacing: 8) {
                Text("THIS WEEK")
                    .font(.widgetOutrun(10))
                    .foregroundColor(.widgetCyan.opacity(0.7))

                Text("\(entry.data.sessionsThisWeek) of \(entry.data.targetSessions)")
                    .font(.widgetOutrun(22))
                    .foregroundColor(.widgetYellow)
                    .minimumScaleFactor(0.7)

                Text("SESSIONS")
                    .font(.widgetOutrun(10))
                    .foregroundColor(.white.opacity(0.5))

                if entry.data.currentStreakDays > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.widgetOrange)
                        Text("\(entry.data.currentStreakDays) day streak")
                            .foregroundColor(.widgetOrange)
                    }
                    .font(.widgetOutrun(10))
                    .neonGlow(.widgetOrange, radius: 4)
                }

                Spacer()
            }

            Spacer()
        }
        .padding(2)
    }

    // MARK: Progress Ring

    private func progressRing(size: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.widgetSurface, lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: entry.data.progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .neonGlow(progressColor, radius: 4)

            // Center text
            VStack(spacing: 0) {
                Text("\(entry.data.sessionsThisWeek)")
                    .font(.widgetOutrun(size * 0.28))
                    .foregroundColor(progressColor)

                Text("/\(entry.data.targetSessions)")
                    .font(.widgetOutrun(size * 0.14))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(width: size, height: size)
    }

    private var progressColor: Color {
        if entry.data.progress >= 1.0 { return .widgetGreen }
        if entry.data.progress >= 0.6 { return .widgetCyan }
        if entry.data.progress >= 0.3 { return .widgetYellow }
        return .widgetRed
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: [progressColor.opacity(0.5), progressColor],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360 * entry.data.progress)
        )
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    WeeklyStreakWidget()
} timeline: {
    WeeklyStreakEntry(date: .now, data: .placeholder)
    WeeklyStreakEntry(date: .now, data: WeeklyStreakData(
        sessionsThisWeek: 5,
        targetSessions: 5,
        currentStreakDays: 14,
        updatedAt: .now
    ))
}

#Preview("Medium", as: .systemMedium) {
    WeeklyStreakWidget()
} timeline: {
    WeeklyStreakEntry(date: .now, data: .placeholder)
}
