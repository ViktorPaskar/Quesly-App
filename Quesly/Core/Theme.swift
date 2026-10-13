import SwiftUI

// MARK: - Colors

extension Color {
    /// Brand dark green — backgrounds, primary buttons, active states.
    static let qGreen = Color(hex: 0x07583D)
    /// Slightly darker green used for gradients and pattern overlays.
    static let qGreenDeep = Color(hex: 0x044330)
    /// Lighter green used in the splash gradient.
    static let qGreenLight = Color(hex: 0x5BA21E)
    /// Brand acid lime — accents on green only (never lime text on white: it fails contrast).
    static let qLime = Color(hex: 0xD4FF00)
    /// Very light green tint for chips and selected states on white.
    static let qMint = Color(hex: 0xEEF6F1)

    static let qInk = Color(hex: 0x16181A)
    /// Secondary text. Dark enough for WCAG AA on white (4.9:1).
    static let qGray = Color(hex: 0x6B6F73)
    static let qLine = Color(hex: 0xE9ECEA)
    static let qField = Color(hex: 0xF3F5F4)
    static let qFlame = Color(hex: 0xFF6A1A)

    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Typography

extension Font {
    /// Brand typeface (Outfit, SIL OFL). Scales with Dynamic Type relative to `style`.
    static func quesly(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(outfitName(weight), size: size, relativeTo: style)
    }

    private static func outfitName(_ weight: Font.Weight) -> String {
        switch weight {
        case .black: return "Outfit-Black"
        case .heavy: return "Outfit-ExtraBold"
        case .bold: return "Outfit-Bold"
        case .semibold: return "Outfit-SemiBold"
        case .medium: return "Outfit-Medium"
        default: return "Outfit-Regular"
        }
    }
}

// MARK: - Motion

extension Animation {
    /// Default bouncy spring for interactive elements.
    static let qSpring = Animation.spring(response: 0.38, dampingFraction: 0.72)
    /// Softer spring for screen-level transitions.
    static let qSmooth = Animation.spring(response: 0.5, dampingFraction: 0.88)
}

/// Button style that gently shrinks on press.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

// MARK: - Shared modifiers

struct QueslyFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.quesly(16))
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.qField))
    }
}

extension View {
    func queslyField() -> some View { modifier(QueslyFieldStyle()) }

    /// Fades + slides a view in, staggered by `index` (capped so long lists don't lag).
    func staggeredAppear(_ index: Int) -> some View {
        modifier(StaggeredAppear(index: index))
    }
}

private struct StaggeredAppear: ViewModifier {
    let index: Int
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
            .onAppear {
                guard !shown else { return }
                withAnimation(.qSmooth.delay(Double(min(index, 8)) * 0.05)) { shown = true }
            }
    }
}
