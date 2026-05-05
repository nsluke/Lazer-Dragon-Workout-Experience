import SwiftUI
import SwiftData
import UIKit

@main
struct LDWEApp: App {
    init() {
        let large = UIFont(name: "OutrunFuture", size: 34) ?? .systemFont(ofSize: 34, weight: .bold)
        let inline = UIFont(name: "OutrunFuture", size: 17) ?? .systemFont(ofSize: 17, weight: .semibold)
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: large, .foregroundColor: UIColor(Color.outrunYellow)]
        UINavigationBar.appearance().titleTextAttributes      = [.font: inline, .foregroundColor: UIColor(Color.outrunCyan)]

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
    @State private var importedWorkout: WorkoutExport?
    @State private var showingImportAlert = false
    @State private var importError: String?

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

        let outrunFont = UIFont(name: "OutrunFuture", size: 9) ?? .systemFont(ofSize: 9)
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
