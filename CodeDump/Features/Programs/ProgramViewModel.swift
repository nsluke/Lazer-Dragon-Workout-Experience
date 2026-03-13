import SwiftData
import Foundation

// MARK: - Day Status

struct ProgramDayStatus: Identifiable {
    let id: Int             // weekday 1–7
    let weekday: Int
    let shortLabel: String  // "M", "T", etc.
    let dayLabel: String?   // e.g. "PUSH" or nil for rest
    let isToday: Bool
    let isCompleted: Bool
    let isMissed: Bool
    let isRestDay: Bool
}

// MARK: - ViewModel

@Observable @MainActor
final class ProgramViewModel {

    // Active enrollment
    var activeProgram: TrainingProgram?

    // Calendar state
    var currentWeekDays: [ProgramDayStatus] = []
    var todaysDayTemplate: ProgramDayTemplate?
    var todaysExercises: [ExercisePickerItem] = []

    // Deload / recovery
    var deloadSuggested = false
    var deloadMessage: String?
    var recoveryScore: RecoveryScore?

    // Adaptive scheduling
    var adaptationMessage: String?

    // Equipment
    var availableEquipment: Set<Equipment> = EquipmentProfile.commercialGymEquipment

    // MARK: - Load

    /// Refreshes all state from the active program. Call on appear.
    func load(
        activePrograms: [TrainingProgram],
        sessions: [WorkoutSession],
        setLogs: [SetLog]
    ) {
        activeProgram = activePrograms.first { $0.isActive }
        guard let program = activeProgram else {
            currentWeekDays = []
            todaysDayTemplate = nil
            todaysExercises = []
            return
        }

        // Auto-advance week if needed
        let computed = program.computedCurrentWeek
        if computed != program.currentWeek {
            program.currentWeek = computed
            program.adaptedSchedule = nil // Reset weekly adaptation
        }

        // Check if program is complete
        if program.isCompleted {
            program.isActive = false
            activeProgram = nil
            return
        }

        // Handle missed days
        let adaptation = ProgramAdaptiveEngine.adaptForMissedDays(program: program)
        switch adaptation {
        case .shift(let adapted, let message):
            program.adaptedSchedule = adapted
            adaptationMessage = message
        case .merge(_, let message):
            adaptationMessage = message
        case .drop(let message):
            program.adaptedSchedule = nil
            adaptationMessage = message
        case .none:
            adaptationMessage = nil
        }

        // Build week day statuses
        buildWeekDays(program: program)

        // Resolve today's template
        todaysDayTemplate = program.todaysDayTemplate
        if let dayTemplate = todaysDayTemplate {
            todaysExercises = resolveExercises(
                templateIDs: dayTemplate.exerciseTemplateIDs,
                equipment: availableEquipment
            )
        } else {
            todaysExercises = []
        }

        // Check deload
        let deloadResult = ProgramAdaptiveEngine.evaluateDeload(
            program: program,
            recentLogs: Array(setLogs.prefix(200)),
            recoveryScore: recoveryScore?.overall
        )
        deloadSuggested = deloadResult.shouldDeload
        deloadMessage = deloadResult.message
    }

    /// Fetches HealthKit recovery data asynchronously.
    func loadRecovery(recentRPEs: [Int], daysSinceLastWorkout: Int) async {
        #if os(iOS)
        let sleep = await RecoveryAnalyzer.fetchSleepHours()
        let hrv = await RecoveryAnalyzer.fetchRecentHRV()
        let baseline = await RecoveryAnalyzer.fetchBaselineHRV()
        recoveryScore = RecoveryAnalyzer.computeRecovery(
            sleepHours: sleep,
            recentHRV: hrv,
            baselineHRV: baseline,
            recentRPEs: recentRPEs,
            daysSinceLastWorkout: daysSinceLastWorkout
        )
        #endif
    }

    // MARK: - Enrollment

    func enroll(in template: ProgramTemplate, context: ModelContext) {
        // Deactivate any existing active program
        let descriptor = FetchDescriptor<TrainingProgram>(
            predicate: #Predicate { $0.isActive == true }
        )
        if let existing = try? context.fetch(descriptor) {
            for program in existing {
                program.isActive = false
            }
        }

        let program = TrainingProgram(
            programTemplateID: template.id,
            durationWeeks: template.durationWeeks
        )
        context.insert(program)
        try? context.save()
        activeProgram = program
    }

    func endProgram(context: ModelContext) {
        activeProgram?.isActive = false
        try? context.save()
        activeProgram = nil
        currentWeekDays = []
        todaysDayTemplate = nil
        todaysExercises = []
    }

    // MARK: - Workout Generation

