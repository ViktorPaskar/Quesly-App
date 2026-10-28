import SwiftUI

struct AchievementsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let items = store.achievements
        let inProgress = items.filter { !$0.isUnlocked && $0.progress > 0 }
        let unlocked = items.filter { $0.isUnlocked }
        let locked = items.filter { !$0.isUnlocked && $0.progress == 0 }
        let totalUnlocked = unlocked.count
        let totalCount = items.count

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header Banner with overall progress
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.qLime)
                                .frame(width: 44, height: 44)
                            QueslyMark(color: .qGreen, cutout: .qLime)
                                .frame(width: 24)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Quiet milestones")
                                .font(.display(20, .semibold))
                                .foregroundStyle(.white)
                            Text("Earned through honest daily reflection — never a race.")
                                .font(.ui(13))
                                .foregroundStyle(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Progress scale in header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(totalUnlocked) of \(totalCount) unlocked")
                                .font(.ui(13, .semibold))
                                .foregroundStyle(Color.qLime)
                            Spacer()
                            Text("\(Int(Double(totalUnlocked) / Double(totalCount) * 100))%")
                                .font(.ui(13, .semibold))
                                .foregroundStyle(Color.white.opacity(0.90))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.20))
                                Capsule().fill(Color.qLime)
                                    .frame(width: max(4, geo.size.width * CGFloat(totalUnlocked) / CGFloat(totalCount)))
                            }
                        }
                        .frame(height: 6)
                    }
                    .padding(.top, 2)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                        .fill(Color.qGreen)
                )
                .padding(.horizontal, DS.Space.m)
                .padding(.top, 8)

                // Section 1: In Progress
                if !inProgress.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("In progress (\(inProgress.count))")
                            .padding(.horizontal, DS.Space.m)

                        VStack(spacing: 0) {
                            ForEach(inProgress) { item in
                                if item.id != inProgress.first?.id { divider }
                                achievementRow(item)
                                    .padding(.horizontal, DS.Space.m)
                                    .padding(.vertical, 14)
                            }
                        }
                        .outlinedBlock()
                        .padding(.horizontal, DS.Space.m)
                    }
                }

                // Section 2: Unlocked
                if !unlocked.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Unlocked (\(unlocked.count))")
                            .padding(.horizontal, DS.Space.m)

                        VStack(spacing: 0) {
                            ForEach(unlocked) { item in
                                if item.id != unlocked.first?.id { divider }
                                achievementRow(item)
                                    .padding(.horizontal, DS.Space.m)
                                    .padding(.vertical, 14)
                            }
                        }
                        .outlinedBlock()
                        .padding(.horizontal, DS.Space.m)
                    }
                }

                // Section 3: Locked
                if !locked.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Locked (\(locked.count))")
                            .padding(.horizontal, DS.Space.m)

                        VStack(spacing: 0) {
                            ForEach(locked) { item in
                                if item.id != locked.first?.id { divider }
                                achievementRow(item)
                                    .padding(.horizontal, DS.Space.m)
                                    .padding(.vertical, 14)
                            }
                        }
                        .outlinedBlock()
                        .padding(.horizontal, DS.Space.m)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color.qCanvas)
        .queslyBackHeader("Milestones")
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.qLine)
            .frame(height: 1)
            .padding(.leading, 82)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.ui(12, .semibold))
            .tracking(0.8)
            .foregroundStyle(Color.qGray)
    }

    private func achievementRow(_ item: Achievement) -> some View {
        HStack(alignment: .top, spacing: 16) {
            HexBadge(asset: item.badgeAsset, isLocked: !item.isUnlocked)
                .frame(width: 50, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.title)
                        .font(.ui(16, .semibold))
                        .foregroundStyle(item.isUnlocked ? Color.qInk : Color.qInk2)
                    if item.isUnlocked {
                        HStack(spacing: 3) {
                            Icon(.checkBold, size: 9)
                            Text("Done")
                                .font(.ui(11, .semibold))
                        }
                        .foregroundStyle(Color.qGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.qGreen.opacity(0.12)))
                    } else {
                        Icon(.lockSimpleFill, size: 12)
                            .foregroundStyle(Color.qGray)
                    }
                }

                Text(item.subtitle)
                    .font(.ui(14))
                    .foregroundStyle(Color.qGray)
                    .fixedSize(horizontal: false, vertical: true)

                // Progress Bar for items with goals
                if !item.isSpecial && item.goal > 1 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(item.progress) of \(item.goal)")
                                .font(.ui(12, .semibold))
                                .foregroundStyle(item.isUnlocked ? Color.qGreen : Color.qBrandText)
                            Spacer()
                            Text("\(Int(Double(item.progress) / Double(max(1, item.goal)) * 100))%")
                                .font(.ui(12, .medium))
                                .foregroundStyle(Color.qGray)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.qLine)
                                Capsule()
                                    .fill(item.isUnlocked ? Color.qGreen : Color.qGreen.opacity(0.85))
                                    .frame(width: max(3, geo.size.width * CGFloat(item.progress) / CGFloat(max(1, item.goal))))
                            }
                        }
                        .frame(height: 5)
                    }
                    .padding(.top, 4)
                }
            }
            Spacer(minLength: 0)
        }
    }
}
