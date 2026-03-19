import SwiftUI

// MARK: - Share Card (1080×1920 Instagram Story format)

struct WorkoutShareCardView: View {
    let workoutName: String
    let totalTime: Int
    let exercisesCompleted: Int
    let setsCompleted: Int
    let setLogs: [SetLog]
    let date: Date

    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.outrunBlack, Color.outrunBackground, Color.outrunBlack],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                Spacer().frame(height: 120)

                // Header
                VStack(spacing: 16) {
                    Text("WORKOUT")
                        .font(.custom("OutrunFuture", size: 48))
                        .foregroundColor(.outrunCyan)
                    Text("COMPLETE")
                        .font(.custom("OutrunFuture", size: 96))
                        .foregroundColor(.outrunYellow)
                        .shadow(color: .outrunYellow.opacity(0.4), radius: 20)
                }

                Spacer().frame(height: 40)

                // Workout name
                Text(workoutName.uppercased())
                    .font(.custom("OutrunFuture", size: 36))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)

                Spacer().frame(height: 60)

                // Stats
                VStack(spacing: 24) {
                    shareStatRow(label: "TOTAL TIME", value: totalTime.formattedTimeLong, color: .outrunCyan)
                    shareStatRow(label: "EXERCISES", value: "\(exercisesCompleted)", color: .outrunYellow)
                    shareStatRow(label: "SETS", value: "\(setsCompleted)", color: .outrunGreen)
                }
                .padding(.horizontal, 80)

                Spacer().frame(height: 60)

                // Top sets
                if !setLogs.isEmpty {
                    topSetsSection
                        .padding(.horizontal, 80)
                }

                Spacer()

                // Synthwave grid
                synthwaveGrid
                    .frame(height: 280)

                // Branding
                VStack(spacing: 8) {
                    Text("LAZER DRAGON")
                        .font(.custom("OutrunFuture", size: 28))
                        .foregroundColor(.outrunPink)
                        .shadow(color: .outrunPink.opacity(0.5), radius: 12)
                    Text(date.formatted(.dateTime.month(.wide).day().year()))
                        .font(.custom("OutrunFuture", size: 20))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.bottom, 80)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Stat Row

    private func shareStatRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.custom("OutrunFuture", size: 28))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(Color.outrunBlack.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Top Sets

    private var topSetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TOP SETS")
                .font(.custom("OutrunFuture", size: 22))
                .foregroundColor(.outrunCyan.opacity(0.7))

            ForEach(Array(bestSets.prefix(5).enumerated()), id: \.offset) { _, log in
                HStack {
                    Text(log.exerciseName)
                        .font(.custom("OutrunFuture", size: 20))
                        .foregroundColor(.outrunYellow)
                        .lineLimit(1)
                    Spacer()
                    HStack(spacing: 16) {
                        if let weight = log.weight {
                            Text("\(Int(weight))lbs")
                                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                                .foregroundColor(.outrunCyan)
                        }
                        if let reps = log.reps {
                            Text("\(reps)r")
                                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                                .foregroundColor(.outrunGreen)
                        }
                        if let rpe = log.rpe {
                            Text("@\(rpe)")
                                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                                .foregroundColor(.outrunOrange)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.outrunBlack.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    /// Best set per exercise (highest weight, then most reps).
    private var bestSets: [SetLog] {
        var best: [String: SetLog] = [:]
        for log in setLogs {
            let key = log.exerciseName
            if let existing = best[key] {
                if (log.weight ?? 0) > (existing.weight ?? 0) ||
                   ((log.weight ?? 0) == (existing.weight ?? 0) && (log.reps ?? 0) > (existing.reps ?? 0)) {
                    best[key] = log
                }
            } else {
                best[key] = log
            }
        }
        return Array(best.values).sorted { ($0.weight ?? 0) > ($1.weight ?? 0) }
    }

    // MARK: - Synthwave Grid

    private var synthwaveGrid: some View {
        Canvas { context, size in
            let horizonY = size.height * 0.3
            let centerX = size.width / 2

            // Horizontal lines (receding into distance)
            let lineCount = 12
            for i in 0..<lineCount {
                let t = Double(i) / Double(lineCount - 1)
                let y = horizonY + (size.height - horizonY) * pow(t, 1.5)
                let alpha = 0.1 + 0.25 * t

                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))

                context.stroke(path, with: .color(.outrunPink.opacity(alpha)), lineWidth: 1.5)
            }

            // Vertical lines (converging to vanishing point)
            let vLineCount = 15
            for i in 0..<vLineCount {
                let fraction = Double(i) / Double(vLineCount - 1)
                let bottomX = size.width * fraction
                let alpha = 0.08 + 0.2 * (1 - abs(fraction - 0.5) * 2)

                var path = Path()
                path.move(to: CGPoint(x: centerX, y: horizonY))
                path.addLine(to: CGPoint(x: bottomX, y: size.height))

                context.stroke(path, with: .color(.outrunCyan.opacity(alpha)), lineWidth: 1)
            }

            // Horizon glow line
            var horizon = Path()
            horizon.move(to: CGPoint(x: 0, y: horizonY))
            horizon.addLine(to: CGPoint(x: size.width, y: horizonY))
            context.stroke(horizon, with: .color(.outrunPink.opacity(0.6)), lineWidth: 2)
        }
    }

    // MARK: - Render to UIImage

    @MainActor
    static func renderImage(
        workoutName: String,
        totalTime: Int,
        exercisesCompleted: Int,
        setsCompleted: Int,
        setLogs: [SetLog],
        date: Date = .now
    ) -> UIImage? {
        let card = WorkoutShareCardView(
            workoutName: workoutName,
            totalTime: totalTime,
            exercisesCompleted: exercisesCompleted,
            setsCompleted: setsCompleted,
            setLogs: setLogs,
            date: date
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1.0 // Already at target pixel dimensions
        return renderer.uiImage
    }
}
