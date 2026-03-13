import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    let onSelect: (ExercisePickerItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomExerciseTemplate.name) private var customTemplates: [CustomExerciseTemplate]

    @State private var searchText = ""
    @State private var selectedMuscles: Set<MuscleGroup> = []
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var showingCustomBuilder = false

    private var allItems: [ExercisePickerItem] {
        let builtIn = ExerciseTemplate.library.map { ExercisePickerItem(from: $0) }
        let custom = customTemplates.map { ExercisePickerItem(from: $0) }
        let merged = custom + builtIn
        return merged.filter { item in
            (selectedMuscles.isEmpty || item.muscles.contains(where: { selectedMuscles.contains($0) }))
            && (selectedEquipment.isEmpty || selectedEquipment.contains(item.equipment))
            && (searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText))
        }
    }

    private var groupedItems: [(MuscleGroup, [ExercisePickerItem])] {
        let grouped = Dictionary(grouping: allItems, by: \.primaryMuscle)
        return MuscleGroup.allCases.compactMap { muscle in
            guard let items = grouped[muscle], !items.isEmpty else { return nil }
            return (muscle, items)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.outrunBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterChips
                    exerciseList
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("EXERCISE LIBRARY")
            .navigationBarTitleDisplayMode(.inline)
            .outrunNavBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.outrunCyan)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCustomBuilder = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.outrunCyan)
                    }
                    .accessibilityLabel("Create custom exercise")
                }
            }
            .sheet(isPresented: $showingCustomBuilder) {
                CustomExerciseBuilderView()
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MuscleGroup.allCases) { muscle in
                        filterChip(
                            label: muscle.displayName,
                            icon: muscle.icon,
                            isSelected: selectedMuscles.contains(muscle)
                        ) {
                            if selectedMuscles.contains(muscle) {
                                selectedMuscles.remove(muscle)
                            } else {
                                selectedMuscles.insert(muscle)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Equipment.allCases) { equip in
                        filterChip(
                            label: equip.displayName,
                            icon: equip.icon,
                            isSelected: selectedEquipment.contains(equip)
                        ) {
                            if selectedEquipment.contains(equip) {
                                selectedEquipment.remove(equip)
                            } else {
                                selectedEquipment.insert(equip)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }

    private func filterChip(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.outrunFuture(9))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.outrunCyan.opacity(0.3) : Color.outrunSurface)
            .foregroundColor(isSelected ? .outrunCyan : .white.opacity(0.6))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.outrunCyan : Color.clear, lineWidth: 1))
        }
        .accessibilityLabel("Filter: \(label)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        List {
            ForEach(groupedItems, id: \.0) { muscle, items in
                Section {
                    ForEach(items) { item in
                        exerciseRow(item)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: muscle.icon)
                        Text(muscle.displayName.uppercased())
                    }
                    .font(.outrunFuture(11))
                    .foregroundColor(.outrunCyan)
                }
                .listRowBackground(Color.outrunSurface)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func exerciseRow(_ item: ExercisePickerItem) -> some View {
        Button {
            onSelect(item)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(.outrunFuture(14))
                        .foregroundColor(.outrunYellow)
                    Spacer()
                    if item.isCustom {
                        Text("CUSTOM")
                            .font(.outrunFuture(8))
                            .foregroundColor(.outrunPink)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.outrunPink.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    Label(item.equipment.displayName, systemImage: item.equipment.icon)
                        .font(.outrunFuture(9))
                        .foregroundColor(.outrunPurple.opacity(0.8))

                    if item.defaultReps > 0 {
                        Text("\(item.defaultReps) reps")
                            .font(.outrunFuture(9))
                            .foregroundColor(.outrunGreen.opacity(0.8))
                    } else {
                        Text(item.defaultDuration.formattedTime)
                            .font(.outrunFuture(9))
                            .foregroundColor(.outrunCyan.opacity(0.8))
                    }
                }

                if !item.instructions.isEmpty {
                    Text(item.instructions)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityHint("Tap to select this exercise")
    }
}
