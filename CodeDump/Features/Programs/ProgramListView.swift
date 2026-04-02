import SwiftUI
import SwiftData

struct ProgramListView: View {
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<TrainingProgram> { $0.isActive == true })
    private var activePrograms: [TrainingProgram]

    @State private var selectedTemplate: ProgramTemplate?
    @State private var viewModel = ProgramViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.outrunBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Active program banner
                        if let active = activePrograms.first,
                           let template = active.programTemplate {
                            activeProgramBanner(active, template: template)
                        }

                        // Program cards
                        ForEach(ProgramTemplate.library) { template in
                            programCard(template)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .outrunTitle("PROGRAMS")
            .outrunNavBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.outrunCyan)
                }
            }
            .sheet(item: $selectedTemplate) { template in
                ProgramDetailView(template: template, path: $path)
            }
        }
    }

    // MARK: - Active Program Banner

    private func activeProgramBanner(_ program: TrainingProgram, template: ProgramTemplate) -> some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                path.append(Route.activeProgram)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.outrunOrange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ACTIVE PROGRAM")
                        .font(.outrunFuture(9))
                        .foregroundColor(.outrunOrange.opacity(0.7))
                    Text(template.name.uppercased())
                        .font(.outrunFuture(14))
                        .foregroundColor(.outrunYellow)
                    Text("Week \(program.currentWeek) / \(template.durationWeeks)")
                        .font(.outrunFuture(10))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.outrunCyan.opacity(0.5))
            }
            .padding(14)
            .background(Color.outrunOrange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.outrunOrange.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Program Card

    private func programCard(_ template: ProgramTemplate) -> some View {
        Button {
            selectedTemplate = template
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Text(template.name.uppercased())
                        .font(.outrunFuture(16))
                        .foregroundColor(.outrunYellow)

                    Spacer()

                    difficultyBadge(template.difficulty)
                }

                // Info row
                HStack(spacing: 12) {
                    infoChip(icon: "calendar", text: "\(template.daysPerWeek) days/wk", color: .outrunCyan)
                    infoChip(icon: "clock", text: "\(template.durationWeeks) weeks", color: .outrunGreen)
                    infoChip(icon: "figure.strengthtraining.traditional", text: "\(template.dayTemplates.flatMap(\.exerciseTemplateIDs).count) exercises", color: .outrunPurple)
                }

                // Description
                Text(template.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(16)
            .background(Color.outrunSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.outrunSurface, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func difficultyBadge(_ difficulty: ProgramDifficulty) -> some View {
        let color: Color = {
            switch difficulty {
            case .beginner:     return .outrunGreen
            case .intermediate: return .outrunCyan
            case .advanced:     return .outrunPink
            }
        }()

        return Text(difficulty.displayName.uppercased())
            .font(.outrunFuture(8))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
    }

    private func infoChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.outrunFuture(9))
        }
        .foregroundColor(color.opacity(0.8))
    }
}
