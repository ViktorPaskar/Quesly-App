import SwiftUI

struct WelcomeView: View {
    @State private var authMode: AuthView.Mode?
    @State private var appeared = false

    private let features: [(Ph, String, String)] = [
        (.sunFill, "1 question every 24h", "A new story prompt every morning"),
        (.globeHemisphereWestFill, "World & Friends feeds", "See how people answer, near and far"),
        (.heartFill, "Positive reactions only", "No dislikes. No hate. Just good vibes"),
        (.paperPlaneTiltFill, "Instant story export", "Share your answer to IG & TikTok"),
    ]

    var body: some View {
        ZStack {
            BrandGradientBackground(animate: true)

            VStack(spacing: 0) {
                Spacer()
                QueslyLogo(height: 42, background: .clear)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)
                Text("ONE QUESTION A DAY.\nMILLIONS OF STORIES")
                    .font(.quesly(15, .bold))
                    .tracking(0.8)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)
                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, f in
                        feature(f.0, f.1, f.2)
                            .opacity(appeared ? 1 : 0)
                            .offset(x: appeared ? 0 : -24)
                            .animation(.qSmooth.delay(0.25 + Double(index) * 0.08), value: appeared)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.bottom, 36)

                VStack(spacing: 6) {
                    LimeButton(title: "Get started", icon: .arrowRightBold) { authMode = .signUp }
                    Button("I already have an account") { authMode = .signIn }
                        .font(.quesly(16, .medium))
                        .foregroundStyle(.white)
                        .frame(height: 48)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)
                .animation(.qSmooth.delay(0.6), value: appeared)
            }
        }
        .onAppear { withAnimation(.qSmooth) { appeared = true } }
        .sheet(item: $authMode) { mode in
            AuthView(mode: mode)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
    }

    private func feature(_ icon: Ph, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Icon(icon, size: 20)
                .foregroundStyle(Color.qGreen)
                .frame(width: 42, height: 42)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.qLime))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.quesly(17, .semibold)).foregroundStyle(.white)
                Text(subtitle).font(.quesly(14)).foregroundStyle(.white.opacity(0.75))
            }
        }
    }
}

#Preview { WelcomeView().environment(AppStore()) }
