import SwiftData
import Foundation

@Model
final class TrainingProgram {
    var programTemplateID: String = ""
    var startDate: Date = Date()
    var currentWeek: Int = 1
    var isActive: Bool = true

    /// JSON-encoded `[[Bool]]` — outer array = weeks, inner = 7 days (Mon–Sun index 0–6).
    var completionGridRaw: String = "[]"

    /// JSON-encoded `[String: String]` mapping weekday numbers to day template IDs.
    /// nil = using the program template's default schedule.
    var adaptedScheduleRaw: String?

    var accumulatedFatigueScore: Double = 0
    var lastDeloadWeek: Int?

    init(programTemplateID: String, durationWeeks: Int = 8) {
        self.programTemplateID = programTemplateID
        self.startDate = Date()
        self.currentWeek = 1
        self.isActive = true
        self.accumulatedFatigueScore = 0
        self.lastDeloadWeek = nil
        self.adaptedScheduleRaw = nil

        // Initialize empty completion grid: durationWeeks × 7 days
        let grid = Array(repeating: Array(repeating: false, count: 7), count: durationWeeks)
        self.completionGridRaw = (try? String(data: JSONEncoder().encode(grid), encoding: .utf8)) ?? "[]"
    }

    // MARK: - Computed Properties

    var completionGrid: [[Bool]] {
        get {
            guard let data = completionGridRaw.data(using: .utf8),
                  let grid = try? JSONDecoder().decode([[Bool]].self, from: data) else {
                return []
            }
            return grid
        }
        set {
            completionGridRaw = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    var adaptedSchedule: [Int: String]? {
        get {
            guard let raw = adaptedScheduleRaw,
                  let data = raw.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return nil
            }
            // Convert string keys back to Int
            var result: [Int: String] = [:]
            for (key, value) in dict {
                if let intKey = Int(key) {
                    result[intKey] = value
                }
            }
            return result
        }
        set {
            guard let newValue else {
                adaptedScheduleRaw = nil
                return
            }
            // Convert Int keys to String for JSON
            let stringKeyed = Dictionary(uniqueKeysWithValues: newValue.map { (String($0.key), $0.value) })
            adaptedScheduleRaw = try? String(data: JSONEncoder().encode(stringKeyed), encoding: .utf8)
        }
    }

    var programTemplate: ProgramTemplate? {
        ProgramTemplate.find(programTemplateID)
    }

    /// The effective schedule for the current week (adapted or default).
    var effectiveSchedule: [Int: String] {
        adaptedSchedule ?? programTemplate?.schedule ?? [:]
    }

    /// Returns the day template for a given ISO weekday (1=Monday..7=Sunday).
    func dayTemplate(forWeekday weekday: Int) -> ProgramDayTemplate? {
        guard let templateID = effectiveSchedule[weekday],
              let program = programTemplate else { return nil }
        return program.dayTemplate(for: templateID)
    }

    /// Today's day template, if today is a workout day.
    var todaysDayTemplate: ProgramDayTemplate? {
        dayTemplate(forWeekday: isoWeekday)
    }

    /// Progress for the current week: (completed workout days, total scheduled workout days).
    var weekProgress: (completed: Int, total: Int) {
        let weekIndex = currentWeek - 1
        guard weekIndex >= 0, weekIndex < completionGrid.count else { return (0, 0) }

        let weekData = completionGrid[weekIndex]
        let schedule = effectiveSchedule
        let total = schedule.count
        var completed = 0
        for (weekday, _) in schedule {
            let dayIndex = weekday - 1 // Convert 1-based weekday to 0-based array index
            if dayIndex >= 0, dayIndex < weekData.count, weekData[dayIndex] {
                completed += 1
            }
        }
        return (completed, total)
    }

    /// Computes the current week number from the start date.
    var computedCurrentWeek: Int {
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: startDate, to: .now).weekOfYear ?? 0
        return max(1, weeks + 1)
    }

    /// Whether the program has finished (current week exceeds duration).
    var isCompleted: Bool {
        guard let template = programTemplate else { return false }
        return computedCurrentWeek > template.durationWeeks
    }

    // MARK: - Mutation

    func markDay(weekIndex: Int, dayIndex: Int, completed: Bool) {
        var grid = completionGrid
        guard weekIndex >= 0, weekIndex < grid.count,
              dayIndex >= 0, dayIndex < grid[weekIndex].count else { return }
        grid[weekIndex][dayIndex] = completed
        completionGrid = grid
    }

    /// Marks today as completed in the current week.
    func markTodayCompleted() {
        let dayIndex = isoWeekday - 1 // 0-based
        markDay(weekIndex: currentWeek - 1, dayIndex: dayIndex, completed: true)
    }

    // MARK: - Helpers

    /// ISO 8601 weekday: 1=Monday..7=Sunday.
    private var isoWeekday: Int {
        let dow = Calendar.current.component(.weekday, from: .now) // 1=Sun..7=Sat
        return dow == 1 ? 7 : dow - 1
    }
}
