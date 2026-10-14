import SwiftUI

/// Profile in a Threads / Instagram-style layout: name + ringed avatar, bio, social proof,
/// actions, streak week and badges, then Answers / Saved.
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
    @State private var confirmBlock = false

    private var isMe: Bool { userId == store.me.id }

    var body: some View {
        let user = store.user(userId)
        let answers = store.answers(of: userId)
        let items = isMe && tab == .saved ? store.savedAnswers : answers

        ScrollView {
            VStack(spacing: 0) {
                ProfileHeader(user: user, isMe: isMe, answersCount: answers.count)
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, 8)

                if isMe {
                    UnderlineTabs(items: Tab.allCases, selection: $tab) { t in
                        t == .answers ? "Answers · \(answers.count)" : "Saved · \(store.savedAnswers.count)"
                    }
                    .padding(.top, 20)
                } else {
                    HStack {
                        Text("Answers").font(.ui(15, .semibold)).foregroundStyle(Color.qInk)
                        Spacer()
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    Rectangle().fill(Color.qLine).frame(height: 1)
                }

                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, answer in
                        AnswerCard(answer: answer, showsQuestion: true, showsAuthor: isMe && tab == .saved)
                            .staggeredAppear(index)
                        Rectangle().fill(Color.qLine).frame(height: 1).padding(.horizontal, DS.Space.screen)
                    }
                    if items.isEmpty {
                        EmptyStateView(
                            icon: tab == .saved && isMe ? .bookmarkSimpleFill : .chatCircleTextFill,
                            title: tab == .saved && isMe ? "Nothing saved yet" : "No answers yet",
                            message: tab == .saved && isMe
                                ? "Tap the bookmark on any answer to keep it here."
                                : (isMe ? "Answer today's question to start your story." : "Their answers will show up here."))
                    }
                }
                .animation(.qSmooth, value: tab)
            }
            .padding(.bottom, 16)
        }
        .background(Color.qBackground)
        .safeAreaInset(edge: .top, spacing: 0) { topBar(user) }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Block @\(user?.username ?? "")?", isPresented: $confirmBlock, titleVisibility: .visible) {
            Button("Block", role: .destructive) {
                store.block(userId)
                dismiss()
            }
        } message: {
            Text("You won't see their answers, and they won't be notified.")
        }
    }

    private func topBar(_ user: AppUser?) -> some View {
        HStack(spacing: 4) {
            if !isTabRoot {
                Button { dismiss() } label: {
                    Icon(.caretLeftBold, size: 22).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")
            }
            if store.isPrivateAccount && isMe {
                Label("Private", systemImage: QIcon.lockSimpleFill.rawValue)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qGray)
                    .padding(.leading, DS.Space.s)
            }
            Spacer()
            ShareLink(item: Invite.text(for: user?.username ?? "")) {
                Icon(.export, size: 24).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Share profile")
            if isMe {
                NavigationLink(value: Route.settings) {
                    Icon(.gearSix, size: 25).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Settings")
            } else {
                Menu {
                    Button(role: .destructive) { confirmBlock = true } label: {
                        Label("Block", systemImage: QIcon.prohibit.rawValue)
                    }
                } label: {
                    Icon(.dotsThreeBold, size: 24).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
                }
                .accessibilityLabel("More")
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 52)
        .background(Color.qBackground)
    }
}

struct ProfileHeader: View {
    @Environment(AppStore.self) private var store
    let user: AppUser?
    let isMe: Bool
    let answersCount: Int
    @State private var appeared = false
    @Environment(\.dynamicTypeSize) private var typeSize

    private var streak: Int { isMe ? store.streak : (user?.streak ?? 0) }
    private var followingCount: Int { isMe ? store.followingUsers.count : (user?.following ?? 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Name + avatar
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(user?.username ?? "")
                            .font(.display(28, .bold))
                            .foregroundStyle(Color.qInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if let badge = user?.badge {
                            HexBadge(color: badge.color, icon: badge.icon).frame(width: 22, height: 22)
                        }
                    }
                    if let location = user?.location, !location.isEmpty {
                        Label(location, systemImage: QIcon.mapPinFill.rawValue)
                            .font(.ui(15))
                            .foregroundStyle(Color.qGray)
                            .lineLimit(2)
                    }
                    if !isMe && streak > 0 {
                        Label("\(streak)-day streak", systemImage: QIcon.fireFill.rawValue)
                            .font(.ui(15))
                            .foregroundStyle(Color.qGray)
                    }
                }
                Spacer(minLength: 0)
                AvatarRing(user: user, size: 84, isActiveToday: isMe ? store.hasAnsweredToday : false)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
            }

            if let bio = user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.ui(16))
                    .foregroundStyle(Color.qInk)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            socialProof

            actions

            if isMe {
                StreakWeekCard(streak: streak)
                BadgesStrip()
            }
        }
        .onAppear { withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.05)) { appeared = true } }
    }

    /// "Followers · following · answers" line with tiny avatars, like Threads.
    private var socialProof: some View {
        let sample = Array(store.followingUsers.prefix(3))
        if typeSize.isAccessibilitySize {
            // Large text: one stat per line instead of a squeezed single row.
            return AnyView(VStack(alignment: .leading, spacing: DS.Space.xxs) {
                link("\(user?.followers ?? 0)", "followers", route: isMe ? .followers : nil)
                link("\(followingCount)", "following", route: isMe ? .following : nil)
                link("\(answersCount)", answersCount == 1 ? "answer" : "answers", route: nil)
            })
        }
        return AnyView(HStack(spacing: 12) {
            AvatarStack(users: sample, size: 22)
            HStack(spacing: 0) {
                link("\(user?.followers ?? 0)", "followers", route: isMe ? .followers : nil)
                Text("  ·  ").font(.ui(15)).foregroundStyle(Color.qGray)
                link("\(followingCount)", "following", route: isMe ? .following : nil)
                Text("  ·  ").font(.ui(15)).foregroundStyle(Color.qGray)
                link("\(answersCount)", answersCount == 1 ? "answer" : "answers", route: nil)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        })
    }

    @ViewBuilder
    private func link(_ value: String, _ label: String, route: Route?) -> some View {
        let text = HStack(spacing: 4) {
            Text(value).font(.ui(15, .semibold)).foregroundStyle(Color.qInk)
            Text(label).font(.ui(15)).foregroundStyle(Color.qGray)
        }
        if let route {
            NavigationLink(value: route) { text }.buttonStyle(.plain)
        } else {
            text
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            if isMe {
                NavigationLink(value: Route.editProfile) { outlined("Edit profile") }
                    .buttonStyle(.pressable)
                ShareLink(item: Invite.text(for: store.me.username)) { outlined("Share profile") }
                    .buttonStyle(.pressable)
            } else if let user {
                let following = store.isFollowing(user.id)
                Button { store.toggleFollow(user.id) } label: {
                    Text(following ? "Following" : "Follow")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(following ? Color.qInk : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                            .fill(following ? Color.qBackground : Color.qGreen))
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                            .stroke(following ? Color.qLine : .clear, lineWidth: 1.5))
                }
                .buttonStyle(.pressable)
                .sensoryFeedback(.success, trigger: following)
                .animation(.qSpring, value: following)
                ShareLink(item: Invite.text(for: user.username)) { outlined("Share profile") }
                    .buttonStyle(.pressable)
            }
        }
    }

    private func outlined(_ title: String) -> some View {
        Text(title)
            .font(.ui(15, .semibold))
            .foregroundStyle(Color.qInk)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qBackground))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).stroke(Color.qLine, lineWidth: 1.5))
    }
}

