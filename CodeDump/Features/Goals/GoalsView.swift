import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FitnessGoal.createdAt) private var allGoals: [FitnessGoal]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \SetLog.date, order: .reverse) private var setLogs: [SetLog]

    @State private var showingAddGoal = false
    @State private var showCompleted = false

    private var activeGoals: [FitnessGoal] {
        allGoals.filter { !$0.isCompleted }
    }

    private var completedGoals: [FitnessGoal] {
        allGoals.filter { $0.isCompleted }
    }

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            if allGoals.isEmpty {
                emptyState
            } else {
                goalsList
            }
        }
        .navigationTitle("GOALS")
        .navigationBarTitleDisplayMode(.large)
        .outrunNavBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddGoal = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.outrunCyan)
                        .fontWeight(.bold)
                }
                .accessibilityLabel("Add goal")
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView()
        }
        .onAppear { refreshGoals() }
        .onChange(of: sessions.count) { refreshGoals() }
    }

    // MARK: - Refresh

    private func refreshGoals() {
        for goal in allGoals where !goal.isCompleted && goal.goalType.isAutoTracked {
            goal.autoUpdate(sessions: sessions, setLogs: setLogs)
        }
        try? modelContext.save()
    }

    // MARK: - Goals List

    private var goalsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Active goals
                if !activeGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ACTIVE")
                            .font(.outrunFuture(10))
                            .foregroundColor(.outrunCyan.opacity(0.7))

                        ForEach(activeGoals, id: \.id) { goal in
                            goalCard(goal)
                        }
                    }
                }

                // Completed goals
                if !completedGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCompleted.toggle()
                            }
                        } label: {
                            HStack {
                                Text("COMPLETED (\(completedGoals.count))")
                                    .font(.outrunFuture(10))
                                    .foregroundColor(.outrunGreen.opacity(0.7))
                                Spacer()
                                Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.outrunGreen.opacity(0.5))
                            }
                        }

                        if showCompleted {
                            ForEach(completedGoals, id: \.id) { goal in
                                goalCard(goal)
                                    .opacity(0.6)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Goal Card

    private func goalCard(_ goal: FitnessGoal) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(progressColor(goal.progress).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: goal.isCompleted ? "checkmark" : goal.goalType.icon)
                        .font(.system(size: 16))
                        .foregroundColor(goal.isCompleted ? .outrunGreen : progressColor(goal.progress))
                }

                // Title + subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title.uppercased())
                        .font(.outrunFuture(12))
                        .foregroundColor(.outrunYellow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 6) {
                        if let name = goal.exerciseName {
                            Text(name)
                                .font(.outrunFuture(8))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        if let days = goal.daysRemaining {
                            Text("\(days)d left")
                                .font(.outrunFuture(8))
                                .foregroundColor(goal.isOverdue ? .outrunRed : .white.opacity(0.4))
                        }
                    }
                }

                Spacer()

                // Progress percentage
                Text("\(goal.progressPercentage)%")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(progressColor(goal.progress))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.outrunSurface)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor(goal.progress))
                        .frame(width: geo.size.width * goal.progress)
                }
            }
            .frame(height: 6)

            // Current vs target
            HStack {
                let currentStr = formatGoalValue(goal.currentValue, type: goal.goalType)
                let targetStr = formatGoalValue(goal.targetValue, type: goal.goalType)
                Text("\(currentStr) / \(targetStr) \(goal.goalType.unit)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
            }
        }
        .padding(14)
        .background(Color.outrunBlack)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    goal.isCompleted ? Color.outrunGreen.opacity(0.3) : Color.outrunSurface.opacity(0.5),
                    lineWidth: 1
                )
        )
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(goal)
            } label: {
                Label("Delete Goal", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(goal.title), \(goal.progressPercentage) percent complete")
    }

    private func progressColor(_ progress: Double) -> Color {
        if progress >= 1.0 { return .outrunGreen }
        if progress >= 0.6 { return .outrunCyan }
        if progress >= 0.3 { return .outrunYellow }
        return .outrunOrange
    }

    private func formatGoalValue(_ value: Double, type: GoalType) -> String {
        switch type {
        case .volumeTarget:
            return SessionAnalytics.formatVolume(value)
        case .frequencyTarget, .repTarget:
            return "\(Int(value))"
        default:
            return "\(Int(value))"
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "target")
                .font(.system(size: 52))
                .foregroundColor(.outrunYellow.opacity(0.4))

            Text("NO GOALS YET")
                .font(.outrunFuture(28))
                .foregroundColor(.outrunCyan)

            Text("Set targets to track\nyour progress.")
                .font(.outrunFuture(14))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                showingAddGoal = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                    Text("ADD GOAL")
                        .font(.outrunFuture(20))
                }
                .foregroundColor(.outrunBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.outrunCyan)
                .cornerRadius(12)
                .shadow(color: .outrunCyan.opacity(0.3), radius: 16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }
}
