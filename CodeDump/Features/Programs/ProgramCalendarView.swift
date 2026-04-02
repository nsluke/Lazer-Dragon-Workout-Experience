import SwiftUI
import SwiftData

struct ProgramCalendarView: View {
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<TrainingProgram> { $0.isActive == true })
    private var activePrograms: [TrainingProgram]

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \SetLog.date, order: .reverse) private var setLogs: [SetLog]

    @AppStorage("equipmentProfile") private var equipmentRaw: String = EquipmentProfile.encode(EquipmentProfile.commercialGymEquipment)

    @State private var viewModel = ProgramViewModel()
    @State private var showEndAlert = false

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            if let program = viewModel.activeProgram,
               let template = program.programTemplate {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            weekHeader(program: program, template: template)
                            weekStrip
                            adaptationBanner
                            deloadBanner
                            recoveryBar
                            todayContent
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }

                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            } else {
                noProgramState
            }
        }
        .outrunTitle("PROGRAM")
        .outrunNavBar()
        .onAppear { refresh() }
        .onChange(of: equipmentRaw) { refresh() }
        .onChange(of: sessions.count) { refresh() }
        .alert("End Program?", isPresented: $showEndAlert) {
            Button("End", role: .destructive) {
                viewModel.endProgram(context: modelContext)
                path.removeLast(path.count)
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Your workout history will be preserved.")
        }
        .task {
            let recentRPEs = setLogs.prefix(30).compactMap(\.rpe)
            let daysSince = daysSinceLastWorkout()
            await viewModel.loadRecovery(recentRPEs: Array(recentRPEs), daysSinceLastWorkout: daysSince)
        }
    }

    private func refresh() {
        viewModel.availableEquipment = EquipmentProfile.decode(equipmentRaw)
        viewModel.load(activePrograms: activePrograms, sessions: sessions, setLogs: setLogs)
    }

    // MARK: - Week Header

    private func weekHeader(program: TrainingProgram, template: ProgramTemplate) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name.uppercased())
                    .font(.outrunFuture(14))
                    .foregroundColor(.outrunYellow)
                Text("WEEK \(program.currentWeek) / \(template.durationWeeks)")
                    .font(.outrunFuture(11))
                    .foregroundColor(.outrunCyan)
            }

            Spacer()

            Button {
                showEndAlert = true
            } label: {
                Text("END")
                    .font(.outrunFuture(11))
                    .foregroundColor(.outrunRed)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.outrunBlack)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.outrunRed.opacity(0.4), lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.currentWeekDays) { day in
                VStack(spacing: 6) {
                    // Weekday label
                    Text(day.shortLabel)
                        .font(.outrunFuture(10))
                        .foregroundColor(day.isToday ? .outrunCyan : .white.opacity(0.4))

                    // Status indicator
                    dayIndicator(day)

                    // Day label
                    if let label = day.dayLabel {
                        Text(abbreviateLabel(label))
                            .font(.outrunFuture(7))
                            .foregroundColor(day.isToday ? .outrunYellow : .white.opacity(0.4))
                            .lineLimit(1)
                    } else {
                        Text("—")
                            .font(.outrunFuture(7))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(dayAccessibilityLabel(day))
            }
        }
        .padding(12)
        .background(Color.outrunSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dayIndicator(_ day: ProgramDayStatus) -> some View {
        ZStack {
            if day.isCompleted {
                Circle()
                    .fill(Color.outrunGreen.opacity(0.3))
                    .frame(width: 30, height: 30)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.outrunGreen)
            } else if day.isMissed {
                Circle()
                    .fill(Color.outrunOrange.opacity(0.2))
                    .frame(width: 30, height: 30)
                Image(systemName: "exclamationmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.outrunOrange)
            } else if day.isToday && !day.isRestDay {
                Circle()
                    .stroke(Color.outrunCyan, lineWidth: 2)
                    .frame(width: 30, height: 30)
                Circle()
                    .fill(Color.outrunCyan.opacity(0.15))
                    .frame(width: 30, height: 30)
            } else if day.isRestDay {
                Circle()
                    .fill(Color.outrunSurface)
                    .frame(width: 30, height: 30)
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: 30, height: 30)
            }
        }
    }

    // MARK: - Banners

    @ViewBuilder
    private var adaptationBanner: some View {
        if let message = viewModel.adaptationMessage {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(.outrunCyan)
                Text(message)
                    .font(.outrunFuture(9))
                    .foregroundColor(.white.opacity(0.75))
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.outrunCyan.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.outrunCyan.opacity(0.3), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var deloadBanner: some View {
        if viewModel.deloadSuggested, let message = viewModel.deloadMessage {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.outrunOrange)
                Text(message)
                    .font(.outrunFuture(9))
                    .foregroundColor(.white.opacity(0.75))
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.outrunOrange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.outrunOrange.opacity(0.3), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var recoveryBar: some View {
        if let score = viewModel.recoveryScore {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("RECOVERY")
                        .font(.outrunFuture(9))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text("\(score.displayPercentage)%")
                        .font(.outrunFuture(11))
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
                .frame(height: 6)

                // Component breakdown
                HStack(spacing: 16) {
                    if let sleep = score.sleepComponent {
                        Label("Sleep \(Int(sleep * 100))%", systemImage: "moon.fill")
                            .font(.outrunFuture(7))
                            .foregroundColor(.outrunPurple.opacity(0.6))
                    }
                    if let hrv = score.hrvComponent {
                        Label("HRV \(Int(hrv * 100))%", systemImage: "heart.fill")
                            .font(.outrunFuture(7))
                            .foregroundColor(.outrunPink.opacity(0.6))
                    }
                    Label("RPE \(Int(score.rpeComponent * 100))%", systemImage: "flame.fill")
                        .font(.outrunFuture(7))
                        .foregroundColor(.outrunOrange.opacity(0.6))
                }
            }
            .padding(12)
            .background(Color.outrunSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Recovery score: \(score.displayPercentage) percent")
        }
    }

    // MARK: - Today's Content

    @ViewBuilder
    private var todayContent: some View {
        if let dayTemplate = viewModel.todaysDayTemplate {
            VStack(alignment: .leading, spacing: 12) {
                Text("TODAY: \(dayTemplate.label.uppercased())")
                    .font(.outrunFuture(14))
                    .foregroundColor(.outrunCyan)

                // Exercise preview
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.todaysExercises.enumerated()), id: \.element.id) { index, item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.outrunFuture(12))
                                    .foregroundColor(.outrunYellow)
                                HStack(spacing: 6) {
                                    ForEach(item.muscles.prefix(2)) { muscle in
                                        HStack(spacing: 2) {
                                            Image(systemName: muscle.icon)
                                                .font(.system(size: 8))
                                            Text(muscle.displayName)
                                                .font(.outrunFuture(7))
                                        }
                                        .foregroundColor(.outrunCyan.opacity(0.6))
                                    }
                                }
                            }

                            Spacer()

                            if item.defaultReps > 0 {
                                Text("\(item.defaultReps) reps")
                                    .font(.outrunFuture(9))
                                    .foregroundColor(.outrunGreen.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)

                        if index < viewModel.todaysExercises.count - 1 {
                            Divider().background(Color.outrunSurface)
                        }
                    }
                }
                .padding(12)
                .background(Color.outrunSurface.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        } else {
            // Rest day
            VStack(spacing: 12) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.outrunPurple.opacity(0.4))
                Text("REST DAY")
                    .font(.outrunFuture(20))
                    .foregroundColor(.outrunPurple)
                Text("Recovery is where gains happen.")
                    .font(.outrunFuture(12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        if viewModel.todaysDayTemplate != nil {
            VStack(spacing: 10) {
                // Start button
                Button {
                    startTodaysWorkout()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("START WORKOUT")
                            .font(.outrunFuture(20))
                    }
                    .foregroundColor(.outrunBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.outrunCyan)
                    .cornerRadius(12)
                    .shadow(color: .outrunCyan.opacity(0.3), radius: 16)
                }

                // Skip button
                Button {
                    viewModel.skipDay()
                    refresh()
                } label: {
                    Text("SKIP DAY")
                        .font(.outrunFuture(14))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.outrunSurface)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.outrunSurface, lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Actions

    private func startTodaysWorkout() {
        guard let workout = viewModel.generateTodaysWorkout(in: modelContext) else { return }
        viewModel.markTodayCompleted()
        try? modelContext.save()
        path.append(Route.session(workout))
    }

    // MARK: - Helpers

    private func dayAccessibilityLabel(_ day: ProgramDayStatus) -> String {
        var parts = [day.shortLabel]
        if day.isToday { parts.append("today") }
        if day.isCompleted { parts.append("completed") }
        else if day.isMissed { parts.append("missed") }
        else if day.isRestDay { parts.append("rest day") }
        if let label = day.dayLabel { parts.append(label) }
        return parts.joined(separator: ", ")
    }

    private func abbreviateLabel(_ label: String) -> String {
        let words = label.uppercased().split(separator: " ")
        if words.count <= 2 { return words.joined(separator: " ") }
        return words.map { String($0.prefix(1)) }.joined()
    }

    private func recoveryColor(_ score: Double) -> Color {
        if score >= 0.7 { return .outrunGreen }
        if score >= 0.4 { return .outrunYellow }
        return .outrunOrange
    }

    private func daysSinceLastWorkout() -> Int {
        guard let last = sessions.first else { return 7 }
        return max(0, Calendar.current.dateComponents([.day], from: last.date, to: .now).day ?? 0)
    }

    private var noProgramState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.outrunCyan.opacity(0.3))
            Text("NO ACTIVE PROGRAM")
                .font(.outrunFuture(18))
                .foregroundColor(.outrunCyan)
            Text("Browse programs to get started.")
                .font(.outrunFuture(12))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
