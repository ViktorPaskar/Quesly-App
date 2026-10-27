import SwiftUI

/// Find people: branded header + search capsule, invite card and suggestions on the gray canvas.
struct DiscoverView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    @State private var suggestions: [AppUser] = []

    var body: some View {
        let results = store.searchUsers(query)
        VStack(spacing: 0) {
            headerBar

            ScrollView {
                LazyVStack(spacing: 0) {
                    if query.isEmpty {
                        InviteCard(username: store.me.username)
                            .padding(.vertical, 8)
                        SectionLabel("Suggested for you")
                        VStack(spacing: 0) {
                            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, user in
                                PersonRow(user: user).staggeredAppear(index)
                            }
                        }
                        .padding(.horizontal, DS.Space.m)
                        .outlinedBlock()
                        if !store.followingUsers.isEmpty {
                            SectionLabel("You follow").padding(.top, 8)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(store.followingUsers) { user in
                                        NavigationLink(value: Route.profile(user.id)) {
                                            VStack(spacing: 8) {
                                                Avatar(user: user, size: 58, showsBadge: true, isSticker: true)
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
                                .padding(.vertical, DS.Space.s)
                                .padding(.horizontal, DS.Space.m)
                            }
                            .outlinedBlock()
                        }
                    } else if results.isEmpty {
                        EmptyStateView(icon: .magnifyingGlass,
                                       title: "No one found",
                                       message: "Nobody called “\(query)” yet. Invite them to Quesly!")
                    } else {
                        VStack(spacing: 0) {
                            ForEach(results) { user in PersonRow(user: user) }
                        }
                        .padding(.horizontal, DS.Space.m)
                        .outlinedBlock()
                        .padding(.top, 12)
                    }
                }
                .padding(.horizontal, DS.Space.m)
                .padding(.bottom, 16)
                .animation(.qSmooth, value: query.isEmpty)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(Color.qCanvas)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if suggestions.isEmpty { suggestions = store.suggestedUsers }
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discover")
                .font(.display(28, .bold))
                .tracking(-0.4)
                .foregroundStyle(Color.qInk)

            HStack(spacing: 10) {
                Icon(.magnifyingGlass, size: 18)
                    .foregroundStyle(Color.qGray)
                TextField("Search people", text: $query)
                    .font(.ui(15))
                    .foregroundStyle(Color.qInk)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Icon(.xCircleFill, size: 18)
                            .foregroundStyle(Color.qGray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Capsule().fill(Color.qField))
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.qBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.qLine).frame(height: 1)
        }
    }
}
