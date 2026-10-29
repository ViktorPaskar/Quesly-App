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

                // MARK: 2. Personal Reflection Stats & Topics
                ReflectionStatsCard()

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

// MARK: - Reflection Stats & Topics Card

struct ReflectionStatsCard: View {
    @Environment(AppStore.self) private var store

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

                Text("REFLECTION STATS")
                    .font(.ui(11, .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Color.qBrandText)

                Spacer()
            }

            // 3 Metric Cards Row
            HStack(spacing: 10) {
                metricCard(
                    value: "\(store.totalQuestionsAnswered)",
                    label: "Answered",
                    icon: .chatCircleTextFill,
                    tint: Color.qGreen,
                    bg: Color(hex: 0xEDF8F3),
                    valColor: Color.qGreenDeep
                )
                metricCard(
                    value: "\(store.uniqueActiveDays)",
                    label: "Active days",
                    icon: .fireFill,
                    tint: Color.qFlame,
                    bg: Color(hex: 0xFFF3EB),
                    valColor: Color(hex: 0xB34700)
                )
                metricCard(
                    value: "\(store.totalSavedCount)",
                    label: "Saved",
                    icon: .bookmarkSimpleFill,
                    tint: Color(hex: 0x4285F4),
                    bg: Color(hex: 0xEBF3FF),
                    valColor: Color(hex: 0x1A56B3)
                )
            }

            Rectangle().fill(Color.qLine.opacity(0.8)).frame(height: 1)

            // Top reflection themes
            VStack(alignment: .leading, spacing: 10) {
                Text("TOP REFLECTION TOPICS")
                    .font(.ui(11, .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.qInk2)

                // Segmented proportion bar with rounded capsules
                GeometryReader { geo in
                    HStack(spacing: 4) {
                        Capsule()
                            .fill(LinearGradient(colors: [Color.qGreen, Color.qGreenDeep], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, geo.size.width * 0.45))
                        Capsule()
                            .fill(LinearGradient(colors: [Color.qLime, Color(hex: 0xB8E600)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, geo.size.width * 0.30))
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: 0x4285F4), Color(hex: 0x6BA4F8)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, geo.size.width * 0.25 - 8))
                    }
                }
                .frame(height: 10)

                // Interactive topic chips
                HStack(spacing: 8) {
                    topicChip(color: Color.qGreen, bg: Color(hex: 0xEDF8F3), text: "Stories", percent: "45%")
                    topicChip(color: Color(hex: 0x7CA600), bg: Color.qLime.opacity(0.22), text: "Wisdom", percent: "30%")
                    topicChip(color: Color(hex: 0x4285F4), bg: Color(hex: 0xEBF3FF), text: "Daily", percent: "25%")
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
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

    private func metricCard(value: String, label: String, icon: QIcon, tint: Color, bg: Color, valColor: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(Color.white).frame(width: 28, height: 28)
                Icon(icon, size: 14)
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(.ui(22, .semibold))
                .foregroundStyle(valColor)
                .monospacedDigit()
            Text(label)
                .font(.ui(11, .semibold))
                .foregroundStyle(tint)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(bg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(tint.opacity(0.20), lineWidth: 1)
                )
        )
    }

    private func topicChip(color: Color, bg: Color, text: String, percent: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.ui(12, .semibold))
                .foregroundStyle(Color.qInk)
            Text(percent)
                .font(.ui(11, .medium))
                .foregroundStyle(Color.qGray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(bg))
        .overlay(Capsule().stroke(color.opacity(0.20), lineWidth: 0.8))
    }
}
