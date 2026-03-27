import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct ProgramProgressProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgramProgressEntry {
        ProgramProgressEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgramProgressEntry) -> Void) {
        let data = WidgetStore.read(ProgramProgressData.self, forKey: WidgetStore.programProgressKey)
        completion(ProgramProgressEntry(date: .now, data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgramProgressEntry>) -> Void) {
        let data = WidgetStore.read(ProgramProgressData.self, forKey: WidgetStore.programProgressKey)
        let entry = ProgramProgressEntry(date: .now, data: data)

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Entry

struct ProgramProgressEntry: TimelineEntry {
    let date: Date
    let data: ProgramProgressData?
}

// MARK: - Widget

struct ProgramProgressWidget: Widget {
    let kind = "ProgramProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgramProgressProvider()) { entry in
            ProgramProgressWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    OutrunWidgetBackground()
                }
        }
        .configurationDisplayName("Program Progress")
        .description("Track your training program completion.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Views

struct ProgramProgressWidgetView: View {
    let entry: ProgramProgressEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let data = entry.data {
            switch family {
            case .systemSmall:
                smallView(data)
            default:
                mediumView(data)
            }
        } else {
            noProgramView
        }
    }

    // MARK: No Program

    private var noProgramView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 28))
                .foregroundColor(.widgetCyan.opacity(0.5))

            Text("NO PROGRAM")
                .font(.widgetOutrun(11))
                .foregroundColor(.white.opacity(0.4))

            Text("Enroll to track progress")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Small

    private func smallView(_ data: ProgramProgressData) -> some View {
        VStack(spacing: 8) {
            progressRing(data: data, size: 72, lineWidth: 6)

            Text("WEEK \(data.currentWeek)/\(data.totalWeeks)")
                .font(.widgetOutrun(9))
                .foregroundColor(.widgetCyan.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(2)
    }

    // MARK: Medium

    private func mediumView(_ data: ProgramProgressData) -> some View {
        HStack(spacing: 20) {
            progressRing(data: data, size: 90, lineWidth: 7)

            VStack(alignment: .leading, spacing: 8) {
                Text(data.programName.uppercased())
                    .font(.widgetOutrun(12))
                    .foregroundColor(.widgetYellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("WEEK \(data.currentWeek) OF \(data.totalWeeks)")
                    .font(.widgetOutrun(10))
                    .foregroundColor(.widgetCyan.opacity(0.7))

                Text("\(data.completedDays)/\(data.totalDays) DAYS")
                    .font(.widgetOutrun(10))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()
            }

            Spacer()
        }
        .padding(2)
    }

    // MARK: Progress Ring

    private func progressRing(data: ProgramProgressData, size: CGFloat, lineWidth: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.widgetSurface, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: data.progress)
                .stroke(
                    AngularGradient(
                        colors: [progressColor(data).opacity(0.5), progressColor(data)],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * data.progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .neonGlow(progressColor(data), radius: 4)

            VStack(spacing: 0) {
                Text("\(Int(data.percentage))%")
                    .font(.widgetOutrun(size * 0.22))
                    .foregroundColor(progressColor(data))
            }
        }
        .frame(width: size, height: size)
    }

    private func progressColor(_ data: ProgramProgressData) -> Color {
        if data.progress >= 0.75 { return .widgetGreen }
        if data.progress >= 0.5  { return .widgetCyan }
        if data.progress >= 0.25 { return .widgetYellow }
        return .widgetOrange
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    ProgramProgressWidget()
} timeline: {
    ProgramProgressEntry(date: .now, data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    ProgramProgressWidget()
} timeline: {
    ProgramProgressEntry(date: .now, data: .placeholder)
}

#Preview("No Program", as: .systemSmall) {
    ProgramProgressWidget()
} timeline: {
    ProgramProgressEntry(date: .now, data: nil)
}
