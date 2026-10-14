import SwiftUI

struct AchievementsView: View {
    @Environment(AppStore.self) private var store
    @State private var animateBars = false

    var body: some View {
        let items = store.achievements
        let unlocked = items.filter(\.isUnlocked).count

        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: animateBars ? CGFloat(unlocked) / CGFloat(items.count) : 0)
                            .stroke(Color.qLime, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(unlocked)/\(items.count)")
                            .font(.ui(18, .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your badges").font(.ui(20, .bold)).foregroundStyle(.white)
                        Text("Answer daily, react kindly and invite friends to collect them all.")
                            .font(.ui(14)).foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qGreen))
                .padding(16)

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    row(item)
                        .padding(.horizontal, DS.Space.screen)
                        .padding(.vertical, 12)
                        .staggeredAppear(index)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color.qBackground)
        .queslyBackHeader("Achievements")
        .onAppear { withAnimation(.easeOut(duration: 1).delay(0.2)) { animateBars = true } }
    }

    private func row(_ item: Achievement) -> some View {
        HStack(spacing: 16) {
            HexBadge(color: item.color, icon: item.icon, isLocked: item.progress == 0 && !item.isUnlocked)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.ui(17, .semibold)).foregroundStyle(Color.qInk)
                Text(item.subtitle).font(.ui(14)).foregroundStyle(Color.qGray)
                if !item.isUnlocked && !item.isSpecial {
                    HStack(spacing: 12) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.qLine)
                                Capsule().fill(item.color)
                                    .frame(width: animateBars ? geo.size.width * CGFloat(item.progress) / CGFloat(item.goal) : 0)
                            }
                        }
                        .frame(height: 6)
                        Text("\(item.progress)/\(item.goal)")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Color.qInk)
                            .monospacedDigit()
                    }
                    .padding(.top, 8)
                }
            }
            Spacer(minLength: 0)
            if item.isUnlocked {
                Icon(.sealCheckFill, size: 26)
                    .foregroundStyle(Color.qBrandText)
                    .pop(on: animateBars)
                    .accessibilityLabel("Unlocked")
            }
        }
    }
}
