import WatchConnectivity
import Foundation

/// Receives workout state from the iPhone and exposes it as published properties.
/// Also sends control actions back to the iPhone.
final class WatchConnectivityManager: NSObject, ObservableObject {

    @Published var phaseTitle: String = "WAITING"
    @Published var setLabel: String = ""
    @Published var splitTimeRemaining: Int = 0
    @Published var splitDuration: Int = 1
    @Published var totalElapsed: Int = 0
    @Published var isRunning: Bool = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendAction(_ action: String) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["action": action], replyHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            if let v = message["phaseTitle"] as? String         { self.phaseTitle = v }
            if let v = message["setLabel"] as? String           { self.setLabel = v }
            if let v = message["splitTimeRemaining"] as? Int    { self.splitTimeRemaining = v }
            if let v = message["splitDuration"] as? Int         { self.splitDuration = v }
            if let v = message["totalElapsed"] as? Int          { self.totalElapsed = v }
            if let v = message["isRunning"] as? Bool            { self.isRunning = v }
        }
    }
}
