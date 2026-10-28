import SwiftUI
import UIKit

/// Six word stickers in a row, no labels (SAME, AWW, LIKE, DEEP, COOL, HUGS). Your current one
/// sits on a gray disc; tapping it again removes it.
struct ReactionPopover: View {
    static let height: CGFloat = 56
    let selected: ReactionKind?
    let onPick: (ReactionKind) -> Void
    @State private var shown = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(ReactionKind.allCases.enumerated()), id: \.element) { index, kind in
                Button { onPick(kind) } label: {
                    ReactionSticker(kind: kind, size: 42)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Circle().fill(selected == kind ? Color.qField : .clear).frame(width: 48, height: 48))
                        .scaleEffect(shown ? 1 : 0.3)
                        .offset(y: shown ? 0 : 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.55).delay(Double(index) * 0.03), value: shown)
                }
                .buttonStyle(PressableStyle(scale: 1.2))
                .accessibilityLabel(kind.label)
                .accessibilityHint(kind.meaning)
                .accessibilityAddTraits(selected == kind ? .isSelected : [])
            }
        }
        .padding(.vertical, DS.Space.xxs)
        .padding(.horizontal, DS.Space.s)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.qBackground)
                .shadow(color: .black.opacity(0.16), radius: 12, y: 8)
        )
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .onAppear { shown = true }
    }
}

/// Author-only: who reacted and with which sticker. Friends first, filterable by sticker.
struct ReactionsSheet: View {
    @Environment(AppStore.self) private var store
    let answer: Answer
    @State private var filter: ReactionKind?

    var body: some View {
        let all = store.reactors(for: answer).sorted { a, b in
            store.isFollowing(a.user.id) && !store.isFollowing(b.user.id)
        }
        let shown = filter.map { f in all.filter { $0.kind == f } } ?? all
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Reactions")
                        .font(.display(20, .semibold))
                        .tracking(-0.2)
                        .foregroundStyle(Color.qInk)
                    Spacer()
                    HStack(spacing: DS.Space.xxs) {
                        Icon(.lockSimpleFill, size: 14)
                        Text("Only you can see this")
                    }
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.l)

                WrappingHStack(spacing: DS.Space.xs, lineSpacing: DS.Space.xs, centered: false) {
                    allChip(count: answer.totalReactions)
                    ForEach(answer.topReactions) { kind in stickerChip(kind) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, DS.Space.m)
                Rectangle().fill(Color.qLine).frame(height: 0.5)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(shown) { item in
                            NavigationLink(value: Route.profile(item.user.id)) { row(item) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, DS.Space.xs)
                    .animation(.qSmooth, value: filter)
                }
            }
            .background(Color.qBackground)
            .toolbar(.hidden, for: .navigationBar)
            .withQueslyRoutes()
        }
    }

    private func row(_ item: AppStore.Reactor) -> some View {
        HStack(spacing: DS.Space.s) {
            FollowableAvatar(user: item.user, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.user.username).font(.ui(15, .semibold)).foregroundStyle(Color.qInk)
                if let name = item.user.name, !name.isEmpty {
                    Text(name).font(.ui(13)).foregroundStyle(Color.qGray)
                }
            }
            .lineLimit(1)
            Spacer(minLength: DS.Space.s)
            ReactionSticker(kind: item.kind, size: 40)
        }
        .padding(.horizontal, DS.Space.screen)
        .frame(height: 60)
        .contentShape(Rectangle())
    }

    private func allChip(count: Int) -> some View {
        let on = filter == nil
        return Button { withAnimation(.qSpring) { filter = nil } } label: {
            (Text("All ").foregroundStyle(on ? Color.white : Color.qInk)
                + Text("\(count)").foregroundStyle(on ? Color.white.opacity(0.7) : Color.qGray))
                .font(.ui(14, .semibold))
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(Capsule().fill(on ? Color.qInk : Color.qField))
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func stickerChip(_ kind: ReactionKind) -> some View {
        let on = filter == kind
        return Button { withAnimation(.qSpring) { filter = kind } } label: {
            HStack(spacing: 6) {
                ReactionSticker(kind: kind, size: 30)
                Text("\(answer.count(kind))")
                    .font(.ui(14, .medium))
                    .foregroundStyle(on ? Color.white.opacity(0.85) : Color.qGray)
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(Capsule().fill(on ? Color.qInk : Color.qField))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(kind.label), \(answer.count(kind))")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// Big sticker that pops in the middle of an answer on double-tap.
struct DoubleTapPop: View {
    let kind: ReactionKind
    let trigger: Int
    @State private var phase: CGFloat = 0

    var body: some View {
        ReactionSticker(kind: kind, size: 96)
            .scaleEffect(phase == 0 ? 0.2 : (phase == 1 ? 1.15 : 1.4))
            .opacity(phase == 1 ? 1 : 0)
            .rotationEffect(.degrees(phase == 1 ? -8 : 0))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
            .allowsHitTesting(false)
            .onChange(of: trigger) { _, _ in
                phase = 0
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { phase = 1 }
                withAnimation(.easeIn(duration: 0.25).delay(0.6)) { phase = 2 }
            }
    }
}

/// Lime / white / green confetti, used after submitting an answer.
struct ConfettiView: View {
    var count = 60
    @State private var fire = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    ConfettiPiece(index: i, size: geo.size, fire: fire)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { fire = true }
    }
}

private struct ConfettiPiece: View {
    let index: Int
    let size: CGSize
    let fire: Bool

    private var seed: Double { Double((index * 7919) % 1000) / 1000 }
    private var seed2: Double { Double((index * 104_729) % 1000) / 1000 }

    var body: some View {
        let colors: [Color] = [.qLime, .white, .qGreenLight, Color(hex: 0xFFD84D)]
        RoundedRectangle(cornerRadius: index.isMultiple(of: 3) ? 4 : 1.5)
            .fill(colors[index % colors.count])
            .frame(width: index.isMultiple(of: 3) ? 8 : 6, height: index.isMultiple(of: 3) ? 8 : 12)
            .rotationEffect(.degrees(fire ? 360 * (seed * 3 - 1.5) : 0))
            .rotation3DEffect(.degrees(fire ? 540 * seed2 : 0), axis: (x: 1, y: 0, z: 0))
            .position(
                x: size.width / 2 + (fire ? CGFloat(seed - 0.5) * size.width * 1.2 : 0),
                y: size.height * 0.45 + (fire ? CGFloat(seed2) * size.height * 0.75 - size.height * 0.2 : 0)
            )
            .opacity(fire ? 0 : 1)
            .animation(.easeOut(duration: 1.4 + seed * 0.6).delay(seed2 * 0.1), value: fire)
    }
}

/// A word sticker (speech bubble with a white rim, art 50 × 36). `size` is the width.
struct ReactionSticker: View {
    let kind: ReactionKind
    var size: CGFloat = 34

    var body: some View {
        Image(kind.assetName)
            .resizable()
            .aspectRatio(50.0 / 36.0, contentMode: .fit)
            .frame(width: size, height: size * 0.72)
            .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
            .accessibilityLabel(kind.label)
    }
}
