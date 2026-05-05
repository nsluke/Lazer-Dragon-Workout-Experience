import Foundation

// MARK: - Muscle Group

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest, back, shoulders, biceps, triceps
    case quads, hamstrings, glutes, calves
    case core, fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .chest:      return "figure.strengthtraining.traditional"
        case .back:       return "figure.rowing"
        case .shoulders:  return "figure.boxing"
        case .biceps:     return "figure.arms.open"
        case .triceps:    return "figure.arms.open"
        case .quads:      return "figure.walk"
        case .hamstrings: return "figure.walk"
        case .glutes:     return "figure.step.training"
        case .calves:     return "figure.step.training"
        case .core:       return "figure.core.training"
        case .fullBody:   return "figure.cross.training"
        }
    }
}

// MARK: - Equipment

enum Equipment: String, CaseIterable, Codable, Identifiable {
    case bodyweight, dumbbells, barbell, kettlebell
    case cable, machine, band, pullupBar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pullupBar: return "Pull-up Bar"
        default: return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .bodyweight:  return "figure.stand"
        case .dumbbells:   return "dumbbell.fill"
        case .barbell:     return "scalemass.fill"
        case .kettlebell:  return "figure.strengthtraining.functional"
        case .cable:       return "cable.connector"
        case .machine:     return "gearshape.fill"
        case .band:        return "lasso"
        case .pullupBar:   return "figure.climbing"
        }
    }
}

// MARK: - Exercise Mode

