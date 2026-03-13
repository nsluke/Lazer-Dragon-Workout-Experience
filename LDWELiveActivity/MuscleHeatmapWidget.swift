import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct MuscleHeatmapProvider: TimelineProvider {
    func placeholder(in context: Context) -> MuscleHeatmapEntry {
        MuscleHeatmapEntry(date: .now, data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MuscleHeatmapEntry) -> Void) {
        let data = WidgetStore.read(MuscleHeatmapData.self, forKey: WidgetStore.muscleHeatmapKey)
        completion(MuscleHeatmapEntry(date: .now, data: data ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MuscleHeatmapEntry>) -> Void) {
        let data = WidgetStore.read(MuscleHeatmapData.self, forKey: WidgetStore.muscleHeatmapKey)
        let entry = MuscleHeatmapEntry(date: .now, data: data ?? .placeholder)

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Entry

struct MuscleHeatmapEntry: TimelineEntry {
    let date: Date
    let data: MuscleHeatmapData
}

// MARK: - Widget

struct MuscleHeatmapWidget: Widget {
    let kind = "MuscleHeatmapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MuscleHeatmapProvider()) { entry in
            MuscleHeatmapWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    OutrunWidgetBackground()
                }
        }
        .configurationDisplayName("Muscle Map")
        .description("See which muscles need attention.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Muscle Display Item

private struct MuscleDisplayItem: Identifiable {
    let id: String
    let label: String
    let icon: String
    let heat: Double
}

// MARK: - Views

struct MuscleHeatmapWidgetView: View {
    let entry: MuscleHeatmapEntry

    private var muscles: [MuscleDisplayItem] {
        MuscleHeatmapWidgetView.allMuscles.map { info in
            MuscleDisplayItem(
                id: info.key,
                label: info.label,
                icon: info.icon,
                heat: entry.data.heatLevel(for: info.key)
            )
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("MUSCLE MAP")
                    .font(.widgetOutrun(10))
                    .foregroundColor(.widgetCyan.opacity(0.7))

                Spacer()

                HStack(spacing: 4) {
                    Circle().fill(Color.widgetRed).frame(width: 5, height: 5)
                    Text("HOT")
                        .font(.widgetOutrun(7))
                        .foregroundColor(.white.opacity(0.4))
                    Circle().fill(Color.widgetGreen).frame(width: 5, height: 5)
                    Text("FRESH")
                        .font(.widgetOutrun(7))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 5),
                spacing: 4
            ) {
                ForEach(muscles) { muscle in
                    muscleCell(muscle)
                }
            }
        }
        .padding(2)
    }

    private func muscleCell(_ muscle: MuscleDisplayItem) -> some View {
        VStack(spacing: 2) {
            Image(systemName: muscle.icon)
                .font(.system(size: 14))
                .foregroundColor(heatColor(muscle.heat))
                .neonGlow(heatColor(muscle.heat), radius: muscle.heat > 0.5 ? 4 : 0)

            Text(muscle.label.uppercased())
                .font(.widgetOutrun(6))
                .foregroundColor(heatColor(muscle.heat).opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(heatColor(muscle.heat).opacity(muscle.heat * 0.15))
        )
    }

    private func heatColor(_ heat: Double) -> Color {
        if heat >= 0.7 { return .widgetRed }
        if heat >= 0.4 { return .widgetOrange }
        if heat > 0    { return .widgetYellow }
        return .widgetGreen
    }

    // MARK: - Muscle Data

    private static let allMuscles: [(key: String, label: String, icon: String)] = [
        ("chest",      "Chest",  "figure.strengthtraining.traditional"),
        ("back",       "Back",   "figure.rowing"),
        ("shoulders",  "Delts",  "figure.boxing"),
        ("biceps",     "Bis",    "figure.arms.open"),
        ("triceps",    "Tris",   "figure.arms.open"),
        ("quads",      "Quads",  "figure.walk"),
        ("hamstrings", "Hams",   "figure.walk"),
        ("glutes",     "Glutes", "figure.step.training"),
        ("core",       "Core",   "figure.core.training"),
        ("calves",     "Calves", "figure.step.training"),
    ]
}

// MARK: - Preview

#Preview("Medium", as: .systemMedium) {
    MuscleHeatmapWidget()
} timeline: {
    MuscleHeatmapEntry(date: .now, data: .placeholder)
}
