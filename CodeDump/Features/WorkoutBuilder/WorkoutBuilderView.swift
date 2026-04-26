import SwiftUI

struct WorkoutBuilderView: View {
    @State private var viewModel: WorkoutBuilderViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingLibrary = false

    init(editing workout: Workout? = nil) {
        _viewModel = State(initialValue: WorkoutBuilderViewModel(editing: workout))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.outrunBackground.ignoresSafeArea()
                Form {
                    nameTypeSection
                    timingSection
                    structureSection
                    exercisesSection
                }
                .scrollContentBackground(.hidden)
            }
            .outrunTitle(viewModel.isEditing ? "EDIT WORKOUT" : "NEW WORKOUT")
            .outrunNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.outrunRed)
                        .font(.outrunFuture(14))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isEditing ? "Update" : "Save") {
                        viewModel.save(in: modelContext)
                        dismiss()
                    }
                    .foregroundColor(viewModel.isValid ? .outrunCyan : .gray)
                    .font(.outrunFuture(14))
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }

    // MARK: - Name & Type

    private var nameTypeSection: some View {
        let vm = Bindable(viewModel)
        return Section {
            TextField("Workout Name", text: vm.name)
                .font(.outrunFuture(16))
                .foregroundColor(.outrunYellow)
            Picker("Type", selection: vm.type) {
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .font(.outrunFuture(14))
            .foregroundColor(.white)
        } header: {
            builderHeader("IDENTITY")
        }
        .listRowBackground(Color.outrunSurface)
    }

    // MARK: - Timing

    private var timingSection: some View {
        let vm = Bindable(viewModel)
        return Section {
            durationStepper("Warmup",                    value: vm.warmupLength,         step: 15)
            durationStepper("Interval Length",           value: vm.intervalLength,        step: 5,  min: 5)
            durationStepper("Rest Between Exercises",    value: vm.restLength,            step: 5)
            durationStepper("Rest Between Sets",         value: vm.restBetweenSetLength,  step: 15)
            durationStepper("Cooldown",                  value: vm.cooldownLength,        step: 15)
        } header: {
            builderHeader("TIMING")
        }
        .listRowBackground(Color.outrunSurface)
    }

    // MARK: - Structure

    private var structureSection: some View {
        let vm = Bindable(viewModel)
        return Section {
            countStepper("Exercises per Set", value: vm.numberOfIntervals, min: 1, max: 20)
            countStepper("Number of Sets",    value: vm.numberOfSets,      min: 1, max: 20)
        } header: {
            builderHeader("STRUCTURE")
        }
        .listRowBackground(Color.outrunSurface)
    }

    // MARK: - Exercises

    @ViewBuilder
    private var exercisesSection: some View {
        Section {
            ForEach(viewModel.exercises.indices, id: \.self) { index in
                ExerciseBuilderRow(
                    exercise: Binding(
                        get: { self.viewModel.exercises[index] },
                        set: { self.viewModel.exercises[index] = $0 }
                    )
                )
            }
            .onDelete { offsets in viewModel.removeExercises(at: offsets) }
            .onMove  { src, dst in viewModel.moveExercises(from: src, to: dst) }

            HStack(spacing: 16) {
                Button {
                    showingLibrary = true
                } label: {
                    Label("From Library", systemImage: "books.vertical.fill")
                        .font(.outrunFuture(13))
                        .foregroundColor(.outrunCyan)
                }

                Button {
                    viewModel.addExercise()
                } label: {
                    Label("Add Blank", systemImage: "plus.circle")
                        .font(.outrunFuture(13))
                        .foregroundColor(.outrunPurple)
                }
            }
        } header: {
            builderHeader("EXERCISES")
        }
        .listRowBackground(Color.outrunSurface)
        .sheet(isPresented: $showingLibrary) {
            ExerciseLibraryView { item in
                viewModel.addExercise(from: item)
            }
        }
    }

    // MARK: - Reusable Controls

    private func durationStepper(_ label: String, value: Binding<Int>, step: Int, min: Int = 0) -> some View {
        HStack {
            Text(label)
                .font(.outrunFuture(13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Stepper(value: value, in: min...3600, step: step) {
                Text(value.wrappedValue.formattedTime)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.outrunYellow)
                    .frame(minWidth: 52, alignment: .trailing)
            }
        }
    }

    private func countStepper(_ label: String, value: Binding<Int>, min: Int, max: Int) -> some View {
        HStack {
            Text(label)
                .font(.outrunFuture(13))
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Stepper(value: value, in: min...max) {
                Text("\(value.wrappedValue)")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.outrunYellow)
                    .frame(minWidth: 32, alignment: .trailing)
            }
        }
    }

    private func builderHeader(_ text: String) -> some View {
        Text(text)
            .font(.outrunFuture(10))
            .foregroundColor(.outrunCyan)
    }
}

// MARK: - Exercise Row

struct ExerciseBuilderRow: View {
    @Binding var exercise: WorkoutBuilderViewModel.DraftExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Exercise name", text: $exercise.name)
                .font(.outrunFuture(15))
                .foregroundColor(.outrunYellow)

            HStack(spacing: 6) {
                // Exercise mode badge
                HStack(spacing: 2) {
                    Image(systemName: exercise.exerciseMode.icon)
                        .font(.system(size: 8))
                    Text(exercise.exerciseMode.displayName)
                        .font(.outrunFuture(7))
                }
                .foregroundColor(.outrunYellow.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.outrunYellow.opacity(0.1))
                .clipShape(Capsule())

                ForEach(exercise.targetMuscleGroups, id: \.self) { muscle in
                    HStack(spacing: 2) {
                        Image(systemName: muscle.icon)
                            .font(.system(size: 8))
                        Text(muscle.displayName)
                            .font(.outrunFuture(7))
                    }
                    .foregroundColor(.outrunCyan.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.outrunCyan.opacity(0.1))
                    .clipShape(Capsule())
                }

                HStack(spacing: 2) {
                    Image(systemName: exercise.equipment.icon)
                        .font(.system(size: 8))
                    Text(exercise.equipment.displayName)
                        .font(.outrunFuture(7))
                }
                .foregroundColor(.outrunPurple.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.outrunPurple.opacity(0.1))
                .clipShape(Capsule())
            }

            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundColor(.outrunCyan.opacity(0.7))
                    Stepper(value: $exercise.splitLength, in: 5...600, step: 5) {
                        Text(exercise.splitLength.formattedTime)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.outrunCyan)
                    }
                }

                if exercise.exerciseMode != .timeBased {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.outrunGreen.opacity(0.7))
                        Stepper(value: $exercise.reps, in: 0...200) {
                            Text(exercise.reps == 0 ? "timed" : "\(exercise.reps) reps")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.outrunGreen)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
