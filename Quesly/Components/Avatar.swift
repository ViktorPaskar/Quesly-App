import SwiftUI
import UIKit

/// User avatar: the signed-in user's own photo when set, otherwise the bundled demo photo
/// (`Assets/Avatars/avatar-<id>`, demo photos shared with quesly.me), otherwise initials on a soft tint.
/// Works without an `AppStore` in the environment (e.g. inside `ImageRenderer` for story cards).
struct Avatar: View {
    let user: AppUser?
    var size: CGFloat = 40
    var showsBadge = false
    var isSticker = false

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
        .overlay {
            if isSticker {
                Circle().strokeBorder(.white, lineWidth: max(2, size * 0.045))
            }
        }
        .shadow(color: isSticker ? .black.opacity(0.10) : .clear, radius: 6, y: 2)
        .overlay(alignment: .bottomTrailing) {
            if showsBadge, let badge = user?.badge {
                HexBadge(tier: badge)
                    .frame(width: size * 0.34, height: size * 0.38)
                    .offset(x: size * 0.04, y: size * 0.04)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Up to two overlapping avatars ("Anna and 3 others"). Two keeps initials legible.
/// A person's photo with the Threads-style lime "+" under it while you don't follow them yet.
/// One tap follows; the badge then pops away.
struct FollowableAvatar: View {
    @Environment(AppStore.self) private var store
    let user: AppUser?
    var size: CGFloat = 40

    private var canFollow: Bool {
        guard let user else { return false }
        return user.id != store.me.id && !store.isFollowing(user.id)
    }

    var body: some View {
        let badge = (size * 0.4).rounded()
        Avatar(user: user, size: size)
            .overlay(alignment: .bottom) {
                if canFollow, let user {
                    Button {
                        withAnimation(.qSpring) { store.toggleFollow(user.id) }
                    } label: {
                        ZStack {
                            Circle().fill(Color.qLime)
                                .overlay(Circle().strokeBorder(Color.qGreen.opacity(0.25), lineWidth: 0.75))
                            Capsule().fill(Color.qGreen).frame(width: 2, height: badge * 0.5)
                            Capsule().fill(Color.qGreen).frame(width: badge * 0.5, height: 2)
                        }
                        .frame(width: badge, height: badge)
                        .overlay(Circle().stroke(Color.qBackground, lineWidth: 2))
                        .padding(10)
                        .contentShape(Rectangle())
                        .padding(-10)
                    }
                    .buttonStyle(.pressable)
                    .offset(y: badge * 0.45)
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel("Follow \(user.username)")
                }
            }
            .sensoryFeedback(.success, trigger: canFollow) { was, now in was && !now }
            .animation(.qSpring, value: canFollow)
    }
}

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
