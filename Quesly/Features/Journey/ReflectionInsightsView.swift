import SwiftUI
import Charts

/// "Reflection Rhythm" detail sheet, health-app style:
/// big headline number + status, filter chips, a time-of-day chart with the average line,
/// a dot-matrix split by part of day, and the reflections themselves.
/// Frosted white cards on a soft mint wash.
struct ReflectionInsightsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPeriod: DayPeriod? = nil

    enum DayPeriod: String, CaseIterable, Identifiable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case night = "Night"

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .morning: return Color(hex: 0xF59E0B)
            case .afternoon: return Color.qGreen
            case .evening: return Color.qPink
            case .night: return Color(hex: 0x6366F1)
            }
        }

        func contains(hour h: Int) -> Bool {
            switch self {
            case .morning: return h >= 6 && h < 12
            case .afternoon: return h >= 12 && h < 18
            case .evening: return h >= 18 && h < 23
            case .night: return h >= 23 || h < 6
            }
        }

        func count(in answers: [Answer]) -> Int {
            let cal = Calendar.current
            return answers.filter { contains(hour: cal.component(.hour, from: $0.createdAt)) }.count
        }

        func percentage(in answers: [Answer]) -> Int {
            guard !answers.isEmpty else { return 0 }
            return Int((Double(count(in: answers)) / Double(answers.count) * 100).rounded())
        }
    }

    // MARK: - Data

    private static func minuteOfDay(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private static func timeLabel(_ minutes: Int) -> String {
        let date = Calendar.current.date(bySettingHour: minutes / 60 % 24, minute: minutes % 60, second: 0, of: .now) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private var filteredAnswers: [Answer] {
        guard let p = selectedPeriod else { return store.myAnswers }
        let cal = Calendar.current
        return store.myAnswers.filter { p.contains(hour: cal.component(.hour, from: $0.createdAt)) }
    }

    private var peak: DayPeriod {
        DayPeriod.allCases.max { $0.count(in: store.myAnswers) < $1.count(in: store.myAnswers) } ?? .morning
    }

    /// Median time of the shown answers (median, so one late night doesn't drag it).
    /// With no filter it uses the peak part of the day, so it agrees with "Morning person".
    private var usualMinute: Int? {
        let cal = Calendar.current
        let pool = selectedPeriod == nil
            ? store.myAnswers.filter { peak.contains(hour: cal.component(.hour, from: $0.createdAt)) }
            : filteredAnswers
        let m = pool.map { Self.minuteOfDay($0.createdAt) }.sorted()
        return m.isEmpty ? nil : m[m.count / 2]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.m) {
                    header
                    chips
                    chartCard
                    dotMatrixCard
                    reflectionsCard
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.s)
                .padding(.bottom, DS.Space.xxl)
            }
            .background(
                LinearGradient(colors: [Color.qMint.opacity(0.55), Color.qBackground],
                               startPoint: .top, endPoint: .center)
                    .ignoresSafeArea()
            )
            .navigationTitle("Reflection Rhythm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.qInk)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(.white))
                            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(usualMinute.map(Self.timeLabel) ?? "—")
                    .font(.display(44, .semibold))
                    .foregroundStyle(Color.qInk)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(selectedPeriod.map { "Usual \($0.rawValue.lowercased()) time" } ?? "Your usual time")
                    .font(.ui(14, .medium))
                    .foregroundStyle(Color.qGray)
            }
            Spacer(minLength: DS.Space.s)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(peak.rawValue) person")
                    .font(.ui(17, .semibold))
                    .foregroundStyle(Color.qBrandText)
                Text("\(peak.percentage(in: store.myAnswers))% of answers")
                    .font(.ui(14, .medium))
                    .foregroundStyle(Color.qGray)
            }
            .padding(.top, 8)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Chips

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", isSelected: selectedPeriod == nil) { selectedPeriod = nil }
                ForEach(DayPeriod.allCases) { p in
                    chip(p.rawValue, isSelected: selectedPeriod == p) {
                        selectedPeriod = selectedPeriod == p ? nil : p
                    }
                }
            }
        }
        .scrollClipDisabled()
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.qSpring) { action() } } label: {
            Text(title)
                .font(.ui(14, .semibold))
                .foregroundStyle(isSelected ? .white : Color.qInk2)
                .padding(.horizontal, 16)
                .frame(height: 38)
                .background(Capsule().fill(isSelected ? Color.qInk : Color.white.opacity(0.75)))
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Chart

    private var chartAnswers: [Answer] {
        filteredAnswers.sorted { $0.createdAt < $1.createdAt }.suffix(14).map { $0 }
    }

    private var chartCard: some View {
        let points = chartAnswers
        let tint = selectedPeriod?.color ?? Color(hex: 0xF59E0B)
        return frosted {
            VStack(alignment: .leading, spacing: 12) {
                Text("Answer time · last \(points.count) answers")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)

                Chart {
                    ForEach(points) { a in
                        LineMark(x: .value("Day", a.createdAt, unit: .day),
                                 y: .value("Time", 1440 - Self.minuteOfDay(a.createdAt)))
                            .interpolationMethod(.monotone)
                            .foregroundStyle(tint.gradient)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))
                        PointMark(x: .value("Day", a.createdAt, unit: .day),
                                  y: .value("Time", 1440 - Self.minuteOfDay(a.createdAt)))
                            .symbolSize(36)
                            .foregroundStyle(tint)
                    }
                    if let avg = usualMinute {
                        RuleMark(y: .value("Usual", 1440 - avg))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            .foregroundStyle(tint.opacity(0.7))
                            .annotation(position: .top, alignment: .leading) {
                                Text("Usual \(Self.timeLabel(avg))")
                                    .font(.ui(12, .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(tint))
                            }
                    }
                }
                .chartYScale(domain: 0...1440) // plotted as 1440 − minute so morning sits at the top
                .chartYAxis {
                    AxisMarks(position: .trailing, values: [0, 360, 720, 1080, 1440]) { v in
                        AxisGridLine().foregroundStyle(Color.qLine)
                        AxisValueLabel {
                            if let m = v.as(Int.self) { Text(Self.timeLabel(1440 - m)).font(.ui(11)).foregroundStyle(Color.qGray) }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .font(.ui(11))
                            .foregroundStyle(Color.qGray)
                    }
                }
                .frame(height: 200)
                .accessibilityLabel("Answer times over recent days")
            }
        }
    }

    // MARK: - Dot matrix

    private var dotMatrixCard: some View {
        let answers = store.myAnswers
        return frosted {
            VStack(alignment: .leading, spacing: 14) {
                Text("Time of day")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(DayPeriod.allCases) { p in
                        let n = p.count(in: answers)
                        let dimmed = selectedPeriod != nil && selectedPeriod != p
                        VStack(alignment: .leading, spacing: 8) {
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(7), spacing: 4), count: 5),
                                      alignment: .leading, spacing: 4) {
                                ForEach(0..<max(n, 1), id: \.self) { _ in
                                    Circle().fill(n == 0 ? Color.qLine : p.color).frame(width: 7, height: 7)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(p.percentage(in: answers))%")
                                .font(.ui(20, .semibold))
                                .foregroundStyle(Color.qInk)
                                .monospacedDigit()
                            Text(p.rawValue)
                                .font(.ui(13, .medium))
                                .foregroundStyle(p.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .opacity(dimmed ? 0.35 : 1)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(p.rawValue), \(p.percentage(in: answers)) percent")
                    }
                }
            }
        }
    }

    // MARK: - Reflections

    private var reflectionsCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack {
                Text(selectedPeriod.map { "\($0.rawValue) reflections" } ?? "Reflections")
                    .font(.ui(17, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Text("\(filteredAnswers.count)")
                    .font(.ui(15))
                    .foregroundStyle(Color.qGray)
            }
            .padding(.top, DS.Space.s)

            frosted(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(filteredAnswers.prefix(6).enumerated()), id: \.element.id) { index, answer in
                        if index > 0 {
                            Rectangle().fill(Color.qLine).frame(height: 1).padding(.leading, DS.Space.m)
                        }
                        reflectionRow(answer)
                    }
                }
            }
        }
    }

    private func reflectionRow(_ answer: Answer) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(answer.questionText)
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                    .lineLimit(1)
                Spacer(minLength: DS.Space.s)
                Text(answer.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.ui(13, .medium))
                    .foregroundStyle(Color.qGray)
                    .monospacedDigit()
            }
            Text(answer.text)
                .font(.ui(14))
                .foregroundStyle(Color.qGray)
                .lineLimit(2)
        }
        .padding(DS.Space.m)
    }

    // MARK: - Frosted card

    private func frosted<Content: View>(padding: CGFloat = 18, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.82))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white, lineWidth: 1.5))
                    .shadow(color: Color.qGreen.opacity(0.06), radius: 16, y: 6)
            )
    }
}

#Preview {
    ReflectionInsightsView().environment(AppStore())
}
