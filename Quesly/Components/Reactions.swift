import SwiftUI

/// The viewer's reaction control: one button that opens a tray of four positive emoji.
struct ReactionControl: View {
    let answer: Answer
    @Binding var isTrayOpen: Bool
    let onPick: (ReactionKind) -> Void

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
            if let burst {
                EmojiBurst(emoji: burst.emoji, trigger: burstTrigger)
                    .offset(x: 6, y: -14)
                    .allowsHitTesting(false)
            }
        }
        .animation(.qSpring, value: isTrayOpen)
    }

    private var trigger: some View {
        Button {
            isTrayOpen = true
        } label: {
            HStack(spacing: 6) {
                if let mine = answer.myReaction {
                    Text(mine.emoji)
                        .font(.system(size: 22))
                        .id(mine)
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                    Text(mine.label)
                        .font(.quesly(14, .semibold))
                        .foregroundStyle(Color.qGreen)
                } else {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20, weight: .medium))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.qGreen, .white)
                                .offset(x: 4, y: -3)
                        }
                    Text("React")
                        .font(.quesly(14, .medium))
                }
            }
            .foregroundStyle(Color.qGray)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Capsule().fill(answer.myReaction == nil ? Color.qField : Color.qMint))
            .contentShape(Capsule())
        }
        .buttonStyle(.pressable)
        .frame(minHeight: 44)
        .accessibilityLabel(answer.myReaction.map { "Your reaction: \($0.label). Change reaction" } ?? "React")
    }

    private var tray: some View {
        HStack(spacing: 2) {
            ForEach(Array(ReactionKind.allCases.enumerated()), id: \.element) { index, kind in
                TrayEmoji(kind: kind, index: index, isSelected: answer.myReaction == kind) {
                    burst = kind
                    burstTrigger += 1
                    onPick(kind)
                    isTrayOpen = false
                }
            }
            Button { isTrayOpen = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.qGray)
                    .frame(width: 32, height: 44)
            }
            .accessibilityLabel("Close reactions")
        }
        .padding(.leading, 6)
        .padding(.trailing, 2)
        .background(
            Capsule().fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
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
            Text(kind.emoji)
                .font(.system(size: 28))
                .frame(width: 46, height: 46)
                .background(Circle().fill(isSelected ? Color.qMint : .clear))
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

/// Author-only summary: top emoji + total. Others never see counts (no popularity contest).
struct ReactionSummary: View {
    let answer: Answer

    var body: some View {
        HStack(spacing: 6) {
            if answer.totalReactions == 0 {
                Image(systemName: "eye.slash").font(.system(size: 12, weight: .semibold))
                Text("No reactions yet").font(.quesly(13, .medium))
            } else {
                HStack(spacing: -6) {
                    ForEach(answer.topReactions.prefix(3)) { kind in
                        Text(kind.emoji)
                            .font(.system(size: 15))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(.white))
                            .overlay(Circle().stroke(Color.qLine, lineWidth: 1))
                    }
                }
                Text("\(answer.totalReactions)")
                    .font(.quesly(14, .semibold))
                    .foregroundStyle(Color.qInk)
                    .contentTransition(.numericText())
                Image(systemName: "lock.fill").font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.qGray.opacity(0.7))
            }
        }
        .foregroundStyle(Color.qGray)
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(Capsule().fill(Color.qField))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(answer.totalReactions) reactions, only visible to you")
    }
}

/// A handful of emoji that float up and fade out.
struct EmojiBurst: View {
    let emoji: String
    let trigger: Int

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { i in
                BurstParticle(emoji: emoji, index: i, trigger: trigger)
            }
        }
    }
}

private struct BurstParticle: View {
    let emoji: String
    let index: Int
    let trigger: Int
    @State private var progress: CGFloat = 1

    var body: some View {
        let angle = CGFloat(index) / 7 * .pi - .pi        // fan upwards
        let distance: CGFloat = 46 + CGFloat(index % 3) * 14
        Text(emoji)
            .font(.system(size: 16 + CGFloat(index % 3) * 4))
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
    let emoji: String
    let trigger: Int
    @State private var phase: CGFloat = 0

    var body: some View {
        Text(emoji)
            .font(.system(size: 76))
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
