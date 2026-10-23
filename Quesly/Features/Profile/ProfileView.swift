import SwiftUI

/// Profile in a Threads / Instagram-style layout: name + ringed avatar, bio, social proof,
/// actions, streak week and badges, then answers.
struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let userId: String
    var isTabRoot = false
    @State private var confirmBlock = false

    private var isMe: Bool { userId == store.me.id }

    var body: some View {
        let user = store.user(userId)
        let answers = store.answers(of: userId)
        // Your profile mixes your answers with the ones you reposted, newest first.
        let items = isMe ? (answers + store.resharedAnswers).sorted { $0.createdAt > $1.createdAt } : answers

        ScrollView {
            VStack(spacing: 0) {
                ProfileHeader(user: user, isMe: isMe)
                    .padding(.horizontal, DS.Space.m)
                    .padding(.top, 8)

                HStack(spacing: 6) {
                    Text("Answers").font(.ui(17, .semibold)).foregroundStyle(Color.qInk)
                    Text("\(answers.count)").font(.ui(15)).foregroundStyle(Color.qGray)
                    Spacer()
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.l)
                .padding(.bottom, DS.Space.xs)

                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, answer in
                        let repost = answer.authorId != userId
                        AnswerCard(answer: answer, showsQuestion: true, showsAuthor: repost, isRepost: repost)
                            .staggeredAppear(index)
                        Rectangle().fill(Color.qLine).frame(height: 1).padding(.horizontal, DS.Space.screen)
                    }
                    if items.isEmpty {
                        EmptyStateView(
                            icon: .chatCircleTextFill,
                            title: "No answers yet",
                            message: isMe ? "Answer today's question to start your story." : "Their answers will show up here.")
                    }
                }
                .padding(.bottom, DS.Space.xs)
                .background(Color.qBlock)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
                .padding(.horizontal, DS.Space.m)
            }
            .padding(.bottom, 16)
        }
        .background(Color.qCanvas)
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
                    Icon(.caretLeftBold, size: DS.Icon.action).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")
            }
            if store.isPrivateAccount && isMe {
                IconLabel("Private", icon: .lockSimpleFill, size: DS.Icon.caption)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qGray)
                    .padding(.leading, DS.Space.s)
            }
            Spacer()
            ShareLink(item: Invite.text(for: user?.username ?? "")) {
                Icon(.export, size: DS.Icon.action).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Share profile")
            if isMe {
                NavigationLink(value: Route.settings) {
                    Icon(.gearSix, size: DS.Icon.action).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Settings")
            } else {
                Menu {
                    Button(role: .destructive) { confirmBlock = true } label: {
                        Label("Block", systemImage: QIcon.prohibit.rawValue)
                    }
                } label: {
                    Icon(.dotsThreeBold, size: DS.Icon.action).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
                }
                .accessibilityLabel("More")
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 52)
        .background(Color.qCanvas)
    }
}

struct ProfileHeader: View {
    @Environment(AppStore.self) private var store
    let user: AppUser?
    let isMe: Bool
    @State private var appeared = false
    @Environment(\.dynamicTypeSize) private var typeSize

