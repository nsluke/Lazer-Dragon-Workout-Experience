import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Binding var path: NavigationPath
    @State private var viewModel: WorkoutSessionViewModel
    @State private var showEndAlert = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SetLog.date, order: .reverse) private var allSetLogs: [SetLog]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]

    init(workout: Workout, path: Binding<NavigationPath>) {
        _path = path
        _viewModel = State(initialValue: WorkoutSessionViewModel(workout: workout))
    }

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            if case .completed = viewModel.phase {
                WorkoutCompletedView(
                    totalTime: viewModel.totalElapsed,
                    exercisesCompleted: viewModel.exercisesCompleted,
                    setsCompleted: viewModel.setsCompleted,
                    workoutName: viewModel.workout.name,
                    setLogs: viewModel.sessionLogs,
                    workout: viewModel.workout,
                    allHistoricalLogs: allSetLogs,
                    allSessions: allSessions,
                    routeCoordinates: viewModel.isGPSWorkout ? viewModel.locationTracker.locations.map(\.coordinate) : [],
                    routeDistance: viewModel.isGPSWorkout ? viewModel.locationTracker.distanceMeters : nil,
                    onDone: { path.removeLast(path.count) }
                )
            } else {
                ZStack {
                    sessionContent

                    if viewModel.pendingLog != nil {
                        SetLogOverlay(viewModel: viewModel)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeOut(duration: 0.3), value: viewModel.pendingLog != nil)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await HealthKitManager.shared.requestAuthorization()
            viewModel.historicalLogs = allSetLogs
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            // Auto-commit any pending log on every phase change. commitSetLog()
            // is a no-op when pendingLog is nil, so this is safe to fire on
            // .interval / .restBetweenSets / .completed alike. finishWorkout()
            // also commits internally, so the .completed branch is defensive.
            if viewModel.pendingLog != nil {
                viewModel.commitSetLog()
            }
            if case .completed = newPhase {
                saveSession()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.handleForeground()
            }
        }
        .alert("End Workout?", isPresented: $showEndAlert) {
            Button("End", role: .destructive) { viewModel.endWorkout() }
            Button("Continue", role: .cancel) { viewModel.resume() }
        } message: {
            Text("You'll lose your current progress.")
        }
    }

    // MARK: - Session Layout

    private var sessionContent: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Spacer()

            timerRing

            Spacer()

            if viewModel.isGPSWorkout {
                gpsStatsBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }

            exerciseInfo
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            controlBar
                .padding(.horizontal, 28)
                .padding(.bottom, 36)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Total elapsed
            VStack(alignment: .leading, spacing: 2) {
                Text("ELAPSED")
                    .font(.outrunFuture(9))
                    .foregroundColor(.white.opacity(0.4))
                    .minimumScaleFactor(0.7)
                Text(viewModel.totalElapsed.formattedTimeLong)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.outrunGreen)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Elapsed time: \(viewModel.totalElapsed.formattedTimeLong)")

            Spacer()

            // Set label (hidden during warmup/cooldown)
            if !viewModel.setLabel.isEmpty {
                Text(viewModel.setLabel)
                    .font(.outrunFuture(13))
                    .foregroundColor(.outrunCyan)
            }

            Spacer()

            // End button
            Button {
                viewModel.pause()
                showEndAlert = true
            } label: {
                Text("END")
                    .font(.outrunFuture(13))
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

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.outrunSurface, lineWidth: 12)

            // Progress arc (counts down)
            Circle()
                .trim(from: 0, to: viewModel.progressRing)
                .stroke(
                    viewModel.phaseColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.splitTimeRemaining)

            // Center: phase title + countdown
            VStack(spacing: 6) {
                Text(viewModel.phaseTitle)
                    .font(.outrunFuture(16))
                    .foregroundColor(viewModel.phaseColor)

                Text(viewModel.splitTimeRemaining.formattedTimeLong)
                    .font(.system(size: 60, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: viewModel.splitTimeRemaining)

                switch viewModel.phase {
                case .idle:
                    Text("tap to start")
                        .font(.outrunFuture(12))
                        .foregroundColor(.outrunCyan.opacity(0.7))
                case .rest, .restBetweenSets:
                    Text("tap to skip")
                        .font(.outrunFuture(12))
                        .foregroundColor(.outrunRed.opacity(0.7))
                default:
                    Color.clear.frame(height: 18)
                }
            }
        }
        .frame(width: 270, height: 270)
        .contentShape(Circle())
        .onTapGesture {
            switch viewModel.phase {
            case .idle:
                viewModel.startWorkout()
            case .rest, .restBetweenSets:
                viewModel.skipForward()
            default:
                break
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.phaseTitle), \(viewModel.splitTimeRemaining.formattedTimeLong) remaining")
        .accessibilityValue("Progress: \(Int(viewModel.progressRing * 100)) percent")
        .accessibilityHint(timerAccessibilityHint)
        .accessibilityAddTraits(.isButton)
    }

    private var timerAccessibilityHint: String {
        switch viewModel.phase {
        case .idle: return "Tap to start workout"
        case .rest, .restBetweenSets: return "Tap to skip rest"
        default: return ""
        }
    }

    // MARK: - GPS Stats

    private var gpsStatsBar: some View {
        let tracker = viewModel.locationTracker
        let isCycling = viewModel.workout.workoutType == .cycling
        return HStack(spacing: 0) {
            gpsStat(
                label: "DISTANCE",
                value: tracker.formattedDistance,
                color: .outrunCyan
            )
            Spacer()
            gpsStat(
                label: isCycling ? "SPEED" : "PACE",
                value: isCycling ? tracker.formattedSpeed : tracker.formattedPace,
                color: .outrunYellow
            )
            Spacer()
            gpsStat(
                label: "AVG",
                value: isCycling
                    ? tracker.averageSpeed(totalSeconds: viewModel.totalElapsed)
                    : tracker.averagePace(totalSeconds: viewModel.totalElapsed),
                color: .outrunGreen
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.outrunSurface)
        .cornerRadius(12)
    }

    private func gpsStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.outrunFuture(9))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Exercise Info

    private var exerciseInfo: some View {
        VStack(spacing: 6) {
            // Superset progress indicator
            if let progress = viewModel.supersetProgress {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 10))
                    Text(progress.total <= 2 ? "SUPERSET" : "CIRCUIT")
                        .font(.outrunFuture(10))
                    Text("\(progress.current)/\(progress.total)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.outrunPurple)
            }

            if let current = viewModel.currentExercise {
                switch current.exerciseMode {
                case .timeBased:
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                        Text("TIMED")
                            .font(.outrunFuture(14))
                    }
                    .foregroundColor(.outrunCyan)
                case .repBased, .hybrid:
                    if current.reps > 0 {
                        Text("\(current.reps) REPS")
                            .font(.outrunFuture(14))
                            .foregroundColor(.outrunYellow)
                    }
                }
            }

            if let next = viewModel.nextExercise {
                let noRest = viewModel.nextIsInSuperset
                Text(noRest ? "NEXT (NO REST): \(next.name.uppercased())" : "NEXT: \(next.name.uppercased())")
                    .font(.outrunFuture(noRest ? 11 : 13))
                    .foregroundColor(noRest ? .outrunPurple.opacity(0.7) : .white.opacity(0.4))
            }
        }
        .frame(minHeight: 44)
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 0) {
            // Previous
            controlButton(icon: "backward.fill", color: .outrunCyan) {
                viewModel.skipBackward()
            }
            .disabled(viewModel.phase == .idle)

            Spacer()

            // Play / Pause / Start
            Button {
                if case .idle = viewModel.phase {
                    viewModel.startWorkout()
                } else {
                    viewModel.playPause()
                }
            } label: {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.outrunBlack)
                    .frame(width: 84, height: 84)
                    .background(viewModel.phaseColor)
                    .clipShape(Circle())
                    .shadow(color: viewModel.phaseColor.opacity(0.5), radius: 12)
            }
            .accessibilityLabel(playPauseAccessibilityLabel)

            Spacer()

            // Next / Skip
            controlButton(icon: "forward.fill", color: .outrunCyan) {
                viewModel.skipForward()
            }
            .disabled(viewModel.phase == .idle || viewModel.phase == .completed)
        }
    }

    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(Color.outrunBlack)
                .clipShape(Circle())
                .overlay(Circle().stroke(color.opacity(0.3), lineWidth: 1))
        }
        .accessibilityLabel(icon == "backward.fill" ? "Previous exercise" : "Next exercise")
        .accessibilityIdentifier(icon == "forward.fill" ? "skip_forward_button" : "skip_backward_button")
    }

    private var playPauseIcon: String {
        if case .idle = viewModel.phase { return "play.fill" }
        return viewModel.isRunning ? "pause.fill" : "play.fill"
    }

    private var playPauseAccessibilityLabel: String {
        if case .idle = viewModel.phase { return "Start workout" }
        return viewModel.isRunning ? "Pause" : "Resume"
    }

    // MARK: - History Persistence

    private func saveSession() {
        let session = WorkoutSession(
            totalElapsed: viewModel.totalElapsed,
            exercisesCompleted: viewModel.exercisesCompleted,
            setsCompleted: viewModel.setsCompleted
        )
        session.workout = viewModel.workout
        viewModel.workout.sessions?.append(session)

        // Save GPS route data if applicable
        if viewModel.isGPSWorkout, !viewModel.locationTracker.locations.isEmpty {
            session.setRoute(from: viewModel.locationTracker.locations)
        }

        modelContext.insert(session)

        // Persist set logs
        for log in viewModel.sessionLogs {
            log.session = session
            session.setLogs?.append(log)
            modelContext.insert(log)
        }

        try? modelContext.save()

        // Refresh workout-relevant widgets (streak, heatmap, PR, program)
        WidgetDataProvider.shared.refreshAfterWorkout(context: modelContext)
    }
}
