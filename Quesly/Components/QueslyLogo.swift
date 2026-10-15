import SwiftUI

/// The Quesly mark: a bar, three dots, a bar. Proportions follow the founder's original logo (456 x 457 units).
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
            let bar = h * 131 / 457
            let dot = h * 132 / 457
            VStack(spacing: 0) {
                Rectangle().fill(color).frame(height: bar)
                ZStack {
                    Rectangle().fill(cutout ?? .clear)
                    HStack(spacing: w * 30 / 456) {
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
        .aspectRatio(456.0 / 457.0, contentMode: .fit)
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

/// The QUESLY wordmark, drawn from the founder's original logo.
/// Units come from the 3038 x 521 master: letters start at x 655 there, and the Q tail reaches the bottom edge.
struct QueslyWordmark: Shape {
    static let size = CGSize(width: 2383, height: 521)

    private static let rects: [CGRect] = [
        // Q
        CGRect(x: 0, y: 0, width: 391, height: 131), CGRect(x: 0, y: 131, width: 131, height: 195),
        CGRect(x: 260, y: 131, width: 131, height: 195), CGRect(x: 0, y: 326, width: 391, height: 130),
        // U
        CGRect(x: 423, y: 0, width: 131, height: 326), CGRect(x: 683, y: 0, width: 131, height: 326),
        CGRect(x: 423, y: 326, width: 391, height: 130),
        // E
        CGRect(x: 846, y: 0, width: 391, height: 131), CGRect(x: 846, y: 131, width: 131, height: 195),
        CGRect(x: 1009, y: 163, width: 228, height: 131), CGRect(x: 846, y: 326, width: 391, height: 130),
        // S
        CGRect(x: 1269, y: 0, width: 391, height: 131), CGRect(x: 1269, y: 131, width: 131, height: 32),
        CGRect(x: 1269, y: 163, width: 391, height: 131), CGRect(x: 1529, y: 294, width: 131, height: 32),
        CGRect(x: 1269, y: 326, width: 391, height: 130),
        // L
        CGRect(x: 1693, y: 0, width: 131, height: 326), CGRect(x: 1693, y: 326, width: 391, height: 130),
        // Y
        CGRect(x: 1992, y: 0, width: 131, height: 163), CGRect(x: 2252, y: 0, width: 131, height: 163),
        CGRect(x: 1992, y: 163, width: 391, height: 131), CGRect(x: 2122, y: 294, width: 131, height: 162),
    ]

    func path(in rect: CGRect) -> Path {
        let t = CGAffineTransform(a: rect.width / Self.size.width, b: 0, c: 0, d: rect.height / Self.size.height,
                                  tx: rect.minX, ty: rect.minY)
        var p = Path()
        for r in Self.rects { p.addRect(r, transform: t) }
        var tail = Path()
        tail.move(to: CGPoint(x: 131, y: 456))
        tail.addLine(to: CGPoint(x: 294, y: 456))
        tail.addLine(to: CGPoint(x: 359, y: 521))
        tail.addLine(to: CGPoint(x: 196, y: 521))
        tail.closeSubpath()
        p.addPath(tail, transform: t)
        return p
    }
}

/// Mark + wordmark, laid out exactly like the master logo. `height` is the height of the whole logo.
struct QueslyLogo: View {
    var height: CGFloat = 22
    var markColor: Color = .qLime
    var textColor: Color = .white
    var background: Color = .qGreen
    var animateDots = false

    var body: some View {
        let u = height / 521
        HStack(alignment: .top, spacing: 199 * u) {
            QueslyMark(color: markColor, cutout: background, animateDots: animateDots)
                .frame(width: 456 * u, height: 457 * u)
            QueslyWordmark()
                .fill(textColor)
                .frame(width: QueslyWordmark.size.width * u, height: height)
        }
        .frame(height: height, alignment: .top)
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
