import SwiftUI
import SwiftData

struct WorkoutCalendarView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @Query(sort: \SetLog.date, order: .reverse) private var allSetLogs: [SetLog]

    @State private var displayedMonth = Date.now
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let weekdaySymbols = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    monthHeader
                    statsBanner
                    streakIndicator
                    calendarGrid
                    dayDetailSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
        }
        .outrunTitle("HISTORY")
        .outrunNavBar()
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.outrunCyan)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(monthYearString)
                .font(.outrunFuture(18))
                .foregroundColor(.outrunYellow)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.outrunCyan)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next month")
            .disabled(isCurrentOrFutureMonth)
            .opacity(isCurrentOrFutureMonth ? 0.3 : 1)
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth).uppercased()
    }

    private var isCurrentOrFutureMonth: Bool {
        let now = Date.now
        let currentComponents = calendar.dateComponents([.year, .month], from: now)
        let displayedComponents = calendar.dateComponents([.year, .month], from: displayedMonth)
        if let cy = currentComponents.year, let cm = currentComponents.month,
           let dy = displayedComponents.year, let dm = displayedComponents.month {
            return (dy > cy) || (dy == cy && dm >= cm)
        }
        return false
    }

    // MARK: - Stats Banner

    private var statsBanner: some View {
        let stats = monthStats
        let sessionsValue = "\(stats.sessions)"
        let activeDaysValue = "\(stats.activeDays)"
        let volumeValue = SessionAnalytics.formatVolume(stats.volume)
        return HStack(spacing: 0) {
            monthStatCard(label: "SESSIONS", value: sessionsValue, color: .outrunCyan)
            monthStatCard(label: "ACTIVE DAYS", value: activeDaysValue, color: .outrunGreen)
            monthStatCard(label: "VOLUME", value: volumeValue, color: .outrunPink)
        }
        .background(Color.outrunSurface)
        .cornerRadius(12)
    }

    private var monthStats: (sessions: Int, activeDays: Int, volume: Double) {
        let monthSessions = sessionsInDisplayedMonth
        let sessionCount = monthSessions.count
        let activeDays = Set(monthSessions.map { calendar.startOfDay(for: $0.date) }).count
        var totalVolume: Double = 0
        for session in monthSessions {
            for log in session.setLogs {
                let w: Double = log.weight ?? 0
                let r: Double = Double(log.reps ?? 0)
                totalVolume += w * r
            }
        }
        return (sessionCount, activeDays, totalVolume)
    }

    private func monthStatCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.outrunFuture(8))
                .foregroundColor(.white.opacity(0.5))
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Streak

    private var streakIndicator: some View {
        let streak = computeStreak()
        return Group {
            if streak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.outrunOrange)
                    Text("\(streak) DAY STREAK")
                        .font(.outrunFuture(13))
                        .foregroundColor(.outrunOrange)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.outrunOrange.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.outrunOrange.opacity(0.3), lineWidth: 1)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(streak) day workout streak")
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.outrunFuture(8))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(height: 20)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(calendarDays, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
        .padding(12)
        .background(Color.outrunSurface)
        .cornerRadius(12)
    }

    private func dayCell(_ day: Date?) -> some View {
        Group {
            if let day {
                let isWorkoutDay = hasWorkout(on: day)
                let isToday = calendar.isDateInToday(day)
                let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
                let dayNumber = calendar.component(.day, from: day)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isSelected {
                            selectedDate = nil
                        } else {
                            selectedDate = day
                        }
                    }
                } label: {
                    ZStack {
                        // Background
                        if isSelected {
                            Circle()
                                .fill(Color.outrunCyan.opacity(0.3))
                        } else if isWorkoutDay {
                            Circle()
                                .fill(Color.outrunGreen.opacity(0.25))
                        }

                        // Today ring
                        if isToday {
                            Circle()
                                .stroke(Color.outrunCyan, lineWidth: 2)
                        }

                        Text("\(dayNumber)")
                            .font(.system(size: 14, weight: isToday ? .bold : .regular, design: .monospaced))
                            .foregroundColor(
                                isSelected ? .outrunCyan :
                                isWorkoutDay ? .outrunGreen :
                                isToday ? .outrunCyan :
                                .white.opacity(0.6)
                            )
                    }
                    .frame(height: 38)
                }
                .accessibilityLabel(dayCellAccessibilityLabel(day: day, isWorkoutDay: isWorkoutDay, isToday: isToday))
            } else {
                // Empty cell for padding
                Color.clear
                    .frame(height: 38)
            }
        }
    }

    // MARK: - Day Detail

    @ViewBuilder
    private var dayDetailSection: some View {
        if let selectedDate {
            let daySessions = sessions(for: selectedDate)
            DayDetailView(
                date: selectedDate,
                sessions: daySessions,
                allHistoricalLogs: allSetLogs,
                allSessions: allSessions
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Calendar Computation

    /// Returns array of optional Dates for the calendar grid.
    /// nil = empty cell (padding before first day / after last day).
    private var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }

        let firstDay = monthInterval.start
        // ISO weekday: Monday=2 in Calendar (1=Sunday)
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        // Convert to Monday-based offset (0=Mon, 6=Sun)
        let leadingBlanks = (firstWeekday + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        for dayOffset in 0..<monthRange.count {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: firstDay) {
                days.append(date)
            }
        }

        // Pad trailing to fill the last row
        let trailingBlanks = (7 - days.count % 7) % 7
        days.append(contentsOf: Array(repeating: nil as Date?, count: trailingBlanks))

        return days
    }

    // MARK: - Data Queries

    private var sessionsInDisplayedMonth: [WorkoutSession] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        return allSessions.filter { $0.date >= monthInterval.start && $0.date < monthInterval.end }
    }

    private var workoutDatesInMonth: Set<DateComponents> {
        Set(sessionsInDisplayedMonth.map {
            calendar.dateComponents([.year, .month, .day], from: $0.date)
        })
    }

    private func hasWorkout(on date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return workoutDatesInMonth.contains(components)
    }

    private func sessions(for date: Date) -> [WorkoutSession] {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        return allSessions.filter { $0.date >= dayStart && $0.date < dayEnd }
            .sorted { $0.date < $1.date }
    }

    private func computeStreak() -> Int {
        let today = calendar.startOfDay(for: .now)
        var streak = 0
        var checkDate = today

        // Check if today has a workout; if not, start from yesterday
        if !hasWorkoutOnDate(checkDate) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while hasWorkoutOnDate(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
    }

    private func hasWorkoutOnDate(_ date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return false }
        return allSessions.contains { $0.date >= dayStart && $0.date < dayEnd }
    }

    // MARK: - Accessibility

    private func dayCellAccessibilityLabel(day: Date, isWorkoutDay: Bool, isToday: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        var label = formatter.string(from: day)
        if isToday { label += ", today" }
        if isWorkoutDay { label += ", workout completed" }
        return label
    }
}
