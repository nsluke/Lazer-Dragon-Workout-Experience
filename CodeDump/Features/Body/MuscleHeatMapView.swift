import SwiftUI

struct MuscleHeatMapView: View {
    let muscleCards: [MuscleHeatMapData]

    @State private var showingFront = true
    @State private var selectedMuscle: MuscleGroup?

    var body: some View {
        VStack(spacing: 14) {
            sideToggle
            silhouette
            legend
        }
        .padding(16)
        .background(Color.outrunSurface)
        .cornerRadius(12)
        .sheet(item: $selectedMuscle) { muscle in
            MuscleDetailSheet(muscle: muscle, card: cardFor(muscle))
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Side Toggle

    private var sideToggle: some View {
        HStack(spacing: 4) {
            toggleButton("FRONT", isSelected: showingFront) {
                withAnimation(.easeInOut(duration: 0.3)) { showingFront = true }
            }
            toggleButton("BACK", isSelected: !showingFront) {
                withAnimation(.easeInOut(duration: 0.3)) { showingFront = false }
            }
        }
    }

    private func toggleButton(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.outrunFuture(12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.outrunCyan.opacity(0.3) : Color.outrunBlack)
                .foregroundColor(isSelected ? .outrunCyan : .white.opacity(0.4))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Silhouette Canvas

    private var silhouette: some View {
        GeometryReader { geo in
            let canvasRect = CGRect(origin: .zero, size: geo.size)
            let side: BodySilhouettePaths.Side = showingFront ? .front : .back
            let zones = BodySilhouettePaths.musclePaths(side: side, in: canvasRect)

            Canvas { context, size in
                // Draw dim body outline
                let outlinePath = BodySilhouettePaths.outline(side: side, in: canvasRect)
                context.stroke(outlinePath, with: .color(.white.opacity(0.08)), lineWidth: 1)
                context.fill(outlinePath, with: .color(.white.opacity(0.04)))

                // Draw each muscle zone with glow for hot muscles
                for (muscle, path) in zones {
                    let color = heatColor(for: muscle)
                    let score = freshnessScore(for: muscle)

                    // Glow pass for fatigued muscles
                    if score < 3 {
                        var glowContext = context
                        glowContext.addFilter(.blur(radius: 10))
                        glowContext.fill(path, with: .color(color.opacity(0.5)))
                    }

                    // Fill pass
                    context.fill(path, with: .color(color.opacity(0.7)))

                    // Wireframe stroke
                    context.stroke(path, with: .color(Color.outrunPurple.opacity(0.4)), lineWidth: 1)
                }
            }
            .gesture(
                SpatialTapGesture()
                    .onEnded { tap in
                        for (muscle, path) in zones.reversed() {
                            if path.contains(tap.location) {
                                selectedMuscle = muscle
                                return
                            }
                        }
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(showingFront ? "Front body muscle heat map" : "Back body muscle heat map")
        }
        .aspectRatio(200.0 / 340.0, contentMode: .fit)
        .frame(maxHeight: 380)
        .id(showingFront) // reset canvas on toggle
    }

    // MARK: - Legend

    private var legend: some View {
        VStack(spacing: 6) {
            // Gradient bar
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.outrunRed, .outrunOrange, .outrunYellow, .outrunCyan, .outrunGreen],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 8)
                .cornerRadius(4)
            }

            HStack {
                Text("FATIGUED")
                    .font(.outrunFuture(8))
                    .foregroundColor(.outrunRed.opacity(0.7))
                Spacer()
                Text("FRESH")
                    .font(.outrunFuture(8))
                    .foregroundColor(.outrunGreen.opacity(0.7))
            }
        }
    }

    // MARK: - Color Mapping

    private func heatColor(for muscle: MuscleGroup) -> Color {
        let score = freshnessScore(for: muscle)
        if score >= 1000 { return .white.opacity(0.15) } // never trained
        if score >= 7    { return .outrunGreen }
        if score >= 4    { return .outrunCyan }
        if score >= 2    { return .outrunYellow }
        if score >= 1    { return .outrunOrange }
        return .outrunRed
    }

    private func freshnessScore(for muscle: MuscleGroup) -> Double {
        cardFor(muscle)?.freshnessScore ?? 1000
    }

    private func cardFor(_ muscle: MuscleGroup) -> MuscleHeatMapData? {
        muscleCards.first { $0.muscle == muscle }
    }
}

// MARK: - Data

struct MuscleHeatMapData: Identifiable {
    var id: String { muscle.rawValue }
    let muscle: MuscleGroup
    let daysSinceLastTrained: Int?
    let setsInLast7Days: Int
    let freshnessScore: Double
}

// MARK: - Detail Sheet

struct MuscleDetailSheet: View {
    let muscle: MuscleGroup
    let card: MuscleHeatMapData?

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: muscle.icon)
                        .font(.system(size: 36))
                        .foregroundColor(headerColor)
                        .shadow(color: headerColor.opacity(0.5), radius: 10)

                    Text(muscle.displayName.uppercased())
                        .font(.outrunFuture(20))
                        .foregroundColor(headerColor)
                }
                .padding(.top, 20)

