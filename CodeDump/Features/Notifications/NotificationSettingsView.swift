import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour")    private var reminderHour   = 18
    @AppStorage("reminderMinute")  private var reminderMinute = 0

    @State private var reminderDate: Date = .defaultReminderTime
    @State private var authDenied = false

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            Form {
                Section {
                    Toggle(isOn: $reminderEnabled) {
                        Label {
                            Text("Daily Reminder")
                                .font(.outrunFuture(15))
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.outrunYellow)
                        }
                    }
                    .tint(.outrunCyan)
                    .onChange(of: reminderEnabled) { _, enabled in
                        Task { await handleToggle(enabled) }
                    }

                    if reminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $reminderDate,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.outrunFuture(14))
                        .foregroundColor(.white.opacity(0.7))
                        .tint(.outrunCyan)
                        .onChange(of: reminderDate) { _, date in
                            let cal = Calendar.current
                            reminderHour   = cal.component(.hour,   from: date)
                            reminderMinute = cal.component(.minute, from: date)
                            Task { await NotificationManager.shared.scheduleReminder(
                                hour: reminderHour, minute: reminderMinute
                            )}
                        }
                    }
                } footer: {
                    if authDenied {
                        Text("Notifications are disabled. Enable them in Settings → Notifications → Lazer Dragon.")
                            .font(.outrunFuture(11))
                            .foregroundColor(.outrunRed)
                    } else {
                        Text("Get a daily nudge to keep your training streak alive.")
                            .font(.outrunFuture(11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .listRowBackground(Color.outrunSurface)
            }
            .scrollContentBackground(.hidden)
        }
        .outrunTitle("NOTIFICATIONS")
        .outrunNavBar()
        .onAppear { reminderDate = .from(hour: reminderHour, minute: reminderMinute) }
    }

    // MARK: - Helpers

    private func handleToggle(_ enabled: Bool) async {
        if enabled {
            let granted = await NotificationManager.shared.requestAuthorization()
            let status  = await NotificationManager.shared.authorizationStatus()
            if status == .denied {
                authDenied = true
                reminderEnabled = false
                return
            }
            if granted {
                await NotificationManager.shared.scheduleReminder(
                    hour: reminderHour, minute: reminderMinute
                )
            }
        } else {
            await NotificationManager.shared.cancelReminder()
        }
    }
}

// MARK: - Date Helpers

private extension Date {
    static var defaultReminderTime: Date {
        .from(hour: 18, minute: 0)
    }

    static func from(hour: Int, minute: Int) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        c.hour   = hour
        c.minute = minute
        c.second = 0
        return Calendar.current.date(from: c) ?? .now
    }
}
