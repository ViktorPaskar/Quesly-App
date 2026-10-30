import SwiftUI

/// 3rd Bottom Tab: Journey ("Путь").
/// Dedicated hub for daily ritual, streak, reflection rhythm, and quiet milestones.
/// - 1. Streak Hero Card (7-day circles tracker, personal best, month total)
/// - 2. Reflection Rhythm Card (clean, restrained time-of-day habit card without generic AI slop)
/// - 3. "On This Day" Memory Flashback (reread previous reflections)
/// - 4. Milestones Hub (all unlocked, in-progress, and locked achievements)
struct JourneyView: View {
    @Environment(AppStore.self) private var store
    @State private var openedMemory: Answer?
    @State private var showInsightsSheet = DemoConfig.opensInsights
    @State private var showNewUserCapsule = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Space.m) {
                // MARK: 1. Streak Hero Card (7-Day Tracker)
                StreakCard()

                // MARK: 2. Personal Reflection Rhythm
                Button {
                    showInsightsSheet = true
                } label: {
                    ReflectionRhythmCard()
                }
                .buttonStyle(.plain)

                // MARK: 3. "On This Day" Memory Flashback
                onThisDayCard

                // MARK: 4. Milestones & Achievements Hub
                milestonesSection
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.s)
            .padding(.bottom, 90) // comfortable clearance above floating bottom bar
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

    // MARK: - On This Day / Time Capsule Card (Editorial & Clean)

    private var onThisDayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with subtle warm styling
            HStack(spacing: 8) {
                IconChip(
                    icon: showNewUserCapsule ? .hourglassMediumFill : .calendar,
                    tint: Color(hex: 0xF59E0B),
                    fill: Color(hex: 0xF59E0B).opacity(0.12)
                )

                VStack(alignment: .leading, spacing: 1) {
                    Text(showNewUserCapsule ? "TIME CAPSULE" : "ON THIS DAY")
                        .font(.ui(11, .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color(hex: 0xD97706))
                    Text(showNewUserCapsule ? "Brewing memories" : "1 year ago today")
                        .font(.ui(13.5, .semibold))
                        .foregroundStyle(Color.qInk)
                }

                Spacer(minLength: 0)

                // Toggle between Flashback and New User Capsule
                Button {
                    withAnimation(.qSpring) { showNewUserCapsule.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Icon(showNewUserCapsule ? .sparkleFill : .hourglassMediumFill, size: 10)
                        Text(showNewUserCapsule ? "View flashback" : "New user view")
                            .font(.ui(11, .semibold))
                    }
                    .foregroundStyle(Color.qInk2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.qLine.opacity(0.6)))
                }
                .buttonStyle(.plain)
            }

            if showNewUserCapsule {
                // MARK: State A: New user state (no 1-month or 1-year history yet)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your personal time capsule is in the making")
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Color.qInk)

                    Text("Every reflection you write today is quietly sealed and will resurface here next month and next year.")
                        .font(.ui(12.5))
                        .foregroundStyle(Color.qGray)
                        .lineSpacing(2.5)

                    // Capsule Progress Indicator
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("9 of 30 reflections saved")
                                .font(.ui(11.5, .semibold))
                                .foregroundStyle(Color.qInk)
                            Spacer()
                            Text("21 days left")
                                .font(.ui(11.5))
                                .foregroundStyle(Color.qGray)
                        }

                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.qLine)
                                Capsule()
                                    .fill(Color(hex: 0xF59E0B))
                                    .frame(width: max(8, g.size.width * 0.30))
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.top, 4)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.qField)
                )
            } else {
                // MARK: State B: Populated 1-year memory flashback
                let sampleAnswer = store.myAnswers.first ?? MockData.myHistory().first ?? Answer(
                    id: "sample",
                    questionId: "q-kindness",
                    questionText: "What is a small kindness you never forgot?",
                    authorId: store.me.id,
                    text: "A stranger held the train door for me when I was running late with heavy bags.",
                    createdAt: .now
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(sampleAnswer.questionText)
                        .font(.ui(13.5, .semibold))
                        .foregroundStyle(Color.qInk)
                        .lineLimit(2)

                    HStack(alignment: .top, spacing: 10) {
                        Rectangle()
                            .fill(Color(hex: 0xF59E0B))
                            .frame(width: 3)
                            .clipShape(Capsule())

                        Text("“\(sampleAnswer.text)”")
                            .font(.display(15, .regular))
                            .foregroundStyle(Color.qInk)
                            .lineSpacing(3)
                            .lineLimit(3)
                    }

                    // Button to open memory details
                    Button {
                        openedMemory = sampleAnswer
                    } label: {
                        HStack(spacing: 5) {
                            Text("Read full reflection")
                                .font(.ui(12.5, .semibold))
                            Icon(.arrowRightBold, size: 10)
                        }
                        .foregroundStyle(Color.qInk)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.qField)
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

// MARK: - Reflection Rhythm & Time-of-Day Habit Card (Clean, Restrained, No Emojis)

struct ReflectionRhythmCard: View {
    @Environment(AppStore.self) private var store

    struct Slot: Identifiable {
        let id: String
        let title: String
        let hours: String
        let systemIcon: String
        let percentage: Int
        let isPeak: Bool
        let colors: [Color]
    }

    private var slots: [Slot] {
        let answers = store.myAnswers
        let cal = Calendar.current
        var morning = 0, afternoon = 0, evening = 0, night = 0

        for a in answers {
            let h = cal.component(.hour, from: a.createdAt)
            switch h {
            case 6..<12: morning += 1
            case 12..<18: afternoon += 1
            case 18..<23: evening += 1
            default: night += 1
            }
        }

        let total = morning + afternoon + evening + night
        let mPct = total > 0 ? Int(round(Double(morning) / Double(total) * 100)) : 54
        let aPct = total > 0 ? Int(round(Double(afternoon) / Double(total) * 100)) : 24
        let ePct = total > 0 ? Int(round(Double(evening) / Double(total) * 100)) : 17
        let nPct = total > 0 ? max(0, 100 - (mPct + aPct + ePct)) : 5

        let maxVal = max(mPct, aPct, ePct, nPct)

        return [
            Slot(
                id: "morning",
                title: "Morning",
                hours: "06–12h",
                systemIcon: "sunrise.fill",
                percentage: mPct,
                isPeak: mPct == maxVal,
                colors: [Color(hex: 0xF59E0B)]
            ),
            Slot(
                id: "afternoon",
                title: "Afternoon",
                hours: "12–18h",
                systemIcon: "sun.max.fill",
                percentage: aPct,
                isPeak: aPct == maxVal && aPct > mPct,
                colors: [Color.qGreen]
            ),
            Slot(
                id: "evening",
                title: "Evening",
                hours: "18–23h",
                systemIcon: "sunset.fill",
                percentage: ePct,
                isPeak: ePct == maxVal && ePct > mPct,
                colors: [Color.qPink]
            ),
            Slot(
                id: "night",
                title: "Night",
                hours: "23–06h",
                systemIcon: "moon.stars.fill",
                percentage: nPct,
                isPeak: nPct == maxVal && nPct > mPct,
                colors: [Color(hex: 0x6366F1)]
            )
        ]
    }

    private var peakSlot: Slot {
        slots.first(where: \.isPeak) ?? slots[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                IconChip(icon: .clock, tint: .qGreen, fill: Color.qMint.opacity(0.35))

                VStack(alignment: .leading, spacing: 1) {
                    Text("REFLECTION RHYTHM")
                        .font(.ui(11, .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.qBrandText)
                    Text("Daily peak & habit pace")
                        .font(.ui(13.5, .medium))
                        .foregroundStyle(Color.qGray)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Details")
                        .font(.ui(12, .semibold))
                        .foregroundStyle(Color.qGreen)
                    Icon(.caretRightBold, size: 10)
                        .foregroundStyle(Color.qGreen)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Capsule().fill(Color.qMint.opacity(0.28)))
            }

            // Hero Peak Time + Subtitle
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Most active at")
                        .font(.ui(12))
                        .foregroundStyle(Color.qGray)
                    Text("8:45 AM")
                        .font(.ui(22, .semibold))
                        .foregroundStyle(Color.qInk)
                        .monospacedDigit()
                }

                Spacer()

                // Proportional Distribution Bars (Clean, Restrained)
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(slots) { slot in
                        barColumn(slot)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.qField)
            )

            // Micro-metrics Footer (Clean 3-column stats)
            HStack(spacing: 0) {
                metricColumn(
                    value: "\(peakSlot.percentage)%",
                    title: "\(peakSlot.title) peak",
                    subtitle: peakSlot.hours
                )

                Rectangle().fill(Color.qLine).frame(width: 1, height: 26)

                metricColumn(
                    value: "94%",
                    title: "Consistency",
                    subtitle: "on-time rhythm"
                )

                Rectangle().fill(Color.qLine).frame(width: 1, height: 26)

                metricColumn(
                    value: "\(store.totalQuestionsAnswered)",
                    title: "Total reflections",
                    subtitle: "answered so far"
                )
            }
            .padding(.top, 2)
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

    private func barColumn(_ slot: Slot) -> some View {
        let barMaxHeight: CGFloat = 50
        let maxPct = CGFloat(max(slots.map(\.percentage).max() ?? 100, 1))
        let normalized = CGFloat(slot.percentage) / maxPct
        let barHeight = slot.percentage == 0 ? 6 : max(10, barMaxHeight * (0.2 + 0.75 * normalized))

        return VStack(spacing: 4) {
            Text("\(slot.percentage)%")
                .font(.ui(10, slot.isPeak ? .bold : .medium))
                .foregroundStyle(slot.isPeak ? Color.qGreenDeep : Color.qGray)
                .monospacedDigit()

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.qLine.opacity(0.65))
                    .frame(width: 24, height: barMaxHeight)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(slot.colors[0])
                    .opacity(slot.isPeak ? 1.0 : 0.65)
                    .frame(width: 24, height: barHeight)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Image(systemName: slot.systemIcon)
                .font(.system(size: 11, weight: slot.isPeak ? .semibold : .regular))
                .foregroundStyle(slot.isPeak ? slot.colors[0] : Color.qGray)
                .padding(.top, 1)
        }
    }

    private func metricColumn(value: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.ui(15, .semibold))
                .foregroundStyle(Color.qInk)
                .monospacedDigit()
            Text(title)
                .font(.ui(11.5, .medium))
                .foregroundStyle(Color.qInk2)
            Text(subtitle)
                .font(.ui(10))
                .foregroundStyle(Color.qGray)
        }
        .frame(maxWidth: .infinity)
    }
}

typealias ReflectionStatsCard = ReflectionRhythmCard
