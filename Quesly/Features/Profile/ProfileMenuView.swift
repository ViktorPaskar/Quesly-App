import SwiftUI

struct ProfileMenuView: View {
    var body: some View {
        List {
            row("Achievements", "checkmark.seal", .achievements)
            row("Invite Friends", "person.badge.plus", .invite)
            row("Settings", "gearshape", .settings)
            row("Feedback", "envelope", .feedback)
        }
        .listStyle(.plain)
        .queslyBackHeader("Profile")
    }

    private func row(_ title: String, _ symbol: String, _ route: Route) -> some View {
        NavigationLink(value: route) {
            Label {
                Text(title).font(.quesly(15)).foregroundStyle(Color.qInk)
            } icon: {
                Image(systemName: symbol).foregroundStyle(Color.qInk)
            }
        }
        .listRowSeparator(.hidden)
    }
}

struct InviteFriendsView: View {
    @Environment(AppStore.self) private var store

    private var inviteText: String {
        "Join me on Quesly — one question a day, millions of stories. Add me: @\(store.me.username) https://quesly.app/invite/\(store.me.username)"
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            HexBadge(color: Color(hex: 0xE84FA5), symbol: "hand.wave.fill")
                .frame(width: 90)
            Text("Invite your friends")
                .font(.quesly(22, .bold))
                .foregroundStyle(Color.qInk)
            Text("Quesly is better with people you care about. Invite 10 friends to unlock the **Vibe Connector** badge.")
                .font(.quesly(15))
                .foregroundStyle(Color.qGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            ShareLink(item: inviteText) {
                Text("Share invite link")
                    .font(.quesly(16, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Capsule().fill(Color.qGreen))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .queslyBackHeader("Invite Friends")
    }
}
