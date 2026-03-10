import AudioToolbox
import UIKit

/// Encapsulates all haptic and audio feedback for the workout session.
/// Must be called on the main thread.
struct FeedbackEngine {

    // MARK: - Haptics

    private static let impactHeavy  = UIImpactFeedbackGenerator(style: .heavy)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()

    /// Called on every phase transition.
    static func phaseChanged() {
        notification.notificationOccurred(.success)
    }

    /// Called when the workout finishes.
    static func workoutCompleted() {
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            notification.notificationOccurred(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            notification.notificationOccurred(.success)
        }
    }

    /// Called each second during the countdown. Provides a tick at 3, 2, 1.
    static func countdownTick(remainingSeconds: Int) {
        switch remainingSeconds {
        case 3:
            impactMedium.impactOccurred(intensity: 0.5)
            playTick()
        case 2:
            impactMedium.impactOccurred(intensity: 0.7)
            playTick()
        case 1:
            impactHeavy.impactOccurred()
            playTick()
        default:
            break
        }
    }

    // MARK: - Audio

    /// A short, sharp click — used for the 3-2-1 countdown.
    private static func playTick() {
        // System sound 1104 is a clean, short click available on all iOS devices.
        AudioServicesPlaySystemSound(1104)
    }

    /// A bright chime — used on phase transitions.
    static func playTransitionChime() {
        // System sound 1057 is a subtle, positive chime.
        AudioServicesPlaySystemSound(1057)
    }
}
