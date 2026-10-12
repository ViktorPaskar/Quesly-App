import SwiftUI

/// Generated avatar (initials on a tinted gradient). Swap for AsyncImage once users have photos.
struct Avatar: View {
    let user: AppUser?
    var size: CGFloat = 40
    var showsBadge = false
    var showsAddButton = false

    var body: some View {
        let hue = user?.avatarHue ?? 0.4
        Circle()
            .fill(LinearGradient(
                colors: [Color(hue: hue, saturation: 0.35, brightness: 0.95),
                         Color(hue: hue, saturation: 0.6, brightness: 0.7)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                Text(user?.initials ?? "?")
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(.white)
            )
            .frame(width: size, height: size)
            .overlay(alignment: .bottomTrailing) {
                if showsBadge, let badge = user?.badge {
                    HexBadge(color: badge.color, symbol: "crown.fill")
                        .frame(width: size * 0.28, height: size * 0.28)
                        .padding(2)
                        .background(Circle().fill(.white))
                        .offset(x: -size * 0.02, y: -size * 0.02)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if showsAddButton {
                    Image(systemName: "plus")
                        .font(.system(size: size * 0.2, weight: .bold))
                        .foregroundStyle(Color.qGreen)
                        .frame(width: size * 0.36, height: size * 0.36)
                        .background(Circle().fill(Color.qLime))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(x: -2, y: 2)
                }
            }
            .accessibilityHidden(true)
    }
}
