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
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Workout.self, Exercise.self, WorkoutSession.self])
    }
}

struct RootView: View {
    @State private var path = NavigationPath()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
        .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
        .preferredColorScheme(.dark)
    }
}

enum Route: Hashable {
    case detail(Workout)
    case session(Workout)
}
