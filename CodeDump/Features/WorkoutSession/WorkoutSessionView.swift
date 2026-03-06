import SwiftUI

struct WorkoutSessionView: View {
    @Binding var path: NavigationPath
    @State private var viewModel: WorkoutSessionViewModel
    @State private var showEndAlert = false

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
                    onDone: { path.removeLast(path.count) }
                )
            } else {
                sessionContent
            }
        }
        .navigationBarBackButtonHidden(true)
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
                Text(viewModel.totalElapsed.formattedTimeLong)
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.outrunGreen)
            }

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

                if case .idle = viewModel.phase {
                    Text("tap to start")
                        .font(.outrunFuture(12))
                        .foregroundColor(.outrunCyan.opacity(0.7))
                }
            }
        }
        .frame(width: 270, height: 270)
        .contentShape(Circle())
        .onTapGesture {
            if case .idle = viewModel.phase {
                viewModel.startWorkout()
            }
        }
    }

    // MARK: - Exercise Info

    private var exerciseInfo: some View {
        VStack(spacing: 6) {
            if let current = viewModel.currentExercise, current.reps > 0 {
                Text("\(current.reps) REPS")
                    .font(.outrunFuture(14))
                    .foregroundColor(.outrunYellow)
            }

            if let next = viewModel.nextExercise {
                Text("NEXT: \(next.name.uppercased())")
                    .font(.outrunFuture(13))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(height: 44)
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
    }

    private var playPauseIcon: String {
        if case .idle = viewModel.phase { return "play.fill" }
        return viewModel.isRunning ? "pause.fill" : "play.fill"
    }
}
