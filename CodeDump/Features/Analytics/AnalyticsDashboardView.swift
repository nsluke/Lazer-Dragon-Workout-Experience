import SwiftUI
import SwiftData
import Charts

struct AnalyticsDashboardView: View {
    @State private var viewModel = AnalyticsViewModel()
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \SetLog.date, order: .reverse) private var allLogs: [SetLog]
    @State private var showingExerciseProgress = false

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    rangePicker
                    statsRow
                    volumeChartSection
                    muscleDistributionSection
                    exerciseProgressSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .outrunTitle("ANALYTICS")
        .outrunNavBar()
        .onAppear { viewModel.refresh(sessions: sessions, allLogs: allLogs) }
        .onChange(of: viewModel.range) { viewModel.refresh(sessions: sessions, allLogs: allLogs) }
    }

    // MARK: - Range Picker

    private var rangePicker: some View {
        HStack(spacing: 4) {
            ForEach(AnalyticsRange.allCases) { range in
                Button {
                    viewModel.range = range
                } label: {
                    Text(range.rawValue)
                        .font(.outrunFuture(12))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(viewModel.range == range ? Color.outrunCyan.opacity(0.3) : Color.outrunBlack)
                        .foregroundColor(viewModel.range == range ? .outrunCyan : .white.opacity(0.4))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(viewModel.totalSessions)", label: "SESSIONS", color: .outrunCyan)
            statCard(value: SessionAnalytics.formatVolume(viewModel.totalVolume), label: "VOLUME", color: .outrunYellow)
            statCard(value: "\(viewModel.totalPRs)", label: "PRs", color: .outrunPink)
            statCard(value: "\(viewModel.currentStreak)", label: "STREAK", color: .outrunGreen)
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.outrunFuture(20))
                .foregroundColor(color)
            Text(label)
                .font(.outrunFuture(9))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.outrunSurface)
        .cornerRadius(12)
    }

    // MARK: - Volume Chart

    private var volumeChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("WEEKLY VOLUME")

            if viewModel.weeklyVolumes.isEmpty {
                emptyState("Complete a workout to see volume trends")
            } else {
                Chart(viewModel.weeklyVolumes) { week in
                    BarMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("Volume", week.volume)
                    )
                    .foregroundStyle(Color.outrunCyan.gradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(SessionAnalytics.formatVolume(v))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.outrunPurple.opacity(0.3))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .chartPlotStyle { plot in
                    plot.background(Color.outrunBlack.opacity(0.3))
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(Color.outrunSurface)
        .cornerRadius(12)
    }

    // MARK: - Muscle Distribution

    private var muscleDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("MUSCLE DISTRIBUTION")

            if viewModel.muscleDistribution.isEmpty {
                emptyState("Log sets to see muscle group breakdown")
            } else {
                Chart(viewModel.muscleDistribution) { item in
                    BarMark(
                        x: .value("Sets", item.sets),
                        y: .value("Muscle", item.muscle.displayName)
                    )
                    .foregroundStyle(muscleColor(item.muscle).gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing, spacing: 4) {
                        Text("\(item.sets)")
                            .font(.outrunFuture(10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .chartPlotStyle { plot in
                    plot.background(Color.outrunBlack.opacity(0.3))
                }
                .frame(height: CGFloat(viewModel.muscleDistribution.count) * 32 + 16)
            }
        }
        .padding(16)
        .background(Color.outrunSurface)
        .cornerRadius(12)
    }

    // MARK: - Exercise Progress

    private var exerciseProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("EXERCISE PROGRESS")

            if viewModel.exerciseNames.isEmpty {
                emptyState("Log weighted sets to track exercise progress")
            } else {
                // Exercise picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.exerciseNames, id: \.self) { name in
                            let id = viewModel.exerciseID(forName: name, logs: allLogs)
                            let isSelected = id == viewModel.selectedExerciseID
                            Button {
                                viewModel.selectedExerciseID = id
                                viewModel.computeExercisePRTimeline(exerciseTemplateID: id ?? name, allLogs: allLogs)
                            } label: {
                                Text(name.uppercased())
                                    .font(.outrunFuture(9))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color.outrunPink.opacity(0.3) : Color.outrunBlack)
                                    .foregroundColor(isSelected ? .outrunPink : .white.opacity(0.4))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isSelected ? Color.outrunPink : .clear, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // PR timeline chart
                if viewModel.exercisePRTimeline.isEmpty {
                    emptyState("No weight data for this exercise")
                } else {
                    Chart(viewModel.exercisePRTimeline) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color.outrunPink)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color.outrunPink)
                        .symbolSize(30)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))lb")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(Color.outrunPurple.opacity(0.3))
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .chartPlotStyle { plot in
                        plot.background(Color.outrunBlack.opacity(0.3))
                    }
                    .frame(height: 200)

                    Button {
                        showingExerciseProgress = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("VIEW DETAILS")
                                .font(.outrunFuture(10))
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 11))
                            Spacer()
                        }
                        .foregroundColor(.outrunCyan)
                        .padding(.vertical, 8)
                        .background(Color.outrunCyan.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingExerciseProgress) {
                        NavigationStack {
                            ExerciseProgressChartView(
                                exerciseTemplateID: viewModel.selectedExerciseID ?? "",
                                exerciseName: viewModel.exerciseNames.first { viewModel.exerciseID(forName: $0, logs: allLogs) == viewModel.selectedExerciseID } ?? ""
                            )
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button("Done") { showingExerciseProgress = false }
                                        .font(.outrunFuture(14))
                                        .foregroundColor(.outrunCyan)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.outrunSurface)
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.outrunFuture(13))
            .foregroundColor(.outrunCyan)
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.outrunFuture(11))
            .foregroundColor(.white.opacity(0.3))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    private func muscleColor(_ muscle: MuscleGroup) -> Color {
        switch muscle {
        case .chest:      return .outrunPink
        case .back:       return .outrunCyan
        case .shoulders:  return .outrunYellow
        case .biceps:     return .outrunGreen
        case .triceps:    return .outrunOrange
        case .quads:      return .outrunCyan
        case .hamstrings: return .outrunPink
        case .glutes:     return .outrunYellow
        case .calves:     return .outrunGreen
        case .core:       return .outrunOrange
        case .fullBody:   return .outrunCyan
        }
    }
}
