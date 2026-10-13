import SwiftUI

/// The Quesly mark: a bar, three dots, a bar.
struct QueslyMark: View {
    var color: Color = .qLime
    /// Fill behind the dots; pass the background color to get the stencil look.
    var cutout: Color? = nil
    /// When true the three dots bounce one after another (used on splash / loading).
    var animateDots = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let bar = h * 0.26
            let dot = h * 0.34
            VStack(spacing: 0) {
                Rectangle().fill(color).frame(height: bar)
                ZStack {
                    Rectangle().fill(cutout ?? .clear)
                    HStack(spacing: w * 0.06) {
                        ForEach(0..<3, id: \.self) { i in
                            BouncingDot(color: color, size: dot, index: i, isActive: animateDots)
                        }
                    }
                }
                .frame(height: h - bar * 2)
                Rectangle().fill(color).frame(height: bar)
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(1.35, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

private struct BouncingDot: View {
    let color: Color
    let size: CGFloat
    let index: Int
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var up = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(up ? 1.25 : 1)
            .onAppear {
                guard isActive, !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(index) * 0.15)) {
                    up = true
                }
            }
    }
}

/// Mark + wordmark. For pixel-perfect branding, replace the Text with the SVG wordmark from Figma.
struct QueslyLogo: View {
    var height: CGFloat = 22
    var markColor: Color = .qLime
    var textColor: Color = .white
    var background: Color = .qGreen
    var animateDots = false

    var body: some View {
        HStack(spacing: height * 0.32) {
            QueslyMark(color: markColor, cutout: background, animateDots: animateDots)
                .frame(height: height * 0.82)
            Text("QUESLY")
                .font(.custom("Outfit-Black", fixedSize: height * 1.12))
                .tracking(height * 0.02)
                .foregroundStyle(textColor)
        }
        .accessibilityElement()
        .accessibilityLabel("Quesly")
    }
}

#Preview {
    VStack(spacing: 24) {
        QueslyLogo(height: 40, animateDots: true)
        QueslyLogo(height: 20, markColor: .qInk, textColor: .qInk, background: .white)
            .padding().background(.white)
    }
    .padding()
    .background(Color.qGreen)
}
