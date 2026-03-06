import SwiftUI
import SwiftData

@main
struct LDWEApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Workout.self, Exercise.self])
    }
}

struct RootView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WorkoutListView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .detail(let workout):
                        WorkoutDetailView(workout: workout, path: $path)
                    case .session(let workout):
                        WorkoutSessionView(workout: workout, path: $path)
                    }
                }
        }
    }
}

enum Route: Hashable {
    case detail(Workout)
    case session(Workout)
}
