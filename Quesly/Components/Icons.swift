import SwiftUI
import UIKit

/// The app's icon vocabulary, one name per concept. Rendered from the UIcons "Regular Rounded" set
/// by Flaticon (template SVGs `Assets/Icons/ui-<case>`; premium licence, no attribution needed) when an asset exists,
/// otherwise from the SF Symbol in the raw value. Every case below has a brand glyph, so content never
/// mixes icon styles; system menus keep SF Symbols (system chrome). Sizes come from `DS.Icon`.
/// Selected state = brand color / lime bubble, not a filled glyph. Always render through `Icon`.
enum QIcon: String {
    // Tabs
    case house = "house", houseFill = "house.fill"
    case magnifyingGlass = "magnifyingglass"
    case bell = "bell", bellFill = "bell.fill", bellRingingFill = "bell.badge.fill"
    case user = "person", userFill = "person.fill"

    // Actions
    case bookmarkSimple = "bookmark", bookmarkSimpleFill = "bookmark.fill"
    case smiley = "face.smiling", smileyFill = "face.smiling.inverse"
    case heart = "heart", heartFill = "heart.fill"
    case paperPlaneTilt = "paperplane", paperPlaneTiltFill = "paperplane.fill"
    case export = "square.and.arrow.up", shareNetworkFill = "square.and.arrow.up.fill"
    case copy = "doc.on.doc", trash = "trash", flag = "flag"
    case pencilSimple = "pencil", pencilSimpleFill = "pencil.line"
    case prohibit = "hand.raised", prohibitFill = "hand.raised.fill"
    case downloadSimple = "arrow.down.to.line"
    /// Repost to your profile. `ui-repost` is drawn to match UIcons Regular Rounded (2-pt rounded strokes, 24 grid).
    case repost = "arrow.2.squarepath"
    case gearSix = "gearshape", gearSixFill = "gearshape.fill"
    case dotsThreeBold = "ellipsis"

    // Navigation & controls
    case caretLeftBold = "chevron.left", caretRightBold = "chevron.right"
    case xBold = "xmark", xCircleFill = "xmark.circle.fill"
    case arrowRightBold = "arrow.right"
    case checkBold = "checkmark", checkCircleFill = "checkmark.circle.fill"
    case plusCircleFill = "plus.circle.fill"
    case eye = "eye", eyeSlash = "eye.slash"

    // Content & status
    case clock = "clock", timer = "timer", hourglassMediumFill = "hourglass"
    case lockSimpleFill = "lock.fill", mapPinFill = "mappin.and.ellipse"
    case globeHemisphereWestFill = "globe.europe.africa.fill"
    case userPlusFill = "person.badge.plus"
    case pushPinFill = "pin.fill", fireFill = "flame.fill"
    case snowflake = "snowflake", calendar = "calendar", info = "info.circle"
    case shieldCheckFill = "checkmark.shield.fill"
    case starFill = "star.fill", sunFill = "sun.max.fill", sparkleFill = "sparkles"
    case medalFill = "medal.fill", crownSimpleFill = "crown.fill"
    case leafFill = "leaf.fill"
    case chatCircleTextFill = "text.bubble.fill", cameraFill = "camera.fill"

    /// Asset name of the UIcons glyph for this concept.
    var assetName: String { "ui-" + String(describing: self) }

    /// Whether the brand icon set covers this concept (else the SF Symbol is used).
    var hasAsset: Bool { UIImage(named: assetName) != nil }

    /// Chevrons, close and check marks read better slightly heavier.
    var defaultWeight: Font.Weight {
        switch self {
        case .caretLeftBold, .caretRightBold, .xBold, .checkBold, .arrowRightBold: return .semibold
        default: return .regular
        }
    }
}

/// Renders a `QIcon` at a given optical size (the glyph's approximate width in points).
struct Icon: View {
    let icon: QIcon
    var size: CGFloat
    var weight: Font.Weight?

    init(_ icon: QIcon, size: CGFloat = DS.Icon.action, weight: Font.Weight? = nil) {
        self.icon = icon
        self.size = size
        self.weight = weight
    }

    var body: some View {
        Group {
            if icon.hasAsset {
                Image(icon.assetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Image(systemName: icon.rawValue)
                    .font(.system(size: size * 0.86, weight: weight ?? icon.defaultWeight))
                    .frame(minWidth: size, minHeight: size)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Icon + text for in-content labels (system `Label` would need an SF Symbol name).
/// Font and color set on the outside apply to both.
struct IconLabel: View {
    let title: String
    let icon: QIcon
    var size: CGFloat = DS.Icon.label

    init(_ title: String, icon: QIcon, size: CGFloat = DS.Icon.label) {
        self.title = title
        self.icon = icon
        self.size = size
    }

    var body: some View {
        HStack(spacing: DS.Space.xxs) {
            Icon(icon, size: size)
            Text(title)
        }
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// A quick scale bounce when `value` changes (works for SVG icons too; off under Reduce Motion).
    func pop<V: Equatable>(on value: V) -> some View {
        modifier(PopEffect(trigger: value))
    }
}

private struct PopEffect<V: Equatable>: ViewModifier {
    let trigger: V
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
            view.scaleEffect(reduceMotion ? 1 : scale)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(1.2, duration: 0.12)
                SpringKeyframe(1.0, duration: 0.35)
            }
        }
    }
}

/// Tinted round icon chip that heads a block or tile (bunq / Revolut style). The tint carries
/// meaning (brand, streak, freeze…); the glyph is always `DS.Icon.inline` in a 34-pt circle.
struct IconChip: View {
    let icon: QIcon
    var tint: Color = .qBrandText
    var fill: Color = .qMint

    var body: some View {
        Icon(icon, size: DS.Icon.inline)
            .foregroundStyle(tint)
            .frame(width: 34, height: 34)
            .background(Circle().fill(fill))
    }
}

extension View {
    /// Lays an action glyph out at its own size, so its visible edge lines up with text and card
    /// edges, while the tap area stays the HIG 44 × 44 pt around it.
    func glyphHitArea() -> some View {
        let inset = (DS.hitTarget - DS.Icon.action) / 2
        return self
            .padding(inset)
            .contentShape(Rectangle())
            .padding(-inset)
    }
}
