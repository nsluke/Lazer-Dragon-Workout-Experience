import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.createdAt) private var workouts: [Workout]
    @State private var showingBuilder = false
    @State private var showingNotificationSettings = false
    @State private var showingEquipmentProfile = false
    @State private var showingQuickStart = false
    @State private var showingPrograms = false
    @State private var editingWorkout: Workout? = nil

    @Query(filter: #Predicate<TrainingProgram> { $0.isActive == true })
    private var activePrograms: [TrainingProgram]

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            if workouts.isEmpty {
                emptyState
            } else {
                workoutList
            }
        }
        .outrunTitle("WORKOUTS")
        .outrunNavBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showingEquipmentProfile = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.outrunCyan)
                    }
                    .accessibilityLabel("Settings")
                    Button {
                        showingNotificationSettings = true
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(.outrunCyan)
                    }
                    .accessibilityLabel("Notifications")
                    Button {
                        showingBuilder = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.outrunCyan)
                            .fontWeight(.bold)
                    }
                    .accessibilityLabel("Create workout")
                }
            }
        }
        .sheet(isPresented: $showingBuilder) {
            WorkoutBuilderView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NavigationStack { NotificationSettingsView() }
        }
        .sheet(item: $editingWorkout) { workout in
            WorkoutBuilderView(editing: workout)
        }
        .sheet(isPresented: $showingEquipmentProfile) {
            EquipmentProfileView()
        }
        .sheet(isPresented: $showingQuickStart) {
            QuickStartView(path: $path)
        }
        .sheet(isPresented: $showingPrograms) {
            ProgramListView(path: $path)
        }
        .onAppear(perform: seedIfNeeded)
    }

    // MARK: - List

    private var workoutList: some View {
        List {
            // Quick Start banner
            Section {
                Button {
                    showingQuickStart = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("QUICK START")
                            .font(.outrunFuture(16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.outrunPink, .outrunPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: .outrunPink.opacity(0.25), radius: 12)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
            }

            // Programs banner
            Section {
                if let active = activePrograms.first,
                   let template = active.programTemplate {
                    // Active program indicator
                    Button {
                        path.append(Route.activeProgram)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.outrunOrange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ACTIVE: \(template.name.uppercased())")
                                    .font(.outrunFuture(14))
                                    .foregroundColor(.outrunYellow)
                                Text("Week \(active.currentWeek) / \(template.durationWeeks)")
                                    .font(.outrunFuture(10))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.outrunCyan.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(
                            LinearGradient(
                                colors: [.outrunCyan.opacity(0.2), .outrunGreen.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.outrunCyan.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        showingPrograms = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.run")
                                .font(.system(size: 16, weight: .bold))
                            Text("PROGRAMS")
                                .font(.outrunFuture(16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.outrunCyan, .outrunGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: .outrunCyan.opacity(0.25), radius: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)

            ForEach(workouts) { workout in
                Button {
                    path.append(Route.detail(workout))
                } label: {
                    WorkoutRow(workout: workout)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.outrunBackground)
                .listRowSeparatorTint(Color.outrunSurface)
                .swipeActions(edge: .leading) {
                    Button {
                        editingWorkout = workout
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.outrunCyan)
                }
            }
            .onDelete(perform: deleteWorkouts)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.outrunYellow.opacity(0.4))

                Text("NO WORKOUTS")
                    .font(.outrunFuture(28))
                    .foregroundColor(.outrunCyan)

                Text("Build your first workout\nand start training.")
                    .font(.outrunFuture(14))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 14) {
                Button {
                    showingQuickStart = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bolt.fill")
                            .fontWeight(.bold)
                        Text("QUICK START")
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

                Button {
                    showingPrograms = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.run")
                            .fontWeight(.bold)
                        Text("PROGRAMS")
                            .font(.outrunFuture(20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.outrunCyan, .outrunGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .outrunCyan.opacity(0.3), radius: 16)
                }

                Button {
                    showingBuilder = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                        Text("CREATE WORKOUT")
                            .font(.outrunFuture(20))
                    }
                    .foregroundColor(.outrunBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.outrunYellow)
                    .cornerRadius(12)
                    .shadow(color: .outrunYellow.opacity(0.3), radius: 16)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Actions

    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(workouts[index])
        }
    }

    // MARK: - Seed Data

    private func seedIfNeeded() {
        guard workouts.isEmpty else { return }

        let lookup = Dictionary(uniqueKeysWithValues: ExerciseTemplate.library.map { ($0.id, $0) })

        func makeExercise(_ templateID: String, order: Int) -> Exercise {
            let t = lookup[templateID]
            return Exercise(
                order: order,
                name: t?.name ?? templateID,
                splitLength: t?.defaultDuration ?? 45,
                reps: t?.defaultReps ?? 10,
                targetMuscleGroupsRaw: t?.muscles.map(\.rawValue).joined(separator: ",") ?? "",
                equipmentRaw: t?.equipment.rawValue ?? "bodyweight",
                templateID: templateID
            )
        }

        // Easy Day — bodyweight basics, short intervals, long rest
        let easy = Workout(
            name: "Easy Day",
            type: .strength,
            warmupLength: 120,
            intervalLength: 30,
            restLength: 45,
            numberOfIntervals: 5,
            numberOfSets: 2,
            restBetweenSetLength: 90,
            cooldownLength: 60
        )
        let easyExercises = [
            "push-ups", "bodyweight-squats", "plank", "lunges", "crunches"
        ]

        // Intermediate Day — dumbbells, moderate pace
        let intermediate = Workout(
            name: "Intermediate Day",
            type: .strength,
            warmupLength: 120,
            intervalLength: 45,
            restLength: 30,
            numberOfIntervals: 7,
            numberOfSets: 3,
            restBetweenSetLength: 90,
            cooldownLength: 60
        )
        let intermediateExercises = [
            "dumbbell-bench-press", "dumbbell-rows", "dumbbell-shoulder-press",
            "dumbbell-bicep-curls", "tricep-dips", "goblet-squats", "dumbbell-lunges"
        ]

        // Hard Day — barbell compounds, high volume
        let hard = Workout(
            name: "Hard Day",
            type: .strength,
            warmupLength: 180,
            intervalLength: 60,
            restLength: 20,
            numberOfIntervals: 8,
            numberOfSets: 4,
            restBetweenSetLength: 120,
            cooldownLength: 90
        )
        let hardExercises = [
            "barbell-bench-press", "barbell-rows", "overhead-press",
            "barbell-squats", "romanian-deadlift", "pull-ups",
            "barbell-bicep-curls", "skull-crushers"
        ]

        // CHALLENGE THE LAZER DRAGON — brutal HIIT gauntlet
        let dragon = Workout(
            name: "CHALLENGE THE LAZER DRAGON",
            type: .hiit,
            warmupLength: 120,
            intervalLength: 45,
            restLength: 10,
            numberOfIntervals: 10,
            numberOfSets: 3,
            restBetweenSetLength: 60,
            cooldownLength: 120
        )
        let dragonExercises = [
            "burpees", "thrusters", "kettlebell-swings", "battle-ropes",
            "box-jumps", "pull-ups", "push-ups", "mountain-climbers",
            "barbell-squats", "plank"
        ]

        let all: [(Workout, [String])] = [
            (easy, easyExercises),
            (intermediate, intermediateExercises),
            (hard, hardExercises),
            (dragon, dragonExercises),
        ]

        for (workout, templateIDs) in all {
            modelContext.insert(workout)
            for (i, tid) in templateIDs.enumerated() {
                let ex = makeExercise(tid, order: i)
                ex.workout = workout
                workout.exercises.append(ex)
                modelContext.insert(ex)
            }
        }
        try? modelContext.save()
    }
}

// MARK: - Workout Row

struct WorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.outrunFuture(22))
                    .foregroundColor(.outrunYellow)
                    .minimumScaleFactor(0.7)
                Text("\(workout.exercises.count) exercises  ·  \(workout.numberOfSets) set\(workout.numberOfSets == 1 ? "" : "s")  ·  ~\(workout.totalDurationEstimate.formattedTime)\(workout.sessions.isEmpty ? "" : "  ·  \(workout.sessions.count) session\(workout.sessions.count == 1 ? "" : "s")")")
                    .font(.outrunFuture(12))
                    .foregroundColor(.outrunCyan.opacity(0.8))
                    .minimumScaleFactor(0.7)
            }
            Spacer()
            Text(workout.workoutType.rawValue)
                .font(.outrunFuture(11))
                .foregroundColor(.outrunPurple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.outrunBlack)
                .cornerRadius(4)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(workout.name), \(workout.workoutType.rawValue). \(workout.exercises.count) exercises, \(workout.numberOfSets) sets, about \(workout.totalDurationEstimate.formattedTime)")
    }
}
