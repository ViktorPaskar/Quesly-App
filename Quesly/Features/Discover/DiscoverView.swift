import SwiftUI

/// Find people: clean branded header + search bar, invite card, recommendations, and following carousel.
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
                            .padding(.top, 8)
                            .padding(.bottom, 6)

                        VStack(spacing: 0) {
                            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, user in
                                if index > 0 {
                                    Rectangle().fill(Color.qLine.opacity(0.65)).frame(height: 0.5)
                                }
                                PersonRow(user: user)
                                    .padding(.vertical, 8)
                                    .staggeredAppear(index)
                            }
                        }
                        .padding(.horizontal, DS.Space.screen)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.qLine, lineWidth: 1)
                                )
                        )

                        if !store.followingUsers.isEmpty {
                            SectionLabel("You follow")
                                .padding(.top, 16)
                                .padding(.bottom, 6)

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
                                .padding(.horizontal, DS.Space.screen)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.qLine, lineWidth: 1)
                                    )
                            )
                        }
                    } else if results.isEmpty {
                        EmptyStateView(icon: .magnifyingGlass,
                                       title: "No one found",
                                       message: "Nobody called “\(query)” yet. Invite them to Quesly!")
                            .padding(.top, 32)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(results.enumerated()), id: \.element.id) { index, user in
                                if index > 0 {
                                    Rectangle().fill(Color.qLine.opacity(0.65)).frame(height: 0.5)
                                }
                                PersonRow(user: user)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal, DS.Space.screen)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.qLine, lineWidth: 1)
                                )
                        )
                        .padding(.top, 12)
                    }
                }
                .padding(.horizontal, DS.Space.m)
                .padding(.bottom, 24)
                .animation(.qSmooth, value: query.isEmpty)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(Color.qBackground)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if suggestions.isEmpty { suggestions = store.suggestedUsers }
        }
    }

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Discover")
                .font(.display(28, .semibold))
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
                    Button {
                        withAnimation(.qSpring) { query = "" }
                    } label: {
                        Icon(.xCircleFill, size: 18)
                            .foregroundStyle(Color.qGray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.qField)
            )
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
