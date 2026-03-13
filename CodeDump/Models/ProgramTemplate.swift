import Foundation

// MARK: - Program Difficulty

enum ProgramDifficulty: String, CaseIterable, Codable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var color: String {
        switch self {
        case .beginner:     return "outrunGreen"
        case .intermediate: return "outrunCyan"
        case .advanced:     return "outrunPink"
        }
    }
}

// MARK: - Program Day Template

struct ProgramDayTemplate: Identifiable, Hashable {
    let id: String
    let label: String
    let workoutType: WorkoutType
    let exerciseTemplateIDs: [String]
    let warmup: Int
    let intervalLength: Int
    let restLength: Int
    let numberOfSets: Int
    let restBetweenSets: Int
    let cooldown: Int
}

// MARK: - Program Template

struct ProgramTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let durationWeeks: Int
    let daysPerWeek: Int
    /// Weekday (1=Monday..7=Sunday) → ProgramDayTemplate.id. Missing days are rest days.
    let schedule: [Int: String]
    let dayTemplates: [ProgramDayTemplate]
    let difficulty: ProgramDifficulty

    func dayTemplate(for id: String) -> ProgramDayTemplate? {
        dayTemplates.first { $0.id == id }
    }

    func dayTemplate(forWeekday weekday: Int) -> ProgramDayTemplate? {
        guard let templateID = schedule[weekday] else { return nil }
        return dayTemplate(for: templateID)
    }

    /// All unique equipment types needed by this program.
    var requiredEquipment: Set<Equipment> {
        var result = Set<Equipment>()
        let lookup = Dictionary(uniqueKeysWithValues: ExerciseTemplate.library.map { ($0.id, $0) })
        for day in dayTemplates {
            for id in day.exerciseTemplateIDs {
                if let template = lookup[id] {
                    result.insert(template.equipment)
                }
            }
        }
        return result
    }

    // MARK: - Hashable (schedule dict needs custom)

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ProgramTemplate, rhs: ProgramTemplate) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Built-in Library

extension ProgramTemplate {
    static let library: [ProgramTemplate] = [
        pushPullLegs,
        upperLower,
        fullBody,
        hiitShred,
        beginner,
    ]

    static func find(_ id: String) -> ProgramTemplate? {
        library.first { $0.id == id }
    }

    // ── Push / Pull / Legs ──

    private static let pushPullLegs = ProgramTemplate(
        id: "push-pull-legs",
        name: "Push / Pull / Legs",
        description: "Classic 6-day split hitting each muscle group twice per week. Great for building size and strength with high frequency.",
        durationWeeks: 8,
        daysPerWeek: 6,
        schedule: [
            1: "ppl-push-a", 2: "ppl-pull-a", 3: "ppl-legs-a",
            4: "ppl-push-b", 5: "ppl-pull-b", 6: "ppl-legs-b",
        ],
        dayTemplates: [
            ProgramDayTemplate(
                id: "ppl-push-a", label: "Push A",
                workoutType: .strength,
                exerciseTemplateIDs: ["barbell-bench-press", "incline-dumbbell-press", "lateral-raises", "tricep-pushdown", "overhead-tricep-extension", "cable-flyes"],
                warmup: 120, intervalLength: 45, restLength: 30, numberOfSets: 3, restBetweenSets: 90, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "ppl-pull-a", label: "Pull A",
                workoutType: .strength,
                exerciseTemplateIDs: ["barbell-row", "pull-ups", "lat-pulldown", "face-pulls", "barbell-curl", "hammer-curl"],
                warmup: 120, intervalLength: 45, restLength: 30, numberOfSets: 3, restBetweenSets: 90, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "ppl-legs-a", label: "Legs A",
                workoutType: .strength,
                exerciseTemplateIDs: ["barbell-squat", "romanian-deadlift", "leg-press", "leg-curl", "standing-calf-raise", "walking-lunges"],
                warmup: 120, intervalLength: 50, restLength: 30, numberOfSets: 3, restBetweenSets: 120, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "ppl-push-b", label: "Push B",
                workoutType: .strength,
                exerciseTemplateIDs: ["dumbbell-bench-press", "overhead-press", "dumbbell-flyes", "arnold-press", "close-grip-bench", "diamond-push-ups"],
                warmup: 120, intervalLength: 45, restLength: 30, numberOfSets: 3, restBetweenSets: 90, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "ppl-pull-b", label: "Pull B",
                workoutType: .strength,
                exerciseTemplateIDs: ["dumbbell-row", "chin-ups", "seated-cable-row", "reverse-flyes", "concentration-curl", "cable-curl"],
                warmup: 120, intervalLength: 45, restLength: 30, numberOfSets: 3, restBetweenSets: 90, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "ppl-legs-b", label: "Legs B",
                workoutType: .strength,
                exerciseTemplateIDs: ["front-squat", "hip-thrust", "bulgarian-split-squat", "leg-extension", "seated-calf-raise", "kettlebell-swing"],
                warmup: 120, intervalLength: 50, restLength: 30, numberOfSets: 3, restBetweenSets: 120, cooldown: 60
            ),
        ],
        difficulty: .intermediate
    )

