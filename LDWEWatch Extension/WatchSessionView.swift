import SwiftUI

struct WatchSessionView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        Group {
            if connectivity.workoutActive {
                sessionView
            } else {
                idleView
            }
        }
        .background(.black)
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 36))
                .foregroundColor(.cyan)

            Text("LAZER DRAGON")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)

            Text("Start a workout on\nyour iPhone to see\nprogress here.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Active Session

    private var sessionView: some View {
        VStack(spacing: 6) {
            // Phase title
            Text(connectivity.phaseTitle)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            // Progress ring with countdown
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progressRing)
                    .stroke(Color.cyan, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progressRing)
                Text(formattedTime)
                    .font(.system(size: 20, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 70, height: 70)

            // Set label
            if !connectivity.setLabel.isEmpty {
                Text(connectivity.setLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Controls
            HStack(spacing: 20) {
                Button { connectivity.sendAction("skipBack") } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)

                Button { connectivity.sendAction("playPause") } label: {
                    Image(systemName: connectivity.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .foregroundColor(.cyan)

                Button { connectivity.sendAction("skipForward") } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
            }
            .padding(.top, 4)
        }
        .padding()
    }

    private var progressRing: Double {
        guard connectivity.splitDuration > 0 else { return 1 }
        return max(0, Double(connectivity.splitTimeRemaining) / Double(connectivity.splitDuration))
    }

    private var formattedTime: String {
        let t = max(0, connectivity.splitTimeRemaining)
        let m = t / 60
        let s = t % 60
        return String(format: "%d:%02d", m, s)
    }
}
