import SwiftUI

struct WelcomeView: View {
    @State private var authMode: AuthView.Mode?
    @State private var appeared = false

    var body: some View {
        ZStack {
            BrandGradientBackground(animate: appeared)

            VStack(spacing: 0) {
                Spacer()
                QueslyLogo(height: 40, background: .clear)
                Text("ONE QUESTION A DAY.\nMILLIONS OF STORIES")
                    .font(.quesly(14, .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.top, 14)
                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    feature("questionmark.bubble.fill", "1 question every 24h")
                    feature("globe.europe.africa.fill", "World & Friends feeds")
                    feature("heart.fill", "Positive emojis only")
                    feature("square.and.arrow.up.fill", "Instant story export")
                }
                .padding(.bottom, 36)

                VStack(spacing: 12) {
                    LimeButton(title: "Get started") { authMode = .signUp }
                    Button("I already have an account") { authMode = .signIn }
                        .font(.quesly(15, .medium))
                        .foregroundStyle(.white)
                        .frame(height: 44)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
        .sheet(item: $authMode) { mode in
            AuthView(mode: mode)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    private func feature(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.qLime)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 9).fill(Color.qGreenDeep.opacity(0.7)))
            Text(title).font(.quesly(16, .medium)).foregroundStyle(.white)
        }
    }
}

#Preview { WelcomeView().environment(AppStore()) }
