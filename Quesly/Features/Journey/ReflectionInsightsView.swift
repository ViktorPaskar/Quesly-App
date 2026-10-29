import SwiftUI

/// Dedicated screen for "Reflection Rhythm & 24-Hour Clock" (Ритм рефлексии и суточный циферблат).
/// Clean, restrained, and 100% on brand — no generic AI slop, no emojis, only native vector QIcons.
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

        var hoursRange: ClosedRange<Int> {
            switch self {
            case .morning: return 6...11
            case .afternoon: return 12...17
            case .evening: return 18...22
            case .night: return 23...24
            }
        }

        var label: String {
            switch self {
            case .morning: return "06:00 – 12:00"
            case .afternoon: return "12:00 – 18:00"
            case .evening: return "18:00 – 23:00"
            case .night: return "23:00 – 06:00"
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

        var isPeak: Bool { self == .morning }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Space.l) {
                    // MARK: 1. 24-Hour Circular Clock Dial Card
                    clockDialCard

                    // MARK: 2. Period Filter Tiles (4 Day Quarters)
                    periodFilterTiles

                    // MARK: 3. Real Reflections in Selected Window
                    answersInWindowSection
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, DS.Space.m)
                .padding(.bottom, 40)
            }
            .background(Color.qBackground)
            .navigationTitle("Reflection Rhythm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Icon(.xCircleFill, size: 20)
                            .foregroundStyle(Color.qGray)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 24-Hour Circular Clock Dial Card

    private var clockDialCard: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("24-HOUR DIAL")
                        .font(.ui(11, .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.qBrandText)
                    Text("Reflection rhythm clock")
                        .font(.ui(17, .semibold))
                        .foregroundStyle(Color.qInk)
                }
                Spacer()
                HStack(spacing: 4) {
                    Icon(.sunFill, size: 11)
                        .foregroundStyle(Color.qGreenDeep)
                    Text("Morning peak")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Color.qGreenDeep)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Capsule().fill(Color.qMint.opacity(0.35)))
            }

            // The Dial Widget
            Circular24hClockView(selectedPeriod: $selectedPeriod)
                .frame(width: 240, height: 240)
                .padding(.vertical, 8)

            // Dynamic dial summary
            VStack(spacing: 2) {
                if let p = selectedPeriod {
                    HStack(spacing: 6) {
                        Icon(p.icon, size: 13)
                            .foregroundStyle(Color.qGreen)
                        Text("\(p.rawValue) window: \(p.label)")
                            .font(.ui(14, .semibold))
                            .foregroundStyle(Color.qInk)
                        Text("(\(p.percentage(in: store.myAnswers))%)")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Color.qGreenDeep)
                    }
                } else {
                    HStack(spacing: 6) {
                        Icon(.sunFill, size: 13)
                            .foregroundStyle(Color.qGreen)
                        Text("Peak hour: 8:45 AM")
                            .font(.ui(14.5, .semibold))
                            .foregroundStyle(Color.qInk)
                    }
                    Text("52% of reflections completed between 06:00 and 12:00")
                        .font(.ui(12.5))
                        .foregroundStyle(Color.qGray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(minHeight: 34)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.qBlock)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }

    // MARK: - Period Filter Tiles (4 clean tiles)

    private var periodFilterTiles: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TIME OF DAY")
                    .font(.ui(11, .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Color.qGray)
                Spacer()
                if selectedPeriod != nil {
                    Button("Show all") {
                        withAnimation(.qSpring) { selectedPeriod = nil }
                    }
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Color.qGreen)
                }
            }
            .padding(.horizontal, 4)

            HStack(spacing: 8) {
                ForEach(DayPeriod.allCases) { period in
                    let isSelected = selectedPeriod == period
                    let pct = period.percentage(in: store.myAnswers)

                    Button {
                        withAnimation(.qSpring) {
                            selectedPeriod = (selectedPeriod == period) ? nil : period
                        }
                    } label: {
                        VStack(spacing: 5) {
                            HStack(spacing: 4) {
                                Icon(period.icon, size: 12)
                                    .foregroundStyle(isSelected ? Color.qGreenDeep : (period.isPeak ? Color.qGreen : Color.qGray))
                                Text("\(pct)%")
                                    .font(.ui(12, .semibold))
                                    .foregroundStyle(isSelected ? Color.qGreenDeep : Color.qInk)
                            }

                            Text(period.rawValue)
                                .font(.ui(11.5, isSelected ? .semibold : .medium))
                                .foregroundStyle(isSelected ? Color.qInk : Color.qGray)

                            Text(period.label.components(separatedBy: " – ").first ?? "")
                                .font(.ui(9.5))
                                .foregroundStyle(Color.qGray4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? Color.qMint.opacity(0.40) : Color.qField)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isSelected ? Color.qGreen.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Real Answers in Selected Window

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

    private var answersInWindowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Icon(.chatCircleTextFill, size: 14)
                    .foregroundStyle(Color.qGreen)
                Text(selectedPeriod.map { "\($0.rawValue) reflections" } ?? "Recent reflections")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Text("\(filteredAnswers.count) answers")
                    .font(.ui(12))
                    .foregroundStyle(Color.qGray)
            }

            VStack(spacing: 8) {
                ForEach(filteredAnswers.prefix(6)) { answer in
                    reflectionRow(answer)
                }
            }
        }
    }

    private func reflectionRow(_ answer: Answer) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(answer.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk)
                    .monospacedDigit()
                Text(answer.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.ui(10.5))
                    .foregroundStyle(Color.qGray)
            }
            .frame(width: 58, alignment: .leading)

            Rectangle()
                .fill(Color.qLine)
                .frame(width: 1, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(answer.questionText)
                    .font(.ui(13, .medium))
                    .foregroundStyle(Color.qInk2)
                    .lineLimit(1)
                Text("“\(answer.text)”")
                    .font(.ui(12))
                    .foregroundStyle(Color.qGray)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.qBlock)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 0.75)
                )
        )
    }
}