    /// Creates a Workout entity for today's program day and returns it for navigation.
    func generateTodaysWorkout(in context: ModelContext) -> Workout? {
        guard let program = activeProgram,
              let dayTemplate = todaysDayTemplate else { return nil }

        let exercises = todaysExercises

        let workout = Workout(
            name: "\(program.programTemplate?.name ?? "Program") — \(dayTemplate.label)",
            type: dayTemplate.workoutType,
            warmupLength: dayTemplate.warmup,
            intervalLength: dayTemplate.intervalLength,
            restLength: dayTemplate.restLength,
            numberOfIntervals: exercises.count,
            numberOfSets: deloadSuggested ? max(2, dayTemplate.numberOfSets - 1) : dayTemplate.numberOfSets,
            restBetweenSetLength: dayTemplate.restBetweenSets,
            cooldownLength: dayTemplate.cooldown
        )
        context.insert(workout)

        for (index, item) in exercises.enumerated() {
            let exercise = Exercise(
                order: index,
                name: item.name,
                splitLength: item.defaultDuration,
                reps: item.defaultReps,
                targetMuscleGroupsRaw: item.muscles.map(\.rawValue).joined(separator: ","),
                equipmentRaw: item.equipment.rawValue,
                templateID: item.id
            )
            exercise.workout = workout
            workout.exercises.append(exercise)
            context.insert(exercise)
        }

        try? context.save()
        return workout
    }

    /// Generates a merged catch-up workout from missed days.
    func generateMergedWorkout(exerciseIDs: [String], in context: ModelContext) -> Workout? {
        guard let program = activeProgram else { return nil }

        let exercises = resolveExercises(templateIDs: exerciseIDs, equipment: availableEquipment)
        guard !exercises.isEmpty else { return nil }

        let workout = Workout(
            name: "\(program.programTemplate?.name ?? "Program") — Catch Up",
            type: .strength,
            warmupLength: 120,
            intervalLength: 45,
            restLength: 30,
            numberOfIntervals: exercises.count,
            numberOfSets: 2,
            restBetweenSetLength: 90,
            cooldownLength: 60
        )
        context.insert(workout)

        for (index, item) in exercises.enumerated() {
            let exercise = Exercise(
                order: index,
                name: item.name,
                splitLength: item.defaultDuration,
                reps: item.defaultReps,
                targetMuscleGroupsRaw: item.muscles.map(\.rawValue).joined(separator: ","),
                equipmentRaw: item.equipment.rawValue,
                templateID: item.id
            )
            exercise.workout = workout
            workout.exercises.append(exercise)
            context.insert(exercise)
        }

        try? context.save()
        return workout
    }

    // MARK: - Day Completion

    func markTodayCompleted() {
        activeProgram?.markTodayCompleted()
    }

    func skipDay() {
        // Mark as completed (skip = done with this day's obligation)
        activeProgram?.markTodayCompleted()
    }

    // MARK: - Private

    private func buildWeekDays(program: TrainingProgram) {
        let weekIndex = program.currentWeek - 1
        let grid = program.completionGrid
        let weekData = weekIndex < grid.count ? grid[weekIndex] : Array(repeating: false, count: 7)
        let schedule = program.effectiveSchedule
        let todayWeekday = isoWeekday()

        let shortLabels = ["M", "T", "W", "T", "F", "S", "S"]

        currentWeekDays = (1...7).map { weekday in
            let dayIndex = weekday - 1
            let isCompleted = dayIndex < weekData.count && weekData[dayIndex]
            let isWorkoutDay = schedule[weekday] != nil
            let isToday = weekday == todayWeekday
            let isPast = weekday < todayWeekday

            let dayLabel: String?
            if let templateID = schedule[weekday],
               let dt = program.programTemplate?.dayTemplate(for: templateID) {
                dayLabel = dt.label.uppercased()
            } else {
                dayLabel = nil
            }

            let isMissed = isPast && isWorkoutDay && !isCompleted

            return ProgramDayStatus(
                id: weekday,
                weekday: weekday,
                shortLabel: shortLabels[dayIndex],
                dayLabel: dayLabel,
                isToday: isToday,
                isCompleted: isCompleted,
                isMissed: isMissed,
                isRestDay: !isWorkoutDay
            )
        }
    }

    private func resolveExercises(
        templateIDs: [String],
        equipment: Set<Equipment>
    ) -> [ExercisePickerItem] {
        let lookup = Dictionary(uniqueKeysWithValues: ExerciseTemplate.library.map { ($0.id, $0) })

        return templateIDs.compactMap { id in
            if let template = lookup[id] {
                // Check if user has the required equipment
                if equipment.contains(template.equipment) {
                    return ExercisePickerItem(from: template)
                }
                // Try to find a substitute: same primary muscle + available equipment
                let substitute = ExerciseTemplate.library.first { alt in
                    alt.id != id
                    && alt.primaryMuscle == template.primaryMuscle
                    && equipment.contains(alt.equipment)
                }
                if let sub = substitute {
                    return ExercisePickerItem(from: sub)
                }
                // No substitute — include anyway (user might have the equipment unlisted)
                return ExercisePickerItem(from: template)
            }
            return nil
        }
    }

    private func isoWeekday() -> Int {
        let dow = Calendar.current.component(.weekday, from: .now)
        return dow == 1 ? 7 : dow - 1
    }
}
