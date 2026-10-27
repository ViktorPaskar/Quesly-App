import SwiftUI

struct AchievementsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let items = store.achievements

        ScrollView {
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
                            .font(.display(18, .bold))
                            .foregroundStyle(.white)
                        Text("Earned naturally through honest daily reflection and real conversations — never a race.")
                            .font(.ui(13))
                            .foregroundStyle(.white.opacity(0.84))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                        .fill(Color.qGreen)
                )
                .padding(.horizontal, DS.Space.m)
                .padding(.top, 8)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Rectangle()
                                .fill(Color.qLine)
                                .frame(height: 1)
                                .padding(.leading, 82)
                        }
                        row(item)
                            .padding(.horizontal, DS.Space.m)
                            .padding(.vertical, 14)
                            .staggeredAppear(index)
                    }
                }
                .outlinedBlock()
                .padding(.horizontal, DS.Space.m)
            }
            .padding(.bottom, 24)
        }
        .background(Color.qCanvas)
        .queslyBackHeader("Milestones")
    }

    private func row(_ item: Achievement) -> some View {
        HStack(spacing: 16) {
            HexBadge(asset: item.badgeAsset, isLocked: !item.isUnlocked)
                .frame(width: 50, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.ui(17, .semibold))
                    .foregroundStyle(Color.qInk)
                Text(item.subtitle)
                    .font(.ui(15))
                    .foregroundStyle(Color.qGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