enum ExerciseMode: String, CaseIterable, Codable, Identifiable {
    case repBased   // Weight + reps + RPE logging (bench press, squat, etc.)
    case timeBased  // Duration + RPE logging (plank, wall sit, etc.)
    case hybrid     // User picks rep or timed when adding to workout (burpees, mountain climbers)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .repBased:  return "Rep-Based"
        case .timeBased: return "Timed"
        case .hybrid:    return "Hybrid"
        }
    }

    var icon: String {
        switch self {
        case .repBased:  return "repeat"
        case .timeBased: return "timer"
        case .hybrid:    return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Exercise Template (Library)

struct ExerciseTemplate: Identifiable, Hashable {
    let id: String            // stable key, e.g. "barbell-bench-press"
    let name: String
    let muscles: [MuscleGroup]
    let equipment: Equipment
    let instructions: String
    let defaultDuration: Int  // seconds — used when adding to a workout
    let defaultReps: Int      // 0 = timed, >0 = rep-based
    let exerciseMode: ExerciseMode

    var primaryMuscle: MuscleGroup { muscles[0] }
}

// MARK: - Built-in Library

extension ExerciseTemplate {
    static let library: [ExerciseTemplate] = [
        // ── Chest ──
        .init(id: "barbell-bench-press",      name: "Barbell Bench Press",       muscles: [.chest, .triceps, .shoulders],     equipment: .barbell,    instructions: "Lie flat, lower bar to chest, press up.",                    defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "dumbbell-bench-press",      name: "Dumbbell Bench Press",      muscles: [.chest, .triceps, .shoulders],     equipment: .dumbbells,  instructions: "Lie flat, press dumbbells from chest level.",                defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "incline-bench-press",       name: "Incline Bench Press",       muscles: [.chest, .shoulders],               equipment: .barbell,    instructions: "Set bench to 30-45°, press bar from upper chest.",          defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "incline-dumbbell-press",    name: "Incline Dumbbell Press",    muscles: [.chest, .shoulders],               equipment: .dumbbells,  instructions: "Set bench to 30-45°, press dumbbells up.",                  defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "dumbbell-flyes",            name: "Dumbbell Flyes",            muscles: [.chest],                           equipment: .dumbbells,  instructions: "Lie flat, arc dumbbells out and together.",                  defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "cable-flyes",               name: "Cable Flyes",               muscles: [.chest],                           equipment: .cable,      instructions: "Set cables high, bring handles together in front.",         defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "push-ups",                  name: "Push-Ups",                  muscles: [.chest, .triceps, .core],           equipment: .bodyweight, instructions: "Hands shoulder-width, lower chest to floor, push up.",      defaultDuration: 30, defaultReps: 15, exerciseMode: .hybrid),
        .init(id: "chest-dips",                name: "Chest Dips",                muscles: [.chest, .triceps],                  equipment: .bodyweight, instructions: "Lean forward on dip bars, lower and press up.",             defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "machine-chest-press",       name: "Machine Chest Press",       muscles: [.chest, .triceps],                  equipment: .machine,    instructions: "Sit upright, press handles forward.",                       defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "pec-deck",                  name: "Pec Deck",                  muscles: [.chest],                           equipment: .machine,    instructions: "Sit upright, bring padded arms together.",                  defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),

        // ── Back ──
        .init(id: "barbell-row",               name: "Barbell Row",               muscles: [.back, .biceps],                   equipment: .barbell,    instructions: "Hinge at hips, pull bar to lower chest.",                   defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "dumbbell-row",              name: "Dumbbell Row",              muscles: [.back, .biceps],                   equipment: .dumbbells,  instructions: "One knee on bench, row dumbbell to hip.",                   defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "pull-ups",                  name: "Pull-Ups",                  muscles: [.back, .biceps],                   equipment: .pullupBar,  instructions: "Hang with overhand grip, pull chin above bar.",             defaultDuration: 45, defaultReps: 8,  exerciseMode: .repBased),
        .init(id: "chin-ups",                  name: "Chin-Ups",                  muscles: [.back, .biceps],                   equipment: .pullupBar,  instructions: "Hang with underhand grip, pull chin above bar.",            defaultDuration: 45, defaultReps: 8,  exerciseMode: .repBased),
        .init(id: "lat-pulldown",              name: "Lat Pulldown",              muscles: [.back, .biceps],                   equipment: .cable,      instructions: "Sit at cable station, pull bar to upper chest.",            defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "seated-cable-row",          name: "Seated Cable Row",          muscles: [.back, .biceps],                   equipment: .cable,      instructions: "Sit upright, pull handle to abdomen.",                      defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "deadlift",                  name: "Deadlift",                  muscles: [.back, .hamstrings, .glutes],       equipment: .barbell,    instructions: "Stand over bar, hinge and lift with flat back.",            defaultDuration: 60, defaultReps: 5,  exerciseMode: .repBased),
        .init(id: "face-pulls",                name: "Face Pulls",                muscles: [.back, .shoulders],                equipment: .cable,      instructions: "Pull rope to face height, squeeze shoulder blades.",        defaultDuration: 45, defaultReps: 15, exerciseMode: .repBased),
        .init(id: "t-bar-row",                 name: "T-Bar Row",                 muscles: [.back, .biceps],                   equipment: .barbell,    instructions: "Straddle bar, pull to chest with V-handle.",                defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),

        // ── Shoulders ──
        .init(id: "overhead-press",            name: "Overhead Press",            muscles: [.shoulders, .triceps],             equipment: .barbell,    instructions: "Press bar from shoulders to overhead lockout.",             defaultDuration: 45, defaultReps: 8,  exerciseMode: .repBased),
        .init(id: "dumbbell-shoulder-press",   name: "Dumbbell Shoulder Press",   muscles: [.shoulders, .triceps],             equipment: .dumbbells,  instructions: "Press dumbbells from shoulder height overhead.",             defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "lateral-raises",            name: "Lateral Raises",            muscles: [.shoulders],                       equipment: .dumbbells,  instructions: "Raise dumbbells out to sides until parallel.",              defaultDuration: 30, defaultReps: 15, exerciseMode: .repBased),
        .init(id: "front-raises",              name: "Front Raises",              muscles: [.shoulders],                       equipment: .dumbbells,  instructions: "Raise dumbbells in front to shoulder height.",              defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "reverse-flyes",             name: "Reverse Flyes",             muscles: [.shoulders, .back],                equipment: .dumbbells,  instructions: "Bent over, raise dumbbells out to sides.",                  defaultDuration: 30, defaultReps: 15, exerciseMode: .repBased),
        .init(id: "arnold-press",              name: "Arnold Press",              muscles: [.shoulders, .triceps],             equipment: .dumbbells,  instructions: "Rotate palms from facing you to forward as you press up.", defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "upright-row",               name: "Upright Row",               muscles: [.shoulders, .biceps],              equipment: .barbell,    instructions: "Pull bar up along body to chin height.",                    defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "machine-shoulder-press",    name: "Machine Shoulder Press",    muscles: [.shoulders, .triceps],             equipment: .machine,    instructions: "Sit upright, press handles overhead.",                      defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),

        // ── Biceps ──
        .init(id: "barbell-curl",              name: "Barbell Curl",              muscles: [.biceps],                          equipment: .barbell,    instructions: "Curl bar from thighs to shoulders, elbows pinned.",        defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "dumbbell-curl",             name: "Dumbbell Curl",             muscles: [.biceps],                          equipment: .dumbbells,  instructions: "Alternate curling dumbbells to shoulders.",                 defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "hammer-curl",               name: "Hammer Curl",               muscles: [.biceps],                          equipment: .dumbbells,  instructions: "Curl with neutral grip (palms facing each other).",        defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "concentration-curl",        name: "Concentration Curl",        muscles: [.biceps],                          equipment: .dumbbells,  instructions: "Sit, brace elbow on inner thigh, curl up.",                defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "cable-curl",                name: "Cable Curl",                muscles: [.biceps],                          equipment: .cable,      instructions: "Curl cable handle from low pulley.",                        defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "preacher-curl",             name: "Preacher Curl",             muscles: [.biceps],                          equipment: .barbell,    instructions: "Rest arms on preacher pad, curl bar up.",                   defaultDuration: 30, defaultReps: 10, exerciseMode: .repBased),

        // ── Triceps ──
        .init(id: "tricep-pushdown",           name: "Tricep Pushdown",           muscles: [.triceps],                         equipment: .cable,      instructions: "Push cable bar down, keeping elbows pinned.",              defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "overhead-tricep-extension", name: "Overhead Tricep Extension", muscles: [.triceps],                         equipment: .dumbbells,  instructions: "Hold dumbbell overhead, lower behind head, extend.",       defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "skull-crushers",            name: "Skull Crushers",            muscles: [.triceps],                         equipment: .barbell,    instructions: "Lie flat, lower bar to forehead, extend arms.",            defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "close-grip-bench",          name: "Close-Grip Bench Press",    muscles: [.triceps, .chest],                  equipment: .barbell,    instructions: "Bench press with hands shoulder-width apart.",              defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "tricep-dips",               name: "Tricep Dips",               muscles: [.triceps, .chest],                  equipment: .bodyweight, instructions: "Upright on dip bars, lower and press up.",                  defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "diamond-push-ups",          name: "Diamond Push-Ups",          muscles: [.triceps, .chest],                  equipment: .bodyweight, instructions: "Push-ups with hands together forming a diamond.",          defaultDuration: 30, defaultReps: 12, exerciseMode: .hybrid),
        .init(id: "cable-overhead-extension",  name: "Cable Overhead Extension",  muscles: [.triceps],                         equipment: .cable,      instructions: "Face away from cable, extend rope overhead.",               defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),

        // ── Quads ──
        .init(id: "barbell-squat",             name: "Barbell Squat",             muscles: [.quads, .glutes, .core],            equipment: .barbell,    instructions: "Bar on upper back, squat to parallel or below.",           defaultDuration: 60, defaultReps: 8,  exerciseMode: .repBased),
        .init(id: "front-squat",               name: "Front Squat",               muscles: [.quads, .core],                    equipment: .barbell,    instructions: "Bar on front delts, squat keeping torso upright.",          defaultDuration: 60, defaultReps: 8,  exerciseMode: .repBased),
        .init(id: "goblet-squat",              name: "Goblet Squat",              muscles: [.quads, .glutes],                  equipment: .kettlebell, instructions: "Hold kettlebell at chest, squat deep.",                     defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "leg-press",                 name: "Leg Press",                 muscles: [.quads, .glutes],                  equipment: .machine,    instructions: "Feet shoulder-width on platform, press up.",               defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "leg-extension",             name: "Leg Extension",             muscles: [.quads],                           equipment: .machine,    instructions: "Sit upright, extend legs to straight.",                     defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "walking-lunges",            name: "Walking Lunges",            muscles: [.quads, .glutes],                  equipment: .bodyweight, instructions: "Step forward into lunge, alternate legs.",                  defaultDuration: 45, defaultReps: 12, exerciseMode: .hybrid),
        .init(id: "bulgarian-split-squat",     name: "Bulgarian Split Squat",     muscles: [.quads, .glutes],                  equipment: .dumbbells,  instructions: "Rear foot on bench, lunge down on front leg.",              defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "sissy-squat",               name: "Sissy Squat",               muscles: [.quads],                           equipment: .bodyweight, instructions: "Lean back, bend knees, lower hips forward.",                defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),

        // ── Hamstrings ──
        .init(id: "romanian-deadlift",         name: "Romanian Deadlift",         muscles: [.hamstrings, .glutes],             equipment: .barbell,    instructions: "Hinge at hips with slight knee bend, lower bar.",          defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "dumbbell-rdl",              name: "Dumbbell RDL",              muscles: [.hamstrings, .glutes],             equipment: .dumbbells,  instructions: "Hinge with dumbbells along thighs.",                        defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "leg-curl",                  name: "Leg Curl",                  muscles: [.hamstrings],                      equipment: .machine,    instructions: "Lie face down, curl heels toward glutes.",                  defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "nordic-hamstring-curl",     name: "Nordic Hamstring Curl",     muscles: [.hamstrings],                      equipment: .bodyweight, instructions: "Kneel, slowly lower torso forward, catch and push back.",  defaultDuration: 45, defaultReps: 6,  exerciseMode: .repBased),
        .init(id: "kettlebell-swing",          name: "Kettlebell Swing",          muscles: [.hamstrings, .glutes, .core],       equipment: .kettlebell, instructions: "Hinge and swing kettlebell to shoulder height.",            defaultDuration: 30, defaultReps: 15, exerciseMode: .hybrid),
        .init(id: "good-mornings",             name: "Good Mornings",             muscles: [.hamstrings, .back],               equipment: .barbell,    instructions: "Bar on back, hinge forward keeping legs nearly straight.", defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),

        // ── Glutes ──
        .init(id: "hip-thrust",                name: "Hip Thrust",                muscles: [.glutes, .hamstrings],             equipment: .barbell,    instructions: "Upper back on bench, drive hips up with bar on lap.",      defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "glute-bridge",              name: "Glute Bridge",              muscles: [.glutes],                          equipment: .bodyweight, instructions: "Lie on back, feet flat, drive hips up.",                    defaultDuration: 30, defaultReps: 15, exerciseMode: .hybrid),
        .init(id: "cable-kickback",            name: "Cable Kickback",            muscles: [.glutes],                          equipment: .cable,      instructions: "Attach ankle cuff, kick leg straight back.",               defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "sumo-deadlift",             name: "Sumo Deadlift",             muscles: [.glutes, .quads, .back],            equipment: .barbell,    instructions: "Wide stance, toes out, grip inside knees, lift.",           defaultDuration: 60, defaultReps: 6,  exerciseMode: .repBased),

        // ── Calves ──
        .init(id: "standing-calf-raise",       name: "Standing Calf Raise",       muscles: [.calves],                          equipment: .machine,    instructions: "Rise onto toes under shoulder pads.",                       defaultDuration: 30, defaultReps: 15, exerciseMode: .repBased),
        .init(id: "seated-calf-raise",         name: "Seated Calf Raise",         muscles: [.calves],                          equipment: .machine,    instructions: "Sit with pad on knees, rise onto toes.",                    defaultDuration: 30, defaultReps: 15, exerciseMode: .repBased),
        .init(id: "bodyweight-calf-raise",     name: "Bodyweight Calf Raise",     muscles: [.calves],                          equipment: .bodyweight, instructions: "Stand on step edge, rise and lower on toes.",               defaultDuration: 30, defaultReps: 20, exerciseMode: .repBased),

        // ── Core ──
        .init(id: "plank",                     name: "Plank",                     muscles: [.core],                            equipment: .bodyweight, instructions: "Hold push-up position on forearms, body straight.",        defaultDuration: 45, defaultReps: 0,  exerciseMode: .timeBased),
        .init(id: "side-plank",                name: "Side Plank",                muscles: [.core],                            equipment: .bodyweight, instructions: "Lie on side, prop on forearm, hold hips up.",               defaultDuration: 30, defaultReps: 0,  exerciseMode: .timeBased),
        .init(id: "hanging-leg-raise",         name: "Hanging Leg Raise",         muscles: [.core],                            equipment: .pullupBar,  instructions: "Hang from bar, raise legs to parallel.",                    defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "cable-woodchop",            name: "Cable Woodchop",            muscles: [.core],                            equipment: .cable,      instructions: "Rotate torso pulling cable diagonally across body.",       defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "ab-wheel-rollout",          name: "Ab Wheel Rollout",          muscles: [.core],                            equipment: .bodyweight, instructions: "Kneel, roll wheel forward, pull back with core.",          defaultDuration: 30, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "russian-twist",             name: "Russian Twist",             muscles: [.core],                            equipment: .bodyweight, instructions: "Sit, lean back, rotate torso side to side.",                defaultDuration: 30, defaultReps: 20, exerciseMode: .hybrid),
        .init(id: "bicycle-crunches",          name: "Bicycle Crunches",          muscles: [.core],                            equipment: .bodyweight, instructions: "Lie on back, alternate elbow to opposite knee.",            defaultDuration: 30, defaultReps: 20, exerciseMode: .hybrid),
        .init(id: "dead-bug",                  name: "Dead Bug",                  muscles: [.core],                            equipment: .bodyweight, instructions: "Lie on back, extend opposite arm and leg alternately.",     defaultDuration: 30, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "mountain-climbers",         name: "Mountain Climbers",         muscles: [.core, .quads],                    equipment: .bodyweight, instructions: "Plank position, drive knees to chest alternately.",        defaultDuration: 30, defaultReps: 0,  exerciseMode: .timeBased),

        // ── Full Body ──
        .init(id: "burpees",                   name: "Burpees",                   muscles: [.fullBody],                        equipment: .bodyweight, instructions: "Squat, jump back to plank, push-up, jump up.",             defaultDuration: 30, defaultReps: 10, exerciseMode: .hybrid),
        .init(id: "thrusters",                 name: "Thrusters",                 muscles: [.fullBody],                        equipment: .barbell,    instructions: "Front squat into overhead press in one motion.",            defaultDuration: 45, defaultReps: 10, exerciseMode: .repBased),
        .init(id: "clean-and-press",           name: "Clean and Press",           muscles: [.fullBody],                        equipment: .barbell,    instructions: "Clean bar to shoulders, then press overhead.",              defaultDuration: 60, defaultReps: 6,  exerciseMode: .repBased),
        .init(id: "dumbbell-snatch",           name: "Dumbbell Snatch",           muscles: [.fullBody],                        equipment: .dumbbells,  instructions: "Pull dumbbell from floor to overhead in one motion.",       defaultDuration: 45, defaultReps: 8,  exerciseMode: .repBased),
        .init(id: "man-makers",                name: "Man Makers",                muscles: [.fullBody],                        equipment: .dumbbells,  instructions: "Push-up, row each side, squat clean, press overhead.",     defaultDuration: 60, defaultReps: 6,  exerciseMode: .repBased),
        .init(id: "turkish-get-up",            name: "Turkish Get-Up",            muscles: [.fullBody],                        equipment: .kettlebell, instructions: "Lie down with weight overhead, stand up keeping it up.",   defaultDuration: 60, defaultReps: 3,  exerciseMode: .repBased),
        .init(id: "battle-ropes",              name: "Battle Ropes",              muscles: [.fullBody],                        equipment: .bodyweight, instructions: "Alternate slamming heavy ropes up and down.",              defaultDuration: 30, defaultReps: 0,  exerciseMode: .timeBased),
        .init(id: "box-jumps",                 name: "Box Jumps",                 muscles: [.fullBody],                        equipment: .bodyweight, instructions: "Jump onto a box, step down, repeat.",                       defaultDuration: 30, defaultReps: 10, exerciseMode: .hybrid),
        .init(id: "jump-squats",               name: "Jump Squats",               muscles: [.quads, .glutes],                  equipment: .bodyweight, instructions: "Squat down, explode up into a jump.",                       defaultDuration: 30, defaultReps: 12, exerciseMode: .hybrid),

        // ── Band ──
        .init(id: "band-pull-apart",           name: "Band Pull-Apart",           muscles: [.shoulders, .back],                equipment: .band,       instructions: "Hold band at chest height, pull apart horizontally.",      defaultDuration: 30, defaultReps: 15, exerciseMode: .repBased),
        .init(id: "banded-squat",              name: "Banded Squat",              muscles: [.quads, .glutes],                  equipment: .band,       instructions: "Band above knees, squat keeping knees pushed out.",        defaultDuration: 45, defaultReps: 12, exerciseMode: .repBased),
        .init(id: "banded-row",                name: "Banded Row",                muscles: [.back, .biceps],                   equipment: .band,       instructions: "Anchor band, pull handles to torso.",                       defaultDuration: 30, defaultReps: 15, exerciseMode: .repBased),
        .init(id: "banded-face-pull",          name: "Banded Face Pull",          muscles: [.shoulders, .back],                equipment: .band,       instructions: "Anchor band at head height, pull to face.",                defaultDuration: 30, defaultReps: 15, exerciseMode: .repBased),
    ]

    /// Grouped by primary muscle for easy browsing.
    static var byMuscle: [MuscleGroup: [ExerciseTemplate]] {
        Dictionary(grouping: library, by: \.primaryMuscle)
    }

    /// Filtered by equipment availability.
    static func filtered(muscles: Set<MuscleGroup>, equipment: Set<Equipment>, search: String) -> [ExerciseTemplate] {
        library.filter { template in
            (muscles.isEmpty || template.muscles.contains(where: { muscles.contains($0) }))
            && (equipment.isEmpty || equipment.contains(template.equipment))
            && (search.isEmpty || template.name.localizedCaseInsensitiveContains(search))
        }
    }
}

// MARK: - Unified Picker Item

struct ExercisePickerItem: Identifiable, Hashable {
    let id: String
    let name: String
    let muscles: [MuscleGroup]
    let equipment: Equipment
    let instructions: String
    let defaultDuration: Int
    let defaultReps: Int
    let exerciseMode: ExerciseMode
    let isCustom: Bool

    var primaryMuscle: MuscleGroup { muscles.first ?? .fullBody }

    init(from template: ExerciseTemplate) {
        self.id = template.id
        self.name = template.name
        self.muscles = template.muscles
        self.equipment = template.equipment
        self.instructions = template.instructions
        self.defaultDuration = template.defaultDuration
        self.defaultReps = template.defaultReps
        self.exerciseMode = template.exerciseMode
        self.isCustom = false
    }

    init(from custom: CustomExerciseTemplate) {
        self.id = custom.id
        self.name = custom.name
        self.muscles = custom.muscleGroups
        self.equipment = custom.equipment
        self.instructions = custom.instructions
        self.defaultDuration = custom.defaultDuration
        self.defaultReps = custom.defaultReps
        self.exerciseMode = custom.exerciseMode
        self.isCustom = true
    }
}
