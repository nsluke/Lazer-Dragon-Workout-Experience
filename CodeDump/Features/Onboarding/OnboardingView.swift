import SwiftUI

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case equipment
    case program
    case permissions
}

// MARK: - Onboarding View

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var selectedProgram: ProgramTemplate?

    @AppStorage("equipmentProfile") private var equipmentRaw: String = EquipmentProfile.encode(EquipmentProfile.commercialGymEquipment)
    @AppStorage("equipmentProfileConfigured") private var equipmentConfigured = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.outrunBlack.ignoresSafeArea()
            gridLines

            VStack(spacing: 0) {
                // Progress dots
                progressIndicator
                    .padding(.top, 16)

                Spacer()

                // Current step content
                Group {
                    switch step {
                    case .welcome:
                        OnboardingWelcomeStep()
                    case .equipment:
                        OnboardingEquipmentStep(
                            equipmentRaw: $equipmentRaw
                        )
                    case .program:
                        OnboardingProgramStep(
                            selectedProgram: $selectedProgram,
                            userEquipment: EquipmentProfile.decode(equipmentRaw)
                        )
                    case .permissions:
                        OnboardingPermissionsStep()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Navigation buttons
                bottomButtons
                    .padding(.bottom, 52)
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 10) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? Color.outrunCyan : Color.outrunPurple.opacity(0.4))
                    .frame(width: s == step ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            // Primary action
            Button(action: advanceStep) {
                Text(step == .permissions ? "LET'S GO" : "CONTINUE")
                    .font(.outrunFuture(20))
                    .foregroundColor(.outrunBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.outrunCyan)
                    .cornerRadius(12)
                    .shadow(color: .outrunCyan.opacity(0.4), radius: 16)
            }

            // Skip (not on welcome or last step)
            if step == .program {
                Button(action: advanceStep) {
                    Text("SKIP")
                        .font(.outrunFuture(13))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Navigation

    private func advanceStep() {
        if step == .equipment {
            equipmentConfigured = true
        }

        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else {
            // Final step — enroll in program if selected, then complete
            if let program = selectedProgram {
                enrollInProgram(program)
            }
            onComplete()
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            step = next
        }
    }

    private func enrollInProgram(_ template: ProgramTemplate) {
        let program = TrainingProgram(
            programTemplateID: template.id,
            durationWeeks: template.durationWeeks
        )
        modelContext.insert(program)
    }

    // MARK: - Grid Lines

    private var gridLines: some View {
        GeometryReader { geo in
            let count = 8
            let spacing = geo.size.width / CGFloat(count)
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    Rectangle()
                        .fill(Color.outrunPurple.opacity(0.15))
                        .frame(width: 1)
                        .offset(x: spacing * CGFloat(i) - geo.size.width / 2)
                }
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(Color.outrunPurple.opacity(0.1))
                        .frame(height: 1)
                        .offset(y: (geo.size.height / 11) * CGFloat(i) - geo.size.height / 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
}
