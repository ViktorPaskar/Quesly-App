import SwiftUI

/// Find people: search, invite and suggestions. Replaces the old Archive tab
/// (your answers + saved now live in Profile).
struct DiscoverView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var suggestions: [AppUser] = []

    var body: some View {
        let results = store.searchUsers(query)
        VStack(spacing: 0) {
            TitleHeader(title: "Discover")
            SearchField(text: $query, prompt: "Search people")
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

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
                                HStack(spacing: 14) {
                                    ForEach(store.followingUsers) { user in
                                        NavigationLink(value: Route.profile(user.id)) {
                                            VStack(spacing: 6) {
                                                Avatar(user: user, size: 58)
                                                Text(user.username)
                                                    .font(.quesly(12, .medium))
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
                        EmptyStateView(icon: .magnifyingGlassBold,
                                       title: "No one found",
                                       message: "Nobody called “\(query)” yet. Invite them to Quesly!")
                    } else {
                        ForEach(results) { user in PersonRow(user: user) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .animation(.qSmooth, value: query.isEmpty)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // Snapshot so followed people don't vanish mid-scroll.
            if suggestions.isEmpty { suggestions = store.suggestedUsers }
        }
    }
}
