import SwiftUI

@main
struct LDWEWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            WatchSessionView()
                .environmentObject(connectivity)
        }
    }
}
