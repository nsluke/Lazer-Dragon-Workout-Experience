import SwiftUI
import Charts

/// Single trending fitness number with a 12-week sparkline and component
/// breakdown. Sits at the top of the Body tab, above the recovery bar.
///
/// The card is purely presentational — score + trend are computed in
/// `StrengthScoreEngine` and passed in.
struct StrengthScoreCard: View {
    let score: StrengthScoreEngine.StrengthScore
    let trend: [StrengthScoreEngine.TrendPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            scoreLine
            sparkline
            breakdown
        }
        .padding(16)
        .background(Color.outrunSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.outrunCyan.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("STRENGTH SCORE")
                .font(.outrunFuture(11))
                .foregroundColor(.outrunCyan.opacity(0.8))
            Spacer()
            if let delta = score.trend.deltaText {
                Text(delta)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(deltaColor)
            }
        }
    }

    private var deltaColor: Color {
        switch score.trend {
        case .up:      return .outrunGreen
        case .down:    return .outrunRed
        case .flat:    return .white.opacity(0.5)
        case .unknown: return .white.opacity(0.4)
        }
    }

    // MARK: - Score line

    private var scoreLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(scoreText)
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .foregroundColor(.outrunCyan)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if !score.hasData {
                Text("LOG A SET TO START")
                    .font(.outrunFuture(10))
                    .foregroundColor(.white.opacity(0.5))
            } else {
                Text("PTS")
                    .font(.outrunFuture(11))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 6)
            }
        }
    }

    private var scoreText: String {
        score.total.formatted(.number.grouping(.automatic))
    }

    // MARK: - Sparkline

    @ViewBuilder
    private var sparkline: some View {
        if hasTrendData {
            Chart(trend) { point in
                LineMark(
                    x: .value("Week", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(Color.outrunCyan)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Week", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.outrunCyan.opacity(0.35), .outrunCyan.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 56)
        } else {
            Rectangle()
                .fill(Color.outrunBlack.opacity(0.4))
                .frame(height: 56)
                .overlay(
                    Text("BUILDING TREND…")
                        .font(.outrunFuture(9))
                        .foregroundColor(.white.opacity(0.3))
                )
                .cornerRadius(8)
        }
    }

    private var hasTrendData: Bool {
        // Need at least 2 non-zero points to draw a meaningful line.
        trend.filter { $0.score > 0 }.count >= 2
    }

    // MARK: - Component breakdown

    private var breakdown: some View {
        HStack(spacing: 12) {
            componentChip(
                label: "STRENGTH",
                value: Int(score.strengthComponent.rounded()).formatted(.number.grouping(.automatic)),
                color: .outrunYellow,
                icon: "bolt.fill"
            )
            componentChip(
                label: "VOLUME",
                value: Int(score.volumeComponent.rounded()).formatted(.number.grouping(.automatic)),
                color: .outrunPink,
                icon: "scalemass.fill"
            )
            componentChip(
                label: "FREQUENCY",
                value: "\(score.frequencyComponent)",
                color: .outrunGreen,
                icon: "calendar"
            )
        }
    }

    private func componentChip(label: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color.opacity(0.7))
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.outrunFuture(7))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.outrunBlack.opacity(0.5))
        .cornerRadius(8)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var parts: [String] = ["Strength score: \(score.total) points."]
        switch score.trend {
        case .up(let d):   parts.append("Up \(d) versus last 28 days.")
        case .down(let d): parts.append("Down \(d) versus last 28 days.")
        case .flat:        parts.append("Unchanged versus last 28 days.")
        case .unknown:     break
        }
        parts.append("Strength component \(Int(score.strengthComponent.rounded())).")
        parts.append("Volume component \(Int(score.volumeComponent.rounded())).")
        parts.append("Frequency \(score.frequencyComponent) sessions.")
        return parts.joined(separator: " ")
    }
}
