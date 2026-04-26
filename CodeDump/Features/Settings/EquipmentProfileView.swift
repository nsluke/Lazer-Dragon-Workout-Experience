import SwiftUI

struct EquipmentProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("equipmentProfile") private var equipmentRaw: String = EquipmentProfile.encode(EquipmentProfile.commercialGymEquipment)
    @AppStorage("equipmentProfileConfigured") private var isConfigured = false

    // Local editing state
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var selectedPreset: EquipmentProfile.Preset = .commercialGym

    var body: some View {
        NavigationStack {
            ZStack {
                Color.outrunBackground.ignoresSafeArea()

                Form {
                    presetSection
                    equipmentGridSection
                    summarySection
                }
                .scrollContentBackground(.hidden)
            }
            .outrunTitle("EQUIPMENT")
            .outrunNavBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.outrunCyan)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundColor(.outrunCyan)
                }
            }
            .onAppear { loadCurrent() }
        }
    }

    // MARK: - Sections

    private var presetSection: some View {
        Section {
            HStack(spacing: 8) {
                ForEach(EquipmentProfile.Preset.allCases) { preset in
                    presetButton(preset)
                }
            }
            .padding(.vertical, 4)
        } header: {
            sectionHeader("PRESET")
        }
        .listRowBackground(Color.outrunSurface)
    }

    private func presetButton(_ preset: EquipmentProfile.Preset) -> some View {
        let isActive = selectedPreset == preset
        return Button {
            selectedPreset = preset
            if preset != .custom {
                selectedEquipment = EquipmentProfile.equipment(for: preset)
            }
        } label: {
            Text(preset.rawValue.uppercased())
                .font(.outrunFuture(10))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? Color.outrunPink.opacity(0.35) : Color.outrunBlack)
                .foregroundColor(isActive ? .outrunPink : .white.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive ? Color.outrunPink : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var equipmentGridSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(Equipment.allCases) { equip in
                    equipmentToggle(equip)
                }
            }
            .padding(.vertical, 4)
        } header: {
            sectionHeader("AVAILABLE EQUIPMENT")
        }
        .listRowBackground(Color.outrunSurface)
    }

    private func equipmentToggle(_ equip: Equipment) -> some View {
        let isSelected = selectedEquipment.contains(equip)
        let isInteractive = selectedPreset == .custom

        return Button {
            guard isInteractive else { return }
            if isSelected {
                selectedEquipment.remove(equip)
            } else {
                selectedEquipment.insert(equip)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: equip.icon)
                    .font(.system(size: 14))
                Text(equip.displayName)
                    .font(.outrunFuture(11))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.outrunCyan.opacity(0.3) : Color.outrunBlack)
            .foregroundColor(isSelected ? .outrunCyan : .white.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.outrunCyan : Color.clear, lineWidth: 1)
            )
            .opacity(isInteractive || isSelected ? 1.0 : 0.4)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(isInteractive)
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                let count = selectedEquipment.count
                let exerciseCount = EquipmentProfile.availableExerciseCount(for: selectedEquipment)

                Text("\(count) equipment type\(count == 1 ? "" : "s") selected")
                    .font(.outrunFuture(11))
                    .foregroundColor(.outrunYellow)

                Text("\(exerciseCount) of \(ExerciseTemplate.library.count) exercises available")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 4)
        } header: {
            sectionHeader("SUMMARY")
        }
        .listRowBackground(Color.outrunSurface)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.outrunFuture(11))
            .foregroundColor(.outrunCyan.opacity(0.7))
    }

    private func loadCurrent() {
        selectedEquipment = EquipmentProfile.decode(equipmentRaw)
        selectedPreset = EquipmentProfile.inferPreset(from: selectedEquipment)
    }

    private func save() {
        equipmentRaw = EquipmentProfile.encode(selectedEquipment)
        isConfigured = true
        dismiss()
    }
}
