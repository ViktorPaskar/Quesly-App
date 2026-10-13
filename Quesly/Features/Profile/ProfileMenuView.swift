import SwiftUI

struct ProfileMenuView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                row("Achievements", .medalFill, Color(hex: 0xE2A72E), .achievements)
                row("Invite Friends", .paperPlaneTiltFill, Color(hex: 0xE84FA5), .invite)
                row("Settings", .gearSixFill, .qGreen, .settings)
                row("Blocked people", .prohibitFill, Color(hex: 0xE5484D), .blocked)
                row("Feedback", .chatCircleTextFill, Color(hex: 0x2D7BF0), .feedback)
            }
            .padding(16)
        }
        .background(Color.white)
        .queslyBackHeader("Profile")
    }

    private func row(_ title: String, _ icon: Ph, _ tint: Color, _ route: Route) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 14) {
                Icon(icon, size: 20)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(tint))
                Text(title).font(.quesly(17, .medium)).foregroundStyle(Color.qInk)
                Spacer()
                Icon(.caretRightBold, size: 16)
                    .foregroundStyle(Color.qGray.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .frame(height: 62)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.qField))
        }
        .buttonStyle(.pressable)
    }
}

struct InviteFriendsView: View {
    @Environment(AppStore.self) private var store
    @State private var wave = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            HexBadge(color: Color(hex: 0xE84FA5), icon: .handWavingFill)
                .frame(width: 110)
                .rotationEffect(.degrees(wave ? 8 : -8))
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: wave)
                .onAppear { wave = true }
            Text("Invite your friends")
                .font(.quesly(28, .bold))
                .foregroundStyle(Color.qInk)
            Text("Quesly is better with people you care about. Invite 10 friends to unlock the **Vibe Connector** badge.")
                .font(.quesly(16))
                .foregroundStyle(Color.qGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 8) {
                ProgressView(value: 7, total: 10).tint(Color(hex: 0xE84FA5))
                Text("7 of 10 friends joined").font(.quesly(14, .medium)).foregroundStyle(Color.qGray)
            }
            .padding(.horizontal, 48)
            .padding(.top, 8)

            Spacer()
            ShareLink(item: Invite.text(for: store.me.username)) {
                Label { Text("Share invite link") } icon: { Icon(.paperPlaneTiltFill, size: 20) }
                    .font(.quesly(17, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(Color.qGreen))
            }
            .buttonStyle(.pressable)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .queslyBackHeader("Invite Friends")
    }
}

struct BlockedUsersView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let blocked = store.blockedIds.compactMap { store.user($0) }.sorted { $0.username < $1.username }
        Group {
            if blocked.isEmpty {
                EmptyStateView(icon: .prohibitFill, title: "No one blocked",
                               message: "People you block won't appear in your feeds, and they won't know.")
                    .frame(maxHeight: .infinity, alignment: .top)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(blocked) { user in
                            HStack(spacing: 12) {
                                Avatar(user: user, size: 44)
                                Text(user.username).font(.quesly(16, .semibold))
                                Spacer()
                                Button("Unblock") { withAnimation(.qSmooth) { store.unblock(user.id) } }
                                    .font(.quesly(14, .semibold))
                                    .foregroundStyle(Color.qGreen)
                                    .padding(.horizontal, 14)
                                    .frame(height: 34)
                                    .background(Capsule().fill(Color.qMint))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(Color.white)
        .queslyBackHeader("Blocked people")
    }
}
