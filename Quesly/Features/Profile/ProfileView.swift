import SwiftUI

/// Own profile (tab root, with Answers / Saved) or another user's profile (pushed from the feed).
struct ProfileView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case answers = "Answers"
        case saved = "Saved"
        var id: String { rawValue }
    }

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let userId: String
    var isTabRoot = false
    @State private var tab: Tab = DemoConfig.showsSavedTab ? .saved : .answers

    private var isMe: Bool { userId == store.me.id }

    var body: some View {
        let user = store.user(userId)
        let answers = store.answers(of: userId)
        let items = isMe && tab == .saved ? store.savedAnswers : answers

        ScrollView {
            VStack(spacing: 0) {
                ProfileHeader(user: user, isMe: isMe, answersCount: answers.count)

                if isMe {
                    UnderlineTabs(items: Tab.allCases, selection: $tab, title: \.rawValue)
                } else {
                    Rectangle().fill(Color.qLine).frame(height: 1)
                }

                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, answer in
                        AnswerCard(answer: answer, showsQuestion: true, showsAuthor: isMe && tab == .saved)
                            .staggeredAppear(index)
                        Rectangle().fill(Color.qLine).frame(height: 1).padding(.leading, 18)
                    }
                    if items.isEmpty {
                        EmptyStateView(
                            symbol: tab == .saved && isMe ? "bookmark.fill" : "text.bubble.fill",
                            title: tab == .saved && isMe ? "Nothing saved yet" : "No answers yet",
                            message: tab == .saved && isMe
                                ? "Tap the bookmark on any answer to keep it here."
                                : (isMe ? "Answer today's question to start your story." : "Their answers will show up here."))
                    }
                }
                .animation(.qSmooth, value: tab)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topLeading) {
            if !isTabRoot {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.black.opacity(0.18)))
                }
                .padding(.horizontal, 12)
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
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                MarkPattern()
                    .frame(height: 190)
                Avatar(user: user, size: 104, showsBadge: true)
                    .padding(5)
                    .background(Circle().fill(.white))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    .offset(y: 54)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.bottom, 60)

            Text(user?.username ?? "")
                .font(.quesly(22, .bold))
                .foregroundStyle(Color.qInk)

            if let location = user?.location, !location.isEmpty {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.quesly(14))
                    .foregroundStyle(Color.qGray)
                    .padding(.top, 2)
            }

            HStack(spacing: 0) {
                stat("\(answersCount)", "Answers", route: nil)
                stat("\(isMe ? store.followingUsers.count : (user?.following ?? 0))", "Following",
                     route: isMe ? .following : nil)
                stat("\(user?.followers ?? 0)", "Followers", route: isMe ? .followers : nil)
                streakStat(isMe ? store.streak : (user?.streak ?? 0), route: isMe ? .achievements : nil)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)

            if let bio = user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.quesly(15))
                    .foregroundStyle(Color.qInk.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 28)
                    .padding(.top, 14)
            }

            HStack(spacing: 10) {
                if isMe {
                    NavigationLink(value: Route.editProfile) {
                        Text("Edit Profile")
                            .font(.quesly(15, .semibold))
                            .foregroundStyle(Color.qInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Capsule().fill(Color.qField))
                    }
                    ShareLink(item: Invite.text(for: store.me.username)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.qInk)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.qField))
                    }
                    .accessibilityLabel("Share profile")
                    NavigationLink(value: Route.menu) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(Color.qInk)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.qField))
                    }
                    .accessibilityLabel("Profile menu")
                } else if let user {
                    let following = store.isFollowing(user.id)
                    Button { store.toggleFollow(user.id) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: following ? "checkmark" : "plus")
                                .font(.system(size: 14, weight: .bold))
                                .contentTransition(.symbolEffect(.replace))
                            Text(following ? "Following" : "Follow")
                        }
                        .font(.quesly(16, .semibold))
                        .foregroundStyle(following ? Color.qGreen : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Capsule().fill(following ? Color.qMint : Color.qGreen))
                    }
                    .sensoryFeedback(.success, trigger: following)
                    .animation(.qSpring, value: following)
                }
            }
            .buttonStyle(.pressable)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.05)) { appeared = true } }
    }

    @ViewBuilder
    private func stat(_ value: String, _ title: String, route: Route?) -> some View {
        let label = VStack(spacing: 2) {
            Text(value).font(.quesly(20, .bold)).foregroundStyle(Color.qGreen)
                .contentTransition(.numericText())
            Text(title).font(.quesly(13)).foregroundStyle(Color.qGray)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())

        if let route {
            NavigationLink(value: route) { label }.buttonStyle(.pressable)
        } else {
            label
        }
    }

    @ViewBuilder
    private func streakStat(_ days: Int, route: Route?) -> some View {
        let label = VStack(spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFC233), .qFlame], startPoint: .top, endPoint: .bottom))
                Text("\(days)d").font(.quesly(20, .bold)).foregroundStyle(Color.qFlame)
            }
            Text("Streak").font(.quesly(13)).foregroundStyle(Color.qGray)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())

        if let route {
            NavigationLink(value: route) { label }.buttonStyle(.pressable)
        } else {
            label
        }
    }
}

/// Green band with a tiled pattern of faded Quesly marks that slowly drifts.
struct MarkPattern: View {
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let cols = 7
            let spacing = geo.size.width / CGFloat(cols)
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [.qGreenDeep, .qGreen], startPoint: .top, endPoint: .bottom)
                ForEach(0..<5, id: \.self) { row in
                    ForEach(0..<(cols + 2), id: \.self) { col in
                        QueslyMark(color: .white.opacity(0.12))
                            .frame(width: 22)
                            .position(x: CGFloat(col) * spacing + (row.isMultiple(of: 2) ? spacing / 2 : 0) - (drift ? spacing : 0),
                                      y: 30 + CGFloat(row) * 40)
                    }
                }
            }
        }
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { drift = true }
        }
    }
}