    // ── Upper / Lower ──

    private static let upperLower = ProgramTemplate(
        id: "upper-lower",
        name: "Upper / Lower",
        description: "Balanced 4-day split alternating upper and lower body. Ideal for intermediate lifters wanting solid recovery between sessions.",
        durationWeeks: 10,
        daysPerWeek: 4,
        schedule: [1: "ul-upper-a", 2: "ul-lower-a", 4: "ul-upper-b", 5: "ul-lower-b"],
        dayTemplates: [
            ProgramDayTemplate(
                id: "ul-upper-a", label: "Upper A",
                workoutType: .strength,
                exerciseTemplateIDs: ["barbell-bench-press", "barbell-row", "overhead-press", "lat-pulldown", "dumbbell-curl", "tricep-pushdown"],
                warmup: 120, intervalLength: 45, restLength: 30, numberOfSets: 3, restBetweenSets: 90, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "ul-lower-a", label: "Lower A",
                workoutType: .strength,
                exerciseTemplateIDs: ["barbell-squat", "romanian-deadlift", "leg-press", "leg-curl", "standing-calf-raise", "plank"],
                warmup: 120, intervalLength: 50, restLength: 30, numberOfSets: 3, restBetweenSets: 120, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "ul-upper-b", label: "Upper B",
                workoutType: .strength,
                exerciseTemplateIDs: ["dumbbell-bench-press", "dumbbell-row", "dumbbell-shoulder-press", "chin-ups", "hammer-curl", "overhead-tricep-extension"],
                warmup: 120, intervalLength: 45, restLength: 30, numberOfSets: 3, restBetweenSets: 90, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "ul-lower-b", label: "Lower B",
                workoutType: .strength,
                exerciseTemplateIDs: ["front-squat", "hip-thrust", "bulgarian-split-squat", "leg-extension", "seated-calf-raise", "hanging-leg-raise"],
                warmup: 120, intervalLength: 50, restLength: 30, numberOfSets: 3, restBetweenSets: 120, cooldown: 60
            ),
        ],
        difficulty: .intermediate
    )

    // ── Full Body ──

    private static let fullBody = ProgramTemplate(
        id: "full-body",
        name: "Full Body",
        description: "Hit every muscle group three times per week with three distinct routines. Perfect for maximizing training frequency on limited days.",
        durationWeeks: 10,
        daysPerWeek: 3,
        schedule: [1: "fb-day-a", 3: "fb-day-b", 5: "fb-day-c"],
        dayTemplates: [
            ProgramDayTemplate(
                id: "fb-day-a", label: "Full Body A",
                workoutType: .strength,
                exerciseTemplateIDs: ["barbell-squat", "barbell-bench-press", "barbell-row", "overhead-press", "barbell-curl", "plank"],
                warmup: 120, intervalLength: 50, restLength: 30, numberOfSets: 3, restBetweenSets: 120, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "fb-day-b", label: "Full Body B",
                workoutType: .strength,
                exerciseTemplateIDs: ["deadlift", "incline-dumbbell-press", "dumbbell-row", "lateral-raises", "tricep-pushdown", "hanging-leg-raise"],
                warmup: 120, intervalLength: 50, restLength: 30, numberOfSets: 3, restBetweenSets: 120, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "fb-day-c", label: "Full Body C",
                workoutType: .strength,
                exerciseTemplateIDs: ["front-squat", "dumbbell-bench-press", "pull-ups", "arnold-press", "hammer-curl", "russian-twist"],
                warmup: 120, intervalLength: 50, restLength: 30, numberOfSets: 3, restBetweenSets: 120, cooldown: 60
            ),
        ],
        difficulty: .intermediate
    )

