import SwiftUI

struct FollowListView: View {
    enum Kind: String, CaseIterable, Identifiable {
        case friends = "Friends"
        case followers = "Followers"
        case following = "Following"

        var id: String { rawValue }
    }

    @Environment(AppStore.self) private var store
    @State var selectedKind: Kind
    @State private var query = ""

    init(kind: Kind = .friends) {
        _selectedKind = State(initialValue: kind)
    }

    private var currentList: [AppUser] {
        switch selectedKind {
        case .friends: return store.friendUsers
        case .followers: return store.followerUsers
        case .following: return store.followingUsers
        }
    }

    private var filtered: [AppUser] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty ? currentList : currentList.filter { $0.username.lowercased().contains(q) }
    }

    var body: some View {
        VStack(spacing: 0) {
            UnderlineTabs(
                items: Kind.allCases,
                selection: $selectedKind,
                title: \.rawValue
            )

            SearchField(text: $query)
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, DS.Space.s)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, user in
                        PersonRow(user: user).staggeredAppear(index)
                    }
                    if filtered.isEmpty {
                        EmptyStateView(
                            icon: selectedKind == .friends ? .userFill : .userFill,
                            title: selectedKind == .friends ? "No friends yet" : "No one here yet",
                            message: selectedKind == .friends
                                ? "When someone you follow follows you back, they'll appear here as a friend."
                                : "Find people to follow in Discover."
                        )
                    }
                }
                .padding(.horizontal, DS.Space.screen)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(Color.qBackground)
        .queslyBackHeader(selectedKind.rawValue)
    }
}
