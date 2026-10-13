import SwiftUI

struct NotificationsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let groups = store.groupedNotifications
        VStack(spacing: 0) {
            TitleHeader(title: "Notifications")
            Rectangle().fill(Color.qLine).frame(height: 1)

            if groups.isEmpty {
                EmptyStateView(icon: .bellRingingFill, title: "All caught up",
                               message: "Reactions, new followers and badges will show up here.")
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                            row(group)
                                .padding(.horizontal, DS.Space.screen)
                                .padding(.vertical, 12)
                                .overlay(alignment: .leading) {
                                    if group.date > store.notificationsSeenAt {
                                        Circle().fill(Color.qGreen).frame(width: 8, height: 8).padding(.leading, 6)
                                            .accessibilityLabel("Unread")
                                    }
                                }
                                .staggeredAppear(index)
                        }
                    }
                }
            }
        }
        .background(Color.qBackground)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { store.markNotificationsSeen() }
    }

    @ViewBuilder
    private func row(_ group: NotificationGroup) -> some View {
        let actors = group.actorIds.compactMap { store.user($0) }
        let content = HStack(alignment: .top, spacing: 12) {
            leading(group, actors: actors)
            VStack(alignment: .leading, spacing: 4) {
                title(group, actors: actors)
                    .font(.ui(15))
                    .foregroundStyle(Color.qInk)
                    .fixedSize(horizontal: false, vertical: true)
                if let answerId = group.answerId, let answer = store.answer(answerId) {
                    Text("“\(answer.text)”")
                        .font(.ui(14))
                        .foregroundStyle(Color.qGray)
                        .lineLimit(1)
                }
                Text(RelativeTime.short(group.date))
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
            }
            Spacer(minLength: 8)
            if group.kind == .follow, let actor = actors.first {
                FollowPill(isFollowing: store.isFollowing(actor.id), compact: true) { store.toggleFollow(actor.id) }
            }
        }

        if group.kind == .badge {
            NavigationLink(value: Route.achievements) { content }.buttonStyle(.plain)
        } else if actors.count == 1, let actor = actors.first {
            NavigationLink(value: Route.profile(actor.id)) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }

    @ViewBuilder
    private func leading(_ group: NotificationGroup, actors: [AppUser]) -> some View {
        switch group.kind {
        case .reaction, .follow:
            ZStack(alignment: .bottomTrailing) {
                AvatarStack(users: actors, size: 40)
                if let r = group.reactions.first {
                    Text(r.emoji)
                        .font(.system(size: 13))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.white))
                        .overlay(Circle().stroke(Color.qLine))
                        .offset(x: 4, y: 4)
                } else if group.kind == .follow {
                    Icon(.userPlusFill, size: 12)
                        .foregroundStyle(Color.qLime)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.qGreen))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(x: 4, y: 4)
                }
            }
        case .badge:
            Icon(.medalFill, size: 22)
                .foregroundStyle(Color.qGreen)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.qLime))
        case .posted:
            QueslyMark(color: .qLime, cutout: .qGreen)
                .frame(width: 20)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.qGreen))
        }
    }

    private func title(_ group: NotificationGroup, actors: [AppUser]) -> Text {
        func bold(_ s: String) -> AttributedString {
            var a = AttributedString(s)
            a.font = .ui(15, .semibold)
            return a
        }
        var text = AttributedString()
        switch group.kind {
        case .reaction:
            guard let first = actors.first else { return Text("New reactions") }
            text += bold(first.username)
            if actors.count == 2 {
                text += AttributedString(" and ")
                text += bold(actors[1].username)
            } else if actors.count > 2 {
                text += AttributedString(" and ")
                text += bold("\(actors.count - 1) others")
            }
            text += AttributedString(" reacted \(group.reactions.map(\.emoji).joined()) to your answer")
        case .follow:
            text += bold(actors.first?.username ?? "Someone")
            text += AttributedString(" started following you")
        case .badge, .posted:
            text = (try? AttributedString(markdown: group.message)) ?? AttributedString(group.message)
        }
        return Text(text)
    }
}
