import SwiftUI
import SwiftData

struct BodyStatusView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \SetLog.date, order: .reverse) private var setLogs: [SetLog]
    @Query private var customTemplates: [CustomExerciseTemplate]

    @State private var muscleCards: [MuscleCardData] = []
    @State private var recommendedMuscles: [MuscleGroup] = []
    @State private var weeklyStats: (sessions: Int, sets: Int, volume: Double) = (0, 0, 0)
    #if os(iOS)
    @State private var recoveryScore: RecoveryScore?
    #endif

    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    #if os(iOS)
                    recoveryBar
                    #endif
                    weeklyStatsSection
                    recommendedSection
                    muscleFreshnessGrid
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
        }
        .outrunTitle("BODY")
        .outrunNavBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: AnalyticsDashboardView()) {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.outrunCyan)
                }
            }
        }
        .onAppear { refresh() }
        .onChange(of: sessions.count) { refresh() }
        #if os(iOS)
        .task { await loadRecovery() }
        #endif
    }

    // MARK: - Data

    private func refresh() {
        var customMuscles: [String: [MuscleGroup]] = [:]
        for ct in customTemplates {
            customMuscles[ct.id] = ct.muscleGroups
        }
        let lookup = MuscleAnalyzer.buildLookup(customMuscles: customMuscles)
        let analyzer = MuscleAnalyzer(templateLookup: lookup)

        let freshness = analyzer.muscleFreshness(sessions: sessions)
        let lastTrained = analyzer.muscleLastTrained(sessions: sessions)
        let setsInWindow = analyzer.muscleSetsInWindow(sessions: sessions, days: 7)

        muscleCards = MuscleGroup.allCases
            .filter { $0 != .fullBody }
            .map { muscle in
                let daysSince: Int?
                if let date = lastTrained[muscle] {
                    daysSince = max(0, Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0)
                } else {
                    daysSince = nil
                }
                let score = freshness.first(where: { $0.muscle == muscle })?.score ?? 1000
                return MuscleCardData(
                    muscle: muscle,
                    daysSinceLastTrained: daysSince,
                    setsInLast7Days: setsInWindow[muscle] ?? 0,
                    freshnessScore: score
                )
            }

        recommendedMuscles = Array(freshness.prefix(3).map(\.muscle))
            .filter { $0 != .fullBody }

        computeWeeklyStats()
    }

    private func computeWeeklyStats() {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: .now) else { return }

        let weekSessions = sessions.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }
        let weekLogs = setLogs.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }

        var volume: Double = 0
        for log in weekLogs {
            let w: Double = log.weight ?? 0
            let r: Double = Double(log.reps ?? 0)
            volume += w * r
        }

        weeklyStats = (weekSessions.count, weekLogs.count, volume)
    }

    #if os(iOS)
    private func loadRecovery() async {
        let recentRPEs = Array(setLogs.prefix(30).compactMap(\.rpe))
        let daysSince = daysSinceLastWorkout()
        let sleep = await RecoveryAnalyzer.fetchSleepHours()
        let hrv = await RecoveryAnalyzer.fetchRecentHRV()
        let baseline = await RecoveryAnalyzer.fetchBaselineHRV()
        recoveryScore = RecoveryAnalyzer.computeRecovery(
            sleepHours: sleep,
            recentHRV: hrv,
            baselineHRV: baseline,
            recentRPEs: recentRPEs,
            daysSinceLastWorkout: daysSince
        )
    }

    private func daysSinceLastWorkout() -> Int {
        guard let last = sessions.first else { return 7 }
        return max(0, Calendar.current.dateComponents([.day], from: last.date, to: .now).day ?? 0)
    }

    // MARK: - Recovery Bar

    @ViewBuilder
    private var recoveryBar: some View {
        if let score = recoveryScore {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("RECOVERY")
                        .font(.outrunFuture(11))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text("\(score.displayPercentage)%")
                        .font(.outrunFuture(14))
                        .foregroundColor(recoveryColor(score.overall))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.outrunSurface)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(recoveryColor(score.overall))
                            .frame(width: geo.size.width * score.overall)
                    }
                }
                .frame(height: 8)

                HStack(spacing: 16) {
                    if let sleep = score.sleepComponent {
                        Label("Sleep \(Int(sleep * 100))%", systemImage: "moon.fill")
                            .font(.outrunFuture(8))
                            .foregroundColor(.outrunPurple.opacity(0.7))
                    }
                    if let hrv = score.hrvComponent {
                        Label("HRV \(Int(hrv * 100))%", systemImage: "heart.fill")
                            .font(.outrunFuture(8))
                            .foregroundColor(.outrunPink.opacity(0.7))
                    }
                    Label("RPE \(Int(score.rpeComponent * 100))%", systemImage: "flame.fill")
                        .font(.outrunFuture(8))
                        .foregroundColor(.outrunOrange.opacity(0.7))
                }
            }
            .padding(14)
            .background(Color.outrunSurface)
            .cornerRadius(12)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Recovery score: \(score.displayPercentage) percent")
        }
    }

    private func recoveryColor(_ score: Double) -> Color {
        if score >= 0.7 { return .outrunGreen }
        if score >= 0.4 { return .outrunYellow }
        return .outrunOrange
    }
    #endif

    // MARK: - Weekly Stats

    private var weeklyStatsSection: some View {
        let sessionsValue = "\(weeklyStats.sessions)"
        let setsValue = "\(weeklyStats.sets)"
        let volumeValue = SessionAnalytics.formatVolume(weeklyStats.volume)
        return HStack(spacing: 10) {
            weekStatCard(label: "SESSIONS", value: sessionsValue, color: .outrunCyan, icon: "figure.strengthtraining.traditional")
            weekStatCard(label: "SETS", value: setsValue, color: .outrunGreen, icon: "number")
            weekStatCard(label: "VOLUME", value: volumeValue, color: .outrunPink, icon: "scalemass.fill")
        }
    }

    private func weekStatCard(label: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color.opacity(0.7))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.outrunFuture(8))
                .foregroundColor(.white.opacity(0.5))
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.outrunBlack)
        .cornerRadius(10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Recommended

    @ViewBuilder
    private var recommendedSection: some View {
        if !recommendedMuscles.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("TRAIN NEXT")
                    .font(.outrunFuture(10))
                    .foregroundColor(.outrunGreen.opacity(0.8))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recommendedMuscles) { muscle in
                            HStack(spacing: 5) {
                                Image(systemName: muscle.icon)
                                    .font(.system(size: 12))
                                Text(muscle.displayName.uppercased())
                                    .font(.outrunFuture(10))
                            }
                            .foregroundColor(.outrunGreen)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.outrunGreen.opacity(0.12))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.outrunGreen.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Recommended to train: \(recommendedMuscles.map(\.displayName).joined(separator: ", "))")
        }
    }

    // MARK: - Muscle Freshness Grid

    private var muscleFreshnessGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MUSCLE STATUS")
                .font(.outrunFuture(10))
                .foregroundColor(.outrunCyan.opacity(0.7))

            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(muscleCards) { card in
                    muscleCard(card)
                }
            }
        }
    }

    private func muscleCard(_ card: MuscleCardData) -> some View {
        let heatColor = heatColor(daysSince: card.daysSinceLastTrained)

        return HStack(spacing: 10) {
            Image(systemName: card.muscle.icon)
                .font(.system(size: 20))
                .foregroundColor(heatColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(card.muscle.displayName.uppercased())
                    .font(.outrunFuture(10))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let days = card.daysSinceLastTrained {
                    Text(days == 0 ? "TODAY" : "\(days)d AGO")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(heatColor.opacity(0.8))
                } else {
                    Text("NEVER")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Spacer(minLength: 0)

            Text("\(card.setsInLast7Days)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            + Text(" sets")
                .font(.outrunFuture(7))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(12)
        .background(heatColor.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(heatColor.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.muscle.displayName): \(card.daysSinceLastTrained.map { "\($0) days ago" } ?? "never trained"), \(card.setsInLast7Days) sets this week")
    }

    private func heatColor(daysSince: Int?) -> Color {
        guard let days = daysSince else { return .white.opacity(0.3) }
        switch days {
        case 0...1: return .outrunRed
        case 2...3: return .outrunOrange
        case 4...5: return .outrunYellow
        default:    return .outrunGreen
        }
    }
}

// MARK: - Muscle Card Data

private struct MuscleCardData: Identifiable {
    var id: String { muscle.rawValue }
    let muscle: MuscleGroup
    let daysSinceLastTrained: Int?
    let setsInLast7Days: Int
    let freshnessScore: Double
}
