import SwiftUI
import UIKit

/// The viewer's reaction control: one button that opens a tray of six positive reactions.
struct ReactionControl: View {
    let answer: Answer
    @Binding var isTrayOpen: Bool
    let onPick: (ReactionKind) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var burst: ReactionKind?
    @State private var burstTrigger = 0

    var body: some View {
        ZStack(alignment: .leading) {
            if isTrayOpen {
                tray.transition(.asymmetric(
                    insertion: .scale(scale: 0.4, anchor: .leading).combined(with: .opacity),
                    removal: .scale(scale: 0.6, anchor: .leading).combined(with: .opacity)))
            } else {
                trigger.transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let burst, !reduceMotion {
                EmojiBurst(kind: burst, trigger: burstTrigger)
                    .offset(x: 6, y: -14)
                    .allowsHitTesting(false)
            }
        }
        .animation(.qSpring, value: isTrayOpen)
    }

    /// Tap = ❤️ (or remove your current reaction). Long-press = choose from all six.
    private var trigger: some View {
        Group {
            if let mine = answer.myReaction {
                ReactionSticker(kind: mine, size: 26)
                    .id(mine)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            } else {
                Icon(.heart, size: 22).foregroundStyle(Color.qGray)
            }
        }
        .frame(minWidth: 32, minHeight: DS.hitTarget)
        .contentShape(Rectangle())
        .onTapGesture { quickReact() }
        .onLongPressGesture(minimumDuration: 0.3) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            isTrayOpen = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(answer.myReaction.map { "Your reaction: \($0.label)" } ?? "Love")
        .accessibilityHint("Hold for more reactions")
        .accessibilityAction { quickReact() }
        .accessibilityAction(named: "Choose reaction") { isTrayOpen = true }
    }

    private func quickReact() {
        let kind = answer.myReaction ?? .love
        if answer.myReaction == nil { fireBurst(kind) }
        onPick(kind)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func fireBurst(_ kind: ReactionKind) {
        burst = kind
        burstTrigger += 1
    }

    private var tray: some View {
        HStack(spacing: 2) {
            ForEach(Array(ReactionKind.allCases.enumerated()), id: \.element) { index, kind in
                TrayEmoji(kind: kind, index: index, isSelected: answer.myReaction == kind) {
                    if answer.myReaction != kind { fireBurst(kind) }
                    onPick(kind)
                    isTrayOpen = false
                }
            }
            Button { isTrayOpen = false } label: {
                Icon(.xBold, size: 14)
                    .foregroundStyle(Color.qGray)
                    .frame(width: 32, height: 44)
            }
            .accessibilityLabel("Close reactions")
        }
        .padding(.leading, 8)
        .padding(.trailing, 2)
        .background(
            Capsule().fill(Color.qSurface)
                .shadow(color: .black.opacity(0.1), radius: 10, y: 3)
        )
        .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
    }
}

private struct TrayEmoji: View {
    let kind: ReactionKind
    let index: Int
    let isSelected: Bool
    let action: () -> Void
    @State private var shown = false

    var body: some View {
        Button(action: action) {
            ReactionSticker(kind: kind, size: kind == .same ? 34 : 32)
                .frame(minWidth: 38, minHeight: 46)
                .padding(.horizontal, kind == .same ? 4 : 0)
                .background(Capsule().fill(isSelected ? Color.qMint : .clear))
                .scaleEffect(shown ? 1 : 0.3)
                .offset(y: shown ? 0 : 10)
        }
        .buttonStyle(PressableStyle(scale: 1.25))
        .sensoryFeedback(.impact(weight: .medium), trigger: isSelected)
        .accessibilityLabel(kind.label)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(Double(index) * 0.04)) { shown = true }
        }
    }
}

