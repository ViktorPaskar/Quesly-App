import SwiftUI

/// First screen. An interactive card deck ("картотека вопросов") showcasing daily questions
/// cycling one after another with tactile physics, social sign-in options, and clear secondary sign-in.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @State private var authMode: AuthView.Mode?
    @State private var appeared = false
    @State private var activeIndex = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct CatalogQuestion: Identifiable {
        let id: Int
        let text: String
        let hotWord: String
        let category: String
    }

    private let catalog: [CatalogQuestion] = [
        .init(id: 0, text: "What's something you're quietly proud of?", hotWord: "PROUD", category: "Daily Reflection"),
        .init(id: 1, text: "Which song always puts you in a good mood?", hotWord: "MOOD", category: "Joy & Music"),
        .init(id: 2, text: "What is a small kindness you never forgot?", hotWord: "KINDNESS", category: "Human Stories"),
        .init(id: 3, text: "What advice would you give your younger self?", hotWord: "ADVICE", category: "Life Wisdom")
    ]

    var body: some View {
        ZStack {
            Color.qBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                QueslyLogo(height: 32, markColor: .qGreen, textColor: .qInk, background: .qLime)
                    .frame(height: 48)
                    .padding(.top, DS.Space.m)
                    .reveal(appeared, delay: 0)

                Spacer(minLength: 12)

                questionCardDeck
                    .padding(.horizontal, DS.Space.screen)

                Spacer(minLength: 12)

                actions
            }
        }
        .onAppear {
            appeared = true
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_800_000_000)
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                    activeIndex = (activeIndex + 1) % catalog.count
                }
            }
        }
        .sheet(item: $authMode) { mode in
            AuthView(mode: mode)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    // MARK: - Card Catalog ("Картотека вопросов")

    private var questionCardDeck: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                // Background Card 2 (furthest back)
                backingCard(scale: 0.92, yOffset: -16, opacity: 0.5)

                // Background Card 1 (middle)
                backingCard(scale: 0.96, yOffset: -8, opacity: 0.8)

                // Front Active Card
                let item = catalog[activeIndex]
                frontCard(item: item)
                    .id(item.id)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        )
                    )
            }
            .frame(height: 256)

            // Discreet deck pagination pills
            HStack(spacing: 6) {
                ForEach(0..<catalog.count, id: \.self) { i in
                    Capsule()
                        .fill(i == activeIndex ? Color.qGreen : Color.qLine)
                        .frame(width: i == activeIndex ? 18 : 6, height: 5)
                        .animation(.qSpring, value: activeIndex)
                }
            }
            .padding(.top, 4)
        }
        .reveal(appeared, delay: 0.15)
    }

    private func backingCard(scale: CGFloat, yOffset: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.qBlock)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.qLine, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, y: 3)
            .frame(height: 240)
            .scaleEffect(scale, anchor: .bottom)
            .offset(y: yOffset)
            .opacity(opacity)
    }

    private func frontCard(item: CatalogQuestion) -> some View {
        let words = item.text.split(separator: " ").map(String.init)

        return VStack(alignment: .leading, spacing: 14) {
            // Header Row: round icon + Daily at 9 AM (TODAY'S QUESTION removed)
            HStack(spacing: 8) {
                QueslyMark(color: .qGreen, cutout: .qLime)
                    .frame(width: 16)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.qLime))
                Text("Daily at 9 AM")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Color.qGray)
                Spacer()
            }

            // Headline with tactile lime keyword sticker
            WrappingHStack(spacing: 7, lineSpacing: 5, centered: false) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    let clean = word.uppercased().filter(\.isLetter)
                    let isHot = clean == item.hotWord
                    Text(word)
                        .font(.display(26, .semibold))
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

            Spacer(minLength: 0)

            Rectangle().fill(Color.qLine).frame(height: 1)

            // Calm card footer: category only
            HStack(spacing: 6) {
                Icon(.sparkleFill, size: 12)
                    .foregroundStyle(Color.qBrandText)
                Text(item.category)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk2)
                Spacer()
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 240)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.qBlock)
                .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }

    // MARK: - Actions & Social Sign-In

    private var actions: some View {
        VStack(spacing: 12) {
            Text("Answer first. Then see what your friends and the world said.")
                .font(.ui(14))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.qGray)
                .padding(.horizontal, DS.Space.xl)
                .padding(.bottom, 2)

            // Primary: Get started
            LimeButton(title: "Get started") { authMode = .signUp }

            // Social sign-in options: Apple & Google with official vector SVGs
            HStack(spacing: 10) {
                // Continue with Apple
                Button {
                    authMode = .signUp
                } label: {
                    HStack(spacing: 8) {
                        Image("ui-apple")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                        Text("Apple")
                            .font(.ui(15, .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Capsule().fill(Color.black))
                }
                .buttonStyle(.pressable)

                // Continue with Google
                Button {
                    authMode = .signUp
                } label: {
                    HStack(spacing: 8) {
                        Image("ui-google")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                        Text("Google")
                            .font(.ui(15, .semibold))
                    }
                    .foregroundStyle(Color.qInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Capsule().fill(Color.qBlock))
                    .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
                }
                .buttonStyle(.pressable)
            }

            // Secondary: I already have an account
            Button {
                authMode = .signIn
            } label: {
                Text("I already have an account")
                    .font(.ui(14, .medium))
                    .foregroundStyle(Color.qGray)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .frame(height: 32)
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.bottom, DS.Space.xs)
        .reveal(appeared, delay: 0.3)
    }
}

private extension View {
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
