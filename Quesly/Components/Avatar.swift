import SwiftUI

/// Generated avatar (initials on a tinted gradient). Swap for AsyncImage once users have photos.
struct Avatar: View {
    let user: AppUser?
    var size: CGFloat = 40
    var showsBadge = false

    var body: some View {
        let hue = user?.avatarHue ?? 0.4
        Circle()
            .fill(LinearGradient(
                colors: [Color(hue: hue, saturation: 0.32, brightness: 0.98),
                         Color(hue: hue, saturation: 0.62, brightness: 0.72)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                Text(user?.initials ?? "?")
                    .font(.custom("Outfit-SemiBold", fixedSize: size * 0.38))
                    .foregroundStyle(.white)
            )
            .frame(width: size, height: size)
            .overlay(alignment: .bottomTrailing) {
                if showsBadge, let badge = user?.badge {
                    HexBadge(color: badge.color, symbol: badge.symbol)
                        .frame(width: size * 0.3, height: size * 0.3)
                        .padding(3)
                        .background(Circle().fill(.white))
                        .offset(x: -size * 0.01, y: -size * 0.01)
                }
            }
            .accessibilityHidden(true)
    }
}

/// Up to three overlapping avatars ("Anna and 3 others").
struct AvatarStack: View {
    let users: [AppUser]
    var size: CGFloat = 34

    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(users.prefix(3).enumerated()), id: \.element.id) { index, user in
                Avatar(user: user, size: size)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .offset(x: CGFloat(index) * size * 0.55)
                    .zIndex(Double(3 - index))
            }
        }
        .frame(width: size + CGFloat(max(0, min(users.count, 3) - 1)) * size * 0.55, height: size, alignment: .leading)
    }
}
