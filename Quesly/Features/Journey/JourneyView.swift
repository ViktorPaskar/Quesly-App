import SwiftUI

/// 3rd Bottom Tab: Journey ("Путь").
/// Dedicated hub for daily habits, streak, memories, and personal milestones.
/// - Streak Hero Card (7-day circles tracker, personal best — without streak freezes)
/// - "On This Day" Memory Card (flashback to previous answers)
/// - Quiet Milestones & Achievements (progress bars, unlocked badges)
/// - Strictly without Reflection Topics stats (which live in the Profile Calendar)
struct JourneyView: View {
    @Environment(AppStore.self) private var store
    @State private var openedMemory: Answer?

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Space.m) {
                // MARK: 1. Streak Hero Card (No freezes)
                StreakCard()

                // MARK: 2. "On This Day" Memory Flashback
                onThisDayCard

                // MARK: 3. Milestones & Achievements Hub
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
                .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
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
                    .shadow(color: Color.qGreen.opacity(0.18), radius: 12, y: 4)
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
                .shadow(color: Color.black.opacity(0.03), radius: 8, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }
}
