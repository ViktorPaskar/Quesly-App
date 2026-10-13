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
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                if isMe {
                    UnderlineTabs(items: Tab.allCases, selection: $tab) { t in
                        t == .answers ? "Answers · \(answers.count)" : "Saved · \(store.savedAnswers.count)"
                    }
                    .padding(.top, 20)
                } else {
                    HStack {
                        Text("Answers").font(.quesly(15, .semibold)).foregroundStyle(Color.qInk)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                    Rectangle().fill(Color.qLine).frame(height: 1)
                }

                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, answer in
                        AnswerCard(answer: answer, showsQuestion: true, showsAuthor: isMe && tab == .saved)
                            .staggeredAppear(index)
                        Rectangle().fill(Color.qLine).frame(height: 1).padding(.horizontal, 18)
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
        .background(Color.white)
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
                Icon(.lockSimpleFill, size: 16).foregroundStyle(Color.qInk)
                    .padding(.leading, isTabRoot ? 12 : 0)
            }
            Text(user?.username ?? "")
                .font(.quesly(20, .bold))
                .foregroundStyle(Color.qInk)
                .padding(.leading, isTabRoot && !store.isPrivateAccount ? 12 : 0)
            Spacer()
            ShareLink(item: Invite.text(for: user?.username ?? "")) {
                Icon(.export, size: 24).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Share profile")
            if isMe {
                NavigationLink(value: Route.menu) {
                    Icon(.gearSix, size: 25).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Menu")
            } else {
                Menu {
                    Button(role: .destructive) { confirmBlock = true } label: {
                        Label("Block", image: Ph.prohibit.assetName)
                    }
                } label: {
                    Icon(.dotsThreeBold, size: 24).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
                }
                .accessibilityLabel("More")
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 52)
        .background(Color.white)
    }
}

struct ProfileHeader: View {
    @Environment(AppStore.self) private var store
    let user: AppUser?
    let isMe: Bool
    let answersCount: Int
    @State private var appeared = false

    private var streak: Int { isMe ? store.streak : (user?.streak ?? 0) }
    private var followingCount: Int { isMe ? store.followingUsers.count : (user?.following ?? 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Name + avatar
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(user?.username ?? "")
                            .font(.quesly(28, .bold, relativeTo: .title))
                            .foregroundStyle(Color.qInk)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if let badge = user?.badge {
                            HexBadge(color: badge.color, icon: badge.icon).frame(width: 22, height: 22)
                        }
                    }
                    HStack(spacing: 6) {
                        chip(icon: .fireFill, text: "\(streak)-day streak", tint: .qFlame)
                        if let location = user?.location, !location.isEmpty {
                            chip(icon: .mapPinFill, text: location, tint: .qGray)
                        }
                    }
                }
                Spacer(minLength: 0)
                AvatarRing(user: user, size: 86)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
            }

            if let bio = user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.quesly(16))
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

    private func chip(icon: Ph, text: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Icon(icon, size: 14).foregroundStyle(tint)
            Text(text).font(.quesly(13, .medium)).foregroundStyle(Color.qInk.opacity(0.8)).lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(Capsule().fill(Color.qField))
    }

    /// "Followers · following · answers" line with tiny avatars, like Threads.
    private var socialProof: some View {
        let sample = Array(store.followingUsers.prefix(3))
        return HStack(spacing: 10) {
            AvatarStack(users: sample, size: 22)
            HStack(spacing: 0) {
                link("\(user?.followers ?? 0)", "followers", route: isMe ? .followers : nil)
                Text("  ·  ").font(.quesly(15)).foregroundStyle(Color.qGray)
                link("\(followingCount)", "following", route: isMe ? .following : nil)
                Text("  ·  ").font(.quesly(15)).foregroundStyle(Color.qGray)
                link("\(answersCount)", answersCount == 1 ? "answer" : "answers", route: nil)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    @ViewBuilder
    private func link(_ value: String, _ label: String, route: Route?) -> some View {
        let text = HStack(spacing: 4) {
            Text(value).font(.quesly(15, .semibold)).foregroundStyle(Color.qInk)
            Text(label).font(.quesly(15)).foregroundStyle(Color.qGray)
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
                        .font(.quesly(15, .semibold))
                        .foregroundStyle(following ? Color.qInk : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(following ? Color.white : Color.qGreen))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
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
            .font(.quesly(15, .semibold))
            .foregroundStyle(Color.qInk)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.qLine, lineWidth: 1.5))
    }
}

/// Avatar with a slowly rotating brand-gradient ring (like an IG story ring).
struct AvatarRing: View {
    let user: AppUser?
    var size: CGFloat = 86
    @State private var spin = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(AngularGradient(colors: [.qLime, .qGreenLight, .qGreen, .qLime], center: .center),
                        lineWidth: 3.5)
                .rotationEffect(.degrees(spin ? 360 : 0))
            Avatar(user: user, size: size - 12, showsBadge: true)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}

/// Green card with the current streak and this week's answered days.
struct StreakWeekCard: View {
    @Environment(AppStore.self) private var store
    let streak: Int
    @State private var appeared = false

    var body: some View {
        let days = store.currentWeek
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Icon(.fireFill, size: 28)
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFD84D), .qFlame], startPoint: .top, endPoint: .bottom))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(.white.opacity(0.12)))
                    .scaleEffect(appeared ? 1 : 0.5)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak)-day streak")
                        .font(.quesly(20, .bold))
                        .foregroundStyle(.white)
                    Text(store.hasAnsweredToday ? "You're on fire. See you tomorrow!" : "Answer today to keep it going")
                        .font(.quesly(14))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
            }
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 7) {
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.quesly(12, .semibold))
                            .foregroundStyle(.white.opacity(day.isToday ? 1 : 0.6))
                        ZStack {
                            Circle().fill(day.answered ? Color.qLime : Color.white.opacity(0.12))
                            if day.answered {
                                Icon(.checkBold, size: 14).foregroundStyle(Color.qGreen)
                            }
                            if day.isToday {
                                Circle().stroke(Color.qLime, lineWidth: 2).padding(-4)
                            }
                        }
                        .frame(width: 30, height: 30)
                        .scaleEffect(appeared ? 1 : 0.2)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15 + Double(index) * 0.05), value: appeared)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: [.qGreen, .qGreenDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .onAppear { withAnimation(.qSpring) { appeared = true } }
    }
}

/// Horizontal strip of badges with a link to all achievements.
struct BadgesStrip: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let items = store.achievements
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Badges").font(.quesly(17, .semibold)).foregroundStyle(Color.qInk)
                Text("\(items.filter(\.isUnlocked).count)/\(items.count)")
                    .font(.quesly(15)).foregroundStyle(Color.qGray)
                Spacer()
                NavigationLink(value: Route.achievements) {
                    HStack(spacing: 2) {
                        Text("See all").font(.quesly(15, .semibold))
                        Icon(.caretRightBold, size: 13)
                    }
                    .foregroundStyle(Color.qGreen)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink(value: Route.achievements) {
                            VStack(spacing: 6) {
                                HexBadge(color: item.color, icon: item.icon, isLocked: !item.isUnlocked)
                                    .frame(width: 54, height: 54)
                                    .opacity(item.isUnlocked ? 1 : 0.55)
                                Text(item.title)
                                    .font(.quesly(12, .medium))
                                    .foregroundStyle(item.isUnlocked ? Color.qInk : Color.qGray)
                                    .lineLimit(1)
                                    .frame(width: 72)
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
