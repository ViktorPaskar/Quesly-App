import SwiftUI

/// Dedicated screen for "Reflection Rhythm" (Ритм рефлексии).
/// Designed with premium Apple / Revolut / Threads restraint:
/// - Hero Clock Dial with high breathing room, clean focal point
/// - Single segmented day periods control (pill bar)
/// - Clean card feed of past reflections with generous typography and no cramped boxes
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

        var hoursLabel: String {
            switch self {
            case .morning: return "6 AM – 12 PM"
            case .afternoon: return "12 PM – 6 PM"
            case .evening: return "6 PM – 11 PM"
            case .night: return "11 PM – 6 AM"
            }
        }

        var icon: QIcon {
            switch self {
            case .morning: return .sunFill
            case .afternoon: return .sparkleFill
            case .evening: return .leafFill
            case .night: return .timer
            }
        }

        func count(in answers: [Answer]) -> Int {
            let cal = Calendar.current
            return answers.filter {
                let h = cal.component(.hour, from: $0.createdAt)
                switch self {
                case .morning: return h >= 6 && h < 12
                case .afternoon: return h >= 12 && h < 18
                case .evening: return h >= 18 && h < 23
                case .night: return h >= 23 || h < 6
                }
            }.count
        }

        func percentage(in answers: [Answer]) -> Int {
            guard !answers.isEmpty else {
                switch self {
                case .morning: return 52
                case .afternoon: return 26
                case .evening: return 17
                case .night: return 5
                }
            }
            let c = count(in: answers)
            return Int(round(Double(c) / Double(answers.count) * 100))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Space.xl) {
                    // MARK: 1. Hero 24-Hour Circular Dial
                    heroDialSection

                    // MARK: 2. Period Filter Segmented Bar
                    periodSegmentedBar

                    // MARK: 3. Reflection History Stream
                    reflectionsStreamSection
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.s)
                .padding(.bottom, DS.Space.xxl)
            }
            .background(Color.qBackground)
            .navigationTitle("Reflection Rhythm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Icon(.xCircleFill, size: 22)
                            .foregroundStyle(Color.qGray)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    // MARK: - 1. Hero 24-Hour Dial Section (Clean, uncluttered, focused)

    private var heroDialSection: some View {
        VStack(spacing: DS.Space.m) {
            // Dial Widget with generous breathing room
            Circular24hClockView(selectedPeriod: $selectedPeriod)
                .frame(width: 250, height: 250)
                .padding(.top, DS.Space.xs)

            // Dynamic Clean Caption (1 clear line)
            VStack(spacing: 3) {
                if let p = selectedPeriod {
                    HStack(spacing: 6) {
                        Icon(p.icon, size: 14)
                            .foregroundStyle(Color.qGreen)
                        Text("\(p.rawValue) · \(p.hoursLabel)")
                            .font(.ui(14, .semibold))
                            .foregroundStyle(Color.qInk)
                        Text("\(p.percentage(in: store.myAnswers))%")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Color.qBrandText)
                    }
                } else {
                    HStack(spacing: 6) {
                        Icon(.sunFill, size: 14)
                            .foregroundStyle(Color.qGreen)
                        Text("Morning peak at 8:45 AM")
                            .font(.ui(14, .semibold))
                            .foregroundStyle(Color.qInk)
                    }
                    Text("52% of reflections happen before noon")
                        .font(.ui(12.5))
                        .foregroundStyle(Color.qGray)
                }
            }
            .frame(height: 38)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.m)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.qBlock)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }

    // MARK: - 2. Period Filter Segmented Bar (Unified, 1 row, clean pills)

    private var periodSegmentedBar: some View {
        HStack(spacing: 6) {
            periodPill(title: "All", pct: nil, isSelected: selectedPeriod == nil) {
                withAnimation(.qSpring) { selectedPeriod = nil }
            }

            ForEach(DayPeriod.allCases) { period in
                let isSelected = selectedPeriod == period
                let pct = period.percentage(in: store.myAnswers)
                periodPill(title: period.rawValue, pct: pct, isSelected: isSelected) {
                    withAnimation(.qSpring) {
                        selectedPeriod = (selectedPeriod == period) ? nil : period
                    }
                }
            }
        }
    }

    private func periodPill(title: String, pct: Int?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title)
                    .font(.ui(12, isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.qGreenDeep : Color.qInk)
                    .lineLimit(1)
                if let pct {
                    Text("\(pct)%")
                        .font(.ui(10, .medium))
                        .foregroundStyle(isSelected ? Color.qBrandText : Color.qGray)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(
                Capsule()
                    .fill(isSelected ? Color.qMint.opacity(0.40) : Color.qField)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.qGreen.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Reflection History Stream (Threads / Apple Notes style)

    private var filteredAnswers: [Answer] {
        let cal = Calendar.current
        guard let p = selectedPeriod else { return store.myAnswers }
        return store.myAnswers.filter {
            let h = cal.component(.hour, from: $0.createdAt)
            switch p {
            case .morning: return h >= 6 && h < 12
            case .afternoon: return h >= 12 && h < 18
            case .evening: return h >= 18 && h < 23
            case .night: return h >= 23 || h < 6
            }
        }
    }

    private var reflectionsStreamSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack {
                Text(selectedPeriod.map { "\($0.rawValue) reflections" } ?? "Reflections")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Text("\(filteredAnswers.count)")
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(filteredAnswers.prefix(6).enumerated()), id: \.element.id) { index, answer in
                    if index > 0 {
                        Rectangle()
                            .fill(Color.qLine)
                            .frame(height: 1)
                            .padding(.horizontal, DS.Space.m)
                    }
                    reflectionRow(answer)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.qBlock)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.qLine, lineWidth: 1)
                    )
            )
        }
    }

    private func reflectionRow(_ answer: Answer) -> some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            // Time column (clean, no wrapping)
            VStack(alignment: .leading, spacing: 1) {
                Text(answer.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk)
                    .monospacedDigit()
                Text(answer.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.ui(11))
                    .foregroundStyle(Color.qGray)
            }
            .frame(width: 62, alignment: .leading)

            // Content column
            VStack(alignment: .leading, spacing: 3) {
                Text(answer.questionText)
                    .font(.ui(13.5, .medium))
                    .foregroundStyle(Color.qInk)
                    .lineLimit(1)
                Text("“\(answer.text)”")
                    .font(.ui(12.5))
                    .foregroundStyle(Color.qGray)
                    .lineLimit(2)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(DS.Space.m)
    }
}

