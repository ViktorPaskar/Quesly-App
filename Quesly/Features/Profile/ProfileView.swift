import SwiftUI

/// Own profile (tab root) or another user's profile (pushed from the feed).
struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let userId: String
    var isTabRoot = false

    private var isMe: Bool { userId == store.me.id }

    var body: some View {
        let user = store.user(userId)
        let answers = store.answers(of: userId)

        ScrollView {
            VStack(spacing: 0) {
                ProfileHeader(user: user, isMe: isMe, answersCount: answers.count)
                Divider()
                LazyVStack(spacing: 0) {
                    ForEach(answers) { answer in
                        AnswerCard(answer: answer, showsQuestion: true)
                        Divider().padding(.leading, 16)
                    }
                    if answers.isEmpty {
                        Text(isMe ? "Answer today's question to start your story." : "No answers yet.")
                            .font(.quesly(14))
                            .foregroundStyle(Color.qGray)
                            .padding(.top, 40)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topLeading) {
            if !isTabRoot {
                Button { dismiss() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                        Text(user?.username ?? "").font(.quesly(15, .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .accessibilityLabel("Back")
            }
        }
    }
}

struct ProfileHeader: View {
    @Environment(AppStore.self) private var store
    let user: AppUser?
    let isMe: Bool
    let answersCount: Int

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                MarkPattern()
                    .frame(height: 170)
                Avatar(user: user, size: 96, showsBadge: true)
                    .padding(4)
                    .background(Circle().fill(.white))
                    .offset(y: 48)
            }
            .padding(.bottom, 52)

            Text(user?.username ?? "")
                .font(.quesly(18, .semibold))
                .foregroundStyle(Color.qInk)

            HStack {
                stat("\(answersCount)", "Answers", route: nil)
                stat("\(isMe ? store.followingUsers.count : (user?.following ?? 0))", "Following",
                     route: isMe ? .following : nil)
                stat("\(user?.followers ?? 0)", "Followers", route: isMe ? .followers : nil)
                stat("\(isMe ? store.streak : (user?.streak ?? 0))d", "Streak", route: isMe ? .achievements : nil)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            if let bio = user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.quesly(12))
                    .foregroundStyle(Color.qInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
            }

            HStack(spacing: 12) {
                if isMe {
                    NavigationLink(value: Route.editProfile) {
                        Text("Edit Profile")
                            .font(.quesly(13, .medium))
                            .foregroundStyle(Color.qInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(Capsule().fill(Color.qField))
                    }
                    NavigationLink(value: Route.menu) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.qGray)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(Color.qField))
                    }
                    .accessibilityLabel("Profile menu")
                } else if let user {
                    let following = store.isFollowing(user.id)
                    Button { store.toggleFollow(user.id) } label: {
                        Text(following ? "Followed" : "Follow")
                            .font(.quesly(13, .semibold))
                            .foregroundStyle(following ? Color.qGreen : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(Capsule().fill(following ? Color.qField : Color.qGreen))
                            .overlay(Capsule().stroke(Color.qGreen, lineWidth: following ? 1 : 0))
                    }
                    .sensoryFeedback(.success, trigger: following)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private func stat(_ value: String, _ title: String, route: Route?) -> some View {
        let label = VStack(spacing: 2) {
            Text(value).font(.quesly(17, .semibold)).foregroundStyle(Color.qGreen)
            Text(title).font(.quesly(10)).foregroundStyle(Color.qGray)
        }
        .frame(maxWidth: .infinity)

        if let route {
            NavigationLink(value: route) { label }.buttonStyle(.plain)
        } else {
            label
        }
    }
}

/// Green band with a tiled pattern of faded Quesly marks.
struct MarkPattern: View {
    var body: some View {
        GeometryReader { geo in
            let cols = 7
            let spacing = geo.size.width / CGFloat(cols)
            ZStack(alignment: .topLeading) {
                Color.qGreen
                ForEach(0..<4, id: \.self) { row in
                    ForEach(0..<(cols + 1), id: \.self) { col in
                        QueslyMark(color: .white.opacity(0.13))
                            .frame(width: 22)
                            .position(x: CGFloat(col) * spacing + (row.isMultiple(of: 2) ? spacing / 2 : 0),
                                      y: 40 + CGFloat(row) * 40)
                    }
                }
            }
        }
        .clipped()
    }
}
