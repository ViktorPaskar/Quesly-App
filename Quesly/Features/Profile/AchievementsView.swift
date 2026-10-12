import SwiftUI

struct AchievementsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        List(store.achievements) { item in
            HStack(spacing: 14) {
                HexBadge(color: item.color, symbol: item.symbol, isLocked: item.progress == 0 && !item.isUnlocked)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).font(.quesly(14, .medium)).foregroundStyle(Color.qInk)
                    Text(item.subtitle).font(.quesly(10)).foregroundStyle(Color.qGray)
                    if !item.isUnlocked && !item.isSpecial {
                        HStack(spacing: 12) {
                            ProgressView(value: Double(item.progress), total: Double(item.goal))
                                .tint(Color.qGreen)
                            Text("\(item.progress) / \(item.goal)")
                                .font(.quesly(10, .medium))
                                .foregroundStyle(Color.qInk)
                                .monospacedDigit()
                        }
                        .padding(.top, 4)
                    }
                }
                Spacer(minLength: 0)
                if item.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.qGreen)
                        .accessibilityLabel("Unlocked")
                }
            }
            .padding(.vertical, 6)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .queslyBackHeader("Achievements")
    }
}
