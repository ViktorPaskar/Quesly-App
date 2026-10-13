import SwiftUI

/// Phosphor icons (MIT, phosphoricons.com), bundled as template SVGs in Assets.xcassets/Icons.
/// Generated list — add new icons by dropping `ph.<name>.imageset` folders and a case here.
enum Ph: String, CaseIterable {
    case house = "house"
    case magnifyingGlass = "magnifying-glass"
    case bell = "bell"
    case user = "user"
    case bookmarkSimple = "bookmark-simple"
    case smiley = "smiley"
    case dotsThree = "dots-three"
    case paperPlaneTilt = "paper-plane-tilt"
    case export = "export"
    case x = "x"
    case caretLeft = "caret-left"
    case caretRight = "caret-right"
    case mapPin = "map-pin"
    case gearSix = "gear-six"
    case pencilSimple = "pencil-simple"
    case copy = "copy"
    case trash = "trash"
    case flag = "flag"
    case prohibit = "prohibit"
    case clock = "clock"
    case hourglassMedium = "hourglass-medium"
    case timer = "timer"
    case arrowRight = "arrow-right"
    case arrowUpRight = "arrow-up-right"
    case check = "check"
    case plus = "plus"
    case eye = "eye"
    case eyeSlash = "eye-slash"
    case lockSimple = "lock-simple"
    case downloadSimple = "download-simple"
    case globeHemisphereWest = "globe-hemisphere-west"
    case users = "users"
    case usersThree = "users-three"
    case shareNetwork = "share-network"
    case chatCircleText = "chat-circle-text"
    case linkSimple = "link-simple"
    case star = "star"
    case signOut = "sign-out"
    case sealCheck = "seal-check"
    case trophy = "trophy"
    case calendarBlank = "calendar-blank"
    case sparkle = "sparkle"
    case camera = "camera"
    case at = "at"
    case quotes = "quotes"
    case bellSimple = "bell-simple"
    case houseFill = "house-fill"
    case bellFill = "bell-fill"
    case userFill = "user-fill"
    case bookmarkSimpleFill = "bookmark-simple-fill"
    case smileyFill = "smiley-fill"
    case paperPlaneTiltFill = "paper-plane-tilt-fill"
    case pushPinFill = "push-pin-fill"
    case fireFill = "fire-fill"
    case sealCheckFill = "seal-check-fill"
    case starFill = "star-fill"
    case checkCircleFill = "check-circle-fill"
    case xCircleFill = "x-circle-fill"
    case plusCircleFill = "plus-circle-fill"
    case globeHemisphereWestFill = "globe-hemisphere-west-fill"
    case usersFill = "users-fill"
    case usersThreeFill = "users-three-fill"
    case lockSimpleFill = "lock-simple-fill"
    case crownSimpleFill = "crown-simple-fill"
    case handWavingFill = "hand-waving-fill"
    case sunFill = "sun-fill"
    case heartFill = "heart-fill"
    case trophyFill = "trophy-fill"
    case medalFill = "medal-fill"
    case gearSixFill = "gear-six-fill"
    case chatCircleTextFill = "chat-circle-text-fill"
    case prohibitFill = "prohibit-fill"
    case sparkleFill = "sparkle-fill"
    case bellRingingFill = "bell-ringing-fill"
    case userPlusFill = "user-plus-fill"
    case confettiFill = "confetti-fill"
    case cameraFill = "camera-fill"
    case mapPinFill = "map-pin-fill"
    case envelopeSimpleFill = "envelope-simple-fill"
    case shieldCheckFill = "shield-check-fill"
    case leafFill = "leaf-fill"
    case footprintsFill = "footprints-fill"
    case lightningFill = "lightning-fill"
    case hourglassMediumFill = "hourglass-medium-fill"
    case shareNetworkFill = "share-network-fill"
    case exportFill = "export-fill"
    case pencilSimpleFill = "pencil-simple-fill"
    case paperPlaneRightFill = "paper-plane-right-fill"
    case flagFill = "flag-fill"
    case magnifyingGlassBold = "magnifying-glass-bold"
    case userPlusBold = "user-plus-bold"
    case checkBold = "check-bold"
    case plusBold = "plus-bold"
    case xBold = "x-bold"
    case caretLeftBold = "caret-left-bold"
    case caretRightBold = "caret-right-bold"
    case arrowRightBold = "arrow-right-bold"
    case arrowUpRightBold = "arrow-up-right-bold"
    case dotsThreeBold = "dots-three-bold"

    var assetName: String { "ph." + rawValue }
}

/// A Phosphor icon rendered as a template image (tinted by `foregroundStyle`).
struct Icon: View {
    let icon: Ph
    var size: CGFloat = 22

    init(_ icon: Ph, size: CGFloat = 22) {
        self.icon = icon
        self.size = size
    }

    var body: some View {
        Image(icon.assetName)
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Springy "pop" used instead of `symbolEffect` for custom icons.
struct PopOnChange<Value: Equatable>: ViewModifier {
    let value: Value
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: value) { _, _ in
                scale = 0.7
                withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) { scale = 1 }
            }
    }
}

extension View {
    func pop<V: Equatable>(on value: V) -> some View { modifier(PopOnChange(value: value)) }
}