// MARK: - 24-Hour Circular Clock Component (Pure, Elegant, Minimal)

private struct Circular24hClockView: View {
    @Binding var selectedPeriod: ReflectionInsightsView.DayPeriod?

    private let dots: [(hour: Double, isPeak: Bool)] = [
        (7.5, false),
        (8.75, true),
        (9.2, true),
        (12.5, false),
        (13.6, false),
        (18.2, false),
        (20.5, false),
        (23.2, false)
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = (size - 36) / 2

            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.qLine.opacity(0.85), lineWidth: 1.5)
                    .frame(width: radius * 2, height: radius * 2)

                // 24 Hour Ticks
                ForEach(0..<24) { h in
                    let angle = Angle.degrees(Double(h) * 15.0 - 90.0)
                    let isMajor = h % 6 == 0
                    let tickLen: CGFloat = isMajor ? 7 : 3.5

                    Rectangle()
                        .fill(isMajor ? Color.qInk2 : Color.qGray4)
                        .frame(width: isMajor ? 1.5 : 1, height: tickLen)
                        .offset(y: -radius + tickLen / 2)
                        .rotationEffect(angle)
                }

                // 4 Time Labels
                Text("00:00")
                    .font(.ui(9, .semibold))
                    .foregroundStyle(Color.qGray)
                    .offset(y: -radius - 11)

                Text("06:00")
                    .font(.ui(9, .semibold))
                    .foregroundStyle(Color.qGray)
                    .offset(x: radius + 15)

                Text("12:00")
                    .font(.ui(9, .semibold))
                    .foregroundStyle(Color.qGray)
                    .offset(y: radius + 11)

                Text("18:00")
                    .font(.ui(9, .semibold))
                    .foregroundStyle(Color.qGray)
                    .offset(x: -radius - 15)

                // Peak Arc: 06:00 to 12:00 (90° to 180° clockwise)
                Circle()
                    .trim(from: 0.25, to: 0.50)
                    .stroke(
                        LinearGradient(colors: [Color.qLime, Color.qGreen], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))

                // Reflection Points
                ForEach(Array(dots.enumerated()), id: \.offset) { _, dot in
                    let angle = Angle.degrees(dot.hour / 24.0 * 360.0 - 90.0)

                    Circle()
                        .fill(dot.isPeak ? Color.qGreen : Color.qMint)
                        .frame(width: dot.isPeak ? 11 : 7, height: dot.isPeak ? 11 : 7)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .offset(x: radius * cos(angle.radians), y: radius * sin(angle.radians))
                }

                // Clean Center Hub
                VStack(spacing: 2) {
                    Text("PEAK")
                        .font(.ui(8.5, .bold))
                        .tracking(1.0)
                        .foregroundStyle(Color.qBrandText)

                    Text("8:45")
                        .font(.ui(26, .bold))
                        .foregroundStyle(Color.qInk)
                        .monospacedDigit()

                    Text("AM")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Color.qGray)
                }
                .frame(width: 96, height: 96)
                .background(
                    Circle()
                        .fill(Color.qBackground)
                        .shadow(color: Color.black.opacity(0.04), radius: 6)
                )
            }
            .frame(width: size, height: size)
            .position(x: center.x, y: center.y)
        }
    }
}
