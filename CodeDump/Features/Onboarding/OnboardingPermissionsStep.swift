import SwiftUI
import UserNotifications
#if canImport(HealthKit)
import HealthKit
#endif

struct OnboardingPermissionsStep: View {
    @State private var healthGranted = false
    @State private var notificationsGranted = false
    @State private var healthRequested = false
    @State private var notificationsRequested = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 32))
                    .foregroundColor(.outrunGreen)

                Text("PERMISSIONS")
                    .font(.outrunFuture(24))
                    .foregroundColor(.white)

                Text("These are optional but make the experience better.")
                    .font(.outrunFuture(12))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 16) {
                // HealthKit
                permissionRow(
                    icon: "heart.fill",
                    title: "APPLE HEALTH",
                    detail: "Save workouts and read recovery data (sleep, HRV) for smarter recommendations.",
                    color: .outrunPink,
                    granted: healthGranted,
                    requested: healthRequested
                ) {
                    await requestHealth()
                }

                // Notifications
                permissionRow(
                    icon: "bell.badge.fill",
                    title: "NOTIFICATIONS",
                    detail: "Get reminded about upcoming program workouts and rest day suggestions.",
                    color: .outrunYellow,
                    granted: notificationsGranted,
                    requested: notificationsRequested
                ) {
                    await requestNotifications()
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Permission Row

    private func permissionRow(
        icon: String,
        title: String,
        detail: String,
        color: Color,
        granted: Bool,
        requested: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.outrunFuture(13))
                    .foregroundColor(.white)

                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.outrunGreen)
                    .font(.system(size: 22))
            } else if requested {
                Image(systemName: "minus.circle")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.system(size: 22))
            } else {
                Button {
                    Task { await action() }
                } label: {
                    Text("ALLOW")
                        .font(.outrunFuture(10))
                        .foregroundColor(.outrunBlack)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(color)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.outrunSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(granted ? color.opacity(0.3) : Color.outrunPurple.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Permission Requests

    private func requestHealth() async {
        #if os(iOS)
        await HealthKitManager.shared.requestAuthorization()
        healthRequested = true
        healthGranted = HealthKitManager.shared.authorizationRequested
        #endif
    }

    private func requestNotifications() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            notificationsRequested = true
            notificationsGranted = granted
        } catch {
            notificationsRequested = true
        }
    }
}