                // Stats
                if let card {
                    HStack(spacing: 16) {
                        detailStat(
                            label: "LAST TRAINED",
                            value: card.daysSinceLastTrained.map { $0 == 0 ? "TODAY" : "\($0)d AGO" } ?? "NEVER",
                            color: .outrunCyan
                        )
                        detailStat(
                            label: "SETS (7 DAYS)",
                            value: "\(card.setsInLast7Days)",
                            color: .outrunPink
                        )
                        detailStat(
                            label: "FRESHNESS",
                            value: freshnessLabel,
                            color: headerColor
                        )
                    }

                    // Freshness bar
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RECOVERY STATUS")
                            .font(.outrunFuture(10))
                            .foregroundColor(.white.opacity(0.5))

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.outrunBlack)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(headerColor)
                                    .frame(width: geo.size.width * freshnessBarProgress)
                            }
                        }
                        .frame(height: 10)
                    }
                    .padding(.horizontal, 20)

                    // Exercises that target this muscle
                    exerciseList
                }

                Spacer()
            }
        }
    }

    private var headerColor: Color {
        guard let card else { return .white.opacity(0.3) }
        let score = card.freshnessScore
        if score >= 1000 { return .white.opacity(0.3) }
        if score >= 7    { return .outrunGreen }
        if score >= 4    { return .outrunCyan }
        if score >= 2    { return .outrunYellow }
        if score >= 1    { return .outrunOrange }
        return .outrunRed
    }

    private var freshnessLabel: String {
        guard let card else { return "N/A" }
        let score = card.freshnessScore
        if score >= 1000 { return "N/A" }
        if score >= 7    { return "FRESH" }
        if score >= 4    { return "RESTED" }
        if score >= 2    { return "MODERATE" }
        if score >= 1    { return "TIRED" }
        return "FATIGUED"
    }

    private var freshnessBarProgress: Double {
        guard let card else { return 0 }
        let score = card.freshnessScore
        if score >= 1000 { return 0 }
        // Map score 0-10 to bar 0-1
        return min(1.0, score / 10.0)
    }

    private func detailStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.outrunFuture(14))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.outrunFuture(7))
                .foregroundColor(.white.opacity(0.4))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.outrunSurface)
        .cornerRadius(10)
    }

    private var exerciseList: some View {
        let exercises = ExerciseTemplate.library.filter { $0.muscles.contains(muscle) }.prefix(6)
        return VStack(alignment: .leading, spacing: 8) {
            Text("EXERCISES")
                .font(.outrunFuture(10))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 20)

            ForEach(Array(exercises), id: \.id) { template in
                HStack(spacing: 10) {
                    Image(systemName: template.equipment.icon)
                        .font(.system(size: 12))
                        .foregroundColor(.outrunPurple.opacity(0.7))
                        .frame(width: 20)
                    Text(template.name)
                        .font(.outrunFuture(11))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
