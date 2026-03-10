import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    let workout: Workout

    @Environment(\.modelContext) private var modelContext

    private var sortedSessions: [WorkoutSession] {
        workout.sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            if sortedSessions.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(sortedSessions) { session in
                        sessionRow(session)
                            .listRowBackground(Color.outrunSurface)
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .outrunNavBar()
    }

    // MARK: - Row

    private func sessionRow(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                .font(.outrunFuture(13))
                .foregroundColor(.outrunCyan)

            HStack(spacing: 24) {
                stat(label: "TIME", value: session.totalElapsed.formattedTimeLong, color: .outrunYellow)
                stat(label: "EXERCISES", value: "\(session.exercisesCompleted)", color: .outrunGreen)
                stat(label: "SETS", value: "\(session.setsCompleted)", color: .outrunOrange)
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
            Text("No sessions yet")
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
