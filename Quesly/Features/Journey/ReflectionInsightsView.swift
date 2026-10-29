import SwiftUI

/// Dedicated screen for "Reflection Rhythm & 24-Hour Clock" (Ритм рефлексии и суточный циферблат).
/// Combines the circular 24h chronotype dial with habit rhythm bars, peak time insights, and depth analytics.
struct ReflectionInsightsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPeriod: DayPeriod? = nil
    @State private var activeTab: InsightTab = .dial

    enum InsightTab: String, CaseIterable {
        case dial = "24h Dial"
        case rhythm = "Rhythm Bars"
    }

    enum DayPeriod: String, CaseIterable, Identifiable {
        case morning = "Morning"
        case afternoon = "Midday"
        case evening = "Evening"
        case night = "Night"

        var id: String { rawValue }

        var hoursRange: ClosedRange<Int> {
            switch self {
            case .morning: return 6...11
            case .afternoon: return 12...17
            case .evening: return 18...22
            case .night: return 23...24 // and 0...5
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

        var icon: String {
            switch self {
            case .morning: return "🌅"
            case .afternoon: return "☀️"
            case .evening: return "🌆"
            case .night: return "🌙"
            }
        }

        var percentage: Int {
            switch self {
            case .morning: return 54
            case .afternoon: return 24
            case .evening: return 17
            case .night: return 5
            }
        }

        var isPeak: Bool { self == .morning }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Space.l) {
                    // MARK: 1. Mode Switcher (24h Dial vs Rhythm Bars)
                    tabSelector

                    // MARK: 2. Hero Interactive Visualization Card
                    switch activeTab {
                    case .dial:
                        clockDialCard
                    case .rhythm:
                        rhythmHistogramCard
                    }

                    // MARK: 3. Period Filter Chips
                    periodFilterChips

                    // MARK: 4. Habit Quality Metrics
                    habitDeepMetricsCard

                    // MARK: 5. Time-of-Day Thought Flashbacks
                    recentReflectionsSection
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

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 4) {
            ForEach(InsightTab.allCases, id: \.self) { tab in
                let selected = activeTab == tab
                Button {
                    withAnimation(.qSpring) { activeTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.ui(13, selected ? .semibold : .medium))
                        .foregroundStyle(selected ? Color.qInk : Color.qGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(
                            selected
                                ? RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white).shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.qField)
        )
    }

    // MARK: - 24-Hour Circular Clock Dial Card

    private var clockDialCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("24-HOUR REFLECTION CLOCK")
                        .font(.ui(11, .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.qBrandText)
                    Text("Daily Chronotype")
                        .font(.ui(17, .semibold))
                        .foregroundStyle(Color.qInk)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("🌅")
                        .font(.system(size: 11))
                    Text("Early Thinker")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Color.qGreenDeep)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Capsule().fill(Color.qLime.opacity(0.35)))
            }

            // The Dial Widget
            Circular24hClockView(selectedPeriod: $selectedPeriod)
                .frame(width: 250, height: 250)
                .padding(.vertical, 10)

            // Dynamic dial legend / selected insight
            VStack(spacing: 4) {
                if let p = selectedPeriod {
                    HStack(spacing: 6) {
                        Text(p.icon).font(.system(size: 14))
                        Text("\(p.rawValue): \(p.label)")
                            .font(.ui(14, .semibold))
                            .foregroundStyle(Color.qInk)
                        Text("(\(p.percentage)%)")
                            .font(.ui(13, .medium))
                            .foregroundStyle(Color.qGreenDeep)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text("🌅").font(.system(size: 14))
                        Text("Peak hour: 8:45 AM")
                            .font(.ui(15, .semibold))
                            .foregroundStyle(Color.qInk)
                    }
                    Text("54% of your reflections happen between 06:00 and 12:00")
                        .font(.ui(12.5))
                        .foregroundStyle(Color.qGray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(minHeight: 38)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.qBlock)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }

    // MARK: - Rhythm Histogram Card

    private var rhythmHistogramCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HABIT RHYTHM")
                        .font(.ui(11, .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.qBrandText)
                    Text("Reflection Distribution")
                        .font(.ui(17, .semibold))
                        .foregroundStyle(Color.qInk)
                }
                Spacer()
                Text("Peak: 8:45 AM")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Color.qGreenDeep)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.qLime.opacity(0.35)))
            }

            // Visual Bars
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(DayPeriod.allCases) { period in
                    let isSelected = selectedPeriod == nil || selectedPeriod == period
                    let isPeak = period.isPeak

                    VStack(spacing: 6) {
                        Text("\(period.percentage)%")
                            .font(.ui(12, isPeak ? .bold : .medium))
                            .foregroundStyle(isPeak ? Color.qGreenDeep : Color.qGray)
                            .monospacedDigit()

                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(Color.qLine.opacity(0.5))
                                .frame(width: 44, height: 96)

                            Capsule()
                                .fill(
                                    isPeak
                                        ? LinearGradient(colors: [Color.qGreen, Color.qLime], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [Color.qGray4, Color.qGray4.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 44, height: max(12, 96 * CGFloat(period.percentage) / 100))
                                .opacity(isSelected ? 1.0 : 0.35)
                        }

                        VStack(spacing: 2) {
                            Text(period.icon).font(.system(size: 11))
                            Text(period.rawValue)
                                .font(.ui(11.5, isPeak ? .semibold : .medium))
                                .foregroundStyle(isPeak ? Color.qInk : Color.qGray)
                            Text(period.label.components(separatedBy: " – ").first ?? "")
                                .font(.ui(9.5))
                                .foregroundStyle(Color.qGray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.qSpring) {
                            selectedPeriod = (selectedPeriod == period) ? nil : period
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.qField.opacity(0.7))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.qBlock)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }

    // MARK: - Period Filter Chips

    private var periodFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "All 24h", icon: "🕒", active: selectedPeriod == nil) {
                    withAnimation(.qSpring) { selectedPeriod = nil }
                }
                ForEach(DayPeriod.allCases) { period in
                    chip(label: period.rawValue, icon: period.icon, active: selectedPeriod == period) {
                        withAnimation(.qSpring) {
                            selectedPeriod = (selectedPeriod == period) ? nil : period
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(label: String, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(icon).font(.system(size: 11))
                Text(label)
                    .font(.ui(12, active ? .semibold : .medium))
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(active ? Color.qGreenDeep : Color.qInk2)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(active ? Color.qLime.opacity(0.35) : Color.qField)
            )
            .overlay(
                Capsule().stroke(active ? Color.qGreen.opacity(0.3) : Color.qLine, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Deep Metrics Card

    private var habitDeepMetricsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HABIT CONSISTENCY & DEPTH")
                .font(.ui(11, .semibold))
                .tracking(0.6)
                .foregroundStyle(Color.qBrandText)

            HStack(spacing: 12) {
                metricBox(
                    icon: "🎯",
                    value: "94%",
                    title: "Rhythm Consistency",
                    caption: "Answered within regular 2h window"
                )
                metricBox(
                    icon: "✍️",
                    value: "48 words",
                    title: "Thought Depth",
                    caption: "+18% deeper during morning coffee"
                )
            }

            HStack(spacing: 12) {
                metricBox(
                    icon: "⚡️",
                    value: "3 min",
                    title: "Avg. Duration",
                    caption: "Unrushed, reflective headspace"
                )
                metricBox(
                    icon: "🔥",
                    value: "\(store.streak) days",
                    title: "Current Habit Streak",
                    caption: "Consecutive daily reflections"
                )
            }
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

    private func metricBox(icon: String, value: String, title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(icon).font(.system(size: 14))
                Spacer()
                Text(value)
                    .font(.ui(16, .semibold))
                    .foregroundStyle(Color.qInk)
                    .monospacedDigit()
            }
            Text(title)
                .font(.ui(12, .semibold))
                .foregroundStyle(Color.qInk2)
            Text(caption)
                .font(.ui(10.5))
                .foregroundStyle(Color.qGray)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.qField.opacity(0.8))
        )
    }

    // MARK: - Recent Reflections in Selected Period

    private var recentReflectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Icon(.chatCircleTextFill, size: 14)
                    .foregroundStyle(Color.qGreen)
                Text("Reflection Timeline")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Text("Chronological")
                    .font(.ui(12))
                    .foregroundStyle(Color.qGray)
            }

            VStack(spacing: 8) {
                timelineRow(time: "8:45 AM", period: "Morning", question: "What is a small kindness you never forgot?", wordCount: 52)
                timelineRow(time: "9:12 AM", period: "Morning", question: "If you could live anywhere, where would it be?", wordCount: 41)
                timelineRow(time: "1:30 PM", period: "Midday", question: "What made you smile today?", wordCount: 28)
                timelineRow(time: "8:10 PM", period: "Evening", question: "What lesson took you the longest to learn?", wordCount: 64)
            }
        }
    }

    private func timelineRow(time: String, period: String, question: String, wordCount: Int) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(time)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk)
                    .monospacedDigit()
                Text(period)
                    .font(.ui(10.5))
                    .foregroundStyle(Color.qGray)
            }
            .frame(width: 64, alignment: .leading)

            Rectangle()
                .fill(Color.qLine)
                .frame(width: 1, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(question)
                    .font(.ui(13, .medium))
                    .foregroundStyle(Color.qInk2)
                    .lineLimit(1)
                Text("\(wordCount) words · Deep thought")
                    .font(.ui(11))
                    .foregroundStyle(Color.qGreenDeep)
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
    private let dots: [(hour: Double, label: String, count: Int)] = [
        (7.5, "7:30 AM", 3),
        (8.75, "8:45 AM (Peak)", 12),
        (9.2, "9:12 AM", 5),
        (12.5, "12:30 PM", 2),
        (13.6, "1:36 PM", 4),
        (18.2, "6:12 PM", 3),
        (20.5, "8:30 PM", 4),
        (23.2, "11:12 PM", 1)
    ]

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = (size - 44) / 2

            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.qLine.opacity(0.8), lineWidth: 1.5)
                    .frame(width: radius * 2, height: radius * 2)

                // 24 Hour Tick Marks
                ForEach(0..<24) { h in
                    let angle = Angle.degrees(Double(h) * 15.0 - 90.0) // 0h at Top
                    let isMajor = h % 6 == 0
                    let tickLen: CGFloat = isMajor ? 8 : 4

                    Rectangle()
                        .fill(isMajor ? Color.qInk2 : Color.qGray4)
                        .frame(width: isMajor ? 2 : 1, height: tickLen)
                        .offset(y: -radius + tickLen / 2)
                        .rotationEffect(angle)
                }

                // 4 Cardinal Time Labels (12h Noon at Bottom, 00h Midnight at Top, 06h Dawn at Right, 18h Dusk at Left)
                // In standard 24h clockwise dial:
                // 00:00 (Midnight) = Top (0°)
                // 06:00 (Morning) = Right (90°)
                // 12:00 (Noon) = Bottom (180°)
                // 18:00 (Evening) = Left (270°)
                Text("00:00")
                    .font(.ui(9, .bold))
                    .foregroundStyle(Color.qGray)
                    .offset(y: -radius - 14)

                Text("06:00")
                    .font(.ui(9, .bold))
                    .foregroundStyle(Color.qGray)
                    .offset(x: radius + 16)

                Text("12:00")
                    .font(.ui(9, .bold))
                    .foregroundStyle(Color.qGray)
                    .offset(y: radius + 14)

                Text("18:00")
                    .font(.ui(9, .bold))
                    .foregroundStyle(Color.qGray)
                    .offset(x: -radius - 16)

                // Highlighted Peak Arc: 06:00 to 12:00 (90° to 180° clockwise from 00:00 top)
                Circle()
                    .trim(from: 0.25, to: 0.50) // from 6h to 12h
                    .stroke(
                        LinearGradient(colors: [Color.qLime, Color.qGreen], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))

                // Reflection Density Dots along the track
                ForEach(Array(dots.enumerated()), id: \.offset) { _, dot in
                    // Angle: hour 0..24 -> 0..360 deg
                    let angle = Angle.degrees(dot.hour / 24.0 * 360.0 - 90.0)
                    let isPeakHour = dot.hour >= 8 && dot.hour <= 9

                    ZStack {
                        Circle()
                            .fill(isPeakHour ? Color.qGreen : Color.qLime)
                            .frame(width: isPeakHour ? 14 : 9, height: isPeakHour ? 14 : 9)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(color: isPeakHour ? Color.qGreen.opacity(0.4) : .clear, radius: 4)
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
                        Circle().fill(Color.qGreen).frame(width: 5, height: 5)
                        Text("54% active")
                            .font(.ui(10, .medium))
                            .foregroundStyle(Color.qGreenDeep)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.qLime.opacity(0.35)))
                    .padding(.top, 2)
                }
                .frame(width: 110, height: 110)
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
