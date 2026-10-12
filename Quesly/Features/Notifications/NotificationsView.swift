import SwiftUI

struct NotificationsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            Text("Notifications")
                .font(.quesly(18, .medium))
                .foregroundStyle(Color.qInk)
                .padding(.vertical, 12)
            Divider()

            if store.notifications.isEmpty {
                ContentUnavailableView("All caught up", systemImage: "bell",
                                       description: Text("Reactions and new badges will show up here."))
            } else {
                List(store.notifications) { item in
                    row(item)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 9, leading: 16, bottom: 9, trailing: 16))
                }
                .listStyle(.plain)
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func row(_ item: AppNotification) -> some View {
        let actor = item.actorId.flatMap { store.user($0) }
        let content = HStack(spacing: 12) {
            if let actor {
                Avatar(user: actor, size: 30)
            } else {
                QueslyMark(color: .qLime, cutout: .qGreen)
                    .frame(width: 15)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.qGreen))
            }
            message(item, actor: actor)
                .font(.quesly(12))
                .foregroundStyle(Color.qInk)
                .lineLimit(2)
            Spacer()
            Text(RelativeTime.short(item.date))
                .font(.quesly(11))
                .foregroundStyle(Color.qGray)
        }
        if let actor {
            NavigationLink(value: Route.profile(actor.id)) { content }
                .buttonStyle(.plain)
        } else if item.kind == .badge {
            NavigationLink(value: Route.achievements) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private func message(_ item: AppNotification, actor: AppUser?) -> Text {
        var text = AttributedString()
        if let actor {
            var name = AttributedString(actor.username + " ")
            name.foregroundColor = .qGreen
            name.font = .quesly(12, .semibold)
            text += name
            text += AttributedString(item.message)
        } else {
            var body = (try? AttributedString(markdown: item.message)) ?? AttributedString(item.message)
            body.foregroundColor = .qGreen
            text += body
        }
        return Text(text)
    }
}
