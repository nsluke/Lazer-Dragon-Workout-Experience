import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.createdAt) private var workouts: [Workout]
    @State private var showingBuilder = false
    @State private var showingNotificationSettings = false
    @State private var editingWorkout: Workout? = nil

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            if workouts.isEmpty {
                emptyState
            } else {
                workoutList
            }
        }
        .navigationTitle("WORKOUTS")
        .navigationBarTitleDisplayMode(.large)
        .outrunNavBar()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showingNotificationSettings = true
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(.outrunCyan)
                    }
                    Button {
                        showingBuilder = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.outrunCyan)
                            .fontWeight(.bold)
                    }
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
        .onAppear(perform: seedForDebugIfNeeded)
    }

    // MARK: - List

    private var workoutList: some View {
        List {
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

    // MARK: - Seed Data (debug/simulator only)

    private func seedForDebugIfNeeded() {
        #if !DEBUG
        return
        #endif
        guard workouts.isEmpty else { return }

        let exerciseData: [(String, Int, Int)] = [
            ("Burpee", 30, 10),
            ("Situp", 30, 30),
            ("Pushup", 30, 10),
            ("Bicep Curl", 30, 10),
            ("Tricep Extension", 30, 10),
            ("Lunge", 30, 10),
            ("Squat", 30, 10),
            ("Plank", 60, 0),
            ("Pull-up", 30, 8),
            ("Seated Back Row", 30, 10),
        ]

        let seeds: [(String, WorkoutType, Int, Int, Int, Int, Int, Int, Int)] = [
            //  name       type       warm ivl  rest #ivl sets setBtw cool
            ("Neko",    .strength, 120, 30, 30, 10, 2, 0,   60),
            ("Doge",    .strength, 120, 40, 30, 10, 2, 0,   60),
            ("Cyborg",  .strength, 120, 45, 20, 10, 2, 0,   60),
            ("Shinobi", .strength, 120, 60, 20, 10, 2, 0,   60),
            ("光線竜",   .hiit,     120, 75, 10, 10, 3, 120, 120),
            ("Test",    .strength, 5,   5,  5,  10, 2, 5,   5),
        ]

        for (name, type, warmup, interval, rest, numIntervals, numSets, restBetweenSets, cooldown) in seeds {
            let workout = Workout(
                name: name,
                type: type,
                warmupLength: warmup,
                intervalLength: interval,
                restLength: rest,
                numberOfIntervals: numIntervals,
                numberOfSets: numSets,
                restBetweenSetLength: restBetweenSets,
                cooldownLength: cooldown
            )
            modelContext.insert(workout)
            for (i, (exName, split, reps)) in exerciseData.enumerated() {
                let ex = Exercise(order: i, name: exName, splitLength: split, reps: reps)
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
                Text("\(workout.exercises.count) exercises  ·  \(workout.numberOfSets) set\(workout.numberOfSets == 1 ? "" : "s")  ·  ~\(workout.totalDurationEstimate.formattedTime)\(workout.sessions.isEmpty ? "" : "  ·  \(workout.sessions.count) session\(workout.sessions.count == 1 ? "" : "s")")")
                    .font(.outrunFuture(12))
                    .foregroundColor(.outrunCyan.opacity(0.8))
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
    }
}
