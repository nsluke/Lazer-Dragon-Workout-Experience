import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    let workout: Workout

    @Environment(\.modelContext) private var modelContext

    private var sortedSessions: [WorkoutSession] {
        workout.sessions.sorted { $0.date > $1.date }
    }

    // MARK: - Aggregate stats

    private var totalTime: Int {
        workout.sessions.reduce(0) { $0 + $1.totalElapsed }
    }

    private var bestTime: Int? {
        workout.sessions.map(\.totalElapsed).min()
    }

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            if sortedSessions.isEmpty {
                emptyState
            } else {
                List {
                    summaryHeader
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                        .listRowSeparator(.hidden)

                    ForEach(sortedSessions) { session in
                        sessionRow(session)
                            .listRowBackground(Color.outrunSurface)
                            .listRowSeparatorTint(Color.outrunBackground)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .outrunTitle("HISTORY")
        .outrunNavBar()
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: 0) {
            summaryCell(
                label: "SESSIONS",
                value: "\(sortedSessions.count)",
                color: .outrunCyan
            )
            divider
            summaryCell(
                label: "TOTAL TIME",
                value: totalTime.formattedTimeLong,
                color: .outrunYellow
            )
            if let best = bestTime {
                divider
                summaryCell(
                    label: "BEST",
                    value: best.formattedTimeLong,
                    color: .outrunGreen
                )
            }
        }
        .padding(.vertical, 16)
        .background(Color.outrunSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.outrunCyan.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    private func summaryCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.outrunFuture(9))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 36)
    }

    // MARK: - Session Row

    private func sessionRow(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.outrunFuture(13))
                .foregroundColor(.outrunCyan)

            HStack(spacing: 24) {
                stat(label: "TIME",      value: session.totalElapsed.formattedTimeLong, color: .outrunYellow)
                stat(label: "EXERCISES", value: "\(session.exercisesCompleted)",        color: .outrunGreen)
                stat(label: "SETS",      value: "\(session.setsCompleted)",             color: .outrunOrange)
            }
        }
        .padding(.vertical, 6)
    }

    private func stat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.outrunFuture(9))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.outrunCyan.opacity(0.4))
            Text("NO SESSIONS YET")
                .font(.outrunFuture(18))
                .foregroundColor(.white.opacity(0.5))
            Text("Complete a workout to see your history.")
                .font(.outrunFuture(12))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Delete

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedSessions[index])
        }
        try? modelContext.save()
    }
}
