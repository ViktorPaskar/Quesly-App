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
                    .font(.ui(11, .bold))
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

/// Flat brand surface used behind green screens. (Deliberately no gradients or blobs.)
struct BrandGradientBackground: View {
    var animate: Bool = false

    var body: some View {
        Color.qGreen.ignoresSafeArea()
    }
}

/// Lime flash with the mark + confetti, shown right after submitting an answer.
struct LimeTransitionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pop = false

    var body: some View {
        ZStack {
            Color.qLime.ignoresSafeArea()
            if !reduceMotion {
                ConfettiView(count: 36).ignoresSafeArea()
            }
            VStack(spacing: 20) {
                QueslyMark(color: .qGreen, animateDots: true)
                    .frame(width: 84)
                    .scaleEffect(pop ? 1 : 0.4)
                Text("Answer posted!")
                    .font(.display(24, .bold))
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
