import SwiftUI
import UIKit

/// User avatar: the signed-in user's own photo when set, otherwise the bundled illustration
/// (`Assets/Avatars/avatar-<id>`, Notionists by Zoish, CC0), otherwise initials on a soft tint.
/// Works without an `AppStore` in the environment (e.g. inside `ImageRenderer` for story cards).
struct Avatar: View {
    let user: AppUser?
    var size: CGFloat = 40
    var showsBadge = false
    var sticker = true

    @Environment(AppStore.self) private var store: AppStore?
    @Environment(\.colorScheme) private var colorScheme

    private var photo: UIImage? {
        guard let user else { return nil }
        if let store, user.id == store.me.id, let mine = store.myPhoto { return mine }
        return UIImage(named: "avatar-\(user.id)")
    }

    var body: some View {
        let hue = user?.avatarHue ?? 0.4
        let dark = colorScheme == .dark
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(hue: hue, saturation: dark ? 0.35 : 0.22, brightness: dark ? 0.32 : 0.93)
                    .overlay(
                        Text(user?.initials ?? "?")
                            .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hue: hue, saturation: dark ? 0.35 : 0.65, brightness: dark ? 0.92 : 0.42))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        // Brand "sticker" look: white rim and a soft lift, like the stickers on quesly.me.
        .overlay {
            if sticker { Circle().strokeBorder(.white, lineWidth: max(1.5, size * 0.05)) }
        }
        .shadow(color: sticker ? Color(hex: 0x022A1E).opacity(0.14) : .clear, radius: size * 0.06, y: size * 0.03)
        .overlay(alignment: .bottomTrailing) {
            if showsBadge, let badge = user?.badge {
                HexBadge(color: badge.color, icon: badge.icon)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .padding(DS.Space.xxs)
                    .background(Circle().fill(Color.qBackground))
                    .offset(x: -size * 0.01, y: -size * 0.01)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Up to two overlapping avatars ("Anna and 3 others"). Two keeps initials legible.
struct AvatarStack: View {
    let users: [AppUser]
    var size: CGFloat = 34
    /// Separator ring between avatars — match the surface they sit on.
    var ring: Color = .qBackground

    private var shown: [AppUser] { Array(users.prefix(2)) }
    private var step: CGFloat { size * 0.62 }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, user in
                Avatar(user: user, size: size)
                    .overlay(Circle().stroke(ring, lineWidth: 2))
                    .offset(x: CGFloat(index) * step)
                    .zIndex(Double(2 - index))
            }
        }
        .frame(width: size + CGFloat(max(0, shown.count - 1)) * step, height: size, alignment: .leading)
    }
}
