import SwiftUI
import MapKit

/// Displays a GPS route on a map. Used in workout completion and history views.
struct RouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    let distanceMeters: Double?
    let totalSeconds: Int
    let isCycling: Bool

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Stats row
            HStack(spacing: 16) {
                routeStat(label: "DISTANCE", value: formattedDistance, color: .outrunCyan)
                routeStat(label: isCycling ? "AVG SPEED" : "AVG PACE", value: formattedAvg, color: .outrunYellow)
                routeStat(label: "DURATION", value: totalSeconds.formattedTimeLong, color: .outrunGreen)
            }
            .padding(.horizontal, 12)

            // Map
            Map(position: $position) {
                if coordinates.count >= 2 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(Color.outrunCyan, lineWidth: 4)
                }

                // Start marker
                if let start = coordinates.first {
                    Annotation("START", coordinate: start) {
                        Circle()
                            .fill(Color.outrunGreen)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }

                // End marker
                if let end = coordinates.last, coordinates.count > 1 {
                    Annotation("FINISH", coordinate: end) {
                        Circle()
                            .fill(Color.outrunRed)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .frame(height: 220)
            .cornerRadius(12)
        }
        .padding(12)
        .background(Color.outrunSurface)
        .cornerRadius(16)
    }

    private func routeStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.outrunFuture(9))
                .foregroundColor(.white.opacity(0.4))
            Text(value)
                .font(.outrunFuture(14))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedDistance: String {
        let miles = (distanceMeters ?? 0) / 1609.344
        return String(format: "%.2f mi", miles)
    }

    private var formattedAvg: String {
        let miles = (distanceMeters ?? 0) / 1609.344
        if isCycling {
            guard totalSeconds > 0 else { return "0.0 mph" }
            let hours = Double(totalSeconds) / 3600
            return String(format: "%.1f mph", miles / hours)
        } else {
            guard miles > 0.01 else { return "-- /mi" }
            let secondsPerMile = Double(totalSeconds) / miles
            let minutes = Int(secondsPerMile) / 60
            let seconds = Int(secondsPerMile) % 60
            return String(format: "%d:%02d /mi", minutes, seconds)
        }
    }
}
