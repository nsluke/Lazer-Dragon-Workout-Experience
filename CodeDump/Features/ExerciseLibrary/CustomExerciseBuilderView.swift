import SwiftUI
import SwiftData

struct CustomExerciseBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedMuscles: Set<MuscleGroup> = []
    @State private var equipment: Equipment = .bodyweight
    @State private var instructions = ""
    @State private var defaultDuration: Int = 30
    @State private var defaultReps: Int = 0

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.outrunBackground.ignoresSafeArea()

                Form {
                    nameSection
                    muscleSection
                    equipmentSection
                    instructionsSection
                    defaultsSection
                }
                .scrollContentBackground(.hidden)
            }
            .outrunTitle("CUSTOM EXERCISE")
            .outrunNavBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.outrunCyan)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundColor(.outrunCyan)
                        .disabled(!canSave)
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            TextField("Exercise Name", text: $name)
                .font(.outrunFuture(16))
                .foregroundColor(.outrunYellow)
        } header: {
            sectionHeader("NAME")
        }
        .listRowBackground(Color.outrunSurface)
    }

    private var muscleSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(MuscleGroup.allCases) { muscle in
                    muscleToggle(muscle)
                }
            }
            .padding(.vertical, 4)
        } header: {
            sectionHeader("MUSCLE GROUPS")
        }
        .listRowBackground(Color.outrunSurface)
    }

    private func muscleToggle(_ muscle: MuscleGroup) -> some View {
        let isSelected = selectedMuscles.contains(muscle)
        return Button {
            if isSelected {
                selectedMuscles.remove(muscle)
            } else {
                selectedMuscles.insert(muscle)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: muscle.icon)
                    .font(.system(size: 10))
                Text(muscle.displayName)
                    .font(.outrunFuture(9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.outrunCyan.opacity(0.3) : Color.outrunBlack)
            .foregroundColor(isSelected ? .outrunCyan : .white.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.outrunCyan : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var equipmentSection: some View {
        Section {
            Picker("Equipment", selection: $equipment) {
                ForEach(Equipment.allCases) { equip in
                    Label(equip.displayName, systemImage: equip.icon)
                        .tag(equip)
                }
            }
            .pickerStyle(.menu)
            .font(.outrunFuture(13))
            .foregroundColor(.outrunPurple)
        } header: {
            sectionHeader("EQUIPMENT")
        }
        .listRowBackground(Color.outrunSurface)
    }

    private var instructionsSection: some View {
        Section {
            TextField("Brief instructions", text: $instructions, axis: .vertical)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2...4)
        } header: {
            sectionHeader("INSTRUCTIONS")
        }
        .listRowBackground(Color.outrunSurface)
    }

    private var defaultsSection: some View {
        Section {
            durationStepper("Duration", value: $defaultDuration, step: 5, min: 5)
            repsStepper("Reps", value: $defaultReps)
        } header: {
            sectionHeader("DEFAULTS")
        }
        .listRowBackground(Color.outrunSurface)
    }

    // MARK: - Controls

    private func durationStepper(_ label: String, value: Binding<Int>, step: Int, min: Int) -> some View {
        HStack {
            Text(label)
                .font(.outrunFuture(13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Stepper(value: value, in: min...600, step: step) {
                Text(value.wrappedValue.formattedTime)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.outrunCyan)
                    .frame(minWidth: 52, alignment: .trailing)
            }
        }
    }

    private func repsStepper(_ label: String, value: Binding<Int>) -> some View {
        HStack {
            Text(label)
                .font(.outrunFuture(13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Stepper(value: value, in: 0...200, step: 1) {
                Text(value.wrappedValue == 0 ? "Timed" : "\(value.wrappedValue)")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.outrunGreen)
                    .frame(minWidth: 52, alignment: .trailing)
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.outrunFuture(11))
            .foregroundColor(.outrunCyan.opacity(0.7))
    }

    // MARK: - Save

    private func save() {
        let template = CustomExerciseTemplate(
            name: name.trimmingCharacters(in: .whitespaces),
            muscleGroups: Array(selectedMuscles),
            equipment: equipment,
            instructions: instructions.trimmingCharacters(in: .whitespaces),
            defaultDuration: defaultDuration,
            defaultReps: defaultReps
        )
        modelContext.insert(template)
        dismiss()
    }
}
