import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @Binding var path: NavigationPath
    @State private var showingEditor = false
    @State private var showingHistory = false

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                List {
                    timingSection
                    structureSection
                    if !workout.sortedExercises.isEmpty {
                        exercisesSection
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                beginButton
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.large)
        .outrunNavBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    ShareLink(
                        item: WorkoutExport(from: workout),
                        preview: SharePreview(workout.name, image: Image(systemName: "figure.strengthtraining.traditional"))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.outrunCyan)
                    }
                    .accessibilityLabel("Share workout")
                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.outrunCyan)
                    }
                    .accessibilityLabel("Workout history")
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.outrunCyan)
                    }
                    .accessibilityLabel("Edit workout")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            WorkoutBuilderView(editing: workout)
        }
        .sheet(isPresented: $showingHistory) {
            NavigationStack {
                WorkoutHistoryView(workout: workout)
            }
        }
    }

    // MARK: - Sections

    private var timingSection: some View {
        Section {
            if workout.warmupLength > 0 {
                detailRow("Warmup", value: workout.warmupLength.formattedTime, color: .outrunGreen)
            }
            if workout.cooldownLength > 0 {
                detailRow("Cooldown", value: workout.cooldownLength.formattedTime, color: .outrunGreen)
            }
            detailRow("Est. Duration", value: workout.totalDurationEstimate.formattedTime, color: .outrunCyan)
        } header: {
            sectionLabel("Timing")
        }
        .listRowBackground(Color.outrunSurface)
    }

    private var structureSection: some View {
        Section {
            detailRow("Sets", value: "\(workout.numberOfSets)", color: .outrunYellow)
            detailRow("Exercises per Set", value: "\(workout.numberOfIntervals)", color: .outrunYellow)
            detailRow("Interval Length", value: workout.intervalLength.formattedTime, color: .outrunYellow)
            if workout.restLength > 0 {
                detailRow("Rest Between Exercises", value: workout.restLength.formattedTime, color: .outrunRed)
            }
            if workout.numberOfSets > 1 && workout.restBetweenSetLength > 0 {
                detailRow("Rest Between Sets", value: workout.restBetweenSetLength.formattedTime, color: .outrunRed)
            }
        } header: {
            sectionLabel("Structure")
        }
        .listRowBackground(Color.outrunSurface)
    }

    private var exercisesSection: some View {
        Section {
            ForEach(workout.sortedExercises) { exercise in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(exercise.name)
                            .font(.outrunFuture(15))
                            .foregroundColor(.outrunYellow)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        if exercise.reps > 0 {
                            Text("\(exercise.reps) reps")
                                .font(.outrunFuture(13))
                                .foregroundColor(.outrunCyan)
                        } else {
                            Text(exercise.splitLength.formattedTime)
                                .font(.outrunFuture(13))
                                .foregroundColor(.outrunCyan)
                        }
                    }

                    if !exercise.targetMuscleGroups.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(exercise.targetMuscleGroups, id: \.self) { muscle in
                                HStack(spacing: 2) {
                                    Image(systemName: muscle.icon)
                                        .font(.system(size: 8))
                                    Text(muscle.displayName)
                                        .font(.outrunFuture(8))
                                }
                                .foregroundColor(.outrunCyan.opacity(0.6))
                            }

                            Label(exercise.equipment.displayName, systemImage: exercise.equipment.icon)
                                .font(.outrunFuture(8))
                                .foregroundColor(.outrunPurple.opacity(0.6))
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Muscles: \(exercise.targetMuscleGroups.map(\.displayName).joined(separator: ", ")). Equipment: \(exercise.equipment.displayName)")
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            sectionLabel("Exercises")
        }
        .listRowBackground(Color.outrunSurface)
    }

    // MARK: - Begin Button

    private var beginButton: some View {
        Button {
            path.append(Route.session(workout))
        } label: {
            Text("BEGIN")
                .font(.outrunFuture(26))
                .foregroundColor(.outrunBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.outrunCyan)
                .cornerRadius(10)
                .minimumScaleFactor(0.7)
        }
        .accessibilityHint("Start \(workout.name) workout")
    }

    // MARK: - Helpers

    private func detailRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.outrunFuture(14))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.outrunFuture(14))
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.outrunFuture(11))
            .foregroundColor(.outrunCyan)
    }
}
