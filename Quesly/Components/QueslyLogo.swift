import SwiftUI

/// The Quesly mark (Oct 2026 logo): a rounded speech-bubble shape with a smiling face of two
/// question-mark "eyes". Vector templates in `Assets/Brand`, traced 1:1 from the founder's SVGs
/// (874 × 602 units). `color` fills the shape; `cutout` fills the face, `nil` leaves it see-through.
struct QueslyMark: View {
    static let aspect: CGFloat = 874.0 / 602.0

    var color: Color = .qLime
    var cutout: Color? = nil
    /// A gentle "hello" bounce (splash / loading). Off under Reduce Motion.
    var animates = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var up = false

    var body: some View {
        ZStack {
            Image("brand-mark").renderingMode(.template).resizable().foregroundStyle(color)
            if let cutout {
                Image("brand-mark-face").renderingMode(.template).resizable().foregroundStyle(cutout)
            }
        }
        .aspectRatio(Self.aspect, contentMode: .fit)
        .scaleEffect(up ? 1.06 : 1)
        .onAppear {
            guard animates, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { up = true }
        }
        .accessibilityHidden(true)
    }
}

/// Mark + "quesly" wordmark laid out like the master logo (3000 × 602 units: mark 874, gap 226,
/// wordmark 1900). `height` is the height of the whole logo.
struct QueslyLogo: View {
    var height: CGFloat = 22
    var markColor: Color = .qLime
    var textColor: Color = .white
    /// Fill of the mark's face; `.clear` lets the background show through.
    var background: Color = .qGreen
    var animates = false

    var body: some View {
        let u = height / 602
        HStack(spacing: 226 * u) {
            QueslyMark(color: markColor, cutout: background == .clear ? nil : background, animates: animates)
                .frame(width: 874 * u, height: height)
            Image("brand-wordmark")
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(textColor)
                .frame(width: 1900 * u, height: height)
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel("Quesly")
    }
}

#Preview {
    VStack(spacing: 24) {
        QueslyLogo(height: 40, animates: true)
        QueslyLogo(height: 24, markColor: .qGreen, textColor: .qInk, background: .qLime)
            .padding().background(.white)
    }
    .padding()
    .background(Color.qGreen)
}
