import SwiftUI

// MARK: - Phase

enum WorkoutPhase: Equatable {
    case idle
    case warmup
    case interval(exerciseIndex: Int, setIndex: Int)
    case rest(nextExerciseIndex: Int, setIndex: Int)
    case restBetweenSets(nextSetIndex: Int)
    case cooldown
    case completed
}

// MARK: - ViewModel

@Observable
@MainActor
final class WorkoutSessionViewModel {
    let workout: Workout

    // Displayed state
    var phase: WorkoutPhase = .idle
    var isRunning = false
    var splitTimeRemaining = 0
    var splitDuration = 1
    var totalElapsed = 0

    // Completion stats
    var exercisesCompleted = 0
    var setsCompleted = 0

    // Wall-clock tracking — the source of truth for all time calculations
    private var phaseStartDate: Date = .now
    private var workoutStartDate: Date = .now
    private var totalPausedTime: TimeInterval = 0
    private var pauseStartDate: Date?

    private var timerTask: Task<Void, Never>?
    private let liveActivity = LiveActivityManager()

    init(workout: Workout) {
        self.workout = workout
    }

    // MARK: - Computed

    var sortedExercises: [Exercise] {
        workout.exercises.sorted { $0.order < $1.order }
    }

    private var exercisesPerSet: Int {
        min(workout.numberOfIntervals, sortedExercises.count)
    }

    var currentExercise: Exercise? {
        switch phase {
        case .interval(let i, _):    return sortedExercises[safe: i]
        case .rest(let next, _):     return sortedExercises[safe: max(0, next - 1)]
        default:                     return nil
        }
    }

    var nextExercise: Exercise? {
        switch phase {
        case .interval(let i, _):    return sortedExercises[safe: i + 1]
        case .rest(let next, _):     return sortedExercises[safe: next]
        default:                     return nil
        }
    }

    var phaseTitle: String {
        switch phase {
        case .idle:                  return "READY"
        case .warmup:                return "WARMUP"
        case .interval(let i, _):    return sortedExercises[safe: i]?.name.uppercased() ?? "GO"
        case .rest:                  return "REST"
        case .restBetweenSets:       return "SET REST"
        case .cooldown:              return "COOLDOWN"
        case .completed:             return "DONE"
        }
    }

    var phaseColor: Color {
        switch phase {
        case .idle:            return .outrunCyan
        case .warmup:          return .outrunGreen
        case .interval:        return .outrunYellow
        case .rest:            return .outrunRed
        case .restBetweenSets: return .outrunOrange
        case .cooldown:        return .outrunGreen
        case .completed:       return .outrunCyan
        }
    }

    var setLabel: String {
        switch phase {
        case .interval(_, let s):     return "SET \(s + 1) / \(workout.numberOfSets)"
        case .rest(_, let s):         return "SET \(s + 1) / \(workout.numberOfSets)"
        case .restBetweenSets(let n): return "SET \(n) DONE"
        default:                      return ""
        }
    }

    var progressRing: Double {
        guard splitDuration > 0 else { return 1 }
        return Double(splitTimeRemaining) / Double(splitDuration)
    }

    var currentActivityState: WorkoutActivityAttributes.ContentState {
        WorkoutActivityAttributes.ContentState(
            phaseTitle: phaseTitle,
            setLabel: setLabel,
            splitTimeRemaining: splitTimeRemaining,
            splitDuration: splitDuration,
            totalElapsed: totalElapsed,
            isRunning: isRunning
        )
    }

    // MARK: - Controls

    func startWorkout() {
        workoutStartDate = .now
        totalPausedTime = 0
        if workout.warmupLength > 0 {
            transition(to: .warmup)
        } else {
            transition(to: .interval(exerciseIndex: 0, setIndex: 0))
        }
        liveActivity.start(workoutName: workout.name, state: currentActivityState)
        WatchConnectivityManager.shared.actionHandler = { [weak self] action in
            switch action {
            case "playPause":   self?.playPause()
            case "skipForward": self?.skipForward()
            case "skipBack":    self?.skipBackward()
            default: break
            }
        }
        resume()
    }

    func playPause() {
        isRunning ? pause() : resume()
    }

    func pause() {
        isRunning = false
        pauseStartDate = .now
        timerTask?.cancel()
        WatchConnectivityManager.shared.sendWorkoutState(watchPayload)
    }

    func resume() {
        guard phase != .idle, phase != .completed else { return }
        // Accumulate paused duration so totalElapsed stays accurate
        if let pauseStart = pauseStartDate {
            totalPausedTime += Date.now.timeIntervalSince(pauseStart)
            pauseStartDate = nil
        }
        // Shift phaseStartDate forward by the time we were paused so the
        // countdown doesn't jump when we resume
        phaseStartDate = .now.addingTimeInterval(-(Double(splitDuration - splitTimeRemaining)))
        isRunning = true
        startTicking()
    }

    func skipForward() {
        handlePhaseEnd()
        if isRunning { startTicking() }
    }

    func skipBackward() {
        switch phase {
        case .interval(let i, let s):
            if i > 0 {
                transition(to: .interval(exerciseIndex: i - 1, setIndex: s))
            } else if s > 0 {
                transition(to: .interval(exerciseIndex: max(0, exercisesPerSet - 1), setIndex: s - 1))
            } else {
                transition(to: .interval(exerciseIndex: 0, setIndex: 0))
            }
        case .rest(let next, let s):
            transition(to: .interval(exerciseIndex: max(0, next - 1), setIndex: s))
        case .restBetweenSets(let next):
            transition(to: .interval(exerciseIndex: max(0, exercisesPerSet - 1), setIndex: max(0, next - 1)))
        case .cooldown:
            transition(to: .interval(exerciseIndex: max(0, exercisesPerSet - 1), setIndex: workout.numberOfSets - 1))
        case .warmup:
            transition(to: .warmup)
        default:
            break
        }
        if isRunning { startTicking() }
    }

