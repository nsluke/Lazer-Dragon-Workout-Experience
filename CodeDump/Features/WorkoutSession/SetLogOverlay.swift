import SwiftUI

struct SetLogOverlay: View {
    var viewModel: WorkoutSessionViewModel
    @State private var weightText: String = ""
    @State private var repsValue: Int = 0
    @State private var rpeValue: Int = 0
    @State private var cachedSuggestion: OverloadSuggestion? = nil
    @FocusState private var weightFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            card
        }
        .onAppear {
            if let pending = viewModel.pendingLog {
                repsValue = pending.targetReps
            }
            computeSuggestion()
        }
        .onChange(of: viewModel.pendingLog?.exerciseName) {
            // Reset fields when a new exercise log appears
            weightText = ""
            rpeValue = 0
            if let pending = viewModel.pendingLog {
                repsValue = pending.targetReps
            }
            computeSuggestion()
        }
    }

    private func computeSuggestion() {
        guard let pending = viewModel.pendingLog,
              let templateID = pending.exerciseTemplateID else {
            cachedSuggestion = nil
            return
        }
        cachedSuggestion = OverloadSuggestion.suggest(
            for: templateID,
            currentSetIndex: pending.setIndex,
            allLogs: viewModel.historicalLogs
        )
    }

    private var card: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("LOG SET")
                    .font(.outrunFuture(12))
                    .foregroundColor(.outrunCyan)
                Spacer()
                Text(viewModel.pendingLog?.exerciseName.uppercased() ?? "")
                    .font(.outrunFuture(11))
                    .foregroundColor(.outrunYellow)
                    .lineLimit(1)
            }

            // Progressive overload suggestion
            if let suggestion = cachedSuggestion {
                suggestionBanner(suggestion)
            }

            // Inputs
            HStack(spacing: 16) {
                // Weight
                VStack(spacing: 4) {
                    Text("WEIGHT")
                        .font(.outrunFuture(8))
                        .foregroundColor(.outrunCyan.opacity(0.6))
                        .minimumScaleFactor(0.7)
                    TextField("--", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.outrunCyan)
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                        .focused($weightFocused)
                        .accessibilityLabel("Weight in pounds")
                    Text("lbs")
                        .font(.outrunFuture(8))
                        .foregroundColor(.outrunCyan.opacity(0.4))
                        .accessibilityHidden(true)
                }

                // Reps
                VStack(spacing: 4) {
                    Text("REPS")
                        .font(.outrunFuture(8))
                        .foregroundColor(.outrunGreen.opacity(0.6))
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 8) {
                        Button {
                            if repsValue > 0 { repsValue -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.outrunGreen.opacity(0.6))
                        }
                        .accessibilityLabel("Decrease reps")
                        Text("\(repsValue)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.outrunGreen)
                            .frame(minWidth: 32)
                        Button {
                            repsValue += 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.outrunGreen.opacity(0.6))
                        }
                        .accessibilityLabel("Increase reps")
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Reps: \(repsValue)")

                // RPE
                VStack(spacing: 4) {
                    Text("RPE")
                        .font(.outrunFuture(8))
                        .foregroundColor(.outrunOrange.opacity(0.6))
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 8) {
                        Button {
                            if rpeValue > 0 { rpeValue -= 1 }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.outrunOrange.opacity(0.6))
                        }
                        .accessibilityLabel("Decrease RPE")
                        Text(rpeValue == 0 ? "--" : "\(rpeValue)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.outrunOrange)
                            .frame(minWidth: 32)
                        Button {
                            if rpeValue < 10 { rpeValue += 1 }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.outrunOrange.opacity(0.6))
                        }
                        .accessibilityLabel("Increase RPE")
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("RPE: \(rpeValue == 0 ? "not set" : "\(rpeValue) out of 10")")
            }

            // Buttons
            HStack(spacing: 16) {
                Button {
                    viewModel.skipSetLog()
                } label: {
                    Text("SKIP")
                        .font(.outrunFuture(14))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.outrunSurface)
                        .cornerRadius(8)
                }

                Button {
                    saveAndCommit()
                } label: {
                    Text("SAVE")
                        .font(.outrunFuture(14))
                        .foregroundColor(.outrunBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.outrunCyan)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.outrunBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.outrunCyan.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .contentShape(Rectangle())
    }

    private func suggestionBanner(_ suggestion: OverloadSuggestion) -> some View {
        let isDeload = suggestion.isDeloadSuggested
        let accentColor: Color = isDeload ? .outrunOrange : .outrunGreen
        let iconName = isDeload ? "arrow.down.circle.fill" : "arrow.up.circle.fill"

        return HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundColor(accentColor)

            Text(suggestion.message)
                .font(.outrunFuture(9))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(2)

            Spacer(minLength: 0)

            Text("TAP")
                .font(.outrunFuture(7))
                .foregroundColor(accentColor.opacity(0.6))
        }
        .padding(10)
        .background(accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            weightText = formatWeight(suggestion.suggestedWeight)
            repsValue = suggestion.suggestedReps
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(suggestion.message)
        .accessibilityHint("Tap to auto-fill suggested weight and reps")
        .accessibilityAddTraits(.isButton)
    }

    private func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(weight))
            : String(format: "%.1f", weight)
    }

    private func saveAndCommit() {
        weightFocused = false
        guard var pending = viewModel.pendingLog else { return }
        pending.weight = Double(weightText)
        pending.reps = repsValue > 0 ? repsValue : nil
        pending.rpe = rpeValue > 0 ? rpeValue : nil
        viewModel.pendingLog = pending
        viewModel.commitSetLog()
    }
}
