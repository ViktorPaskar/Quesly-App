import SwiftUI

/// Animated green-lime gradient splash from the prototype.
struct SplashView: View {
    @State private var animate = false
    @State private var showTagline = false

    var body: some View {
        ZStack {
            BrandGradientBackground(animate: animate)
            VStack(spacing: 12) {
                QueslyLogo(height: 38, background: .clear, animateDots: true)
                    .scaleEffect(animate ? 1 : 0.85)
                    .opacity(animate ? 1 : 0)
                Text("ONE QUESTION A DAY. MILLIONS OF STORIES")
                    .font(.quesly(11, .bold))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { animate = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) { showTagline = true }
        }
    }
}

/// Living brand gradient: soft lime and green blobs drifting over the brand green.
struct BrandGradientBackground: View {
    var animate: Bool
    @State private var drift = false

    var body: some View {
        // The blobs live in an overlay so their size never affects the layout of the screen.
        Color.qGreen
            .overlay {
                ZStack {
                    Circle()
                        .fill(Color.qLime.opacity(0.75))
                        .frame(width: 420, height: 420)
                        .blur(radius: 90)
                        .offset(x: drift ? 120 : 60, y: drift ? -300 : -220)
                    Circle()
                        .fill(Color.qGreenLight.opacity(0.9))
                        .frame(width: 460, height: 460)
                        .blur(radius: 100)
                        .offset(x: drift ? -140 : -60, y: drift ? 320 : 240)
                    Circle()
                        .fill(Color.qGreenDeep.opacity(0.85))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                }
            }
            .clipped()
        .ignoresSafeArea()
        .onAppear {
            guard animate else { return }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}

/// Lime flash with the mark + confetti, shown right after submitting an answer.
struct LimeTransitionView: View {
    @State private var pop = false

    var body: some View {
        ZStack {
            Color.qLime.ignoresSafeArea()
            ConfettiView()
                .ignoresSafeArea()
            VStack(spacing: 18) {
                QueslyMark(color: .qGreen, animateDots: true)
                    .frame(width: 84)
                    .scaleEffect(pop ? 1 : 0.4)
                Text("Answer posted!")
                    .font(.quesly(24, .bold))
                    .foregroundStyle(Color.qGreen)
                    .opacity(pop ? 1 : 0)
                    .offset(y: pop ? 0 : 12)
            }
        }
        .sensoryFeedback(.success, trigger: pop)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { pop = true }
        }
    }
}

#Preview { SplashView() }
