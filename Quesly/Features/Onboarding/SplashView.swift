import SwiftUI

/// Animated green-lime gradient splash from the prototype.
struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            BrandGradientBackground(animate: animate)
            VStack(spacing: 10) {
                QueslyLogo(height: 34, background: .clear)
                Text("ONE QUESTION A DAY. MILLIONS OF STORIES")
                    .font(.quesly(10, .bold))
                    .tracking(0.6)
                    .foregroundStyle(.white)
            }
            .scaleEffect(animate ? 1 : 0.92)
            .opacity(animate ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { animate = true }
        }
    }
}

struct BrandGradientBackground: View {
    var animate: Bool

    var body: some View {
        ZStack {
            Color.qGreen
            RadialGradient(colors: [Color.qLime.opacity(0.85), .clear],
                           center: animate ? .topTrailing : .top,
                           startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Color.qGreenLight.opacity(0.9), .clear],
                           center: animate ? .bottomLeading : .bottom,
                           startRadius: 0, endRadius: 460)
            RadialGradient(colors: [Color.qGreenDeep.opacity(0.9), .clear],
                           center: .center, startRadius: 0, endRadius: 260)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 2.4), value: animate)
    }
}

/// Lime flash with the mark, shown after submitting an answer (frame 6 of the demo).
struct LimeTransitionView: View {
    @State private var pop = false

    var body: some View {
        ZStack {
            Color.qLime.ignoresSafeArea()
            QueslyMark(color: .qGreen)
                .frame(width: 80)
                .scaleEffect(pop ? 1 : 0.6)
                .opacity(pop ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { pop = true }
        }
    }
}

#Preview { SplashView() }
