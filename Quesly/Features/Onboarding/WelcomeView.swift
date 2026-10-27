import SwiftUI

/// First screen. One idea, shown rather than described: today's question on a tactile
/// editorial card, with real social proof and clear entry points.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @State private var authMode: AuthView.Mode?
    @State private var appeared = false

    private var question: DailyQuestion { store.todayQuestion }
    private var words: [String] {
        question.text.split(separator: " ").map(String.init)
    }

    var body: some View {
        ZStack {
            Color.qBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                QueslyLogo(height: 32, markColor: .qGreen, textColor: .qInk, background: .qLime)
                    .frame(height: 48)
                    .padding(.top, DS.Space.m)
                    .reveal(appeared, delay: 0)

                Spacer(minLength: DS.Space.m)

                heroCard

                Spacer(minLength: DS.Space.m)

                actions
            }
        }
        .onAppear { appeared = true }
        .sheet(item: $authMode) { mode in
            AuthView(mode: mode)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    private var heroCard: some View {
        let highlighted = question.keyWords

        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                QueslyMark(color: .qGreen, cutout: .qLime)
                    .frame(width: 16)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.qLime))
                Text("TODAY'S QUESTION")
                    .font(.ui(12, .bold))
                    .tracking(1.0)
                    .foregroundStyle(Color.qBrandText)
                Spacer()
                Text("Daily at 9 AM")
                    .font(.ui(12, .medium))
                    .foregroundStyle(Color.qGray)
            }

            WrappingHStack(spacing: 7, lineSpacing: 5, centered: false) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    let clean = word.uppercased().filter(\.isLetter)
                    let isHot = highlighted.contains(clean)
                    Text(word)
                        .font(.display(28, .bold))
                        .foregroundStyle(isHot ? Color.qGreen : Color.qInk)
                        .padding(.horizontal, isHot ? 8 : 0)
                        .padding(.vertical, isHot ? 2 : 0)
                        .background {
                            if isHot {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.qLime)
                                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                            }
                        }
                        .rotationEffect(.degrees(isHot ? -2 : 0))
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            Rectangle().fill(Color.qLine).frame(height: 1)

            HStack(spacing: DS.Space.s) {
                AvatarStack(users: Array(store.users.values.sorted { $0.id < $1.id }.prefix(3)), size: 30, ring: .white)
                Text("**\(store.answeredTodayCount.formatted())** answered today")
                    .font(.ui(14))
                    .foregroundStyle(Color.qInk2)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.qBlock)
                .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
        .padding(.horizontal, DS.Space.screen)
        .reveal(appeared, delay: 0.15)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Text("Answer first. Then see what your friends and the world said.")
                .font(.ui(14))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.qGray)
                .padding(.horizontal, DS.Space.xl)
                .padding(.bottom, 2)

            GreenButton(title: "Get started") { authMode = .signUp }

            Button("I already have an account") { authMode = .signIn }
                .font(.ui(16, .semibold))
                .foregroundStyle(Color.qInk)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.bottom, DS.Space.xs)
        .reveal(appeared, delay: 0.3)
    }
}

private extension View {
    /// Fade + rise in on first appear; instant under Reduce Motion.
    func reveal(_ shown: Bool, delay: Double) -> some View {
        modifier(Reveal(shown: shown, delay: delay))
    }
}

private struct Reveal: ViewModifier {
    let shown: Bool
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 12)
            .animation(.qSmooth.delay(delay), value: shown)
    }
}

#Preview { WelcomeView().environment(AppStore()) }
