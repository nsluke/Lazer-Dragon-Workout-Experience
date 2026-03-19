import SwiftUI

/// Drill-down view shown below the calendar when a day is tapped.
/// Shows per-session cards with workout name, duration, volume, exercise summaries, and PR badges.
struct DayDetailView: View {
    let date: Date
    let sessions: [WorkoutSession]
    let allHistoricalLogs: [SetLog]
    let allSessions: [WorkoutSession]

    @State private var summaries: [SessionSummaryEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            Text(dateHeaderString)
                .font(.outrunFuture(12))
                .foregroundColor(.outrunCyan)

            if sessions.isEmpty {
                restDayCard
            } else {
                ForEach(summaries) { entry in
                    sessionCard(entry)
                }
            }
        }
        .task(id: date) {
            computeSummaries()
        }
    }

    // MARK: - Rest Day

    private var restDayCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 28))
                .foregroundColor(.outrunPurple.opacity(0.4))
            Text("REST DAY")
                .font(.outrunFuture(16))
                .foregroundColor(.outrunPurple)
            Text("No workouts recorded.")
                .font(.outrunFuture(10))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.outrunBlack)
        .cornerRadius(12)
    }

    // MARK: - Session Card

    private func sessionCard(_ entry: SessionSummaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: workout name + duration
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.workoutName.uppercased())
                        .font(.outrunFuture(14))
                        .foregroundColor(.outrunYellow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(entry.session.totalElapsed.formattedTimeLong)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.outrunCyan.opacity(0.7))
                }

                Spacer()

                // PR count badge
                if entry.summary.prCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10))
                        Text("\(entry.summary.prCount) PR\(entry.summary.prCount > 1 ? "s" : "")")
                            .font(.outrunFuture(9))
                    }
                    .foregroundColor(.outrunYellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.outrunYellow.opacity(0.15))
                    .cornerRadius(6)
                }
            }

            // Stats row
            HStack(spacing: 0) {
                miniStat(
                    label: "VOLUME",
                    value: SessionAnalytics.formatVolume(entry.summary.totalVolume),
                    color: .outrunPink
                )
                miniStat(
                    label: "EXERCISES",
                    value: "\(entry.summary.totalExercises)",
                    color: .outrunYellow
                )
                miniStat(
                    label: "SETS",
                    value: "\(entry.summary.totalSets)",
                    color: .outrunGreen
                )
            }
            .background(Color.outrunBackground.opacity(0.5))
            .cornerRadius(8)

            // Exercise list
            ForEach(entry.summary.exerciseSummaries) { ex in
                exerciseRow(ex)
            }

            // Muscle chips
            if !entry.summary.muscleGroupsHit.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.summary.muscleGroupsHit) { muscle in
                            HStack(spacing: 3) {
                                Image(systemName: muscle.icon)
                                    .font(.system(size: 9))
                                Text(muscle.displayName.uppercased())
                                    .font(.outrunFuture(7))
                            }
                            .foregroundColor(.outrunCyan.opacity(0.7))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.outrunCyan.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.outrunBlack)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.outrunSurface.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func miniStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.outrunFuture(7))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private func exerciseRow(_ ex: SessionAnalytics.ExerciseSummary) -> some View {
        HStack {
            Text(ex.exerciseName)
                .font(.outrunFuture(10))
                .foregroundColor(.outrunYellow.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            HStack(spacing: 8) {
                Text("\(ex.sets.count) sets")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))

                if let best = ex.bestSet, let w = best.weight {
                    Text("\(Int(w)) lbs")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.outrunCyan)
                }

                if let pr = ex.pr, pr.isPR {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.outrunYellow)
                }
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private var dateHeaderString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date).uppercased()
    }

    private func computeSummaries() {
        summaries = sessions.map { session in
            let summary = SessionAnalytics.analyze(
                sessionLogs: session.setLogs,
                allHistoricalLogs: allHistoricalLogs,
                workout: session.workout,
                allSessions: allSessions
            )
            return SessionSummaryEntry(
                session: session,
                summary: summary,
                workoutName: session.workout?.name ?? "Workout"
            )
        }
    }
}

// MARK: - Supporting Types

private struct SessionSummaryEntry: Identifiable {
    let id = UUID()
    let session: WorkoutSession
    let summary: SessionAnalytics.SessionSummary
    let workoutName: String
}
