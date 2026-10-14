import SwiftUI

/// First screen: shows the product instead of describing it — real answer cards drift up behind the brand.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @State private var authMode: AuthView.Mode?
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.qGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                // The cards are an overlay so their (very tall, looping) content never pushes the buttons off screen.
                GeometryReader { geo in
                    FloatingAnswers(answers: store.todayAnswers)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .opacity(appeared ? 1 : 0)
                        .animation(.qSmooth.delay(0.2), value: appeared)
                }

                brand
            }
        }
        .onAppear { withAnimation(.qSmooth) { appeared = true } }
        .sheet(item: $authMode) { mode in
            AuthView(mode: mode)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    private var brand: some View {
        VStack(spacing: 0) {
            QueslyLogo(height: 38, background: .clear)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.9)
            Text("ONE QUESTION A DAY.\nMILLIONS OF STORIES")
                .font(.ui(15, .bold))
                .tracking(0.8)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.top, DS.Space.m)
                .opacity(appeared ? 1 : 0)
            Text("Answer today's question, then see how friends and the world answered it.")
                .font(.ui(15))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, DS.Space.xs)
                .padding(.horizontal, DS.Space.xxl)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: DS.Space.xs) {
                LimeButton(title: "Get started", icon: .arrowRightBold) { authMode = .signUp }
                Button("I already have an account") { authMode = .signIn }
                    .font(.ui(16, .medium))
                    .foregroundStyle(.white)
                    .frame(height: 48)
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.xl)
            .padding(.bottom, DS.Space.m)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            .animation(.qSmooth.delay(0.4), value: appeared)
        }
        .padding(.top, DS.Space.m)
    }
}

// MARK: - Floating cards

/// Two columns of answer cards scrolling upward at different speeds, looping seamlessly.
/// Static under Reduce Motion. The fade at both ends is a mask, not decoration.
private struct FloatingAnswers: View {
    let answers: [Answer]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var columns: [[Answer]] {
        let usable = answers.filter { !$0.text.isEmpty }
        return [
            usable.enumerated().filter { $0.offset.isMultiple(of: 2) }.map { $0.element },
            usable.enumerated().filter { !$0.offset.isMultiple(of: 2) }.map { $0.element },
        ]
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .top, spacing: DS.Space.s) {
                MarqueeColumn(answers: columns[0], time: time, speed: 14, startOffset: 0)
                MarqueeColumn(answers: columns[1], time: time, speed: 10, startOffset: 70)
            }
            .padding(.horizontal, DS.Space.screen)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .clipped()
        .mask(
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.18),
                .init(color: .black, location: 0.72),
                .init(color: .clear, location: 1),
            ], startPoint: .top, endPoint: .bottom)
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MarqueeColumn: View {
    let answers: [Answer]
    let time: TimeInterval
    let speed: Double
    let startOffset: CGFloat
    @State private var loopHeight: CGFloat = 0

    private var offset: CGFloat {
        guard loopHeight > 0 else { return -startOffset }
        let travelled = CGFloat((time * speed).truncatingRemainder(dividingBy: Double(loopHeight)))
        return -((travelled + startOffset).truncatingRemainder(dividingBy: loopHeight))
    }

    var body: some View {
        VStack(spacing: DS.Space.s) {
            stack
                .background(GeometryReader { geo in
                    Color.clear.onAppear { loopHeight = geo.size.height + DS.Space.s }
                })
            stack // second copy so the loop has no gap
        }
        .offset(y: offset)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var stack: some View {
        VStack(spacing: DS.Space.s) {
            ForEach(answers) { MiniAnswerCard(answer: $0) }
        }
    }
}

private struct MiniAnswerCard: View {
    @Environment(AppStore.self) private var store
    let answer: Answer

    var body: some View {
        let author = store.user(answer.authorId)
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.xs) {
                Avatar(user: author, size: 26)
                Text(author?.username ?? "")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk)
                    .lineLimit(1)
            }
            Text(answer.text)
                .font(.ui(15))
                .foregroundStyle(Color.qInk)
                .lineLimit(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Space.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qSurface))
    }
}

#Preview { WelcomeView().environment(AppStore()) }
