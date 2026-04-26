import SwiftUI
import SwiftData

struct ProgramDetailView: View {
    let template: ProgramTemplate
    @Binding var path: NavigationPath

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProgramViewModel()
    @State private var expandedDay: String? = nil
    @State private var showingEnrollConfirm = false

    @AppStorage("equipmentProfile") private var equipmentRaw: String = EquipmentProfile.encode(EquipmentProfile.commercialGymEquipment)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.outrunBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            headerSection
                            scheduleStrip
                            equipmentSection
                            dayTemplatesSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100) // Space for button
                    }

                    enrollButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            .outrunTitle(template.name.uppercased())
            .outrunNavBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.outrunCyan)
                }
            }
            .alert("Start Program?", isPresented: $showingEnrollConfirm) {
                Button("Start") {
                    startProgram()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will replace any active program. Your workout history is kept.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Difficulty + duration badges
            HStack(spacing: 10) {
                difficultyBadge(template.difficulty)
                infoBadge(icon: "calendar", text: "\(template.daysPerWeek) days/week", color: .outrunCyan)
                infoBadge(icon: "clock", text: "\(template.durationWeeks) weeks", color: .outrunGreen)
            }

            Text(template.description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Weekly Schedule Strip

    private var scheduleStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WEEKLY SCHEDULE")
                .font(.outrunFuture(11))
                .foregroundColor(.outrunCyan.opacity(0.7))

            HStack(spacing: 0) {
                let labels = ["M", "T", "W", "T", "F", "S", "S"]
                ForEach(1...7, id: \.self) { weekday in
                    let dayTemplateID = template.schedule[weekday]
                    let dayLabel = dayTemplateID.flatMap { id in
                        template.dayTemplate(for: id)?.label
                    }

                    VStack(spacing: 4) {
                        Text(labels[weekday - 1])
                            .font(.outrunFuture(10))
                            .foregroundColor(dayLabel != nil ? .outrunCyan : .white.opacity(0.3))

                        if let label = dayLabel {
                            Text(abbreviate(label))
                                .font(.outrunFuture(8))
                                .foregroundColor(.outrunYellow)
                                .lineLimit(1)
                        } else {
                            Text("—")
                                .font(.outrunFuture(8))
                                .foregroundColor(.white.opacity(0.2))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(dayLabel != nil ? Color.outrunSurface : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(4)
            .background(Color.outrunSurface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Equipment

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EQUIPMENT NEEDED")
                .font(.outrunFuture(11))
                .foregroundColor(.outrunCyan.opacity(0.7))

            let required = template.requiredEquipment
            let userEquipment = EquipmentProfile.decode(equipmentRaw)
            let missing = required.subtracting(userEquipment)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(Array(required).sorted(by: { $0.rawValue < $1.rawValue })) { equip in
                    HStack(spacing: 4) {
                        Image(systemName: equip.icon)
                            .font(.system(size: 10))
                        Text(equip.displayName)
                            .font(.outrunFuture(9))
                    }
                    .foregroundColor(missing.contains(equip) ? .outrunOrange : .outrunGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(missing.contains(equip) ? Color.outrunOrange.opacity(0.1) : Color.outrunGreen.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            if !missing.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.outrunOrange)
                        .font(.system(size: 12))
                    Text("Some equipment not in your profile. Substitutions will be made.")
                        .font(.system(size: 12))
                        .foregroundColor(.outrunOrange.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Day Templates

    private var dayTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORKOUTS")
                .font(.outrunFuture(11))
                .foregroundColor(.outrunCyan.opacity(0.7))

            ForEach(template.dayTemplates) { day in
                dayTemplateCard(day)
            }
        }
    }

    private func dayTemplateCard(_ day: ProgramDayTemplate) -> some View {
        let isExpanded = expandedDay == day.id
        let lookup = Dictionary(uniqueKeysWithValues: ExerciseTemplate.library.map { ($0.id, $0) })

        return VStack(spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    expandedDay = isExpanded ? nil : day.id
                }
            } label: {
                HStack {
                    Text(day.label.uppercased())
                        .font(.outrunFuture(13))
                        .foregroundColor(.outrunYellow)

                    Spacer()

                    Text("\(day.exerciseTemplateIDs.count) exercises")
                        .font(.outrunFuture(9))
                        .foregroundColor(.white.opacity(0.4))

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.outrunCyan.opacity(0.5))
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            // Expanded exercise list
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(day.exerciseTemplateIDs, id: \.self) { templateID in
                        if let template = lookup[templateID] {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name)
                                        .font(.outrunFuture(12))
                                        .foregroundColor(.white.opacity(0.8))

                                    HStack(spacing: 6) {
                                        ForEach(template.muscles.prefix(2)) { muscle in
                                            HStack(spacing: 2) {
                                                Image(systemName: muscle.icon)
                                                    .font(.system(size: 8))
                                                Text(muscle.displayName)
                                                    .font(.outrunFuture(7))
                                            }
                                            .foregroundColor(.outrunCyan.opacity(0.6))
                                        }

                                        Label(template.equipment.displayName, systemImage: template.equipment.icon)
                                            .font(.outrunFuture(7))
                                            .foregroundColor(.outrunPurple.opacity(0.6))
                                    }
                                }

                                Spacer()

                                if template.defaultReps > 0 {
                                    Text("\(template.defaultReps) reps")
                                        .font(.outrunFuture(9))
                                        .foregroundColor(.outrunGreen.opacity(0.7))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color.outrunSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Enroll Button

    private var enrollButton: some View {
        Button {
            showingEnrollConfirm = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("START PROGRAM")
                    .font(.outrunFuture(20))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [.outrunPink, .outrunPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .outrunPink.opacity(0.3), radius: 16)
        }
    }

    // MARK: - Actions

    private func startProgram() {
        viewModel.enroll(in: template, context: modelContext)

        #if os(iOS)
        Task { await RecoveryAnalyzer.requestRecoveryAuthorization() }
        #endif

        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            path.append(Route.activeProgram)
        }
    }

    // MARK: - Helpers

    private func difficultyBadge(_ difficulty: ProgramDifficulty) -> some View {
        let color: Color = {
            switch difficulty {
            case .beginner:     return .outrunGreen
            case .intermediate: return .outrunCyan
            case .advanced:     return .outrunPink
            }
        }()

        return Text(difficulty.displayName.uppercased())
            .font(.outrunFuture(9))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
    }

    private func infoBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.outrunFuture(9))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private func abbreviate(_ label: String) -> String {
        // "Push A" → "PUSH A", "Full Body A" → "FB A", etc.
        let words = label.split(separator: " ")
        if words.count <= 2 { return label.uppercased() }
        // Take initials of first words + last word
        let initials = words.dropLast().map { String($0.prefix(1)) }.joined()
        return (initials + " " + words.last!).uppercased()
    }
}
