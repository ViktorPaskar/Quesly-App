import SwiftUI
import UIKit

// MARK: - Design tokens
//
// One place for every visual decision. Views use these tokens, never raw numbers or hex values.
//
//  Spacing   4-pt grid: xxs 4 · xs 8 · s 12 · m 16 · l 20 · xl 24 · xxl 32 · xxxl 48
//  Radius    s 8 (chips, small controls) · m 12 (buttons, fields, rows) · l 20 (cards, sheets)
//  Type      Outfit = brand display only (question, big titles, logo).
//            SF Pro = all UI and reading text, scales with Dynamic Type.
//  Color     Semantic roles with light + dark values. Lime is an accent on green only.
//  Motion    One spring for interactions, one for transitions; disabled under Reduce Motion.

enum DS {
    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
        /// Standard horizontal screen margin.
        static let screen: CGFloat = 20
    }

    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 20
    }

    /// Minimum tappable size (HIG).
    static let hitTarget: CGFloat = 44
}

// MARK: - Colors

extension Color {
    // Brand (fixed in both appearances)
    /// Brand dark green — primary buttons, active states, hero surfaces.
    static let qGreen = Color(hex: 0x07583D)
    static let qGreenDeep = Color(hex: 0x044330)
    static let qGreenLight = Color(hex: 0x5BA21E)
    /// Brand acid lime — accent on green surfaces only (fails contrast as text on white).
    static let qLime = Color(hex: 0xD4FF00)
    static let qFlame = Color(hex: 0xFF6A1A)
    /// Streak freeze ❄️ (icon/text) and its soft fill.
    static let qIce = Color(light: 0x2F7FE0, dark: 0x7DB8FF)
    static let qIceSoft = Color(light: 0xE6F0FC, dark: 0x16263B)

    // Semantic roles (adapt to light / dark)
    /// Primary text.
    static let qInk = Color(light: 0x16181A, dark: 0xF2F4F3)
    /// Secondary text (≥ 4.5:1 on background).
    static let qGray = Color(light: 0x6B6F73, dark: 0x9EA3A7)
    /// Hairline separators and outlines.
    static let qLine = Color(light: 0xE9ECEA, dark: 0x2A2E2C)
    /// Neutral fill for fields, chips and secondary buttons.
    static let qField = Color(light: 0xF3F5F4, dark: 0x1E2220)
    /// Brand-tinted fill for selected states on neutral backgrounds.
    static let qMint = Color(light: 0xEAF4EE, dark: 0x16302A)
    /// Brand green used as *text or icon* color on neutral backgrounds (lighter in dark mode).
    static let qBrandText = Color(light: 0x07583D, dark: 0x7FD49B)
    /// App background.
    static let qBackground = Color(light: 0xFFFFFF, dark: 0x0C0E0D)
    /// Elevated surfaces (sheets, popovers).
    static let qSurface = Color(light: 0xFFFFFF, dark: 0x161917)

    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255,
                           alpha: 1)
        })
    }
}

// MARK: - Typography

extension Font {
    /// UI text on the SF Pro scale. Sizes snap to the type scale and scale with Dynamic Type.
    ///
    /// Scale: 12 caption · 13 footnote · 15 subheadline · 16 callout · 17 body · 20 title3 · 22 title2 · 28 title · 34 largeTitle
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        // The scale matches Apple's text-style point sizes exactly, so we can use the styles
        // themselves and get Dynamic Type for free.
        .system(scale(size).1, design: .default, weight: weight)
    }

    /// Brand display face (Outfit). Use only for the question, hero titles and brand moments.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        let (_, style) = scale(size)
        return .custom(outfitName(weight), size: size, relativeTo: style)
    }

    private static func scale(_ size: CGFloat) -> (CGFloat, Font.TextStyle) {
        switch size {
        case ..<12.5: return (12, .caption)
        case ..<14: return (13, .footnote)
        case ..<15.5: return (15, .subheadline)
        case ..<16.5: return (16, .callout)
        case ..<18.5: return (17, .body)
        case ..<21: return (20, .title3)
        case ..<25: return (22, .title2)
        case ..<31: return (28, .title)
        default: return (34, .largeTitle)
        }
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
    /// Interactions (taps, toggles, selection).
    static let qSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)
    /// Screen-level transitions and content changes.
    static let qSmooth = Animation.spring(response: 0.45, dampingFraction: 0.9)
}

/// Button style that gently shrinks on press.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

// MARK: - Shared modifiers

struct QueslyFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.ui(17))
            .padding(.horizontal, DS.Space.m)
            .frame(minHeight: 50)
            .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qField))
    }
}

extension View {
    func queslyField() -> some View { modifier(QueslyFieldStyle()) }

    /// Fades a list item in, staggered by `index`. Skipped entirely under Reduce Motion.
    func staggeredAppear(_ index: Int) -> some View {
        modifier(StaggeredAppear(index: index))
    }
}

private struct StaggeredAppear: ViewModifier {
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 8)
            .onAppear {
                guard !shown, !reduceMotion else { return }
                withAnimation(.qSmooth.delay(Double(min(index, 6)) * 0.04)) { shown = true }
            }
    }
}