// MARK: - 24-Hour Circular Clock Component

private struct Circular24hClockView: View {
    @Binding var selectedPeriod: ReflectionInsightsView.DayPeriod?

    // 24-hour mock reflection data points: (hour: 0-24, minute: 0-59, label)
    private let dots: [(hour: Double, count: Int)] = [
        (7.5, 3),
        (8.75, 12),
        (9.2, 5),
        (12.5, 2),
        (13.6, 4),
        (18.2, 3),
        (20.5, 4),
        (23.2, 1)
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = (size - 40) / 2

            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.qLine.opacity(0.85), lineWidth: 1.5)
                    .frame(width: radius * 2, height: radius * 2)

                // 24 Hour Tick Marks
                ForEach(0..<24) { h in
                    let angle = Angle.degrees(Double(h) * 15.0 - 90.0)
                    let isMajor = h % 6 == 0
                    let tickLen: CGFloat = isMajor ? 8 : 4

                    Rectangle()
                        .fill(isMajor ? Color.qInk2 : Color.qGray4)
                        .frame(width: isMajor ? 2 : 1, height: tickLen)
                        .offset(y: -radius + tickLen / 2)
                        .rotationEffect(angle)
                }

                // 4 Cardinal Time Labels
                Text("00:00")
                    .font(.ui(9, .bold))
                    .foregroundStyle(Color.qGray)
                    .offset(y: -radius - 12)

                Text("06:00")
                    .font(.ui(9, .bold))
                    .foregroundStyle(Color.qGray)
                    .offset(x: radius + 16)

                Text("12:00")
                    .font(.ui(9, .bold))
                    .foregroundStyle(Color.qGray)
                    .offset(y: radius + 12)

                Text("18:00")
                    .font(.ui(9, .bold))
                    .foregroundStyle(Color.qGray)
                    .offset(x: -radius - 16)

                // Highlighted Peak Arc: 06:00 to 12:00 (90° to 180° clockwise)
                Circle()
                    .trim(from: 0.25, to: 0.50)
                    .stroke(
                        LinearGradient(colors: [Color.qLime, Color.qGreen], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))

                // Reflection Density Dots along the track
                ForEach(Array(dots.enumerated()), id: \.offset) { _, dot in
                    let angle = Angle.degrees(dot.hour / 24.0 * 360.0 - 90.0)
                    let isPeakHour = dot.hour >= 8 && dot.hour <= 9

                    ZStack {
                        Circle()
                            .fill(isPeakHour ? Color.qGreen : Color.qMint)
                            .frame(width: isPeakHour ? 13 : 8, height: isPeakHour ? 13 : 8)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                    .offset(x: radius * cos(angle.radians), y: radius * sin(angle.radians))
                }

                // Dial Center Hub
                VStack(spacing: 2) {
                    Text("PEAK")
                        .font(.ui(9, .bold))
                        .tracking(1.0)
                        .foregroundStyle(Color.qBrandText)

                    Text("8:45")
                        .font(.ui(26, .bold))
                        .foregroundStyle(Color.qInk)
                        .monospacedDigit()

                    Text("AM")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Color.qGray)

                    HStack(spacing: 3) {
                        Circle().fill(Color.qGreen).frame(width: 4, height: 4)
                        Text("Morning")
                            .font(.ui(10, .semibold))
                            .foregroundStyle(Color.qGreenDeep)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.qMint.opacity(0.35)))
                    .padding(.top, 1)
                }
                .frame(width: 104, height: 104)
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
