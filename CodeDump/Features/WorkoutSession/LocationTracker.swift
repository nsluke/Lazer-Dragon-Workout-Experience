import CoreLocation
import Foundation

/// Tracks GPS location during run and cycling workouts.
/// Collects a route of CLLocations and computes live distance/pace/speed.
@MainActor
@Observable
final class LocationTracker: NSObject {
    private(set) var locations: [CLLocation] = []
    private(set) var isTracking = false

    /// Total distance in meters
    private(set) var distanceMeters: Double = 0

    /// Current speed in m/s (from latest CLLocation, smoothed)
    private(set) var currentSpeed: Double = 0

    private let manager = CLLocationManager()
    private var lastFilteredLocation: CLLocation?

    override init() {
        super.init()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 5 // meters — avoid jitter
        #if os(iOS)
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
        #endif
    }

    // MARK: - Public

    func requestPermission() {
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        locations = []
        distanceMeters = 0
        currentSpeed = 0
        lastFilteredLocation = nil
        isTracking = true
        manager.delegate = self
        manager.startUpdatingLocation()
    }

    func stop() {
        isTracking = false
        manager.stopUpdatingLocation()
    }

    // MARK: - Formatted Stats

    /// Distance formatted as miles (e.g. "3.24 mi")
    var formattedDistance: String {
        let miles = distanceMeters / 1609.344
        return String(format: "%.2f mi", miles)
    }

    /// Current pace as min/mile (e.g. "8:32 /mi") for running
    var formattedPace: String {
        guard currentSpeed > 0.3 else { return "-- /mi" }
        let secondsPerMile = 1609.344 / currentSpeed
        let minutes = Int(secondsPerMile) / 60
        let seconds = Int(secondsPerMile) % 60
        return String(format: "%d:%02d /mi", minutes, seconds)
    }

    /// Current speed in mph (e.g. "15.2 mph") for cycling
    var formattedSpeed: String {
        let mph = currentSpeed * 2.23694
        return String(format: "%.1f mph", mph)
    }

    /// Average pace for the entire run
    func averagePace(totalSeconds: Int) -> String {
        let miles = distanceMeters / 1609.344
        guard miles > 0.01 else { return "-- /mi" }
        let secondsPerMile = Double(totalSeconds) / miles
        let minutes = Int(secondsPerMile) / 60
        let seconds = Int(secondsPerMile) % 60
        return String(format: "%d:%02d /mi", minutes, seconds)
    }

    /// Average speed for the entire ride
    func averageSpeed(totalSeconds: Int) -> String {
        guard totalSeconds > 0 else { return "0.0 mph" }
        let hours = Double(totalSeconds) / 3600
        let miles = distanceMeters / 1609.344
        return String(format: "%.1f mph", miles / hours)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationTracker: CLLocationManagerDelegate {

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations newLocations: [CLLocation]) {
        Task { @MainActor in
            for location in newLocations {
                // Filter out low-accuracy readings
                guard location.horizontalAccuracy >= 0,
                      location.horizontalAccuracy < 30 else { continue }

                if let last = lastFilteredLocation {
                    let delta = location.distance(from: last)
                    // Ignore tiny movements (GPS jitter)
                    guard delta >= 2 else { continue }
                    distanceMeters += delta
                }

                lastFilteredLocation = location
                locations.append(location)

                // Smooth speed: use CLLocation's speed if positive, else compute
                if location.speed >= 0 {
                    currentSpeed = location.speed
                } else if let last = locations.dropLast().last {
                    let dt = location.timestamp.timeIntervalSince(last.timestamp)
                    if dt > 0 {
                        currentSpeed = location.distance(from: last) / dt
                    }
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location errors are non-fatal — just keep trying
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Re-check after user responds to permission prompt
    }
}
