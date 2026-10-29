import SwiftUI

enum NotificationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case reactions = "Reactions"
    case follows = "Follows"
    var id: String { rawValue }
}

struct NotificationsView: View {
    @Environment(AppStore.self) private var store
    @State private var filter: NotificationFilter = .all
    @State private var reactionAnswer: Answer?
    @State private var memoryAnswer: Answer?

    private var filteredGroups: [NotificationGroup] {
        let all = store.groupedNotifications
        switch filter {
        case .all: return all
        case .reactions: return all.filter { $0.kind == .reaction }
        case .follows: return all.filter { $0.kind == .follow }
        }
    }

    var body: some View {
        let groups = filteredGroups
        VStack(spacing: 0) {
            headerBar

            ScrollView {
                if groups.isEmpty {
                    EmptyStateView(icon: .bellRingingFill, title: "All caught up",
                                   message: "Reactions, new followers and milestones will show up here.")
                } else {
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
        }
        .background(Color.qCanvas)
        .toolbar(.hidden, for: .navigationBar)
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

    private var headerBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.display(28, .semibold))
                .tracking(-0.4)
                .foregroundStyle(Color.qInk)

            HStack(spacing: 8) {
                ForEach(NotificationFilter.allCases) { item in
                    let isSelected = filter == item
                    Button {
                        withAnimation(.qSmooth) { filter = item }
                    } label: {
                        Text(item.rawValue)
                            .font(.ui(13, .semibold))
                            .foregroundStyle(isSelected ? Color.qLime : Color.qInk2)
                            .padding(.horizontal, 14)
                            .frame(height: 32)
                            .background(
                                Capsule().fill(isSelected ? Color.qGreen : Color.qField)
                            )
                    }
                    .buttonStyle(.pressable)
                }
                Spacer()
            }
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color.qBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.qLine).frame(height: 1)
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
                    if index > 0 { Rectangle().fill(Color.qLine).frame(height: 1).padding(.leading, 70) }
                    row(group)
                        .padding(.horizontal, DS.Space.m)
                        .padding(.vertical, 13)
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

    private func cleanSnippet(_ raw: String) -> String {
        let quoteChars = CharacterSet(charactersIn: "\"“”'‘’")
        return raw.trimmingCharacters(in: quoteChars)
    }

    @ViewBuilder
    private func row(_ group: NotificationGroup) -> some View {
        let actors = group.actorIds.compactMap { store.user($0) }
        let content = HStack(alignment: .center, spacing: 12) {
            leading(group, actors: actors)
            VStack(alignment: .leading, spacing: 3) {
                title(group, actors: actors)
                    .font(.ui(15))
                    .foregroundStyle(Color.qInk)
                    .fixedSize(horizontal: false, vertical: true)
                if let answerId = group.answerId, let answer = store.answer(answerId) {
                    Text("“\(cleanSnippet(answer.text))”")
                        .font(.ui(14))
                        .foregroundStyle(Color.qGray)
                        .lineLimit(1)
                }
                Text(RelativeTime.short(group.date))
                    .font(.ui(12))
                    .foregroundStyle(Color.qGray)
            }
            Spacer(minLength: 8)
            if group.kind == .reaction, let r = group.reactions.first {
                ReactionSticker(kind: r, size: 32)
            } else if group.kind == .follow, let actor = actors.first {
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
            Avatar(user: actors.first, size: 42, isSticker: true)
        case .badge:
            HexBadge(asset: "badge-streak3")
                .frame(width: 40, height: 44)
        case .posted:
            QueslyMark(color: .qLime, cutout: .qGreen)
                .frame(width: 24)
                .frame(width: 42, height: 42)
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
