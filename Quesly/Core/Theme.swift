import SwiftUI

// MARK: - Colors

extension Color {
    /// Brand dark green — backgrounds, primary buttons, active states.
    static let qGreen = Color(hex: 0x07583D)
    /// Slightly darker green used for gradients and pattern overlays.
    static let qGreenDeep = Color(hex: 0x044330)
    /// Lighter green used in the splash gradient.
    static let qGreenLight = Color(hex: 0x5BA21E)
    /// Brand acid lime — accents, highlighted words, CTA buttons on green.
    static let qLime = Color(hex: 0xD4FF00)

    static let qInk = Color(hex: 0x1C1C1E)
    static let qGray = Color(hex: 0x8E8E93)
    static let qLine = Color(hex: 0xECECEC)
    static let qField = Color(hex: 0xF3F3F3)

    // Reaction colors
    static let qHeart = Color(hex: 0xF0306A)
    static let qFire = Color(hex: 0xFF7A1A)
    static let qSmile = Color(hex: 0x16B26B)
    static let qClap = Color(hex: 0x2D7BF0)

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
    /// Single entry point for the app's typography.
    /// To use the Figma font (e.g. Gilroy), add the .otf files to the target,
    /// list them under "Fonts provided by application" and return
    /// `.custom("Gilroy-\(weightName)", size: size)` here.
    static func quesly(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - Shared modifiers

struct QueslyFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.quesly(15))
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.qLine, lineWidth: 1))
    }
}

extension View {
    func queslyField() -> some View { modifier(QueslyFieldStyle()) }
}