    private var streak: Int { isMe ? store.streak : (user?.streak ?? 0) }
    private var followingCount: Int { isMe ? store.followingUsers.count : (user?.following ?? 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            // Identity block: avatar, name, place, bio, actions.
            VStack(alignment: .leading, spacing: DS.Space.m) {
                HStack(alignment: .center, spacing: DS.Space.m) {
                    AvatarRing(user: user, size: 76, isActiveToday: isMe ? store.hasAnsweredToday : false)
                        .scaleEffect(appeared ? 1 : 0.6)
                        .opacity(appeared ? 1 : 0)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(user?.username ?? "")
                                .font(.display(28, .bold))
                                .foregroundStyle(Color.qInk)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            if let badge = user?.badge {
                                HexBadge(color: badge.color, icon: badge.icon).frame(width: 20, height: 20)
                            }
                        }
                        if let location = user?.location, !location.isEmpty {
                            IconLabel(location, icon: .mapPinFill)
                                .font(.ui(15))
                                .foregroundStyle(Color.qGray)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                }

                if let bio = user?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.ui(16))
                        .foregroundStyle(Color.qInk)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                actions
            }
            .block()
            .staggeredAppear(0)

            statTiles.staggeredAppear(1)

            if isMe {
                MemoriesCard().staggeredAppear(2)
                BadgesStrip().block().staggeredAppear(3)
            }
        }
        .onAppear { withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.05)) { appeared = true } }
    }

    /// Big-number tiles (answers or streak, followers, following), like balances in a banking app.
    private var statTiles: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: DS.Space.s))
            : AnyLayout(HStackLayout(spacing: DS.Space.s))
        return layout {
            // Your own streak lives in the memories block below, so here it's your answer count.
            if isMe {
                let count = store.answers(of: store.me.id).count
                tile(count, count == 1 ? "Answer" : "Answers", icon: .chatCircleTextFill,
                     tint: .qBrandText, fill: .qMint, route: nil)
            } else {
                tile(streak, "Day streak", icon: .fireFill, tint: .qFlame, fill: Color.qFlameSoft, route: nil)
            }
            tile(user?.followers ?? 0, "Followers", icon: .userFill, tint: .qIce, fill: .qIceSoft,
                 route: isMe ? .followers : nil)
            tile(followingCount, "Following", icon: .userPlusFill, tint: .qViolet,
                 fill: .qVioletSoft, route: isMe ? .following : nil)
        }
    }

    /// bunq / Revolut-style tile: a tinted icon chip, then the big number and a short label.
    /// Each tile has its own meaning colour (brand green, flame, ice, violet) only on the chip.
    @ViewBuilder
    private func tile(_ value: Int, _ label: String, icon: QIcon, tint: Color, fill: Color, route: Route?) -> some View {
        let content = VStack(alignment: .leading, spacing: DS.Space.s) {
            IconChip(icon: icon, tint: tint, fill: fill)
            VStack(alignment: .leading, spacing: 2) {
                CountUpText(value: value)
                    .font(.display(22, .bold))
                    .foregroundStyle(Color.qInk)
                Text(label).font(.ui(13)).foregroundStyle(Color.qGray)
                    .lineLimit(1)
            }
        }
        .block(padding: DS.Space.m)
        if let route {
            NavigationLink(value: route) { content }.buttonStyle(.pressable)
        } else {
            content
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
                            .fill(following ? Color.qField : Color.qGreen))
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
            .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qField))
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

/// Horizontal strip of badges with a link to all achievements.
struct BadgesStrip: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let items = store.achievements
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: DS.Space.s) {
                IconChip(icon: .medalFill, tint: .qGold, fill: .qGoldSoft)
                Text("Badges").font(.ui(17, .semibold)).foregroundStyle(Color.qInk)
                Text("\(items.filter(\.isUnlocked).count)/\(items.count)")
                    .font(.ui(15)).foregroundStyle(Color.qGray)
                Spacer()
                NavigationLink(value: Route.achievements) {
                    HStack(spacing: 2) {
                        Text("See all").font(.ui(15, .semibold))
                        Icon(.caretRightBold, size: DS.Icon.caption)
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
                                    .font(.ui(12))
                                    .foregroundStyle(item.isUnlocked ? Color.qInk : Color.qGray)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: 84, alignment: .top)
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

/// A number that counts up from zero the first time it appears (instantly under Reduce Motion).
struct CountUpText: View {
    let value: Int
    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("\(shown)")
            .contentTransition(.numericText(value: Double(shown)))
            .monospacedDigit()
            .onAppear {
                guard shown != value else { return }
                if reduceMotion { shown = value } else {
                    withAnimation(.smooth(duration: 0.9).delay(0.2)) { shown = value }
                }
            }
            .onChange(of: value) { _, new in withAnimation(.qSmooth) { shown = new } }
            .accessibilityLabel("\(value)")
    }
}
