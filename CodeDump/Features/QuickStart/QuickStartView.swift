import SwiftUI
import SwiftData

struct QuickStartView: View {
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \CustomExerciseTemplate.name) private var customTemplates: [CustomExerciseTemplate]

    @AppStorage("equipmentProfile") private var equipmentRaw: String = EquipmentProfile.encode(EquipmentProfile.commercialGymEquipment)
    @AppStorage("equipmentProfileConfigured") private var equipmentConfigured = false

    @State private var viewModel = QuickStartViewModel()
    @State private var showingEquipmentSetup = false
    @State private var swapRequest: SwapRequest? = nil

    struct SwapRequest: Identifiable {
        let id = UUID()
        let index: Int
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.outrunBackground.ignoresSafeArea()

                if viewModel.hasGenerated {
                    previewScreen
                } else {
                    configScreen
                }
            }
            .navigationTitle("QUICK START")
            .navigationBarTitleDisplayMode(.inline)
            .outrunNavBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.outrunCyan)
                }
            }
            .sheet(isPresented: $showingEquipmentSetup) {
                EquipmentProfileView()
            }
            .sheet(item: $swapRequest) { request in
                ExerciseLibraryView { item in
                    viewModel.swapExercise(at: request.index, with: item)
                }
            }
            .onChange(of: equipmentRaw) {
                viewModel.availableEquipment = EquipmentProfile.decode(equipmentRaw)
            }
            .onAppear {
                viewModel.availableEquipment = EquipmentProfile.decode(equipmentRaw)
            }
        }
    }

    // MARK: - Config Screen

    private var configScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    durationPicker
                    equipmentSummary
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
            }

            Spacer()

            generateButton
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
        }
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DURATION")

            HStack(spacing: 10) {
                ForEach([15, 30, 45, 60], id: \.self) { minutes in
                    durationChip(minutes)
                }
            }
        }
    }

    private func durationChip(_ minutes: Int) -> some View {
        let isSelected = viewModel.selectedDuration == minutes
        return Button {
            viewModel.selectedDuration = minutes
        } label: {
            Text("\(minutes) MIN")
                .font(.outrunFuture(14))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? Color.outrunPink.opacity(0.35) : Color.outrunSurface)
                .foregroundColor(isSelected ? .outrunPink : .white.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.outrunPink : Color.clear, lineWidth: 1.5)
                )
                .minimumScaleFactor(0.7)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(minutes) minutes")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var equipmentSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("EQUIPMENT")

            HStack {
                let equip = viewModel.availableEquipment
                let preset = EquipmentProfile.inferPreset(from: equip)

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.rawValue.uppercased())
                        .font(.outrunFuture(14))
                        .foregroundColor(.outrunYellow)
                    Text("\(equip.count) equipment type\(equip.count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Button {
                    showingEquipmentSetup = true
                } label: {
                    Text("CHANGE")
                        .font(.outrunFuture(11))
                        .foregroundColor(.outrunCyan)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.outrunSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.outrunCyan.opacity(0.5), lineWidth: 1)
                        )
                }
            }
            .padding(14)
            .background(Color.outrunSurface)
            .cornerRadius(12)

            if !equipmentConfigured {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.outrunOrange)
                        .font(.system(size: 12))
                    Text("Set up your equipment for better recommendations")
                        .font(.system(size: 12))
                        .foregroundColor(.outrunOrange.opacity(0.8))
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var generateButton: some View {
        Button {
            viewModel.generate(sessions: sessions, customTemplates: customTemplates)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .fontWeight(.bold)
                Text("GENERATE")
                    .font(.outrunFuture(20))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [.outrunPink, .outrunPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .outrunPink.opacity(0.3), radius: 16)
        }
    }

    // MARK: - Preview Screen

    private var previewScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Muscle focus
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.outrunCyan)
                        Text(viewModel.muscleFocusSummary)
                            .font(.outrunFuture(13))
                            .foregroundColor(.outrunCyan)
                    }
                    .padding(.horizontal, 4)

                    // Editable name
                    TextField("Workout Name", text: $viewModel.generatedName)
                        .font(.outrunFuture(22))
                        .foregroundColor(.outrunYellow)
                        .padding(14)
                        .background(Color.outrunSurface)
                        .cornerRadius(10)

                    // Warning
                    if let warning = viewModel.warningMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.outrunOrange)
                                .font(.system(size: 12))
                            Text(warning)
                                .font(.system(size: 12))
                                .foregroundColor(.outrunOrange.opacity(0.8))
                        }
                    }

                    // Workout info
                    workoutInfoBar

                    // Exercise list
                    exercisePreviewList
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            VStack(spacing: 10) {
                // Regenerate
                Button {
                    viewModel.hasGenerated = false
                    viewModel.generatedExercises = []
                } label: {
                    Text("REGENERATE")
                        .font(.outrunFuture(14))
                        .foregroundColor(.outrunPurple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.outrunSurface)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.outrunPurple.opacity(0.5), lineWidth: 1)
                        )
                }

                // Start
                Button {
                    startWorkout()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("START WORKOUT")
                            .font(.outrunFuture(20))
                    }
                    .foregroundColor(.outrunBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.outrunCyan)
                    .cornerRadius(12)
                    .shadow(color: .outrunCyan.opacity(0.3), radius: 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    private var workoutInfoBar: some View {
        HStack(spacing: 16) {
            infoChip(icon: "clock", text: "\(viewModel.selectedDuration) min", color: .outrunCyan)

            let volume = viewModel.calculateVolume(durationMinutes: viewModel.selectedDuration)
            infoChip(icon: "arrow.counterclockwise", text: "\(volume.totalSets) set\(volume.totalSets == 1 ? "" : "s")", color: .outrunGreen)

            infoChip(icon: "figure.strengthtraining.traditional", text: "\(viewModel.generatedExercises.count) exercises", color: .outrunYellow)
        }
    }

    private func infoChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.outrunFuture(10))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var exercisePreviewList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.generatedExercises.enumerated()), id: \.element.id) { index, exercise in
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.outrunFuture(14))
                                .foregroundColor(.outrunYellow)

                            HStack(spacing: 8) {
                                // Muscle tags
                                ForEach(exercise.targetMuscleGroups.prefix(2)) { muscle in
                                    HStack(spacing: 2) {
                                        Image(systemName: muscle.icon)
                                            .font(.system(size: 8))
                                        Text(muscle.displayName)
                                            .font(.outrunFuture(8))
                                    }
                                    .foregroundColor(.outrunCyan.opacity(0.7))
                                }

                                // Equipment
                                Label(exercise.equipment.displayName, systemImage: exercise.equipment.icon)
                                    .font(.outrunFuture(8))
                                    .foregroundColor(.outrunPurple.opacity(0.7))
                            }
                        }

                        Spacer()

                        // Swap button
                        Button {
                            swapRequest = SwapRequest(index: index)
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14))
                                .foregroundColor(.outrunCyan)
                                .padding(8)
                                .background(Color.outrunSurface)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Swap \(exercise.name)")
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 4)

                    if index < viewModel.generatedExercises.count - 1 {
                        Divider()
                            .background(Color.outrunSurface)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.outrunSurface.opacity(0.5))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.outrunFuture(12))
            .foregroundColor(.outrunCyan.opacity(0.7))
    }

    private func startWorkout() {
        let workout = viewModel.createWorkout(in: modelContext)
        dismiss()
        // Small delay to let sheet dismiss before navigating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            path.append(Route.session(workout))
        }
    }
}
