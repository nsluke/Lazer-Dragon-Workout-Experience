import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @Binding var path: NavigationPath

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
                HStack {
                    Text(exercise.name)
                        .font(.outrunFuture(15))
                        .foregroundColor(.outrunYellow)
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
        }
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
