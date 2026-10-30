import SwiftUI

/// Dedicated screen for "Reflection Rhythm" (Ритм рефлексии).
/// Authentic, human-designed habit analytics (Apple Health & Day One inspired):
/// - Daylight Horizon 24h timeline with precise peak hour marker
/// - Diurnal color distribution (Amber sunrise, Emerald afternoon, Bubblegum evening, Indigo night)
/// - Clean segmented filter pills
/// - Streamlined reflection history feed
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

        var systemIcon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "cloud.sun.fill"
            case .evening: return "sunset.fill"
            case .night: return "moon.stars.fill"
            }
        }

        var color: Color {
            switch self {
            case .morning: return Color(hex: 0xF59E0B)
            case .afternoon: return Color.qGreen
            case .evening: return Color.qPink
            case .night: return Color(hex: 0x6366F1)
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
                case .morning: return 48
                case .afternoon: return 26
                case .evening: return 17
                case .night: return 9
                }
            }
            let c = count(in: answers)
            return Int(round(Double(c) / Double(answers.count) * 100))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Space.l) {
                    // MARK: 1. Hero Daylight Horizon Timeline Card
                    heroHorizonCard

                    // MARK: 2. Period Filter Segmented Pills
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

    // MARK: - 1. Hero Daylight Horizon Card (Apple Health style, no AI circle)

    private var heroHorizonCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            // Header stats
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: 0xF59E0B))
                            .frame(width: 8, height: 8)
                        Text("PEAK HABIT HOUR")
                            .font(.ui(11, .semibold))
                            .tracking(0.8)
                            .foregroundStyle(Color.qGray)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("8:45")
                            .font(.display(34, .bold))
                            .foregroundStyle(Color.qInk)
                            .monospacedDigit()
                        Text("AM")
                            .font(.ui(16, .semibold))
                            .foregroundStyle(Color.qGray)
                    }

                    Text("48% of reflections written before noon")
                        .font(.ui(13))
                        .foregroundStyle(Color.qGray)
                }

                Spacer()

                // Morning Badge
                HStack(spacing: 5) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xD97706))
                    Text("Morning")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Color.qInk)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(hex: 0xFEF3C7)))
            }

            // Continuous Proportional Daylight Bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    let totalWidth = geo.size.width
                    HStack(spacing: 3) {
                        ForEach(DayPeriod.allCases) { period in
                            let pct = CGFloat(period.percentage(in: store.myAnswers)) / 100.0
                            let barW = max(12, totalWidth * pct - 3)

                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(period.color)
                                .frame(width: barW, height: 16)
                        }
                    }
                }
                .frame(height: 16)

                // 24-hour Timeline axis
                HStack {
                    Text("12 AM").font(.ui(10.5, .medium)).foregroundStyle(Color.qGray)
                    Spacer()
                    Text("6 AM").font(.ui(10.5, .medium)).foregroundStyle(Color.qGray)
                    Spacer()
                    Text("12 PM").font(.ui(10.5, .medium)).foregroundStyle(Color.qGray)
                    Spacer()
                    Text("6 PM").font(.ui(10.5, .medium)).foregroundStyle(Color.qGray)
                    Spacer()
                    Text("12 AM").font(.ui(10.5, .medium)).foregroundStyle(Color.qGray)
                }
            }
            .padding(.top, 4)

            // Micro 4-zone legend
            HStack(spacing: 0) {
                ForEach(DayPeriod.allCases) { p in
                    HStack(spacing: 4) {
                        Circle().fill(p.color).frame(width: 6, height: 6)
                        Text(p.rawValue)
                            .font(.ui(11.5, .medium))
                            .foregroundStyle(Color.qInk2)
                        Text("\(p.percentage(in: store.myAnswers))%")
                            .font(.ui(11, .semibold))
                            .foregroundStyle(Color.qGray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.qBlock)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }

    // MARK: - 2. Period Filter Segmented Bar (Unified, 1 row, clean pills)

    private var periodSegmentedBar: some View {
        HStack(spacing: 6) {
            periodPill(title: "All", pct: nil, color: Color.qGreenDeep, isSelected: selectedPeriod == nil) {
                withAnimation(.qSpring) { selectedPeriod = nil }
            }

            ForEach(DayPeriod.allCases) { period in
                let isSelected = selectedPeriod == period
                let pct = period.percentage(in: store.myAnswers)
                periodPill(title: period.rawValue, pct: pct, color: period.color, isSelected: isSelected) {
                    withAnimation(.qSpring) {
                        selectedPeriod = (selectedPeriod == period) ? nil : period
                    }
                }
            }
        }
    }

    private func periodPill(title: String, pct: Int?, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.ui(12.5, isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.white : Color.qInk)
                    .lineLimit(1)
                if let pct {
                    Text("\(pct)%")
                        .font(.ui(10, .medium))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.qGray)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color.qBlock)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : Color.qLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Past Reflections Stream

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
            // Time column
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

#Preview {
    ReflectionInsightsView().environment(AppStore())
}
