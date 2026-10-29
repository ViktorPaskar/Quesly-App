import SwiftUI

/// 3rd Bottom Tab: Journey ("Путь").
/// Dedicated hub for daily habits, streak, reflection stats, memories, and personal milestones.
/// - Streak Hero Card (7-day circles tracker, personal best — without streak freezes)
/// - Reflection Stats & Topics Card (Answered, Active Days, Saved + Proportion Topics)
/// - "On This Day" Memory Card (flashback to previous answers)
/// - Quiet Milestones & Achievements (progress bars, unlocked badges)
struct JourneyView: View {
    @Environment(AppStore.self) private var store
    @State private var openedMemory: Answer?

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Space.m) {
                // MARK: 1. Streak Hero Card (7-Day Tracker)
                StreakCard()

                // MARK: 2. Personal Reflection Rhythm & Habit Dashboard
                ReflectionRhythmCard()

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
    }

    // MARK: - On This Day Flashback Card

    private var onThisDayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xEDF8F3))
                        .frame(width: 32, height: 32)
                    Icon(.sparkleFill, size: 14)
                        .foregroundStyle(Color.qGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("ON THIS DAY")
                        .font(.ui(11, .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.qBrandText)
                    Text("1 year ago")
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Color.qInk)
                }

                Spacer()

                Text(Date.now.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.ui(12, .medium))
                    .foregroundStyle(Color.qGray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.qField))
            }

            // Memory Quote
            let sampleAnswer = store.myAnswers.first ?? MockData.myHistory().first ?? Answer(
                id: "sample",
                questionId: "q-kindness",
                questionText: "What is a small kindness you never forgot?",
                authorId: store.me.id,
                text: "A stranger held the train door for me when I was running late with heavy bags.",
                createdAt: .now
            )
            VStack(alignment: .leading, spacing: 8) {
                Text(sampleAnswer.questionText)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk2)
                    .lineLimit(2)

                Text("“\(sampleAnswer.text)”")
                    .font(.display(16, .regular))
                    .foregroundStyle(Color.qInk)
                    .lineSpacing(3)
                    .lineLimit(4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.qField)
            )

            // Button to open memory details
            Button {
                openedMemory = sampleAnswer
            } label: {
                HStack(spacing: 6) {
                    Text("Read full reflection")
                        .font(.ui(13, .semibold))
                    Icon(.arrowRightBold, size: 11)
                }
                .foregroundStyle(Color.qGreen)
            }
            .buttonStyle(.plain)
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

    // MARK: - Milestones Section

    private var milestonesSection: some View {
        let items = store.achievements
        let inProgress = items.filter { !$0.isUnlocked && $0.progress > 0 }
        let unlocked = items.filter { $0.isUnlocked }
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

                    VStack(spacing: 8) {
                        ForEach(inProgress) { ach in
                            MilestoneRow(achievement: ach)
                        }
                    }
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

                    VStack(spacing: 8) {
                        ForEach(unlocked) { ach in
                            MilestoneRow(achievement: ach)
                        }
                    }
                }
            }
        }
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
                        .background(Capsule().fill(Color(hex: 0xEDF8F3)))
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
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.qBlock)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }
}

// MARK: - Reflection Rhythm & Time-of-Day Habit Dashboard

struct ReflectionRhythmCard: View {
    @Environment(AppStore.self) private var store

