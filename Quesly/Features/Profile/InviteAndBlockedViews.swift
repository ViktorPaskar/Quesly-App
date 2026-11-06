import SwiftUI

/// "2 of 3 friends" progress toward the Vibe Connector badge.
private struct FriendGoalProgress: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(store.friendGoalProgress), total: Double(AppStore.friendGoal))
                .tint(Color.qGreen)
            Text("\(store.friendGoalProgress) of \(AppStore.friendGoal) friends")
                .font(.ui(15))
                .foregroundStyle(Color.qGray)
        }
    }
}

/// Friends feed when you follow nobody yet: the invite is the screen's one main action.
struct NoFriendsInvitePrompt: View {
    @Environment(AppStore.self) private var store
    var onDiscover: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HexBadge(asset: "badge-vibe", isLocked: !store.hasVibeBadge)
                    .frame(width: 44, height: 50)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quesly is better with friends")
                        .font(.ui(16, .semibold))
                        .foregroundStyle(Color.qInk)
                    Text(store.hasVibeBadge
                         ? "Invite friends to see their answers here."
                         : "Add \(AppStore.friendGoal) to see their answers and unlock **Vibe Connector**.")
                        .font(.ui(14))
                        .foregroundStyle(Color.qGray)
                }
                Spacer(minLength: 0)
            }

            if !store.hasVibeBadge {
                FriendGoalProgress()
            }

            HStack(spacing: 8) {
                ShareLink(item: Invite.text(for: store.me.username)) {
                    Text("Invite friends")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: DS.hitTarget)
                        .background(Capsule().fill(Color.qGreen))
                }
                .buttonStyle(.pressable)
                Button(action: onDiscover) {
                    Text("Find people")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(Color.qBrandText)
                        .frame(maxWidth: .infinity).frame(height: DS.hitTarget)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.qField))
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, DS.Space.s)
    }
}

/// Quiet reminder at the end of the Friends feed while you have 1–2 of the 3 friends.
struct FriendGoalNudge: View {
    @Environment(AppStore.self) private var store
    var onDiscover: () -> Void

    private var remaining: Int { AppStore.friendGoal - store.friendGoalProgress }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HexBadge(asset: "badge-vibe", isLocked: true)
                    .frame(width: 36, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add \(remaining) more \(remaining == 1 ? "friend" : "friends")")
                        .font(.ui(16, .semibold))
                        .foregroundStyle(Color.qInk)
                    Text("Unlock the Vibe Connector badge")
                        .font(.ui(14))
                        .foregroundStyle(Color.qGray)
                }
                Spacer(minLength: 0)
            }
            FriendGoalProgress()
            HStack(spacing: 8) {
                ShareLink(item: Invite.text(for: store.me.username)) {
                    Text("Invite")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: DS.hitTarget)
                        .background(Capsule().fill(Color.qGreen))
                }
                .buttonStyle(.pressable)
                Button(action: onDiscover) {
                    Text("Find people")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(Color.qBrandText)
                        .frame(maxWidth: .infinity).frame(height: DS.hitTarget)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(16)
        // The feed canvas is white, so this block sits on the neutral field color.
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.qField))
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, DS.Space.s)
    }
}

struct InviteFriendsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            HexBadge(asset: "badge-vibe", isLocked: !store.hasVibeBadge)
                .frame(width: 110, height: 125)
            Text("Invite your friends")
                .font(.display(28, .semibold))
                .foregroundStyle(Color.qInk)
            Text(store.hasVibeBadge
                 ? "Quesly is better with people you care about. You've unlocked the **Vibe Connector** badge."
                 : "Quesly is better with people you care about. Add \(AppStore.friendGoal) friends to unlock the **Vibe Connector** badge.")
                .font(.ui(16))
                .foregroundStyle(Color.qGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            FriendGoalProgress()
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
