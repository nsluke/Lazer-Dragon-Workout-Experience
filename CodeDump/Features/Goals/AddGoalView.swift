import SwiftUI
import SwiftData

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: GoalType = .weightTarget
    @State private var selectedExercise: ExerciseTemplate?
    @State private var targetValueText = ""
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var exerciseSearch = ""

    private var filteredExercises: [ExerciseTemplate] {
        if exerciseSearch.isEmpty { return ExerciseTemplate.library }
        let query = exerciseSearch.lowercased()
        return ExerciseTemplate.library.filter { $0.name.lowercased().contains(query) }
    }

    private var canCreate: Bool {
        guard let value = Double(targetValueText), value > 0 else { return false }
        if selectedType.needsExercise && selectedExercise == nil { return false }
        return true
    }

    private var autoTitle: String {
        let target = targetValueText.isEmpty ? "?" : targetValueText
        if let exercise = selectedExercise, selectedType.needsExercise {
            return "\(exercise.name) \(target) \(selectedType.unit)"
        }
        return "\(selectedType.displayName) \(target) \(selectedType.unit)"
    }

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    goalTypePicker
                    if selectedType.needsExercise {
                        exercisePicker
                    }
                    targetInput
                    deadlineSection
                    previewCard
                    createButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("NEW GOAL")
                .font(.outrunFuture(28))
                .foregroundColor(.outrunYellow)
            Text("Set a target to crush.")
                .font(.outrunFuture(12))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Goal Type Picker

    private var goalTypePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TYPE")
                .font(.outrunFuture(10))
                .foregroundColor(.outrunCyan.opacity(0.7))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GoalType.allCases) { type in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedType = type
                                // Clear exercise if new type doesn't need one
                                if !type.needsExercise {
                                    selectedExercise = nil
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 12))
                                Text(type.displayName.uppercased())
                                    .font(.outrunFuture(9))
                            }
                            .foregroundColor(selectedType == type ? .outrunBlack : .outrunCyan)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(selectedType == type ? Color.outrunCyan : Color.outrunSurface)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        selectedType == type ? Color.clear : Color.outrunCyan.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .accessibilityLabel("\(type.displayName), \(selectedType == type ? "selected" : "not selected")")
                    }
                }
            }
        }
    }

    // MARK: - Exercise Picker

    private var exercisePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EXERCISE")
                .font(.outrunFuture(10))
                .foregroundColor(.outrunCyan.opacity(0.7))

            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
                TextField("Search exercises...", text: $exerciseSearch)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                if !exerciseSearch.isEmpty {
                    Button {
                        exerciseSearch = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(12)
            .background(Color.outrunSurface)
            .cornerRadius(10)

            // Exercise list (scrollable, capped height)
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredExercises) { exercise in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedExercise = exercise
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: exercise.primaryMuscle.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedExercise?.id == exercise.id ? .outrunBlack : .outrunCyan.opacity(0.6))
                                    .frame(width: 24)

                                Text(exercise.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(selectedExercise?.id == exercise.id ? .outrunBlack : .white)
                                    .lineLimit(1)

                                Spacer()

                                if selectedExercise?.id == exercise.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.outrunBlack)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                selectedExercise?.id == exercise.id
                                    ? Color.outrunCyan
                                    : Color.outrunBlack
                            )
                            .cornerRadius(8)
                        }
                        .accessibilityLabel("\(exercise.name), \(selectedExercise?.id == exercise.id ? "selected" : "not selected")")
                    }
                }
            }
            .frame(maxHeight: 200)
            .background(Color.outrunSurface.opacity(0.3))
            .cornerRadius(12)
        }
    }

    // MARK: - Target Input

    private var targetInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TARGET")
                .font(.outrunFuture(10))
                .foregroundColor(.outrunCyan.opacity(0.7))

            HStack(spacing: 12) {
                TextField("0", text: $targetValueText)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.outrunYellow)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.outrunSurface)
                    .cornerRadius(12)
                    .accessibilityLabel("Target value")

                Text(selectedType.unit.uppercased())
                    .font(.outrunFuture(14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 60)
            }

            Text(targetHint)
                .font(.outrunFuture(8))
                .foregroundColor(.white.opacity(0.3))
        }
    }

    private var targetHint: String {
        switch selectedType {
        case .weightTarget:  return "The weight you want to lift for this exercise."
        case .repTarget:     return "The number of reps you want to hit in one set."
        case .volumeTarget:  return "Weekly total volume (weight x reps) across all exercises."
        case .frequencyTarget: return "Number of workouts per week."
        case .bodyWeight:    return "Your target body weight. Update manually."
        }
    }

    // MARK: - Deadline

    private var deadlineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $hasDeadline) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 14))
                        .foregroundColor(.outrunPurple)
                    Text("SET DEADLINE")
                        .font(.outrunFuture(10))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .tint(.outrunCyan)

            if hasDeadline {
                DatePicker(
                    "Deadline",
                    selection: $deadline,
                    in: Date.now...,
                    displayedComponents: .date
                )
                #if os(iOS)
                .datePickerStyle(.graphical)
                #endif
                .tint(.outrunCyan)
                .colorScheme(.dark)
                .padding(12)
                .background(Color.outrunSurface)
                .cornerRadius(12)
                .accessibilityLabel("Goal deadline date picker")
            }
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(spacing: 6) {
            Text("PREVIEW")
                .font(.outrunFuture(8))
                .foregroundColor(.white.opacity(0.3))

            HStack(spacing: 10) {
                Image(systemName: selectedType.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.outrunCyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text(autoTitle.uppercased())
                        .font(.outrunFuture(11))
                        .foregroundColor(.outrunYellow)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    HStack(spacing: 6) {
                        if let exercise = selectedExercise, selectedType.needsExercise {
                            Text(exercise.primaryMuscle.displayName)
                                .font(.outrunFuture(8))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        if hasDeadline {
                            let days = max(0, Calendar.current.dateComponents([.day], from: .now, to: deadline).day ?? 0)
                            Text("\(days)d")
                                .font(.outrunFuture(8))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }

                Spacer()

                Text("0%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.outrunOrange)
            }
            .padding(14)
            .background(Color.outrunBlack)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.outrunSurface.opacity(0.5), lineWidth: 1)
            )
        }
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button {
            createGoal()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .fontWeight(.bold)
                Text("CREATE GOAL")
                    .font(.outrunFuture(20))
            }
            .foregroundColor(.outrunBlack)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(canCreate ? Color.outrunCyan : Color.outrunCyan.opacity(0.3))
            .cornerRadius(12)
            .shadow(color: canCreate ? .outrunCyan.opacity(0.3) : .clear, radius: 16)
        }
        .disabled(!canCreate)
        .accessibilityLabel("Create goal")
        .accessibilityHint(canCreate ? "Creates a new fitness goal" : "Fill in all required fields first")
    }

    // MARK: - Create

    private func createGoal() {
        guard let targetValue = Double(targetValueText), targetValue > 0 else { return }

        let goal = FitnessGoal(
            title: autoTitle,
            type: selectedType,
            targetValue: targetValue,
            exerciseTemplateID: selectedType.needsExercise ? selectedExercise?.id : nil,
            deadline: hasDeadline ? deadline : nil
        )

        modelContext.insert(goal)
        try? modelContext.save()
        #if os(iOS)
        FeedbackEngine.phaseChanged()
        #endif
        dismiss()
    }
}
