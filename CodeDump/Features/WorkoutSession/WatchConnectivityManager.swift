import WatchConnectivity
import Foundation

/// Bridges the workout session to the Apple Watch companion app.
/// Sends state updates to the Watch and handles action commands from the Watch.
@MainActor
final class WatchConnectivityManager: NSObject {

    static let shared = WatchConnectivityManager()

    /// Called when the Watch sends a control action ("playPause", "skipForward", "skipBack").
    var actionHandler: ((String) -> Void)?

    /// Last payload sent — re-pushed when the Watch becomes reachable.
    private var lastPayload: [String: Any] = [:]

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendWorkoutState(_ payload: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        lastPayload = payload

        // Always update application context so the Watch gets it when it opens.
        try? WCSession.default.updateApplicationContext(payload)

        // Also send a live message if the Watch is open right now.
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error {
            print("[LDWE] WatchConnectivity activation failed: \(error.localizedDescription)")
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    /// Watch just became reachable (app foregrounded) — push the latest state immediately.
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor in
            guard !self.lastPayload.isEmpty else { return }
            session.sendMessage(self.lastPayload, replyHandler: nil)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        Task { @MainActor in
            self.actionHandler?(action)
        }
    }
}
