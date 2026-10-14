import SwiftUI

/// Find people: search, invite and suggestions. Replaces the old Archive tab
/// (your answers + saved now live in Profile).
struct DiscoverView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var suggestions: [AppUser] = []

    var body: some View {
        let results = store.searchUsers(query)
        // Native large title that collapses on scroll, with the system search bar under it.
        ScrollView {
                LazyVStack(spacing: 0) {
                    if query.isEmpty {
                        InviteCard(username: store.me.username)
                            .padding(.vertical, 8)
                        SectionLabel("Suggested for you")
                        ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, user in
                            PersonRow(user: user).staggeredAppear(index)
                        }
                        if !store.followingUsers.isEmpty {
                            SectionLabel("You follow").padding(.top, 8)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(store.followingUsers) { user in
                                        NavigationLink(value: Route.profile(user.id)) {
                                            VStack(spacing: 8) {
                                                Avatar(user: user, size: 58)
                                                Text(user.username)
                                                    .font(.ui(12, .medium))
                                                    .foregroundStyle(Color.qInk)
                                                    .lineLimit(1)
                                                    .frame(width: 70)
                                            }
                                        }
                                        .buttonStyle(.pressable)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } else if results.isEmpty {
                        EmptyStateView(icon: .magnifyingGlass,
                                       title: "No one found",
                                       message: "Nobody called “\(query)” yet. Invite them to Quesly!")
                    } else {
                        ForEach(results) { user in PersonRow(user: user) }
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, 16)
                .animation(.qSmooth, value: query.isEmpty)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color.qBackground)
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search people")
        .onAppear {
            // Snapshot so followed people don't vanish mid-scroll.
            if suggestions.isEmpty { suggestions = store.suggestedUsers }
        }
    }
}
