import SwiftUI
import UIKit

/// The app's icon vocabulary, one name per concept. Rendered from the UIcons "Regular Rounded" set
/// by Flaticon (template SVGs `Assets/Icons/ui-<case>`, attribution in Settings) when an asset exists,
/// otherwise from the SF Symbol in the raw value. System menus keep SF Symbols (system chrome).
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
    case gearSix = "gearshape", gearSixFill = "gearshape.fill"
    case dotsThreeBold = "ellipsis"

    // Navigation & controls
    case caretLeftBold = "chevron.left", caretRightBold = "chevron.right"
    case xBold = "xmark", xCircleFill = "xmark.circle.fill"
    case arrowRightBold = "arrow.right", arrowUpRightBold = "arrow.up.right"
    case checkBold = "checkmark", checkCircleFill = "checkmark.circle.fill"
    case plusCircleFill = "plus.circle.fill"
    case eye = "eye", eyeSlash = "eye.slash"

    // Content & status
    case wifiSlash = "wifi.slash"
    case clock = "clock", timer = "timer", hourglassMediumFill = "hourglass"
    case lockSimpleFill = "lock.fill", mapPinFill = "mappin.and.ellipse"
    case globeHemisphereWestFill = "globe.europe.africa.fill"
    case usersFill = "person.2.fill", usersThreeFill = "person.3.fill", userPlusFill = "person.badge.plus"
    case pushPinFill = "pin.fill", fireFill = "flame.fill"
    case snowflake = "snowflake", calendar = "calendar", info = "info.circle"
    case sealCheckFill = "checkmark.seal.fill", shieldCheckFill = "checkmark.shield.fill"
    case starFill = "star.fill", sunFill = "sun.max.fill", sparkleFill = "sparkles"
    case medalFill = "medal.fill", crownSimpleFill = "crown.fill"
    case handWavingFill = "hand.wave.fill", leafFill = "leaf.fill", lightningFill = "bolt.fill"
    case footprintsFill = "figure.walk", chatCircleTextFill = "text.bubble.fill", cameraFill = "camera.fill"

    /// Asset name of the UIcons glyph for this concept.
    var assetName: String { "ui-" + String(describing: self) }

    /// Whether the brand icon set covers this concept (else the SF Symbol is used).
    var hasAsset: Bool { UIImage(named: assetName) != nil }

    /// Chevrons, close and check marks read better slightly heavier.
    var defaultWeight: Font.Weight {
        switch self {
        case .caretLeftBold, .caretRightBold, .xBold, .checkBold, .arrowRightBold, .arrowUpRightBold: return .semibold
        default: return .regular
        }
    }
}

/// Renders a `QIcon` at a given optical size (the glyph's approximate width in points).
struct Icon: View {
    let icon: QIcon
    var size: CGFloat
    var weight: Font.Weight?

    init(_ icon: QIcon, size: CGFloat = 22, weight: Font.Weight? = nil) {
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
    var size: CGFloat = 15

    init(_ title: String, icon: QIcon, size: CGFloat = 15) {
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
