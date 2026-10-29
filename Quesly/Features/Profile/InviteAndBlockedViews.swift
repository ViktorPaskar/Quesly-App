import SwiftUI

struct InviteFriendsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            HexBadge(color: Color(hex: 0xE84FA5), icon: .smileyFill)
                .frame(width: 110)
            Text("Invite your friends")
                .font(.display(28, .semibold))
                .foregroundStyle(Color.qInk)
            Text("Quesly is better with people you care about. Invite 10 friends to unlock the **Vibe Connector** badge.")
                .font(.ui(16))
                .foregroundStyle(Color.qGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 8) {
                ProgressView(value: 7, total: 10).tint(Color(hex: 0xE84FA5))
                Text("7 of 10 friends joined").font(.ui(15)).foregroundStyle(Color.qGray)
            }
            .padding(.horizontal, 48)
            .padding(.top, 8)

            Spacer()
            ShareLink(item: Invite.text(for: store.me.username)) {
                Text("Share invite link")
                    .font(.ui(17, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(Color.qGreen))
            }
            .buttonStyle(.pressable)
            .padding(.horizontal, DS.Space.screen)
            .padding(.bottom, 24)
        }
        .background(Color.qBackground)
        .queslyBackHeader("Invite friends")
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
                                Text(user.username).font(.ui(16, .semibold))
                                Spacer()
                                Button("Unblock") { withAnimation(.qSmooth) { store.unblock(user.id) } }
                                    .font(.ui(14, .semibold))
                                    .foregroundStyle(Color.qInk)
                                    .padding(.horizontal, 16)
                                    .frame(height: 34)
                                    .background(Capsule().fill(Color.qField))
                                    .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, DS.Space.screen)
                }
            }
        }
        .background(Color.qBackground)
        .queslyBackHeader("Blocked people")
    }
}
