# The Lazer Dragon Workout Experience

A fully-featured iOS workout timer and training companion with an outrun/synthwave aesthetic. Built entirely in Swift with SwiftUI, SwiftData, and zero external dependencies.

[![Swift Version][swift-image]][swift-url] [![License][license-image]][license-url] [![Platform](https://img.shields.io/badge/platform-iOS%2018%2B-purple.svg)](https://developer.apple.com/ios/)

## Screenshots

| Home | Workout Builder | Workout Complete | Body Status |
|------|----------------|------------------|-------------|
| ![Home](screenshots/WorkoutMain.png) | ![Builder](screenshots/EditWorkout.png) | ![Complete](screenshots/WorkoutComplete.png) | ![Body](screenshots/Body.png) |

## Features

### Workout Engine
- Interval timer with configurable warmup, exercise, rest, and cooldown phases
- Per-set logging — track weight, reps, and RPE for every set
- Progressive overload suggestions based on RPE-driven linear periodization
- Personal record detection (weight PRs and rep PRs) with animated badges
- Live Activity support on the lock screen
- Apple Watch companion app

### Exercise Intelligence
- 96 built-in exercise templates with muscle group and equipment tagging
- Custom exercise creation with user-defined muscle targets
- Searchable and filterable exercise library
- Smart Quick Start — generates workouts based on muscle freshness and available equipment
- Equipment profiles (Home Gym, Commercial Gym, or custom)

### Training Programs
- 5 built-in programs (Push/Pull/Legs, Upper/Lower, Full Body, HIIT Shred, Beginner)
- Adaptive scheduling — adjusts when you miss days
- Fatigue-aware deload suggestions
- Completion tracking with calendar grid

### Body Status
- Muscle freshness scoring — see which muscles are recovered and ready to train
- Weekly volume and set tracking
- Recovery score powered by HealthKit (sleep + HRV + RPE composite)
- Recommended muscle groups to train next

### Goals
- Set targets for weight, reps, volume, workout frequency, or body weight
- Auto-tracking from workout history for weight/rep/volume/frequency goals
- Deadline tracking with progress bars
- Auto-completion when targets are met

### History & Analytics
- Monthly calendar view with workout activity
- Per-day drill-down showing session details, volume, and muscle groups hit
- Session-over-session volume trends
- Streak tracking

### Sharing & Export
- Outrun-styled share cards (1080×1920) via ImageRenderer
- Weekly stats cards (1080×1080)
- Workout template export/import (.ldwe file format with Transferable)

## Tech Stack

| | |
|---|---|
| **Language** | Swift 5 |
| **UI** | SwiftUI |
| **Data** | SwiftData + CloudKit (automatic sync) |
| **Architecture** | MVVM with `@Observable` ViewModels |
| **Min Deployment** | iOS 18 |
| **Dependencies** | None |

## Project Structure

```
CodeDump/
├── AppDelegate.swift            # @main app entry, TabView, navigation routing
├── Models/
│   ├── WorkoutModel.swift       # @Model Workout + WorkoutType enum
│   ├── Exercise.swift           # @Model Exercise (muscle groups, equipment, templateID)
│   ├── WorkoutSession.swift     # @Model WorkoutSession (date, duration, completion data)
│   ├── SetLog.swift             # @Model SetLog (weight/reps/RPE per set)
│   ├── FitnessGoal.swift        # @Model FitnessGoal (auto-tracked targets)
│   ├── TrainingProgram.swift    # @Model program enrollment + schedule
│   ├── CustomExerciseTemplate.swift
│   ├── ExerciseLibrary.swift    # 96 built-in exercise templates
│   ├── MuscleAnalyzer.swift     # Muscle freshness + volume scoring
│   ├── OverloadSuggestion.swift # Progressive overload algorithm
│   ├── RecoveryAnalyzer.swift   # HealthKit sleep/HRV recovery score
│   ├── SessionAnalytics.swift   # PR detection + volume analytics
│   ├── ProgramTemplate.swift    # Built-in program definitions
│   ├── EquipmentProfile.swift   # Equipment preset management
│   ├── WorkoutTransferable.swift
│   └── Theme.swift              # Outrun color palette + fonts + extensions
└── Features/
    ├── WorkoutList/             # Home screen with Quick Start + Programs
    ├── WorkoutDetail/           # Workout preview with muscle/equipment tags
    ├── WorkoutBuilder/          # Create/edit workouts with library picker
    ├── WorkoutSession/          # Timer, set logging, Live Activity, haptics
    ├── WorkoutCompleted/        # Post-workout summary with PRs + share
    ├── WorkoutHistory/          # Calendar view + day drill-down
    ├── ExerciseLibrary/         # Searchable exercise browser + custom builder
    ├── QuickStart/              # Smart workout generation
    ├── Programs/                # Training program browse/enroll/calendar
    ├── Body/                    # Muscle freshness + recovery dashboard
    ├── Goals/                   # Goal tracking + creation
    ├── Sharing/                 # Share cards + template export
    └── Settings/                # Equipment profile setup
```

## Getting Started

1. Clone the repo
2. Open `CodeDump.xcodeproj` (not .xcworkspace)
3. Set deployment target to iOS 18
4. Build and run

**iCloud sync** requires adding the iCloud capability in Signing & Capabilities with container `iCloud.com.lazerdragon.ldwe`.

## Custom Fonts

- **OutrunFuture** — primary display font used throughout the app
- **MorningStar** and **Mozart** — available for future use

Fonts are registered in `Info.plist` and accessed via `Font.outrunFuture(_ size:)`.

[swift-image]: https://img.shields.io/badge/swift-5-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: LICENSE
