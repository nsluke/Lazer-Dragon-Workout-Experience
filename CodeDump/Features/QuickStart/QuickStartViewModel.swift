import SwiftData
import Foundation

@Observable @MainActor
final class QuickStartViewModel {

    // MARK: - User Selections

    var selectedDuration: Int = 30    // 15, 30, 45, 60
    var selectedType: WorkoutType = .strength

    // MARK: - Generated Output

    var generatedExercises: [WorkoutBuilderViewModel.DraftExercise] = []
    var generatedName: String = ""
    var muscleFocusSummary: String = ""
    var warningMessage: String? = nil
    var hasGenerated: Bool = false

    // MARK: - Equipment (from @AppStorage via caller)

    var availableEquipment: Set<Equipment> = EquipmentProfile.commercialGymEquipment

    // MARK: - Generate Workout

    /// Main generation entry point.
    /// - Parameters:
    ///   - sessions: All completed workout sessions (for freshness analysis).
    ///   - customTemplates: User-created exercise templates.
    func generate(sessions: [WorkoutSession], customTemplates: [CustomExerciseTemplate]) {
        warningMessage = nil

        // 1. Build template lookup
        var customMuscles: [String: [MuscleGroup]] = [:]
        for ct in customTemplates {
            customMuscles[ct.id] = ct.muscleGroups
        }
        let lookup = MuscleAnalyzer.buildLookup(customMuscles: customMuscles)
        let analyzer = MuscleAnalyzer(templateLookup: lookup)

        // 2. Calculate muscle freshness
        let freshness = analyzer.muscleFreshness(sessions: sessions)

        // 3. Select target muscles (based on duration)
        let muscleCount: Int
        switch selectedDuration {
        case 15: muscleCount = 1
        case 30: muscleCount = 2
        case 45: muscleCount = 3
        default: muscleCount = 4
        }

        // Exclude .fullBody and .calves from primary targeting
        let primaryCandidates = freshness.filter { $0.muscle != .fullBody && $0.muscle != .calves }
        let targetMuscles = Array(primaryCandidates.prefix(muscleCount).map(\.muscle))

        guard !targetMuscles.isEmpty else {
            warningMessage = "No muscle groups available."
            return
        }

        // 4. Build candidate pool: matching muscles + available equipment
        var candidates = filterCandidates(
            targetMuscles: targetMuscles,
            equipment: availableEquipment,
            customTemplates: customTemplates
        )

        // Fallback to bodyweight if too few candidates
        if candidates.count < 3 {
            let bodyweightFallback = filterCandidates(
                targetMuscles: targetMuscles,
                equipment: [.bodyweight],
                customTemplates: customTemplates
            )
            for item in bodyweightFallback where !candidates.contains(where: { $0.id == item.id }) {
                candidates.append(item)
            }
            if candidates.count < 3 {
                warningMessage = "Limited exercises for your equipment. Consider updating your profile."
            }
        }

        // 5. Calculate volume
        let volume = calculateVolume(durationMinutes: selectedDuration)

        // 6. Select exercises
        let selected = selectExercises(
            from: candidates,
            targetMuscles: targetMuscles,
            count: volume.exercisesPerSet
        )

        // 7. Convert to DraftExercise
        generatedExercises = selected.enumerated().map { index, item in
            WorkoutBuilderViewModel.DraftExercise(
                name: item.name,
                splitLength: item.defaultDuration,
                reps: item.defaultReps,
                targetMuscleGroups: item.muscles,
                equipment: item.equipment,
                exerciseMode: item.exerciseMode,
                templateID: item.id
            )
        }

        // 8. Generate name
        generatedName = generateWorkoutName(targetMuscles: targetMuscles)
        muscleFocusSummary = targetMuscles.map(\.displayName).joined(separator: " & ").uppercased() + " FOCUS"
        hasGenerated = true
    }

    // MARK: - Swap Exercise

    /// Replaces the exercise at the given index with a new one.
    func swapExercise(at index: Int, with item: ExercisePickerItem) {
        guard generatedExercises.indices.contains(index) else { return }
        generatedExercises[index] = WorkoutBuilderViewModel.DraftExercise(
            name: item.name,
            splitLength: item.defaultDuration,
            reps: item.defaultReps,
            targetMuscleGroups: item.muscles,
            equipment: item.equipment,
            exerciseMode: item.exerciseMode,
            templateID: item.id
        )
    }

    // MARK: - Save & Create Workout

    /// Creates and persists the generated workout, returning it for navigation.
    func createWorkout(in context: ModelContext) -> Workout {
        let volume = calculateVolume(durationMinutes: selectedDuration)

        let workout = Workout(
            name: generatedName.trimmingCharacters(in: .whitespaces),
            type: selectedType,
            warmupLength: volume.warmup,
            intervalLength: volume.intervalLength,
            restLength: volume.restLength,
            numberOfIntervals: generatedExercises.count,
            numberOfSets: volume.totalSets,
            restBetweenSetLength: volume.restBetweenSets,
            cooldownLength: volume.cooldown
        )
        context.insert(workout)

        for (index, draft) in generatedExercises.enumerated() {
            let exercise = Exercise(
                order: index,
                name: draft.name.trimmingCharacters(in: .whitespaces),
                splitLength: draft.splitLength,
                reps: draft.reps,
                targetMuscleGroupsRaw: draft.targetMuscleGroups.map(\.rawValue).joined(separator: ","),
                equipmentRaw: draft.equipment.rawValue,
                exerciseModeRaw: draft.exerciseMode.rawValue,
                templateID: draft.templateID
            )
            exercise.workout = workout
            workout.exercises.append(exercise)
            context.insert(exercise)
        }

        try? context.save()
        return workout
    }

