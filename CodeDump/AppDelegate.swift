import SwiftUI
import SwiftData
import UIKit

@main
struct LDWEApp: App {
    init() {

        // Activate WatchConnectivity immediately so the session handshake
        // happens at launch, not only when a workout starts.
        _ = WatchConnectivityManager.shared
    }

    static let sharedContainer: ModelContainer = {
        let schema = Schema([
            Workout.self, Exercise.self, WorkoutSession.self,
            SetLog.self, CustomExerciseTemplate.self, TrainingProgram.self,
            FitnessGoal.self
        ])

        // UI-test launches use an in-memory store so every test launch starts
        // with an empty SwiftData state. Without this, accumulating sessions
        // from prior cases push seed workouts down the list and seed buttons
        // become not-hittable on smaller devices in the multi-device matrix.
        if ProcessInfo.processInfo.arguments.contains("-UITesting") {
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            if let container = try? ModelContainer(for: schema, configurations: [memoryConfig]) {
                return container
            }
        }

        let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            print("[LDWE] CloudKit unavailable (\(error.localizedDescription)). Falling back to local storage.")
            let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("[LDWE] Cannot create local database: \(error.localizedDescription)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(Self.sharedContainer)
    }
}

// MARK: - Tab Enum

enum Tab: Int {
    case workouts, calendar, body, goals
}

// MARK: - Route Enum

enum Route: Hashable {
    case detail(Workout)
    case session(Workout)
    case activeProgram
    case exerciseProgress(templateID: String, name: String)
}

// MARK: - Root View

struct RootView: View {
    @State private var selectedTab: Tab = .workouts
    @State private var workoutsPath = NavigationPath()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }
    private var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding && !isUITesting
    }
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var recentSessions: [WorkoutSession]
    @Query private var allWorkouts: [Workout]
    @State private var importedWorkout: WorkoutExport?
    @State private var showingImportAlert = false
    @State private var importError: String?
    @State private var didAutoStartUITestSession = false

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutsTab(path: $workoutsPath)
                .tabItem {
                    Label("WORKOUTS", systemImage: "dumbbell.fill")
                }
                .tag(Tab.workouts)

            CalendarTab()
                .tabItem {
                    Label("HISTORY", systemImage: "calendar")
                }
                .tag(Tab.calendar)

            BodyTab()
                .tabItem {
                    Label("BODY", systemImage: "figure.stand")
                }
                .tag(Tab.body)

            GoalsTab()
                .tabItem {
                    Label("GOALS", systemImage: "target")
                }
                .tag(Tab.goals)
        }
        .tint(.outrunCyan)
        .fullScreenCover(isPresented: .constant(shouldShowOnboarding)) {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            styleTabBar()
            WidgetDataProvider.shared.refreshAll(context: modelContext)
            WatchConnectivityManager.shared.sendIdleContext(lastWorkoutDate: recentSessions.first?.date)
            autoStartUITestSessionIfNeeded()
        }
        .onChange(of: allWorkouts) { _, _ in
            // The seed runs in WorkoutListView.onAppear and populates this
            // @Query asynchronously. Re-check once the seed lands so the
            // UI-test deep-link fires even when the seed wasn't ready at
            // RootView.onAppear.
            autoStartUITestSessionIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            WidgetDataProvider.shared.refreshAll(context: modelContext)
        }
        .onOpenURL { url in
            handleImport(url: url)
        }
        .alert("Import Workout?", isPresented: $showingImportAlert) {
            Button("Import") {
                if let export = importedWorkout {
                    let workout = export.createWorkout(in: modelContext)
                    selectedTab = .workouts
                    workoutsPath.append(Route.detail(workout))
                }
                importedWorkout = nil
            }
            Button("Cancel", role: .cancel) {
                importedWorkout = nil
            }
        } message: {
            Text("Import \"\(importedWorkout?.name ?? "Workout")\" with \(importedWorkout?.exercises.count ?? 0) exercises?")
        }
        .alert("Import Failed", isPresented: .init(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "The file could not be imported.")
        }
    }

    // MARK: - Tab Bar Styling

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.outrunBlack)

        let outrunFont = UIFont(name: "Audiowide-Regular", size: 9) ?? .systemFont(ofSize: 9)
        let normalColor = UIColor(Color.white.opacity(0.4))
        let selectedColor = UIColor(Color.outrunCyan)

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: outrunFont,
            .foregroundColor: normalColor
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: outrunFont,
            .foregroundColor: selectedColor
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - UI-test deep link

    /// When `-UITestStartSession` is set, push a minimal "Easy Day" workout
    /// session onto the navigation path automatically. This skips the
    /// workout-list and detail-screen taps, which are flaky on iOS 18.5
    /// simulators because SwiftUI's List `.swipeActions` gesture
    /// recognizer intercepts the cell tap. UI tests still navigate the
    /// session itself (skip-forward → completed screen) — only the list
    /// hop is bypassed.
    private func autoStartUITestSessionIfNeeded() {
        guard !didAutoStartUITestSession,
              ProcessInfo.processInfo.arguments.contains("-UITestStartSession") else {
            return
        }
        let easyDay: Workout
        if let existing = allWorkouts.first(where: { $0.name == "Easy Day" }) {
            easyDay = existing
        } else {
            // The in-memory store starts empty (see sharedContainer's
            // -UITesting branch); insert a minimal Easy Day inline so we
            // don't depend on WorkoutListView's onAppear-driven seed,
            // which never runs when we deep-link past the list.
            easyDay = Self.makeUITestSeedWorkout()
            modelContext.insert(easyDay)
            try? modelContext.save()
        }
        didAutoStartUITestSession = true
        selectedTab = .workouts
        workoutsPath.append(Route.session(easyDay))
    }

    private static func makeUITestSeedWorkout() -> Workout {
        let workout = Workout(
            name: "Easy Day",
            type: .strength,
            warmupLength: 5,
            intervalLength: 5,
            restLength: 5,
            numberOfIntervals: 2,
            numberOfSets: 1,
            restBetweenSetLength: 5,
            cooldownLength: 5
        )
        let exercises = [
            Exercise(order: 0, name: "Push-ups", splitLength: 5, reps: 10, targetMuscleGroupsRaw: "chest", equipmentRaw: "bodyweight", templateID: "push-ups"),
            Exercise(order: 1, name: "Squats", splitLength: 5, reps: 10, targetMuscleGroupsRaw: "quads", equipmentRaw: "bodyweight", templateID: "bodyweight-squats")
        ]
        for exercise in exercises {
            exercise.workout = workout
        }
        workout.exercises = exercises
        return workout
    }

    // MARK: - Import

    private func handleImport(url: URL) {
        guard url.pathExtension == "ldwe" else {
            importError = "This file type is not supported."
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            importError = "The file could not be read."
            return
        }
        guard let export = WorkoutExport.decode(from: data) else {
            importError = "The workout file is corrupted or in an unsupported format."
            return
        }
        importedWorkout = export
        showingImportAlert = true
    }
}

// MARK: - Tab Wrappers

struct WorkoutsTab: View {
    @Binding var path: NavigationPath

    var body: some View {
        NavigationStack(path: $path) {
            WorkoutListView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .detail(let workout):
                        WorkoutDetailView(workout: workout, path: $path)
                    case .session(let workout):
                        WorkoutSessionView(workout: workout, path: $path)
                    case .activeProgram:
                        ProgramCalendarView(path: $path)
                    case .exerciseProgress(let templateID, let name):
                        ExerciseProgressChartView(exerciseTemplateID: templateID, exerciseName: name)
                    }
                }
        }
    }
}

struct CalendarTab: View {
    var body: some View {
        NavigationStack {
            WorkoutCalendarView()
        }
    }
}

struct BodyTab: View {
    var body: some View {
        NavigationStack {
            BodyStatusView()
        }
    }
}

struct GoalsTab: View {
    var body: some View {
        NavigationStack {
            GoalsView()
        }
    }
}
