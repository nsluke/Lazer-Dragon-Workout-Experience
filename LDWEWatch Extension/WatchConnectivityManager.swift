import WatchConnectivity
import Foundation

/// Receives workout state from the iPhone and exposes it as published properties.
/// Runs a local timer to compute countdown values from reference timestamps,
/// keeping the Watch perfectly in sync with the phone's wall clock.
final class WatchConnectivityManager: NSObject, ObservableObject {

    @Published var workoutActive: Bool = false
    @Published var phaseTitle: String = "WAITING"
    @Published var setLabel: String = ""
    @Published var splitTimeRemaining: Int = 0
    @Published var splitDuration: Int = 1
    @Published var totalElapsed: Int = 0
    @Published var isRunning: Bool = false

    // Reference timestamps from the iPhone
    private var phaseStartDate: Date = .distantPast
    private var workoutStartDate: Date = .distantPast
    private var totalPausedTime: TimeInterval = 0
    private var timer: Timer?

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendAction(_ action: String) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["action": action], replyHandler: nil)
    }

    // MARK: - Local Timer

    private func startLocalTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.tick() }
        }
    }

    private func stopLocalTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard isRunning else { return }
        let now = Date.now
        let phaseElapsed = Int(now.timeIntervalSince(phaseStartDate))
        splitTimeRemaining = max(0, splitDuration - phaseElapsed)
        totalElapsed = Int(now.timeIntervalSince(workoutStartDate) - totalPausedTime)
    }

    // MARK: - Apply State

    private func apply(_ context: [String: Any]) {
        if let v = context["workoutActive"] as? Bool   { workoutActive = v }
        if let v = context["phaseTitle"]    as? String { phaseTitle = v }
        if let v = context["setLabel"]      as? String { setLabel = v }
        if let v = context["splitDuration"] as? Int    { splitDuration = v }

        if let v = context["phaseStartDate"] as? TimeInterval {
            phaseStartDate = Date(timeIntervalSince1970: v)
        }
        if let v = context["workoutStartDate"] as? TimeInterval {
            workoutStartDate = Date(timeIntervalSince1970: v)
        }
        if let v = context["totalPausedTime"] as? TimeInterval {
            totalPausedTime = v
        }

        if let v = context["isRunning"] as? Bool {
            isRunning = v
            if v {
                tick() // Immediate update before first timer fire
                startLocalTimer()
            } else {
                stopLocalTimer()
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        let context = session.receivedApplicationContext
        guard !context.isEmpty else { return }
        DispatchQueue.main.async { self.apply(context) }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.apply(message) }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.apply(applicationContext) }
    }
}
