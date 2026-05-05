import SwiftUI
import SwiftData
import Charts

// MARK: - Enums

enum ProgressMetric: String, CaseIterable, Identifiable {
    case weight = "WEIGHT"
    case volume = "VOLUME"
    case estimated1RM = "EST 1RM"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .weight:       return .outrunCyan
        case .volume:       return .outrunPink
        case .estimated1RM: return .outrunYellow
        }
    }

    var unit: String {
        switch self {
        case .weight:       return "lbs"
        case .volume:       return "lbs"
        case .estimated1RM: return "lbs"
        }
    }
}

enum ProgressTimeRange: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case allTime = "ALL"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .oneMonth:     return 30
        case .threeMonths:  return 90
        case .sixMonths:    return 180
        case .allTime:      return nil
        }
    }
}

// MARK: - Data Point

struct ProgressDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let weight: Double
    let reps: Int
}

// MARK: - View

struct ExerciseProgressChartView: View {
    let exerciseTemplateID: String
    let exerciseName: String

    @Query(sort: \SetLog.date) private var allLogs: [SetLog]
    @State private var selectedMetric: ProgressMetric = .weight
    @State private var selectedRange: ProgressTimeRange = .threeMonths
    @State private var selectedPoint: ProgressDataPoint?

    var body: some View {
        ZStack {
            Color.outrunBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    personalBestCard
                    metricPicker
                    rangePicker
                    chartSection
                    recentSessionsList
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .outrunTitle(exerciseName.uppercased())
        .outrunNavBar()
    }

    // MARK: - Filtered Data

    private var filteredLogs: [SetLog] {
        let relevant = allLogs.filter {
            ($0.exerciseTemplateID ?? $0.exerciseName) == exerciseTemplateID && $0.weight != nil && $0.weight! > 0
        }
        guard let days = selectedRange.days else { return relevant }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        return relevant.filter { $0.date >= cutoff }
    }

    private var dataPoints: [ProgressDataPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredLogs) { calendar.startOfDay(for: $0.date) }

        return grouped.compactMap { (day, logs) -> ProgressDataPoint? in
            bestPoint(from: logs, date: day)
        }
        .sorted { $0.date < $1.date }
    }

    private func bestPoint(from logs: [SetLog], date: Date) -> ProgressDataPoint? {
        var bestValue: Double = 0
        var bestWeight: Double = 0
        var bestReps: Int = 0

        for log in logs {
            let w = log.weight ?? 0
            let r = log.reps ?? 0
            let value: Double
            switch selectedMetric {
            case .weight:
                value = w
            case .volume:
                value = w * Double(r)
            case .estimated1RM:
                value = r > 0 ? w * (1 + Double(r) / 30.0) : w
            }
            if value > bestValue {
                bestValue = value
                bestWeight = w
                bestReps = r
            }
        }

        guard bestValue > 0 else { return nil }
        return ProgressDataPoint(date: date, value: bestValue, weight: bestWeight, reps: bestReps)
    }

    // MARK: - Personal Best

    private var allTimeDataPoints: [ProgressDataPoint] {
        let calendar = Calendar.current
        let relevant = allLogs.filter {
            ($0.exerciseTemplateID ?? $0.exerciseName) == exerciseTemplateID && $0.weight != nil && $0.weight! > 0
        }
        let grouped = Dictionary(grouping: relevant) { calendar.startOfDay(for: $0.date) }
        return grouped.compactMap { (day, logs) -> ProgressDataPoint? in
            bestPoint(from: logs, date: day)
        }
    }

    private var personalBest: ProgressDataPoint? {
        allTimeDataPoints.max { $0.value < $1.value }
    }

    private var trendDirection: Int {
        let points = dataPoints
        guard points.count >= 6 else { return 0 }
        let recent = points.suffix(3).map(\.value).reduce(0, +) / 3.0
        let prior = points.dropLast(3).suffix(3).map(\.value).reduce(0, +) / 3.0
        let diff = (recent - prior) / max(prior, 1)
        if diff > 0.02 { return 1 }
        if diff < -0.02 { return -1 }
        return 0
    }

