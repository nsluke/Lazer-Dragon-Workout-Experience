import SwiftData
import Foundation
import CoreLocation

@Model
final class WorkoutSession {
    var date: Date = Date()
    var totalElapsed: Int = 0      // seconds
    var exercisesCompleted: Int = 0
    var setsCompleted: Int = 0

    /// GPS route data — JSON-encoded array of [lat, lon, timestamp, altitude]
    var routeDataRaw: String?
    /// Total distance in meters
    var distanceMeters: Double?

    var workout: Workout?

    // CloudKit requires to-many relationships to be optional.
    @Relationship(deleteRule: .cascade, inverse: \SetLog.session)
    var setLogs: [SetLog]? = []

    init(date: Date = .now, totalElapsed: Int, exercisesCompleted: Int, setsCompleted: Int) {
        self.date = date
        self.totalElapsed = totalElapsed
        self.exercisesCompleted = exercisesCompleted
        self.setsCompleted = setsCompleted
    }

    // MARK: - Route Helpers

    var routeCoordinates: [CLLocationCoordinate2D] {
        guard let raw = routeDataRaw,
              let data = raw.data(using: .utf8),
              let points = try? JSONDecoder().decode([[Double]].self, from: data) else { return [] }
        return points.compactMap { point in
            guard point.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
        }
    }

    func setRoute(from locations: [CLLocation]) {
        let points = locations.map { [$0.coordinate.latitude, $0.coordinate.longitude, $0.timestamp.timeIntervalSince1970, $0.altitude] }
        routeDataRaw = (try? String(data: JSONEncoder().encode(points), encoding: .utf8)) ?? nil

        // Calculate total distance
        var total: Double = 0
        for i in 1..<locations.count {
            total += locations[i].distance(from: locations[i - 1])
        }
        distanceMeters = total
    }
}
