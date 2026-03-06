import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.createdAt) private var workouts: [Workout]
    @State private var showingBuilder = false

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
                Button {
                    showingBuilder = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.outrunCyan)
                        .fontWeight(.bold)
                }
            }
        }
        .sheet(isPresented: $showingBuilder) {
            WorkoutBuilderView()
        }
        .onAppear(perform: seedIfNeeded)
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
            }
            .onDelete(perform: deleteWorkouts)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("NO WORKOUTS")
                .font(.outrunFuture(28))
                .foregroundColor(.outrunCyan)
            Text("Tap + to build your first workout")
                .font(.outrunFuture(16))
                .foregroundColor(.outrunYellow)
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
                Text("\(workout.exercises.count) exercises  ·  \(workout.numberOfSets) set\(workout.numberOfSets == 1 ? "" : "s")")
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
