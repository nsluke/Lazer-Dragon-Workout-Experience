import SwiftUI
import SwiftData

// MARK: - Weekly Stats Card (1080×1080 square)

struct WeeklyStatsCardView: View {
    let totalSets: Int
    let totalVolume: Double    // weight × reps summed
    let sessionsCount: Int
    let topMuscle: MuscleGroup?
    let weekLabel: String      // e.g. "MAR 10 – MAR 16"

    private let cardSize: CGFloat = 1080

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.outrunBlack, Color.outrunBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 40) {
                // Header
                VStack(spacing: 8) {
                    Text("WEEKLY STATS")
                        .font(.custom("Audiowide-Regular", size: 48))
                        .foregroundColor(.outrunCyan)
                        .shadow(color: .outrunCyan.opacity(0.4), radius: 12)
                    Text(weekLabel)
                        .font(.custom("Audiowide-Regular", size: 24))
                        .foregroundColor(.white.opacity(0.4))
                }

                // Stats grid
                VStack(spacing: 24) {
                    HStack(spacing: 24) {
                        statCard(label: "SESSIONS", value: "\(sessionsCount)", color: .outrunPink)
                        statCard(label: "TOTAL SETS", value: "\(totalSets)", color: .outrunCyan)
                    }
                    HStack(spacing: 24) {
                        statCard(label: "VOLUME", value: formatVolume(totalVolume), color: .outrunYellow)
                        if let muscle = topMuscle {
                            statCard(label: "TOP MUSCLE", value: muscle.displayName.uppercased(), color: .outrunGreen)
                        } else {
                            statCard(label: "TOP MUSCLE", value: "—", color: .outrunGreen)
                        }
                    }
                }
                .padding(.horizontal, 60)

                Spacer()

                // Branding
                Text("LAZER DRAGON")
                    .font(.custom("Audiowide-Regular", size: 28))
                    .foregroundColor(.outrunPink.opacity(0.5))
            }
            .padding(.vertical, 80)
        }
        .frame(width: cardSize, height: cardSize)
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.custom("Audiowide-Regular", size: 18))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.custom("Audiowide-Regular", size: 36))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.outrunBlack.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }

    private func formatVolume(_ vol: Double) -> String {
        if vol >= 1_000_000 { return String(format: "%.1fM", vol / 1_000_000) }
        if vol >= 1_000 { return String(format: "%.0fK", vol / 1_000) }
        return "\(Int(vol))"
    }

    // MARK: - Render

    @MainActor
    static func renderImage(
        totalSets: Int,
        totalVolume: Double,
        sessionsCount: Int,
        topMuscle: MuscleGroup?,
        weekLabel: String
    ) -> UIImage? {
        let card = WeeklyStatsCardView(
            totalSets: totalSets,
            totalVolume: totalVolume,
            sessionsCount: sessionsCount,
            topMuscle: topMuscle,
            weekLabel: weekLabel
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1.0
        return renderer.uiImage
    }

    // MARK: - Compute from SetLogs

    static func computeWeeklyStats(from setLogs: [SetLog], sessions: [WorkoutSession]) -> (totalSets: Int, totalVolume: Double, sessionsCount: Int, topMuscle: MuscleGroup?, weekLabel: String) {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return (0, 0, 0, nil, "")
        }
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        // Filter logs to this week
        let weekLogs = setLogs.filter { $0.date >= weekStart && $0.date < weekEnd }
        let weekSessions = sessions.filter { $0.date >= weekStart && $0.date < weekEnd }

        let totalSets = weekLogs.count
        let totalVolume = weekLogs.reduce(0.0) { sum, log in
            sum + (log.weight ?? 0) * Double(log.reps ?? 0)
        }

        // Find most trained muscle
        var muscleCounts: [MuscleGroup: Int] = [:]
        let lookup = Dictionary(uniqueKeysWithValues: ExerciseTemplate.library.map { ($0.id, $0) })
        for log in weekLogs {
            if let tid = log.exerciseTemplateID, let template = lookup[tid] {
                for muscle in template.muscles {
                    muscleCounts[muscle, default: 0] += 1
                }
            }
        }
        let topMuscle = muscleCounts.max(by: { $0.value < $1.value })?.key

        // Week label
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let label = "\(fmt.string(from: weekStart).uppercased()) – \(fmt.string(from: calendar.date(byAdding: .day, value: 6, to: weekStart)!).uppercased())"

        return (totalSets, totalVolume, weekSessions.count, topMuscle, label)
    }
}
