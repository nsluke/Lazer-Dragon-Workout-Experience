import SwiftUI

struct WatchSessionView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
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
        .background(.black)
    }

    private var progressRing: Double {
        guard connectivity.splitDuration > 0 else { return 1 }
        return Double(connectivity.splitTimeRemaining) / Double(connectivity.splitDuration)
    }

    private var formattedTime: String {
        let m = connectivity.splitTimeRemaining / 60
        let s = connectivity.splitTimeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }
}