/// Avatar with a slowly rotating brand-gradient ring (like an IG story ring).
/// Avatar with a brand ring that means something: "answered today".
struct AvatarRing: View {
    let user: AppUser?
    var size: CGFloat = 84
    var isActiveToday = false

    var body: some View {
        ZStack {
            if isActiveToday {
                Circle().stroke(Color.qGreen, lineWidth: 2.5)
            }
            Avatar(user: user, size: isActiveToday ? size - 10 : size, showsBadge: true)
        }
        .frame(width: size, height: size)
    }
}

/// Streak with the last 7 days (rolling, so the dots always agree with the number).
struct StreakWeekCard: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let streak: Int
    @State private var appeared = false

    var body: some View {
        let days = store.lastSevenDays
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
                Icon(.fireFill, size: 20).foregroundStyle(Color.qFlame)
                Text("\(streak)-day streak")
                    .font(.ui(17, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Text(store.hasAnsweredToday ? "See you tomorrow" : "Answer today to keep it")
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
            }
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: DS.Space.xs) {
                        ZStack {
                            Circle().fill(day.answered ? Color.qGreen : Color.qLine)
                            if day.answered {
                                Icon(.checkBold, size: 13).foregroundStyle(.white)
                            }
                        }
                        .frame(width: 30, height: 30)
                        .overlay {
                            if day.isToday {
                                Circle().stroke(Color.qGreen, lineWidth: 2).padding(-4)
                            }
                        }
                        .scaleEffect(appeared || reduceMotion ? 1 : 0.4)
                        .animation(.qSpring.delay(0.1 + Double(index) * 0.04), value: appeared)
                        Text(day.isToday ? "Today" : day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.ui(12, day.isToday ? .semibold : .regular))
                            .foregroundStyle(day.isToday ? Color.qInk : Color.qGray)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(day.date.formatted(.dateTime.weekday(.wide))), \(day.answered ? "answered" : "not answered")")
                }
            }
        }
        .padding(DS.Space.m)
        .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qField))
        .onAppear { appeared = true }
    }
}

/// Horizontal strip of badges with a link to all achievements.
struct BadgesStrip: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let items = store.achievements
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Badges").font(.ui(17, .semibold)).foregroundStyle(Color.qInk)
                Text("\(items.filter(\.isUnlocked).count)/\(items.count)")
                    .font(.ui(15)).foregroundStyle(Color.qGray)
                Spacer()
                NavigationLink(value: Route.achievements) {
                    HStack(spacing: 2) {
                        Text("See all").font(.ui(15, .semibold))
                        Icon(.caretRightBold, size: 13)
                    }
                    .foregroundStyle(Color.qBrandText)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink(value: Route.achievements) {
                            VStack(spacing: 8) {
                                HexBadge(color: item.color, icon: item.icon, isLocked: !item.isUnlocked)
                                    .frame(width: 54, height: 54)
                                    .opacity(item.isUnlocked ? 1 : 0.55)
                                Text(item.title)
                                    .font(.ui(12, .medium))
                                    .foregroundStyle(item.isUnlocked ? Color.qInk : Color.qGray)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: 76, alignment: .top)
                            }
                        }
                        .buttonStyle(.pressable)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
