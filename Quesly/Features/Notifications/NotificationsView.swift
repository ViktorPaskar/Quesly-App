import SwiftUI

struct NotificationsView: View {
    @Environment(AppStore.self) private var store
    @State private var reactionAnswer: Answer?
    @State private var memoryAnswer: Answer?

    var body: some View {
        let groups = store.groupedNotifications
        // Native large title that collapses on scroll.
        ScrollView {
            if groups.isEmpty {
                EmptyStateView(icon: .bellRingingFill, title: "All caught up",
                               message: "Reactions, new followers and badges will show up here.")
            } else {
                // "Today" and "Earlier", each a white block on the gray canvas.
                let today = groups.filter { Calendar.current.isDateInToday($0.date) }
                let earlier = groups.filter { !Calendar.current.isDateInToday($0.date) }
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    section("Today", today)
                    section("Earlier", earlier)
                }
                .padding(.horizontal, DS.Space.m)
                .padding(.bottom, DS.Space.l)
            }
        }
        .background(Color.qCanvas)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .onDisappear { store.markNotificationsSeen() }
        .sheet(item: $reactionAnswer) { answer in
            ReactionsSheet(answer: answer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
        .sheet(item: $memoryAnswer) { answer in
            MemoryDetailSheet(answer: answer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [NotificationGroup]) -> some View {
        if !items.isEmpty {
            Text(title)
                .font(.ui(15, .semibold))
                .foregroundStyle(Color.qGray)
                .padding(.horizontal, DS.Space.xs)
                .padding(.top, DS.Space.s)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, group in
                    if index > 0 { Rectangle().fill(Color.qLine).frame(height: 1).padding(.leading, 68) }
                    row(group)
                        .padding(.horizontal, DS.Space.m)
                        .padding(.vertical, 12)
                        .overlay(alignment: .leading) {
                            if group.date > store.notificationsSeenAt {
                                Circle().fill(Color.qGreen).frame(width: 7, height: 7).padding(.leading, 5)
                                    .accessibilityLabel("Unread")
                            }
                        }
                        .staggeredAppear(index)
                }
            }
            .outlinedBlock()
        }
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
                        .font(.ui(15))
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
            NavigationLink(value: Route.achievements) { content.contentShape(Rectangle()) }.buttonStyle(.plain)
        } else if group.kind == .reaction, let answerId = group.answerId, let answer = store.answer(answerId) {
            Button { reactionAnswer = answer } label: { content.contentShape(Rectangle()) }.buttonStyle(.plain)
        } else if group.kind == .posted, let answer = group.answerId.flatMap({ store.answer($0) }) ?? store.todaysAnswer {
            Button { memoryAnswer = answer } label: { content.contentShape(Rectangle()) }.buttonStyle(.plain)
        } else if let actor = actors.first {
            NavigationLink(value: Route.profile(actor.id)) { content.contentShape(Rectangle()) }.buttonStyle(.plain)
        } else {
            content
        }
    }

    @ViewBuilder
    private func leading(_ group: NotificationGroup, actors: [AppUser]) -> some View {
        switch group.kind {
        case .reaction, .follow:
            ZStack(alignment: .bottomTrailing) {
                Avatar(user: actors.first, size: 40)
                if let r = group.reactions.first {
                    ReactionSticker(kind: r, size: 28)
                        .offset(x: 4, y: 4)
                } else if group.kind == .follow {
                    Icon(.userPlusFill, size: DS.Icon.caption)
                        .foregroundStyle(Color.qLime)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.qGreen))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(x: 4, y: 4)
                }
            }
        case .badge:
            Icon(.medalFill, size: DS.Icon.action)
                .foregroundStyle(Color.qGreen)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.qLime))
        case .posted:
            QueslyMark(color: .qLime, cutout: .qGreen)
                .frame(width: 26)
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
            text += AttributedString(" reacted to your answer")
        case .follow:
            text += bold(actors.first?.username ?? "Someone")
            text += AttributedString(" started following you")
        case .badge, .posted:
            text = (try? AttributedString(markdown: group.message)) ?? AttributedString(group.message)
        }
        return Text(text)
    }
}
