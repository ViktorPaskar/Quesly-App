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
            SearchField(text: $query)
                .padding(16)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, user in
                        PersonRow(user: user).staggeredAppear(index)
                    }
                    if filtered.isEmpty {
                        EmptyStateView(icon: .userFill, title: "No one here yet",
                                       message: "Find people to follow in Discover.")
                    }
                }
                .padding(.horizontal, DS.Space.screen)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(Color.qBackground)
        .queslyBackHeader(kind == .following ? "Following" : "Followers")
        .onAppear {
            if people.isEmpty {
                people = kind == .following ? store.followingUsers : store.followerUsers
            }
        }
    }
}