    private var personalBestCard: some View {
        Group {
            if let pb = personalBest {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PERSONAL BEST")
                            .font(.outrunFuture(9))
                            .foregroundColor(.white.opacity(0.4))
                        Text(formatValue(pb.value))
                            .font(.outrunFuture(28))
                            .foregroundColor(selectedMetric.color)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(pb.weight)) lbs × \(pb.reps) reps")
                            .font(.outrunFuture(11))
                            .foregroundColor(.white.opacity(0.6))
                        Text(pb.date.formatted(.dateTime.month(.abbreviated).day().year()))
                            .font(.outrunFuture(9))
                            .foregroundColor(.white.opacity(0.3))
                        if trendDirection != 0 {
                            HStack(spacing: 4) {
                                Image(systemName: trendDirection > 0 ? "arrow.up.right" : "arrow.down.right")
                                Text(trendDirection > 0 ? "TRENDING UP" : "TRENDING DOWN")
                                    .font(.outrunFuture(8))
                            }
                            .foregroundColor(trendDirection > 0 ? .outrunGreen : .outrunRed)
                        }
                    }
                }
                .padding(16)
                .background(Color.outrunSurface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Pickers

    private var metricPicker: some View {
        HStack(spacing: 4) {
            ForEach(ProgressMetric.allCases) { metric in
                Button {
                    selectedMetric = metric
                } label: {
                    Text(metric.rawValue)
                        .font(.outrunFuture(11))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedMetric == metric ? metric.color.opacity(0.3) : Color.outrunBlack)
                        .foregroundColor(selectedMetric == metric ? metric.color : .white.opacity(0.4))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var rangePicker: some View {
        HStack(spacing: 4) {
            ForEach(ProgressTimeRange.allCases) { range in
                Button {
                    selectedRange = range
                } label: {
                    Text(range.rawValue)
                        .font(.outrunFuture(12))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedRange == range ? Color.outrunCyan.opacity(0.3) : Color.outrunBlack)
                        .foregroundColor(selectedRange == range ? .outrunCyan : .white.opacity(0.4))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedMetric.rawValue) OVER TIME")
                .font(.outrunFuture(13))
                .foregroundColor(.outrunCyan)

            if dataPoints.isEmpty {
                Text("No data for this exercise yet")
                    .font(.outrunFuture(11))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                Chart(dataPoints) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.rawValue, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [selectedMetric.color.opacity(0.2), selectedMetric.color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.rawValue, point.value)
                    )
                    .foregroundStyle(selectedMetric.color)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.rawValue, point.value)
                    )
                    .foregroundStyle(selectedMetric.color)
                    .symbolSize(30)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatAxisValue(v))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.outrunPurple.opacity(0.3))
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .chartPlotStyle { plot in
                    plot.background(Color.outrunBlack.opacity(0.3))
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { drag in
                                        let x = drag.location.x - geometry[proxy.plotFrame!].origin.x
                                        guard let date: Date = proxy.value(atX: x) else { return }
                                        selectedPoint = dataPoints.min {
                                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedPoint = nil
                                    }
                            )
                    }
                }
                .frame(height: 250)

                if let point = selectedPoint {
                    HStack {
                        Text(point.date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.outrunFuture(10))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text("\(formatValue(point.value)) \(selectedMetric.unit)")
                            .font(.outrunFuture(12))
                            .foregroundColor(selectedMetric.color)
                        Spacer()
                        Text("\(Int(point.weight)) lbs × \(point.reps)")
                            .font(.outrunFuture(10))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .padding(16)
        .background(Color.outrunSurface)
        .cornerRadius(12)
    }

    // MARK: - Recent Sessions

    private var recentSessionsList: some View {
        Group {
            let points = Array(dataPoints.suffix(10).reversed())
            if !points.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT SESSIONS")
                        .font(.outrunFuture(13))
                        .foregroundColor(.outrunCyan)

                    ForEach(points) { point in
                        HStack {
                            Text(point.date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.outrunFuture(11))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatValue(point.value))
                                    .font(.outrunFuture(14))
                                    .foregroundColor(selectedMetric.color)
                                Text("\(Int(point.weight)) lbs × \(point.reps) reps")
                                    .font(.outrunFuture(9))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(16)
                .background(Color.outrunSurface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Formatting

    private func formatValue(_ value: Double) -> String {
        if value >= 10000 {
            return String(format: "%.1fk", value / 1000)
        }
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(value))"
            : String(format: "%.1f", value)
    }

    private func formatAxisValue(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "%.0fk", value / 1000)
        }
        return "\(Int(value))"
    }
}
