import SwiftUI

struct WorkoutCompletedView: View {
    let totalTime: Int
    let exercisesCompleted: Int
    let setsCompleted: Int
    let workoutName: String
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Header
                VStack(spacing: 8) {
                    Text("WORKOUT")
                        .font(.outrunFuture(20))
                        .foregroundColor(.outrunCyan)
                    Text("COMPLETE")
                        .font(.outrunFuture(52))
                        .foregroundColor(.outrunYellow)
                    Text(workoutName.uppercased())
                        .font(.outrunFuture(18))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Stats
                VStack(spacing: 12) {
                    statRow(label: "TOTAL TIME",  value: totalTime.formattedTimeLong, color: .outrunCyan)
                    statRow(label: "EXERCISES",   value: "\(exercisesCompleted)",     color: .outrunYellow)
                    statRow(label: "SETS",        value: "\(setsCompleted)",          color: .outrunGreen)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Done button
                Button(action: onDone) {
                    Text("DONE")
                        .font(.outrunFuture(28))
                        .foregroundColor(.outrunBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.outrunCyan)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.outrunFuture(14))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.outrunBlack)
        .cornerRadius(8)
    }
}
