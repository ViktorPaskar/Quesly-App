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
                    .lineLimit(1)
                Text(answer.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.ui(11))
                    .foregroundStyle(Color.qGray)
                    .lineLimit(1)
            }
            .frame(width: 76, alignment: .leading)

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

// MARK: - 24-Hour Circular Clock Component (Clear, Colorful, Intuitive)

private struct Circular24hClockView: View {
    @Binding var selectedPeriod: ReflectionInsightsView.DayPeriod?

    private struct DotData {
        let hour: Double
        let isPeak: Bool
        let color: Color
    }

    private let dots: [DotData] = [
        DotData(hour: 7.5, isPeak: false, color: Color(hex: 0xF59E0B)),
        DotData(hour: 8.75, isPeak: true, color: Color.qGreen),
        DotData(hour: 9.2, isPeak: true, color: Color(hex: 0x10B981)),
        DotData(hour: 12.5, isPeak: false, color: Color(hex: 0x0EA5E9)),
        DotData(hour: 13.6, isPeak: false, color: Color(hex: 0x0EA5E9)),
        DotData(hour: 18.2, isPeak: false, color: Color(hex: 0xF43F5E)),
        DotData(hour: 20.5, isPeak: false, color: Color(hex: 0xF43F5E)),
        DotData(hour: 23.2, isPeak: false, color: Color(hex: 0x6366F1))
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = (size - 44) / 2

            ZStack {
                // Diurnal Daylight Quadrants (4 soft distinct colored tracks)
                // Night quadrant: 23:00 to 06:00 (-105° to 0°)
                Circle()
                    .trim(from: 23.0 / 24.0, to: 1.0)
                    .stroke(Color(hex: 0x6366F1).opacity(0.18), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: 0.0, to: 6.0 / 24.0)
                    .stroke(Color(hex: 0x6366F1).opacity(0.18), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))

                // Morning quadrant: 06:00 to 12:00 (0° to 90°)
                Circle()
                    .trim(from: 6.0 / 24.0, to: 12.0 / 24.0)
                    .stroke(Color(hex: 0xF59E0B).opacity(0.20), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))

                // Afternoon quadrant: 12:00 to 18:00 (90° to 180°)
                Circle()
                    .trim(from: 12.0 / 24.0, to: 18.0 / 24.0)
                    .stroke(Color(hex: 0x0EA5E9).opacity(0.20), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))

                // Evening quadrant: 18:00 to 23:00 (180° to 255°)
                Circle()
                    .trim(from: 18.0 / 24.0, to: 23.0 / 24.0)
                    .stroke(Color(hex: 0xF43F5E).opacity(0.20), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))

                // Peak Active Arc: 06:00 to 12:00 Glowing Sunrise Gradient
                Circle()
                    .trim(from: 0.25, to: 0.50)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: 0xF59E0B), Color.qLime, Color.qGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 7.5, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))

                // Clear Human-Friendly Cardinal Labels
                Text("12 AM")
                    .font(.ui(11.5, .bold))
                    .foregroundStyle(Color(hex: 0x6366F1))
                    .offset(y: -radius - 13)

                Text("6 AM")
                    .font(.ui(11.5, .bold))
                    .foregroundStyle(Color(hex: 0xD97706))
                    .offset(x: radius + 20)

                Text("12 PM")
                    .font(.ui(11.5, .bold))
                    .foregroundStyle(Color(hex: 0x0284C7))
                    .offset(y: radius + 13)

                Text("6 PM")
                    .font(.ui(11.5, .bold))
                    .foregroundStyle(Color(hex: 0xE11D48))
                    .offset(x: -radius - 20)

                // Reflection Points with Diurnal Colors
                ForEach(Array(dots.enumerated()), id: \.offset) { _, dot in
                    let angle = Angle.degrees(dot.hour / 24.0 * 360.0 - 90.0)

                    Circle()
                        .fill(dot.color)
                        .frame(width: dot.isPeak ? 12 : 8, height: dot.isPeak ? 12 : 8)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.8))
                        .shadow(color: dot.color.opacity(0.4), radius: 3)
                        .offset(x: radius * cos(angle.radians), y: radius * sin(angle.radians))
                }

                // Generous, Clear Center Focal Hub
                VStack(spacing: 3) {
                    Text("PEAK HOUR")
                        .font(.ui(9, .bold))
                        .tracking(1.2)
                        .foregroundStyle(Color.qBrandText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.qMint.opacity(0.35)))

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("8:45")
                            .font(.display(30, .bold))
                            .foregroundStyle(Color.qInk)
                            .monospacedDigit()
                        Text("AM")
                            .font(.ui(13, .bold))
                            .foregroundStyle(Color.qBrandText)
                    }
                }
                .frame(width: 104, height: 104)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 3)
                )
            }
            .frame(width: size, height: size)
            .position(x: center.x, y: center.y)
        }
    }
}
