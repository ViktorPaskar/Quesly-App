import SwiftUI

/// The Quesly mark: a bar, three dots, a bar.
struct QueslyMark: View {
    var color: Color = .qLime
    /// Color of the dots' "cut-out" band; pass the background color to get the stencil look.
    var cutout: Color? = nil

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
                        ForEach(0..<3, id: \.self) { _ in
                            Circle().fill(color).frame(width: dot, height: dot)
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

/// Mark + wordmark. Replace the Text with the SVG wordmark exported from Figma for pixel accuracy.
struct QueslyLogo: View {
    var height: CGFloat = 22
    var markColor: Color = .qLime
    var textColor: Color = .white
    var background: Color = .qGreen

    var body: some View {
        HStack(spacing: height * 0.35) {
            QueslyMark(color: markColor, cutout: background)
                .frame(height: height * 0.8)
            Text("QUESLY")
                .font(.system(size: height, weight: .black))
                .fontWidth(.expanded)
                .tracking(-0.5)
                .foregroundStyle(textColor)
        }
        .accessibilityElement()
        .accessibilityLabel("Quesly")
    }
}

#Preview {
    VStack(spacing: 24) {
        QueslyLogo(height: 40)
        QueslyLogo(height: 20, markColor: .qInk, textColor: .qInk, background: .white)
            .padding().background(.white)
    }
    .padding()
    .background(Color.qGreen)
}
