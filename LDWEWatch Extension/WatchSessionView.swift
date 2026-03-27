import SwiftUI
import WatchKit

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
        .onChange(of: connectivity.phaseTitle) {
            WKInterfaceDevice.current().play(.notification)
        }
        .onChange(of: connectivity.workoutActive) {
            if connectivity.workoutActive {
                WKInterfaceDevice.current().play(.start)
            } else {
                WKInterfaceDevice.current().play(.success)
            }
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .font(.system(size: 36))
                .foregroundColor(.cyan)

            Text("LAZER DRAGON")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)

            if let lastDate = connectivity.lastWorkoutDate {
                Text("Last workout")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                Text(lastDate, style: .relative)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.cyan.opacity(0.8))
                    + Text(" ago")
                    .font(.system(size: 12))
                    .foregroundColor(.cyan.opacity(0.8))
            }

            Spacer().frame(height: 4)

            Label("START ON iPHONE", systemImage: "iphone")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
    }

    // MARK: - Active Session

    private var sessionView: some View {
        VStack(spacing: 6) {
            // Phase title + exercise name
            VStack(spacing: 2) {
                Text(connectivity.phaseTitle)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if !connectivity.exerciseName.isEmpty {
                    Text(connectivity.exerciseName)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }

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

            // Set label + total elapsed
            HStack {
                if !connectivity.setLabel.isEmpty {
                    Text(connectivity.setLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(formattedTotalElapsed)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }

            // Controls
            HStack(spacing: 20) {
                Button {
                    connectivity.sendAction("skipBack")
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)

                Button {
                    connectivity.sendAction("playPause")
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Image(systemName: connectivity.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                .foregroundColor(.cyan)

                Button {
                    connectivity.sendAction("skipForward")
                    WKInterfaceDevice.current().play(.click)
                } label: {
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

    private var formattedTotalElapsed: String {
        let t = max(0, connectivity.totalElapsed)
        let m = t / 60
        let s = t % 60
        return String(format: "%d:%02d", m, s)
    }
}
