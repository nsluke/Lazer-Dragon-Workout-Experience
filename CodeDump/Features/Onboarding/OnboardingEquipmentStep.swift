import SwiftUI

struct OnboardingEquipmentStep: View {
    @Binding var equipmentRaw: String

    @State private var selectedEquipment: Set<Equipment> = []
    @State private var selectedPreset: EquipmentProfile.Preset = .commercialGym

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.outrunYellow)

                Text("YOUR GYM")
                    .font(.outrunFuture(24))
                    .foregroundColor(.white)

                Text("What equipment do you have access to?")
                    .font(.outrunFuture(12))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Presets
            HStack(spacing: 8) {
                ForEach(EquipmentProfile.Preset.allCases) { preset in
                    presetButton(preset)
                }
            }
            .padding(.horizontal, 24)

            // Equipment grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    ForEach(Equipment.allCases) { equip in
                        equipmentToggle(equip)
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxHeight: 280)

            // Summary
            let exerciseCount = EquipmentProfile.availableExerciseCount(for: selectedEquipment)
            Text("\(selectedEquipment.count) equipment types \u{2022} \(exerciseCount) exercises available")
                .font(.outrunFuture(11))
                .foregroundColor(.outrunYellow)
        }
        .onAppear {
            selectedEquipment = EquipmentProfile.decode(equipmentRaw)
            selectedPreset = EquipmentProfile.inferPreset(from: selectedEquipment)
        }
        .onChange(of: selectedEquipment) {
            equipmentRaw = EquipmentProfile.encode(selectedEquipment)
            selectedPreset = EquipmentProfile.inferPreset(from: selectedEquipment)
        }
    }

    // MARK: - Preset Button

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

    // MARK: - Equipment Toggle

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
}
