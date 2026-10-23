import SwiftUI

/// First screen. One idea, shown rather than described: today's question, big, with the people who
/// already answered it, and one clear way in. Logo on top, the question as the hero, actions below.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @State private var authMode: AuthView.Mode?
    @State private var appeared = false

    private var question: DailyQuestion { store.todayQuestion }
    private var words: [String] { question.text.uppercased().split(separator: " ").map(String.init) }

    var body: some View {
        ZStack {
            Color.qGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                QueslyLogo(height: 22, background: .clear)
                    .frame(height: 44)
                    .padding(.top, DS.Space.xs)
                    .reveal(appeared, delay: 0)

                Spacer(minLength: DS.Space.xl)

                hero

                Spacer(minLength: DS.Space.xl)

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

    private var hero: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            Text("Today's question")
                .font(.ui(15, .semibold))
                .foregroundStyle(Color.qLime)
                .reveal(appeared, delay: 0.1)

            let keyWords = question.keyWords
            WrappingHStack(spacing: 10, lineSpacing: 4, centered: false) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    let isHot = keyWords.contains(word.filter(\.isLetter))
                    Text(word)
                        .font(.display(40, .heavy))
                        .foregroundStyle(isHot ? Color.qGreen : .white)
                        .padding(.horizontal, isHot ? 8 : 0)
                        .background {
                            if isHot {
                                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.qLime)
                            }
                        }
                        .rotationEffect(.degrees(isHot ? -3 : 0))
                        .reveal(appeared, delay: 0.2 + Double(index) * 0.05)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(question.text)

            HStack(spacing: DS.Space.s) {
                AvatarStack(users: Array(store.users.values.sorted { $0.id < $1.id }.prefix(2)), size: 32, ring: .qGreen)
                Text("**\(store.answeredTodayCount.formatted())** people answered today")
                    .font(.ui(15))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .accessibilityElement(children: .combine)
            .reveal(appeared, delay: 0.3 + Double(words.count) * 0.05)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Space.xl)
    }

    private var actions: some View {
        VStack(spacing: DS.Space.xs) {
            Text("Answer first. Then see what your friends and the world said.")
                .font(.ui(15))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, DS.Space.xl)
                .padding(.bottom, DS.Space.s)
            LimeButton(title: "Get started") { authMode = .signUp }
            Button("I already have an account") { authMode = .signIn }
                .font(.ui(17, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.bottom, DS.Space.xs)
        .reveal(appeared, delay: 0.6)
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