    // ── HIIT Shred ──

    private static let hiitShred = ProgramTemplate(
        id: "hiit-shred",
        name: "HIIT Shred",
        description: "High-intensity 5-day program focused on fat loss and conditioning. Short intervals, compound movements, and metabolic circuits.",
        durationWeeks: 6,
        daysPerWeek: 5,
        schedule: [
            1: "hiit-upper-push", 2: "hiit-lower-power", 3: "hiit-full-metabolic",
            4: "hiit-upper-pull", 5: "hiit-lower-burn",
        ],
        dayTemplates: [
            ProgramDayTemplate(
                id: "hiit-upper-push", label: "Upper Push HIIT",
                workoutType: .hiit,
                exerciseTemplateIDs: ["push-ups", "thrusters", "mountain-climbers", "dumbbell-shoulder-press", "diamond-push-ups", "burpees"],
                warmup: 90, intervalLength: 30, restLength: 15, numberOfSets: 3, restBetweenSets: 60, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "hiit-lower-power", label: "Lower Power HIIT",
                workoutType: .hiit,
                exerciseTemplateIDs: ["jump-squats", "kettlebell-swing", "walking-lunges", "goblet-squat", "box-jumps", "glute-bridge"],
                warmup: 90, intervalLength: 30, restLength: 15, numberOfSets: 3, restBetweenSets: 60, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "hiit-full-metabolic", label: "Metabolic Circuit",
                workoutType: .hiit,
                exerciseTemplateIDs: ["burpees", "mountain-climbers", "kettlebell-swing", "thrusters", "battle-ropes", "man-makers"],
                warmup: 60, intervalLength: 30, restLength: 10, numberOfSets: 4, restBetweenSets: 60, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "hiit-upper-pull", label: "Upper Pull HIIT",
                workoutType: .hiit,
                exerciseTemplateIDs: ["dumbbell-row", "band-pull-apart", "chin-ups", "face-pulls", "dumbbell-curl", "banded-row"],
                warmup: 90, intervalLength: 30, restLength: 15, numberOfSets: 3, restBetweenSets: 60, cooldown: 60
            ),
            ProgramDayTemplate(
                id: "hiit-lower-burn", label: "Lower Burn HIIT",
                workoutType: .hiit,
                exerciseTemplateIDs: ["banded-squat", "dumbbell-rdl", "jump-squats", "walking-lunges", "bodyweight-calf-raise", "mountain-climbers"],
                warmup: 90, intervalLength: 30, restLength: 15, numberOfSets: 3, restBetweenSets: 60, cooldown: 60
            ),
        ],
        difficulty: .advanced
    )

    // ── Beginner ──

    private static let beginner = ProgramTemplate(
        id: "beginner",
        name: "Beginner",
        description: "Gentle 3-day introduction to strength training. Machine and bodyweight focused with lower volume and longer rest periods.",
        durationWeeks: 8,
        daysPerWeek: 3,
        schedule: [1: "beg-day-a", 3: "beg-day-b", 5: "beg-day-c"],
        dayTemplates: [
            ProgramDayTemplate(
                id: "beg-day-a", label: "Day A",
                workoutType: .strength,
                exerciseTemplateIDs: ["machine-chest-press", "lat-pulldown", "leg-press", "dumbbell-curl", "plank"],
                warmup: 180, intervalLength: 45, restLength: 45, numberOfSets: 2, restBetweenSets: 90, cooldown: 120
            ),
            ProgramDayTemplate(
                id: "beg-day-b", label: "Day B",
                workoutType: .strength,
                exerciseTemplateIDs: ["goblet-squat", "dumbbell-bench-press", "seated-cable-row", "machine-shoulder-press", "dead-bug"],
                warmup: 180, intervalLength: 45, restLength: 45, numberOfSets: 2, restBetweenSets: 90, cooldown: 120
            ),
            ProgramDayTemplate(
                id: "beg-day-c", label: "Day C",
                workoutType: .strength,
                exerciseTemplateIDs: ["leg-extension", "leg-curl", "dumbbell-row", "push-ups", "bicycle-crunches"],
                warmup: 180, intervalLength: 45, restLength: 45, numberOfSets: 2, restBetweenSets: 90, cooldown: 120
            ),
        ],
        difficulty: .beginner
    )
}