/// Author-only list of who reacted, filterable by emoji (Instagram-style).
struct ReactionsSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let answer: Answer
    @State private var filter: ReactionKind?

    var body: some View {
        let all = store.reactors(for: answer)
        let shown = filter.map { f in all.filter { $0.kind == f } } ?? all
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Space.xs) {
                        chip(title: "All \(all.count)", isOn: filter == nil) { filter = nil }
                        ForEach(answer.topReactions) { kind in
                            chip(title: "\(answer.count(kind))", kind: kind, isOn: filter == kind) { filter = kind }
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.vertical, DS.Space.s)
                }
                Divider()
                List(shown) { item in
                    NavigationLink(value: Route.profile(item.user.id)) {
                        HStack(spacing: DS.Space.s) {
                            Avatar(user: item.user, size: 40)
                            Text(item.user.username).font(.ui(15, .semibold)).foregroundStyle(Color.qInk)
                            Spacer()
                            ReactionSticker(kind: item.kind, size: 30)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .animation(.qSmooth, value: filter)
                IconLabel("Only you can see who reacted", icon: .lockSimpleFill, size: 13)
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
                    .padding(.vertical, DS.Space.s)
            }
            .navigationTitle("Reactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .withQueslyRoutes()
        }
    }

    private func chip(title: String, kind: ReactionKind? = nil, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.qSpring) { action() } }) {
            HStack(spacing: 6) {
                if let kind { ReactionSticker(kind: kind, size: 22) }
                Text(title)
            }
                .font(.ui(15, .semibold))
                .foregroundStyle(isOn ? Color.qBackground : Color.qInk)
                .padding(.horizontal, DS.Space.s)
                .frame(height: 34)
                .background(Capsule().fill(isOn ? Color.qInk : Color.qField))
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// A handful of emoji that float up and fade out.
struct EmojiBurst: View {
    let kind: ReactionKind
    let trigger: Int

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { i in
                BurstParticle(kind: kind, index: i, trigger: trigger)
            }
        }
    }
}

private struct BurstParticle: View {
    let kind: ReactionKind
    let index: Int
    let trigger: Int
    @State private var progress: CGFloat = 1

    var body: some View {
        let angle = CGFloat(index) / 7 * .pi - .pi        // fan upwards
        let distance: CGFloat = 46 + CGFloat(index % 3) * 14
        ReactionSticker(kind: kind, size: 20 + CGFloat(index % 3) * 5)
            .offset(x: cos(angle) * distance * progress,
                    y: sin(angle) * distance * progress - 20 * progress)
            .scaleEffect(progress < 1 ? 1.1 : 0.6)
            .opacity(progress < 1 ? 1 - Double(progress) : 0)
            .onChange(of: trigger) { _, _ in
                progress = 0
                withAnimation(.easeOut(duration: 0.7)) { progress = 1 }
            }
    }
}

/// Big emoji that pops in the middle of a card on double-tap.
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

/// A reaction drawn like the site's stickers: 3D emoji on a lime disc with a white rim,
/// or the green SAME word pill. `size` is the disc diameter.
struct ReactionSticker: View {
    let kind: ReactionKind
    var size: CGFloat = 28

    var body: some View {
        Group {
            if let asset = kind.assetName {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.64, height: size * 0.64)
                    .frame(width: size, height: size)
                    .background(
                        Circle()
                            .fill(RadialGradient(colors: [Color(hex: 0xF1FF9A), .qLime, Color(hex: 0xB5DA00)],
                                                 center: UnitPoint(x: 0.35, y: 0.3),
                                                 startRadius: 0, endRadius: size * 0.6))
                            .padding(size * 0.06)
                            .background(Circle().fill(.white))
                    )
            } else {
                Text("SAME")
                    .font(.display(size * 0.38, .black))
                    .foregroundStyle(Color.qLime)
                    .padding(.horizontal, size * 0.28)
                    .frame(height: size * 0.8)
                    .background(
                        Capsule().fill(Color.qGreen)
                            .padding(size * 0.06)
                            .background(Capsule().fill(.white))
                    )
                    .fixedSize()
            }
        }
        .shadow(color: Color(hex: 0x022A1E).opacity(0.25), radius: size * 0.1, y: size * 0.06)
        .accessibilityLabel(kind.label)
    }
}
