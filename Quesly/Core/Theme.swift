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
        /// Containers: cards, blocks, the question card, sheets of content.
        static let l: CGFloat = 16
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

    /// Icon glyph sizes, matched to the text they sit with (HIG: icons align with the type scale).
    enum Icon {
        /// Next to caption / footnote text (12–13 pt): badges, meta, lock hints.
        static let caption: CGFloat = 13
        /// Inline with body / subheadline text (15–17 pt): labels, chips, buttons.
        static let inline: CGFloat = 17
        /// Default for `IconLabel` (with subheadline text, 15 pt).
        static let label: CGFloat = 15
        /// Leading icon in list rows and tiles.
        static let row: CGFloat = 20
        /// Standalone actions: card actions, toolbar and navigation buttons.
        static let action: CGFloat = 22
        /// Tab bar glyphs.
        static let tab: CGFloat = 24
    }

    /// Minimum tappable size (HIG).
    static let hitTarget: CGFloat = 44
}

// MARK: - Colors

extension Color {
    // Brand (official palette: 053424, 08563B, D4FF00, FF8FC0, 9BD9B5, FF4F3D)
    /// #053424 — Brand dark obsidian pine green: deepest contrast, dark mode base, dark accents.
    static let qGreenDeep = Color(hex: 0x053424)
    /// #08563B — Brand emerald green: primary buttons, active states, key brand markers.
    static let qGreen = Color(hex: 0x08563B)
    static let qGreenLight = Color(hex: 0x5BA21E)
    /// #D4FF00 — Brand electric lime: high-energy accent, mascot face cutout, dot pulses.
    static let qLime = Color(hex: 0xD4FF00)
    /// #FF4F3D — Brand coral flame: streak container, fire icons, active streaks, alerts.
    static let qFlame = Color(hex: 0xFF4F3D)
    static let qFlameSoft = Color(hex: 0xFF4F3D, opacity: 0.12)
    /// #FF8FC0 — Brand bubblegum pink / rose: playful accent, likes, hearts, social highlights.
    static let qPink = Color(hex: 0xFF8FC0)
    static let qPinkSoft = Color(hex: 0xFF8FC0, opacity: 0.14)
    /// #9BD9B5 — Brand pastel sage: calm accents, soft chips, completed day markers, gentle highlights.
    static let qSage = Color(hex: 0x9BD9B5)
    static let qSageSoft = Color(hex: 0x9BD9B5, opacity: 0.18)

    static let qViolet = Color(hex: 0x7C4DEB)
    static let qVioletSoft = Color(hex: 0x7C4DEB, opacity: 0.12)
    static let qGold = Color(hex: 0xB97C0C)
    static let qGoldSoft = Color(hex: 0xE2A72E, opacity: 0.16)
    /// Cool blue accent and its soft fill.
    static let qIce = Color(light: 0x2D6BE4, dark: 0x7DB8FF)
    static let qIceSoft = Color(light: 0xE6EEFD, dark: 0x16263B)
    static let qDanger = Color(hex: 0xFF4F3D)

    // Secondary palette: accents only.
    /// #9BD9B5: your just-posted answer glow.
    static let qAqua = Color(hex: 0x9BD9B5)
    /// #DAFFA6: small "best" marks.
    static let qLimeSoft = Color(hex: 0xDAFFA6)
    /// Soft warm fill.
    static let qPeach = Color(hex: 0xFFEDE3)

    // Semantic roles (adapt to light / dark)
    /// Primary text.
    static let qInk = Color(light: 0x0A0A0A, dark: 0xF2F4F3)
    /// Secondary text: bios, "Reacted by …".
    static let qInk2 = Color(light: 0x3A3A3C, dark: 0xC7C7CC)
    /// Tertiary text: time, captions, inactive icons (spec `ink3`).
    static let qGray = Color(light: 0x6C6C70, dark: 0x9EA3A7)
    /// Disabled controls, missed-day rings.
    static let qGray4 = Color(hex: 0xC7C7CC)
    /// Hairline separators and outlines.
    static let qLine = Color(light: 0xECECEE, dark: 0x2A2E2C)
    /// Clean neutral fill for fields, chips and secondary buttons.
    static let qField = Color(light: 0xF5F6F8, dark: 0x12241C)
    /// Brand pastel sage (#9BD9B5): soft fill for selected states, chips and highlights on neutral backgrounds.
    static let qMint = Color(light: 0x9BD9B5, dark: 0x1A4032)
    /// Brand green used as *text or icon* color on neutral backgrounds (lighter in dark mode).
    static let qBrandText = Color(light: 0x08563B, dark: 0x7FD49B)
    /// App background.
    static let qBackground = Color(light: 0xFFFFFF, dark: 0x053424)
    /// Elevated surfaces (sheets, popovers).
    static let qSurface = Color(light: 0xFFFFFF, dark: 0x12241C)
    /// Screen background: clean pure white canvas.
    static let qCanvas = Color(light: 0xFFFFFF, dark: 0x053424)
    /// Feed background behind the white answer cards.
    static let qFeedCanvas = Color(light: 0xFFFFFF, dark: 0x053424)
    /// White rounded block that sits on `qCanvas`.
    static let qBlock = Color(light: 0xFFFFFF, dark: 0x0E261D)

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
    /// UI text in Inter at the exact size, scaling with Dynamic Type relative to the nearest
    /// Apple text style. Weights: 400 / 500 / 600 / 700.
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(interName(weight), size: size, relativeTo: scale(size).1)
    }

    private static func interName(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: return "Inter-Bold"
        case .semibold: return "Inter-SemiBold"
        case .medium: return "Inter-Medium"
        default: return "Inter-Regular"
        }
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
    /// Gray on white screens; white (`qBlock`) on the gray canvas.
    var fill: Color = .qField
    func body(content: Content) -> some View {
        content
            .font(.ui(17))
            .padding(.horizontal, DS.Space.m)
            .frame(minHeight: 50)
            .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(fill))
    }
}

extension View {
    func queslyField(fill: Color = .qField) -> some View { modifier(QueslyFieldStyle(fill: fill)) }

    /// White rounded block on the gray canvas (Revolut / N26-style screens).
    func block(padding: CGFloat = DS.Space.m) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .outlinedBlock()
    }

    /// Rounded white block with a whisper-thin border so it stays crisp on both white and gray surfaces.
    func outlinedBlock(radius: CGFloat = DS.Radius.l) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background(shape.fill(Color.qBlock))
            .overlay(shape.strokeBorder(Color.qLine.opacity(0.65), lineWidth: 0.5))
    }

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
