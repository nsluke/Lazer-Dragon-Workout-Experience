import WatchConnectivity
import Foundation

/// Bridges the workout session to the Apple Watch companion app.
/// Sends state updates to the Watch and handles action commands from the Watch.
@MainActor
final class WatchConnectivityManager: NSObject {

    static let shared = WatchConnectivityManager()

    /// Called when the Watch sends a control action ("playPause", "skipForward", "skipBack").
    var actionHandler: ((String) -> Void)?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendWorkoutState(_ payload: [String: Any]) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(payload, replyHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String else { return }
        Task { @MainActor in
            self.actionHandler?(action)
        }
    }
}
