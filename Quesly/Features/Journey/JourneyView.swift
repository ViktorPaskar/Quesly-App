import SwiftUI

/// 3rd Bottom Tab: Journey.
/// Apple Fitness–style summary: one big number per section, one supporting line, generous air.
/// - 1. Streak hero (the number, the week, best / this month)
/// - 2. Rhythm (when you usually answer, one bar)
/// - 3. On this day (a past answer to reread)
/// - 4. Milestones
struct JourneyView: View {
    @Environment(AppStore.self) private var store
    @State private var openedMemory: Answer?
    @State private var showInsightsSheet = DemoConfig.opensInsights

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                streakHero

                section("Rhythm") {
                    Button { showInsightsSheet = true } label: { rhythmCard }
                        .buttonStyle(.pressable)
                }

                if let memory = store.myAnswers.first(where: { !Calendar.current.isDateInToday($0.createdAt) }) {
                    section("On this day") {
                        Button { openedMemory = memory } label: { memoryCard(memory) }
                            .buttonStyle(.pressable)
                    }
                }

                milestonesSection
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.s)
            .padding(.bottom, 90) // clearance above the floating dock
        }
        .background(Color.qBackground)
        .navigationTitle("Journey")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $openedMemory) { answer in
            MemoryDetailSheet(answer: answer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showInsightsSheet) {
            ReflectionInsightsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Section scaffold

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.ui(20, .semibold))
                .foregroundStyle(Color.qInk)
            content()
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qField))
    }

    // MARK: - 1. Streak hero

    private var weekDays: [Date] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: .now)
        let start = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private var streakHero: some View {
        let cal = Calendar.current
        let streak = store.streak
        let best = max(store.bestStreak, streak)
        let thisMonth = store.answeredDays.filter { cal.isDate($0, equalTo: .now, toGranularity: .month) }.count

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(streak)")
                    .font(.display(76, .semibold))
                    .foregroundStyle(Color.qFlame)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("day streak")
                    .font(.ui(20, .semibold))
                    .foregroundStyle(Color.qInk)
            }
            .accessibilityElement(children: .combine)

            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let done = store.answeredDays.contains { cal.isDate($0, inSameDayAs: day) }
                    let isToday = cal.isDateInToday(day)
                    VStack(spacing: 8) {
                        Circle()
                            .fill(done ? Color.qFlame : Color.qField)
                            .overlay(Circle().strokeBorder(isToday && !done ? Color.qFlame : .clear, lineWidth: 2))
                            .frame(width: 30, height: 30)
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.ui(12, isToday ? .semibold : .regular))
                            .foregroundStyle(isToday ? Color.qInk : Color.qGray)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))), \(done ? "answered" : "not answered")")
                }
            }

            Text("Best \(best) days · \(thisMonth) this month")
                .font(.ui(15))
                .foregroundStyle(Color.qGray)
        }
    }

    // MARK: - 2. Rhythm

    private var rhythm: [(period: String, share: Double, color: Color)] {
        let cal = Calendar.current
        var m = 0, a = 0, e = 0, n = 0
        for answer in store.myAnswers {
            switch cal.component(.hour, from: answer.createdAt) {
            case 6..<12: m += 1
            case 12..<18: a += 1
            case 18..<23: e += 1
            default: n += 1
            }
        }
        let total = max(1, m + a + e + n)
        return [("Morning", Double(m) / Double(total), Color(hex: 0xF5A30B)),
                ("Afternoon", Double(a) / Double(total), Color.qGreen),
                ("Evening", Double(e) / Double(total), Color(hex: 0xF29CC0)),
                ("Night", Double(n) / Double(total), Color(hex: 0x8B85E8))]
    }

    private var usualTime: String {
        let cal = Calendar.current
        // Median time inside the most common part of the day, so it agrees with "Mostly in the …".
        let peak = rhythm.max { $0.share < $1.share }?.period
        let inPeak = store.myAnswers.filter { a in
            let h = cal.component(.hour, from: a.createdAt)
            switch peak {
            case "Morning": return (6..<12).contains(h)
            case "Afternoon": return (12..<18).contains(h)
            case "Evening": return (18..<23).contains(h)
            default: return h >= 23 || h < 6
            }
        }
        let minutes = inPeak.map { cal.component(.hour, from: $0.createdAt) * 60 + cal.component(.minute, from: $0.createdAt) }
        guard !minutes.isEmpty else { return "—" }
        let median = minutes.sorted()[minutes.count / 2]
        let date = cal.date(bySettingHour: median / 60, minute: median % 60, second: 0, of: .now) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private var rhythmCard: some View {
        let parts = rhythm
        let peak = parts.max { $0.share < $1.share }
        return card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You usually answer at")
                            .font(.ui(15))
                            .foregroundStyle(Color.qGray)
                        Text(usualTime)
                            .font(.display(34, .semibold))
                            .foregroundStyle(Color.qInk)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.qGray)
                        .accessibilityHidden(true)
                }

                GeometryReader { geo in
                    HStack(spacing: 3) {
                        ForEach(parts, id: \.period) { part in
                            Capsule().fill(part.color)
                                .frame(width: max(part.share > 0 ? 6 : 0, (geo.size.width - 9) * part.share))
                        }
                    }
                }
                .frame(height: 10)
                .accessibilityHidden(true)

                if let peak {
                    Text("Mostly in the \(peak.period.lowercased()) · \(Int((peak.share * 100).rounded()))%")
                        .font(.ui(15))
                        .foregroundStyle(Color.qGray)
                }
            }
        }
    }

    // MARK: - 3. On this day

    private func memoryCard(_ answer: Answer) -> some View {
        card {
            VStack(alignment: .leading, spacing: 10) {
                Text(answer.createdAt.formatted(.dateTime.month(.wide).day()))
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qGray)
                Text(answer.questionText)
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                    .multilineTextAlignment(.leading)
                Text(answer.text)
                    .font(.display(20))
                    .foregroundStyle(Color.qInk)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
        }
    }

    // MARK: - Milestones Section

    private var milestonesSection: some View {
        let items = store.achievements
        let inProgress = items.filter { !$0.isUnlocked && $0.progress > 0 }
        let unlocked = items.filter { $0.isUnlocked }
        let locked = items.filter { !$0.isUnlocked && $0.progress == 0 }
        let totalUnlocked = unlocked.count
        let totalCount = items.count

        return VStack(alignment: .leading, spacing: 16) {
            // Header banner with progress scale
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.qLime)
                            .frame(width: 40, height: 40)
                        QueslyMark(color: .qGreen, cutout: .qLime)
                            .frame(width: 22)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quiet milestones")
                            .font(.display(19, .semibold))
                            .foregroundStyle(.white)
                        Text("Earned through honest daily reflection.")
                            .font(.ui(12))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                // Progress scale
                let percentage = totalCount > 0 ? Int(Double(totalUnlocked) / Double(totalCount) * 100) : 0
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(totalUnlocked) of \(totalCount) unlocked")
                            .font(.ui(12, .semibold))
                            .foregroundStyle(Color.qLime)
                        Spacer()
                        Text("\(percentage)%")
                            .font(.ui(12, .semibold))
                            .foregroundStyle(Color.white.opacity(0.90))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.20))
                            Capsule().fill(Color.qLime)
                                .frame(width: max(4, geo.size.width * CGFloat(totalUnlocked) / CGFloat(max(1, totalCount))))
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.qGreen)
            )

            // In Progress Section
            if !inProgress.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("IN PROGRESS (\(inProgress.count))")
                        .font(.ui(11, .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.qGray)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(inProgress.enumerated()), id: \.element.id) { index, ach in
                            if index > 0 { divider }
                            MilestoneRow(achievement: ach)
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

            // Unlocked Section
            if !unlocked.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("UNLOCKED (\(unlocked.count))")
                        .font(.ui(11, .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.qGray)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(unlocked.enumerated()), id: \.element.id) { index, ach in
                            if index > 0 { divider }
                            MilestoneRow(achievement: ach)
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

            // Locked Section
            if !locked.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LOCKED (\(locked.count))")
                        .font(.ui(11, .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.qGray)
                        .padding(.leading, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(locked.enumerated()), id: \.element.id) { index, ach in
                            if index > 0 { divider }
                            MilestoneRow(achievement: ach)
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
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.qLine)
            .frame(height: 1)
            .padding(.leading, 72)
    }
}

// MARK: - Milestone Row

private struct MilestoneRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 14) {
            HexBadge(asset: achievement.badgeAsset, isLocked: !achievement.isUnlocked)
                .frame(width: 44, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Color.qInk)

                    if achievement.isUnlocked {
                        HStack(spacing: 3) {
                            Icon(.checkBold, size: 9)
                            Text("Done")
                                .font(.ui(10, .semibold))
                        }
                        .foregroundStyle(Color.qGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.qMint.opacity(0.35)))
                    } else if achievement.progress == 0 {
                        Icon(.lockSimpleFill, size: 11)
                            .foregroundStyle(Color.qGray4)
                    }
                }

                Text(achievement.subtitle)
                    .font(.ui(12))
                    .foregroundStyle(Color.qGray)
                    .lineLimit(2)

                if !achievement.isUnlocked && !achievement.isSpecial && achievement.goal > 1 {
                    HStack(spacing: 8) {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.qLine)
                                Capsule().fill(Color.qGreen)
                                    .frame(width: max(3, g.size.width * CGFloat(achievement.progress) / CGFloat(achievement.goal)))
                            }
                        }
                        .frame(height: 4)

                        Text("\(achievement.progress)/\(achievement.goal)")
                            .font(.ui(11, .semibold))
                            .foregroundStyle(Color.qInk2)
                            .monospacedDigit()
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
    }
}
