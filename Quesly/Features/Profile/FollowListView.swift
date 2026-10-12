import SwiftUI

struct FollowListView: View {
    enum Kind { case following, followers }

    @Environment(AppStore.self) private var store
    let kind: Kind
    @State private var query = ""
    /// Snapshot so un-following doesn't make rows disappear mid-tap.
    @State private var people: [AppUser] = []

    private var filtered: [AppUser] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty ? people : people.filter { $0.username.lowercased().contains(q) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 13)).foregroundStyle(Color.qGray)
                TextField("Search", text: $query)
                    .font(.quesly(14))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.qField))
            .padding(16)

            List(filtered) { user in
                HStack(spacing: 12) {
                    NavigationLink(value: Route.profile(user.id)) {
                        HStack(spacing: 12) {
                            Avatar(user: user, size: 40)
                            Text(user.username).font(.quesly(15, .medium)).foregroundStyle(Color.qInk)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    let following = store.isFollowing(user.id)
                    Button { store.toggleFollow(user.id) } label: {
                        Text(following ? "Followed" : "Follow")
                            .font(.quesly(11, .medium))
                            .foregroundStyle(following ? Color.qGreen : .white)
                            .frame(width: 76, height: 28)
                            .background(RoundedRectangle(cornerRadius: 6)
                                .fill(following ? Color.qGreen.opacity(0.08) : Color.qGreen))
                    }
                    .buttonStyle(.borderless)
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
        }
        .background(Color.white)
        .queslyBackHeader(kind == .following ? "Following" : "Followers")
        .onAppear {
            if people.isEmpty {
                people = kind == .following ? store.followingUsers : store.followerUsers
            }
        }
    }
}
