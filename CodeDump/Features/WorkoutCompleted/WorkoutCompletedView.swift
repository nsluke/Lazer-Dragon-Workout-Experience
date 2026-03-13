import SwiftUI

struct WorkoutCompletedView: View {
    let totalTime: Int
    let exercisesCompleted: Int
    let setsCompleted: Int
    let workoutName: String
    var setLogs: [SetLog] = []
    var workout: Workout? = nil
    var allHistoricalLogs: [SetLog] = []
    var allSessions: [WorkoutSession] = []
    let onDone: () -> Void

    @State private var showingShare = false
    @State private var summary: SessionAnalytics.SessionSummary?
    @State private var showPRBadges = false

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                        .padding(.top, 20)

                    // Improvement banner (PRs + volume delta)
                    if let summary, summary.prCount > 0 || summary.volumeDeltaPercent != nil {
                        improvementBanner(summary)
                    }

                    // Stats grid
                    statsSection

                    // Muscle group chips
                    if let summary, !summary.muscleGroupsHit.isEmpty {
                        muscleChipsSection(summary.muscleGroupsHit)
                    }

                    // Per-exercise summary cards
                    if let summary {
                        exerciseCardsSection(summary.exerciseSummaries)
                    }

                    // Share + Done
                    buttonsSection
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showingShare) {
            ShareSheetView(
                workoutName: workoutName,
                totalTime: totalTime,
                exercisesCompleted: exercisesCompleted,
                setsCompleted: setsCompleted,
                setLogs: setLogs,
                workout: workout
            )
        }
        .task {
            summary = SessionAnalytics.analyze(
                sessionLogs: setLogs,
                allHistoricalLogs: allHistoricalLogs,
                workout: workout,
                allSessions: allSessions
            )
            // Delay PR badge animation for dramatic effect
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showPRBadges = true
            }
            if let summary, summary.prCount > 0 {
                FeedbackEngine.workoutCompleted()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("WORKOUT")
                .font(.outrunFuture(20))
                .foregroundColor(.outrunCyan)
            Text("COMPLETE")
                .font(.outrunFuture(48))
                .foregroundColor(.outrunYellow)
                .minimumScaleFactor(0.5)
            Text(workoutName.uppercased())
                .font(.outrunFuture(16))
                .foregroundColor(.white.opacity(0.5))
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Workout complete: \(workoutName)")
    }

    // MARK: - Improvement Banner

    private func improvementBanner(_ summary: SessionAnalytics.SessionSummary) -> some View {
        HStack(spacing: 16) {
            if summary.prCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.outrunYellow)
                    Text("\(summary.prCount) NEW PR\(summary.prCount > 1 ? "s" : "")!")
                        .font(.outrunFuture(14))
                        .foregroundColor(.outrunYellow)
                }
                .scaleEffect(showPRBadges ? 1.0 : 0.5)
                .opacity(showPRBadges ? 1.0 : 0.0)
            }

            if let delta = summary.volumeDeltaPercent {
                HStack(spacing: 6) {
                    Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 14))
                        .foregroundColor(delta >= 0 ? .outrunGreen : .outrunOrange)
                    Text(SessionAnalytics.volumeDeltaMessage(percent: delta))
                        .font(.outrunFuture(12))
                        .foregroundColor(delta >= 0 ? .outrunGreen : .outrunOrange)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color.outrunSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    summary.prCount > 0 ? Color.outrunYellow.opacity(0.4) : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(improvementAccessibilityLabel(summary))
    }

    private func improvementAccessibilityLabel(_ summary: SessionAnalytics.SessionSummary) -> String {
        var parts: [String] = []
        if summary.prCount > 0 {
            parts.append("\(summary.prCount) new personal record\(summary.prCount > 1 ? "s" : "")")
        }
        if let delta = summary.volumeDeltaPercent {
            let direction = delta >= 0 ? "up" : "down"
            parts.append("Volume \(direction) \(Int(abs(delta))) percent")
        }
        return parts.joined(separator: ". ")
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(spacing: 10) {
            // Row 1: Time, Exercises, Sets
            HStack(spacing: 10) {
                statCard(label: "TIME", value: totalTime.formattedTimeLong, color: .outrunCyan, icon: "clock.fill")
                statCard(label: "EXERCISES", value: "\(exercisesCompleted)", color: .outrunYellow, icon: "figure.strengthtraining.traditional")
                statCard(label: "SETS", value: "\(setsCompleted)", color: .outrunGreen, icon: "number")
            }

            // Row 2: Volume + VS Last
            if let summary {
                HStack(spacing: 10) {
                    statCard(
                        label: "VOLUME",
                        value: SessionAnalytics.formatVolume(summary.totalVolume),
                        color: .outrunPink,
                        icon: "scalemass.fill"
                    )

                    if let delta = summary.volumeDeltaPercent {
                        statCard(
                            label: "VS LAST",
                            value: "\(delta >= 0 ? "+" : "")\(Int(delta))%",
                            color: delta >= 0 ? .outrunGreen : .outrunOrange,
                            icon: delta >= 0 ? "arrow.up" : "arrow.down"
                        )
                    }
                }
            }
        }
    }

    private func statCard(label: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
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
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.outrunBlack)
        .cornerRadius(10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Muscle Chips

    private func muscleChipsSection(_ muscles: [MuscleGroup]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MUSCLES TRAINED")
                .font(.outrunFuture(10))
                .foregroundColor(.outrunCyan.opacity(0.7))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(muscles) { muscle in
                        HStack(spacing: 5) {
                            Image(systemName: muscle.icon)
                                .font(.system(size: 11))
                            Text(muscle.displayName.uppercased())
                                .font(.outrunFuture(9))
                        }
                        .foregroundColor(.outrunCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.outrunSurface)
                        .cornerRadius(20)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Muscles trained: \(muscles.map(\.displayName).joined(separator: ", "))")
    }

    // MARK: - Exercise Cards

    private func exerciseCardsSection(_ summaries: [SessionAnalytics.ExerciseSummary]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXERCISE BREAKDOWN")
                .font(.outrunFuture(10))
                .foregroundColor(.outrunCyan.opacity(0.7))

            ForEach(summaries) { exerciseSummary in
                exerciseCard(exerciseSummary)
            }
        }
    }

    private func exerciseCard(_ ex: SessionAnalytics.ExerciseSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Exercise header: name + PR badge
            HStack {
                Text(ex.exerciseName.uppercased())
                    .font(.outrunFuture(12))
                    .foregroundColor(.outrunYellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                if let pr = ex.pr, pr.isPR, showPRBadges {
                    prBadge(pr)
                }
            }

            // Set rows
            ForEach(Array(ex.sets.enumerated()), id: \.offset) { index, setLog in
                setRow(setNumber: index + 1, log: setLog)
            }

            // Footer: exercise volume + muscle tags
            HStack {
                Text("VOL: \(SessionAnalytics.formatVolume(ex.volume))")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.outrunPink.opacity(0.8))

                Spacer()

                HStack(spacing: 4) {
                    ForEach(ex.muscleGroups) { muscle in
                        Text(muscle.displayName.uppercased())
                            .font(.outrunFuture(7))
                            .foregroundColor(.outrunCyan.opacity(0.6))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.outrunCyan.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.outrunBlack)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    (ex.pr?.isPR == true && showPRBadges)
                        ? Color.outrunYellow.opacity(0.3)
                        : Color.outrunSurface.opacity(0.5),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
    }

    private func prBadge(_ pr: SessionAnalytics.ExercisePR) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 10))
            Text(pr.isWeightPR ? "WEIGHT PR" : "REP PR")
                .font(.outrunFuture(8))
        }
        .foregroundColor(.outrunYellow)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.outrunYellow.opacity(0.15))
        .cornerRadius(6)
        .transition(.scale.combined(with: .opacity))
        .accessibilityLabel(pr.isWeightPR ? "Weight personal record" : "Rep personal record")
    }

    private func setRow(setNumber: Int, log: SetLog) -> some View {
        HStack {
            Text("SET \(setNumber)")
                .font(.outrunFuture(8))
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 44, alignment: .leading)

            Spacer()

            HStack(spacing: 12) {
                if let weight = log.weight {
                    Text("\(Int(weight)) lbs")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.outrunCyan)
                }
                if let reps = log.reps {
                    Text("\(reps) reps")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.outrunGreen)
                }
                if let rpe = log.rpe {
                    Text("@\(rpe)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.outrunOrange)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(setLogAccessibilityLabel(setNumber: setNumber, log: log))
    }

    // MARK: - Buttons

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            Button {
                showingShare = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                    Text("SHARE")
                        .font(.outrunFuture(20))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.outrunPink, .outrunPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .outrunPink.opacity(0.25), radius: 12)
            }

            Button(action: onDone) {
                Text("DONE")
                    .font(.outrunFuture(28))
                    .foregroundColor(.outrunBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.outrunCyan)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Accessibility Helpers

    private func setLogAccessibilityLabel(setNumber: Int, log: SetLog) -> String {
        var parts = ["Set \(setNumber)"]
        if let weight = log.weight { parts.append("\(Int(weight)) pounds") }
        if let reps = log.reps { parts.append("\(reps) reps") }
        if let rpe = log.rpe { parts.append("RPE \(rpe)") }
        return parts.joined(separator: ", ")
    }
}