    struct Slot: Identifiable {
        let id: String
        let title: String
        let hours: String
        let icon: String
        let percentage: Int
        let isPeak: Bool
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
            Slot(id: "morning", title: "Morning", hours: "06–12h", icon: "🌅", percentage: mPct, isPeak: mPct == maxVal),
            Slot(id: "afternoon", title: "Midday", hours: "12–18h", icon: "☀️", percentage: aPct, isPeak: aPct == maxVal && aPct > mPct),
            Slot(id: "evening", title: "Evening", hours: "18–23h", icon: "🌆", percentage: ePct, isPeak: ePct == maxVal && ePct > mPct),
            Slot(id: "night", title: "Night", hours: "23–06h", icon: "🌙", percentage: nPct, isPeak: nPct == maxVal && nPct > mPct)
        ]
    }

    private var peakSlot: Slot {
        slots.first(where: \.isPeak) ?? slots[0]
    }

    private var archetypeInfo: (title: String, insight: String, time: String) {
        switch peakSlot.id {
        case "afternoon":
            return ("Midday Pause", "You reflect best during your afternoon break.", "1:40 PM")
        case "evening":
            return ("Dusk Philosopher", "Evenings are when your reflections run deepest.", "8:15 PM")
        case "night":
            return ("Night Owl", "Quiet midnight hours bring your most candid thoughts.", "11:30 PM")
        default:
            return ("Early Thinker", "Your thoughts are clearest with your morning coffee.", "8:45 AM")
        }
    }

    private var avgWordCount: Int {
        let answers = store.myAnswers
        guard !answers.isEmpty else { return 42 }
        let totalWords = answers.reduce(0) { $0 + $1.text.split(whereSeparator: \.isWhitespace).count }
        return max(18, totalWords / answers.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xEDF8F3))
                        .frame(width: 30, height: 30)
                    Icon(.chartBarFill, size: 14)
                        .foregroundStyle(Color.qGreen)
                }

                Text("REFLECTION RHYTHM")
                    .font(.ui(11, .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Color.qBrandText)

                Spacer()

                // Archetype Pill
                HStack(spacing: 4) {
                    Text(peakSlot.icon)
                        .font(.system(size: 11))
                    Text(archetypeInfo.title)
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Color.qGreenDeep)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(
                    Capsule()
                        .fill(Color.qLime.opacity(0.30))
                )
            }

            // Hero insight
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Peak time:")
                        .font(.ui(13.5, .medium))
                        .foregroundStyle(Color.qGray)
                    Text(archetypeInfo.time)
                        .font(.ui(22, .semibold))
                        .foregroundStyle(Color.qInk)
                        .monospacedDigit()
                }

                Text(archetypeInfo.insight)
                    .font(.ui(13.5))
                    .foregroundStyle(Color.qInk2)
                    .lineLimit(2)
            }

            // Time-of-day Distribution Chart
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(slots) { slot in
                        barColumn(slot)
                    }
                }
                .frame(height: 100)
                .padding(.horizontal, 8)
                .padding(.top, 6)
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.qField.opacity(0.7))
            )

            // Micro-metrics Footer
            HStack(spacing: 0) {
                metricColumn(
                    value: "94%",
                    title: "Consistency",
                    subtitle: "on-time rhythm"
                )

                Rectangle().fill(Color.qLine).frame(width: 1, height: 28)

                metricColumn(
                    value: "\(avgWordCount) w",
                    title: "Avg. Depth",
                    subtitle: "words per answer"
                )

                Rectangle().fill(Color.qLine).frame(width: 1, height: 28)

                metricColumn(
                    value: "\(store.totalQuestionsAnswered)",
                    title: "Answered",
                    subtitle: "total reflections"
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
        let barMaxHeight: CGFloat = 58
        let barHeight = max(8, barMaxHeight * CGFloat(slot.percentage) / 100.0)

        return VStack(spacing: 5) {
            // Percentage label
            Text("\(slot.percentage)%")
                .font(.ui(11, slot.isPeak ? .bold : .medium))
                .foregroundStyle(slot.isPeak ? Color.qGreenDeep : Color.qGray)
                .monospacedDigit()

            // Vertical capsule bar
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.qLine.opacity(0.6))
                    .frame(width: 32, height: barMaxHeight)

                Capsule()
                    .fill(
                        slot.isPeak
                            ? LinearGradient(colors: [Color.qGreen, Color.qGreenDeep], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.qGray4, Color.qGray4], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 32, height: barHeight)
            }

            // Slot icon & hours
            HStack(spacing: 2) {
                Text(slot.icon)
                    .font(.system(size: 10))
                Text(slot.hours)
                    .font(.ui(10.5, slot.isPeak ? .semibold : .medium))
                    .foregroundStyle(slot.isPeak ? Color.qInk : Color.qGray)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }

    private func metricColumn(value: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.ui(16, .semibold))
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