    // MARK: - Volume Calculation

    struct VolumeSpec {
        let exercisesPerSet: Int
        let totalSets: Int
        let intervalLength: Int
        let restLength: Int
        let warmup: Int
        let cooldown: Int
        let restBetweenSets: Int
    }

    func calculateVolume(durationMinutes: Int) -> VolumeSpec {
        let intervalLen = 45
        let restLen = 30
        let warmup = durationMinutes >= 30 ? 120 : 60
        let cooldown = durationMinutes >= 30 ? 60 : 30
        let restBetweenSets = 60

        let effectiveTime = (durationMinutes * 60) - warmup - cooldown
        let timePerExercise = intervalLen + restLen  // ~75 sec

        let totalSets: Int
        let exercisesPerSet: Int

        switch durationMinutes {
        case 15:
            totalSets = 1
            exercisesPerSet = min(6, max(3, effectiveTime / timePerExercise))
        case 30:
            totalSets = 2
            let perSet = effectiveTime - restBetweenSets // account for rest between sets
            exercisesPerSet = min(8, max(4, perSet / totalSets / timePerExercise))
        case 45:
            totalSets = 2
            let perSet = effectiveTime - restBetweenSets
            exercisesPerSet = min(10, max(5, perSet / totalSets / timePerExercise))
        default: // 60
            totalSets = 3
            let perSet = effectiveTime - (restBetweenSets * 2)
            exercisesPerSet = min(10, max(6, perSet / totalSets / timePerExercise))
        }

        return VolumeSpec(
            exercisesPerSet: exercisesPerSet,
            totalSets: totalSets,
            intervalLength: intervalLen,
            restLength: restLen,
            warmup: warmup,
            cooldown: cooldown,
            restBetweenSets: restBetweenSets
        )
    }

    // MARK: - Private Helpers

    private func filterCandidates(
        targetMuscles: [MuscleGroup],
        equipment: Set<Equipment>,
        customTemplates: [CustomExerciseTemplate]
    ) -> [ExercisePickerItem] {
        let targetSet = Set(targetMuscles)

        // Built-in library
        let builtIn = ExerciseTemplate.filtered(
            muscles: targetSet,
            equipment: equipment,
            search: ""
        ).map { ExercisePickerItem(from: $0) }

        // Custom templates matching
        let custom = customTemplates
            .filter { ct in
                let ctMuscles = Set(ct.muscleGroups)
                return !ctMuscles.isDisjoint(with: targetSet) && equipment.contains(ct.equipment)
            }
            .map { ExercisePickerItem(from: $0) }

        return builtIn + custom
    }

    private func selectExercises(
        from candidates: [ExercisePickerItem],
        targetMuscles: [MuscleGroup],
        count: Int
    ) -> [ExercisePickerItem] {
        guard !candidates.isEmpty else { return [] }

        // Distribute slots across muscles
        let perMuscle = max(1, count / targetMuscles.count)
        let remainder = count - (perMuscle * targetMuscles.count)
        var selected: [ExercisePickerItem] = []
        var usedIDs: Set<String> = []

        for (i, muscle) in targetMuscles.enumerated() {
            let slotsForMuscle = perMuscle + (i < remainder ? 1 : 0)

            let pool = candidates.filter { item in
                item.primaryMuscle == muscle && !usedIDs.contains(item.id)
            }

            // Separate compounds (muscles.count >= 2) and isolations
            let compounds = pool.filter { $0.muscles.count >= 2 }.shuffled()
            let isolations = pool.filter { $0.muscles.count < 2 }.shuffled()

            // Pick compounds first (up to half), then isolations
            let compoundCount = min(compounds.count, (slotsForMuscle + 1) / 2)
            let picks = Array(compounds.prefix(compoundCount))
                + Array(isolations.prefix(slotsForMuscle - compoundCount))

            for pick in picks.prefix(slotsForMuscle) {
                selected.append(pick)
                usedIDs.insert(pick.id)
            }
        }

        // If we still need more (e.g. not enough per-muscle), fill from remaining
        if selected.count < count {
            let remaining = candidates.filter { !usedIDs.contains($0.id) }.shuffled()
            for item in remaining {
                if selected.count >= count { break }
                selected.append(item)
                usedIDs.insert(item.id)
            }
        }

        return Array(selected.prefix(count))
    }

    private func generateWorkoutName(targetMuscles: [MuscleGroup]) -> String {
        let adjectives = ["NEON", "CYBER", "LASER", "TURBO", "HYPER", "ULTRA", "MEGA", "PLASMA", "BLAZE", "SURGE"]
        let adj = adjectives.randomElement() ?? "NEON"

        if targetMuscles.count == 1 {
            return "\(adj) \(targetMuscles[0].displayName.uppercased())"
        } else if targetMuscles.count == 2 {
            return "\(adj) \(targetMuscles[0].displayName.uppercased()) & \(targetMuscles[1].displayName.uppercased())"
        } else {
            return "\(adj) POWER MIX"
        }
    }
}
