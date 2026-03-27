import SwiftUI

struct OnboardingProgramStep: View {
    @Binding var selectedProgram: ProgramTemplate?
    let userEquipment: Set<Equipment>

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 32))
                    .foregroundColor(.outrunCyan)

                Text("PICK A PROGRAM")
                    .font(.outrunFuture(24))
                    .foregroundColor(.white)

                Text("Follow a structured plan, or skip and build your own.")
                    .font(.outrunFuture(12))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Program list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ProgramTemplate.library, id: \.id) { program in
                        programCard(program)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 360)
        }
    }

    // MARK: - Program Card

    private func programCard(_ program: ProgramTemplate) -> some View {
        let isSelected = selectedProgram?.id == program.id
        let hasEquipment = program.requiredEquipment.isSubset(of: userEquipment)
        let difficultyColor = difficultyDisplayColor(program.difficulty)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedProgram = isSelected ? nil : program
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(program.name.uppercased())
                        .font(.outrunFuture(14))
                        .foregroundColor(isSelected ? .outrunCyan : .white)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.outrunCyan)
                    }
                }

                Text(program.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label("\(program.daysPerWeek)x/wk", systemImage: "calendar")
                    Label("\(program.durationWeeks) weeks", systemImage: "clock")
                    Text(program.difficulty.displayName)
                        .foregroundColor(difficultyColor)
                }
                .font(.outrunFuture(10))
                .foregroundColor(.white.opacity(0.4))

                if !hasEquipment {
                    Label("Needs equipment you don't have", systemImage: "exclamationmark.triangle.fill")
                        .font(.outrunFuture(9))
                        .foregroundColor(.outrunOrange)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.outrunCyan.opacity(0.15) : Color.outrunSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.outrunCyan : Color.outrunPurple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func difficultyDisplayColor(_ difficulty: ProgramDifficulty) -> Color {
        switch difficulty {
        case .beginner:     return .outrunGreen
        case .intermediate: return .outrunCyan
        case .advanced:     return .outrunPink
        }
    }
}
