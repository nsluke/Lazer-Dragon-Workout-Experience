import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct PRCelebrationProvider: TimelineProvider {
    func placeholder(in context: Context) -> PRCelebrationEntry {
        PRCelebrationEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PRCelebrationEntry) -> Void) {
        let data = WidgetStore.read(PRCelebrationData.self, forKey: WidgetStore.prCelebrationKey)
        completion(PRCelebrationEntry(date: .now, data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PRCelebrationEntry>) -> Void) {
        let data = WidgetStore.read(PRCelebrationData.self, forKey: WidgetStore.prCelebrationKey)
        let entry = PRCelebrationEntry(date: .now, data: data)

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Entry

struct PRCelebrationEntry: TimelineEntry {
    let date: Date
    let data: PRCelebrationData?
}

// MARK: - Widget

struct PRCelebrationWidget: Widget {
    let kind = "PRCelebrationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PRCelebrationProvider()) { entry in
            PRCelebrationWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    OutrunWidgetBackground()
                }
        }
        .configurationDisplayName("PR Celebration")
        .description("Celebrate your latest personal record.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Views

struct PRCelebrationWidgetView: View {
    let entry: PRCelebrationEntry

    var body: some View {
        if let pr = entry.data {
            prContent(pr)
        } else {
            emptyState
        }
    }

    // MARK: PR Content

    private func prContent(_ pr: PRCelebrationData) -> some View {
        VStack(spacing: 6) {
            // Trophy
            ZStack {
                Circle()
                    .fill(Color.widgetYellow.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.widgetYellow)
                    .neonGlow(.widgetYellow, radius: 8)
            }

            Text("NEW PR!")
                .font(.widgetOutrun(11))
                .foregroundColor(.widgetPink)
                .neonGlow(.widgetPink, radius: 4)

            Text(pr.exerciseName.uppercased())
                .font(.widgetOutrun(10))
                .foregroundColor(.widgetYellow)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            Text(pr.displayValue)
                .font(.widgetOutrun(14))
                .foregroundColor(.white)
                .neonGlow(.widgetCyan, radius: 4)

            Text(pr.achievedAt.prRelativeString)
                .font(.widgetOutrun(7))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(2)
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "trophy")
                .font(.system(size: 28))
                .foregroundColor(.widgetSurface)

            Text("NO PR YET")
                .font(.widgetOutrun(10))
                .foregroundColor(.white.opacity(0.3))

            Text("Hit the gym!")
                .font(.widgetOutrun(8))
                .foregroundColor(.white.opacity(0.2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Date Formatting Helper

private extension Date {
    var prRelativeString: String {
        let calendar = Calendar.current
        let now = Date.now
        let components = calendar.dateComponents([.day], from: self, to: now)
        let days = components.day ?? 0

        if days == 0 { return "TODAY" }
        if days == 1 { return "YESTERDAY" }
        if days < 7  { return "\(days) DAYS AGO" }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self).uppercased()
    }
}

// MARK: - Preview

#Preview("Small - With PR", as: .systemSmall) {
    PRCelebrationWidget()
} timeline: {
    PRCelebrationEntry(date: .now, data: .placeholder)
}

#Preview("Small - Empty", as: .systemSmall) {
    PRCelebrationWidget()
} timeline: {
    PRCelebrationEntry(date: .now, data: nil)
}