    func endWorkout() {
        pause()
        transition(to: .completed)
    }

    /// Called when the app returns to foreground. Restarts the tick loop so any
    /// time spent in the background is immediately caught up.
    func handleForeground() {
        guard isRunning else { return }
        startTicking()
    }

    // MARK: - Timer

    private func startTicking() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self, self.isRunning else { continue }
                self.tick()
            }
        }
    }

    private func tick() {
        // Derive all time values from wall clock, not counters.
        // This means any time spent backgrounded is automatically accounted for.
        totalElapsed = Int(Date.now.timeIntervalSince(workoutStartDate) - totalPausedTime)

        let phaseElapsed = Int(Date.now.timeIntervalSince(phaseStartDate))
        splitTimeRemaining = max(0, splitDuration - phaseElapsed)

        // Countdown haptics / audio on last 3 seconds of each phase
        FeedbackEngine.countdownTick(remainingSeconds: splitTimeRemaining)

        // Catch up through however many phases completed while backgrounded.
        while splitTimeRemaining == 0, isRunning, phase != .completed {
            handlePhaseEnd()
            if isRunning {
                // Recalculate for the new phase
                let newElapsed = Int(Date.now.timeIntervalSince(phaseStartDate))
                splitTimeRemaining = max(0, splitDuration - newElapsed)
            }
        }
    }

    // MARK: - State Machine

    private func transition(to newPhase: WorkoutPhase) {
        // Fire feedback on every real transition (not idle or first setup)
        if phase != .idle, newPhase != .idle {
            if case .completed = newPhase {
                FeedbackEngine.workoutCompleted()
            } else {
                FeedbackEngine.phaseChanged()
                FeedbackEngine.playTransitionChime()
            }
        }
        phase = newPhase
        phaseStartDate = .now
        switch newPhase {
        case .warmup:
            splitDuration = max(1, workout.warmupLength)
        case .interval(let i, _):
            let exercise = sortedExercises[safe: i]
            let duration = (exercise?.splitLength ?? 0) > 0 ? exercise!.splitLength : workout.intervalLength
            splitDuration = max(1, duration)
        case .rest:
            splitDuration = max(1, workout.restLength)
        case .restBetweenSets:
            splitDuration = max(1, workout.restBetweenSetLength)
        case .cooldown:
            splitDuration = max(1, workout.cooldownLength)
        case .idle, .completed:
            splitDuration = 1
        }
        splitTimeRemaining = splitDuration
        // Update Live Activity and Watch after all state is set (except .completed — handled by finishWorkout)
        if case .completed = newPhase { } else {
            liveActivity.update(state: currentActivityState)
            WatchConnectivityManager.shared.sendWorkoutState(watchPayload)
        }
    }

    private func handlePhaseEnd() {
        switch phase {

        case .idle:
            startWorkout()

        case .warmup:
            transition(to: .interval(exerciseIndex: 0, setIndex: 0))

        case .interval(let i, let s):
            exercisesCompleted += 1
            let isLastExercise = i + 1 >= exercisesPerSet
            let isLastSet = s + 1 >= workout.numberOfSets

            if isLastExercise && isLastSet {
                if workout.cooldownLength > 0 {
                    transition(to: .cooldown)
                } else {
                    setsCompleted += 1
                    finishWorkout()
                }
            } else if isLastExercise {
                setsCompleted += 1
                if workout.restBetweenSetLength > 0 {
                    transition(to: .restBetweenSets(nextSetIndex: s + 1))
                } else {
                    transition(to: .interval(exerciseIndex: 0, setIndex: s + 1))
                }
            } else if workout.restLength > 0 {
                transition(to: .rest(nextExerciseIndex: i + 1, setIndex: s))
            } else {
                transition(to: .interval(exerciseIndex: i + 1, setIndex: s))
            }

        case .rest(let next, let s):
            transition(to: .interval(exerciseIndex: next, setIndex: s))

        case .restBetweenSets(let next):
            transition(to: .interval(exerciseIndex: 0, setIndex: next))

        case .cooldown:
            setsCompleted = workout.numberOfSets
            finishWorkout()

        case .completed:
            break
        }
    }

    private func finishWorkout() {
        isRunning = false
        timerTask?.cancel()
        let start = workoutStartDate
        let end = start.addingTimeInterval(TimeInterval(totalElapsed))
        let type = workout.workoutType
        transition(to: .completed)
        liveActivity.end(finalState: currentActivityState)
        WatchConnectivityManager.shared.actionHandler = nil
        WatchConnectivityManager.shared.sendWorkoutState(watchPayload)
        Task { await HealthKitManager.shared.saveWorkout(type: type, start: start, end: end) }
    }

    // MARK: - Watch

    private var watchPayload: [String: Any] {
        [
            "phaseTitle": phaseTitle,
            "setLabel": setLabel,
            "splitTimeRemaining": splitTimeRemaining,
            "splitDuration": splitDuration,
            "totalElapsed": totalElapsed,
            "isRunning": isRunning
        ]
    }
}
