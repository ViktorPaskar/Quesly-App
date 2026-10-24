import SwiftUI

/// Profile sections, switched by the underline slider or a horizontal swipe.
enum ProfileTab: String, CaseIterable, Identifiable {
    case answers, reposts, calendar, saved
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// Profile on a white screen: who you are (name, @nick, numbers, bio, actions) centred, then sticky
/// tabs: Answers, Reposts and, on your own profile only, Calendar and the private Saved list.
struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let userId: String
    var isTabRoot = false
    @State private var confirmBlock = false
    @State private var tab: ProfileTab = DemoConfig.initialProfileTab
    /// Mini avatar + @nick in the top bar once the name scrolls away.
    @State private var showsMiniTitle = false

    private var isMe: Bool { userId == store.me.id }
    private var tabs: [ProfileTab] { isMe ? ProfileTab.allCases : [.answers, .reposts] }

    var body: some View {
        let user = store.user(userId)
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ProfileHeader(user: user, isMe: isMe)
                        .padding(.horizontal, DS.Space.m)
                        .padding(.top, DS.Space.xs)
                        .padding(.bottom, DS.Space.l)
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: ProfileHeaderTopKey.self,
                                                   value: geo.frame(in: .named("profileScroll")).minY)
                        })

                    Section {
                        content
                            .padding(.top, tab == .calendar ? DS.Space.m : 0)
                            .frame(maxWidth: .infinity, minHeight: 360, alignment: .top)
                            .contentShape(Rectangle())
                            .simultaneousGesture(swipe)
                            .animation(.qSmooth, value: tab)
                    } header: {
                        UnderlineTabs(items: tabs, selection: $tab, title: \.title)
                            .background(Color.qBackground)
                            .id("tabs")
                    }
                }
                .padding(.bottom, DS.Space.m)
            }
            .coordinateSpace(name: "profileScroll")
            .onPreferenceChange(ProfileHeaderTopKey.self) { top in
                let shows = top < -56
                if shows != showsMiniTitle { withAnimation(.qSmooth) { showsMiniTitle = shows } }
            }
            .task {
                guard DemoConfig.scrollsProfileToList else { return }
                try? await Task.sleep(for: .milliseconds(500))
                proxy.scrollTo("tabs", anchor: .top)
            }
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

    // MARK: Tabs

    @ViewBuilder
    private var content: some View {
        if tab == .calendar {
            VStack(spacing: DS.Space.s) {
                StreakCard()
                MemoriesCard(showsHeader: false)
            }
            .padding(.horizontal, DS.Space.m)
        } else {
            let items = answers(for: tab)
            // On white, answers are rows split by inset hairlines (Threads), not floating cards.
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, answer in
                    if index > 0 {
                        Rectangle().fill(Color.qLine).frame(height: 1).padding(.horizontal, DS.Space.m)
                    }
                    AnswerCard(answer: answer, showsQuestion: true, showsAuthor: answer.authorId != userId,
                               isCompact: true)
                        .staggeredAppear(index)
                }
                if items.isEmpty { emptyState }
            }
        }
    }

    private func answers(for tab: ProfileTab) -> [Answer] {
        switch tab {
        case .answers: return store.answers(of: userId)
        case .reposts: return isMe ? store.resharedAnswers : []
        case .saved: return store.bookmarkedAnswers
        case .calendar: return []
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        switch tab {
        case .reposts:
            EmptyStateView(icon: .repost, title: "No reposts yet",
                           message: isMe ? "Repost an answer you love and it stays here on your profile."
                               : "Answers they repost will show up here.")
        case .saved:
            EmptyStateView(icon: .bookmarkSimpleFill, title: "Nothing saved yet",
                           message: "Tap the bookmark on an answer to keep it here. Only you can see this list.")
        default:
            EmptyStateView(icon: .chatCircleTextFill, title: "No answers yet",
                           message: isMe ? "Answer today's question to start your story." : "Their answers will show up here.")
        }
    }

    /// Horizontal swipe moves to the neighbouring tab, like paging.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24).onEnded { value in
            let dx = value.translation.width, dy = value.translation.height
            guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5, let i = tabs.firstIndex(of: tab) else { return }
            let next = dx < 0 ? i + 1 : i - 1
            guard tabs.indices.contains(next) else { return }
            withAnimation(.qSmooth) { tab = tabs[next] }
        }
    }

    // MARK: Top bar

    private func topBar(_ user: AppUser?) -> some View {
        HStack(spacing: DS.Space.xxs) {
            if !isTabRoot {
                Button { dismiss() } label: {
                    Icon(.caretLeftBold, size: DS.Icon.action).foregroundStyle(Color.qInk).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Back")
            }
            if isMe && store.streak > 0 {
                StreakChip(days: store.streak, fill: .qField).padding(.leading, DS.Space.xs)
            }
            if store.isPrivateAccount && isMe {
                IconLabel("Private", icon: .lockSimpleFill, size: DS.Icon.caption)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qGray)
                    .padding(.leading, DS.Space.xs)
            }
            Spacer()
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
        .overlay {
            if showsMiniTitle {
                HStack(spacing: DS.Space.xs) {
                    Avatar(user: user, size: 24)
                    Text(user?.username ?? "")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(Color.qInk)
                        .lineLimit(1)
                }
                .frame(maxWidth: 200)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, DS.Space.xs)
        .frame(height: 52)
        .background(Color.qBackground)
    }
}

private struct ProfileHeaderTopKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

/// Profile top, left-aligned like Threads: name and @nick beside the photo, bio, the numbers
/// as one line of text, then two equal actions.
struct ProfileHeader: View {
    @Environment(AppStore.self) private var store
    let user: AppUser?
    let isMe: Bool
    @State private var appeared = false

    private var followingCount: Int { isMe ? store.followingUsers.count : (user?.following ?? 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: DS.Space.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(user?.displayName ?? "")
                        .font(.display(28, .bold))
                        .foregroundStyle(Color.qInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    nickLine
                }
                Spacer(minLength: 0)
                Avatar(user: user, size: 64)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
            }

            if let bio = user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.ui(15))
                    .foregroundStyle(Color.qInk.opacity(0.85))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, DS.Space.m)
            }

            stats.padding(.top, DS.Space.m)
            actions.padding(.top, DS.Space.l)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .staggeredAppear(0)
        .onAppear { withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.05)) { appeared = true } }
    }

    /// "@nick", plus "· 🔥 2-day streak" on someone else's profile (yours sits in the top bar).
    private var nickLine: some View {
        HStack(spacing: DS.Space.xxs) {
            Text("@\(user?.username ?? "")")
                .foregroundStyle(Color.qGray)
                .lineLimit(1)
            if !isMe, let streak = user?.streak, streak > 0 {
                Text("·").foregroundStyle(Color.qGray)
                Icon(.fireFill, size: DS.Icon.caption).foregroundStyle(Color.qFlame)
                Text("\(streak)-day streak")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                    .lineLimit(1)
            }
        }
        .font(.ui(15))
    }

    // MARK: Stats

    private var stats: some View {
        HStack(spacing: DS.Space.l) {
            let answers = store.answers(of: user?.id ?? "").count
            stat(answers, answers == 1 ? "answer" : "answers", route: nil)
            stat(user?.followers ?? 0, (user?.followers ?? 0) == 1 ? "follower" : "followers",
                 route: isMe ? .followers : nil)
            stat(followingCount, "following", route: isMe ? .following : nil)
        }
    }

    @ViewBuilder
    private func stat(_ value: Int, _ label: String, route: Route?) -> some View {
        let text = (Text("\(value) ").font(.ui(15, .semibold)).foregroundStyle(Color.qInk)
            + Text(label).font(.ui(15)).foregroundStyle(Color.qGray))
            .lineLimit(1)
        if let route {
            NavigationLink(value: route) { text }
                .buttonStyle(.pressable)
                .frame(minHeight: DS.hitTarget)
        } else {
            text.frame(minHeight: DS.hitTarget)
        }
    }

    // MARK: Actions

    private var actions: some View {
        HStack(spacing: DS.Space.xs) {
            if isMe {
                NavigationLink(value: Route.editProfile) { pill("Edit profile", style: .mint) }
                    .buttonStyle(.pressable)
                ShareLink(item: Invite.text(for: store.me.username)) { pill("Share profile") }
                    .buttonStyle(.pressable)
            } else if let user {
                let following = store.isFollowing(user.id)
                Button { store.toggleFollow(user.id) } label: {
                    pill(following ? "Following" : "Follow", style: following ? .mint : .green)
                }
                .buttonStyle(.pressable)
                .sensoryFeedback(.success, trigger: following)
                .animation(.qSpring, value: following)
                ShareLink(item: Invite.text(for: user.username)) { pill("Share profile") }
                    .buttonStyle(.pressable)
            }
        }
    }

    /// Brand trio: green (main action), mint (your own / done state), light gray (secondary).
    private enum PillStyle { case green, mint, gray }

    private func pill(_ title: String, style: PillStyle = .gray) -> some View {
        Text(title)
            .font(.ui(15, .semibold))
            .foregroundStyle(style == .green ? Color.white : style == .mint ? Color.qBrandText : Color.qInk)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Capsule().fill(style == .green ? Color.qGreen : style == .mint ? Color.qMint : Color.qField))
            .frame(minHeight: DS.hitTarget)
            .contentShape(Rectangle())
    }
}

/// Calendar tab, top block: the streak, freezes in stock and a 7-step bar to the next freeze.
struct StreakCard: View {
    @Environment(AppStore.self) private var store
    @State private var showsFreezeInfo = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            header
            freezeProgress
        }
        .padding(DS.Space.m)
        .outlinedBlock()
    }

    private var header: some View {
        HStack(spacing: DS.Space.s) {
            Icon(.fireFill, size: DS.Icon.action)
                .foregroundStyle(Color.qFlame)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.qFlameSoft))
            VStack(alignment: .leading, spacing: 0) {
                Text("\(store.streak)-day streak")
                    .font(.display(20, .bold))
                    .foregroundStyle(Color.qInk)
                Text(store.hasAnsweredToday ? "See you tomorrow" : "Answer today to keep it")
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
            }
            Spacer(minLength: DS.Space.xs)
            Button { showsFreezeInfo = true } label: {
                HStack(spacing: DS.Space.xxs) {
                    Icon(.snowflake, size: DS.Icon.caption, weight: .semibold)
                    Text(store.streakFreezes == 1 ? "1 freeze" : "\(store.streakFreezes) freezes")
                        .font(.ui(13, .semibold))
                }
                .foregroundStyle(Color.qIce)
                .padding(.horizontal, DS.Space.s)
                .frame(height: 28)
                .background(Capsule().fill(Color.qIceSoft))
                .frame(minHeight: DS.hitTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityHint("Explains streak freezes")
            .popover(isPresented: $showsFreezeInfo) {
                Text("Miss a day and a freeze keeps your streak alive automatically. You earn one for every 7-day streak, up to \(AppStore.maxFreezes).")
                    .font(.ui(15))
                    .foregroundStyle(Color.qInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(DS.Space.m)
                    .frame(width: 290)
                    .presentationCompactAdaptation(.popover)
            }
        }
    }

    /// One segment per day of the current 7-day run.
    private var freezeProgress: some View {
        let full = store.streakFreezes >= AppStore.maxFreezes
        let into = full ? 7 : store.streak % 7
        let left = 7 - into
        return VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack {
                Text(full ? "Freezes full" : "Next freeze")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                if !full {
                    Text(left == 1 ? "1 day to go" : "\(left) days to go")
                        .font(.ui(13))
                        .foregroundStyle(Color.qGray)
                }
            }
            HStack(spacing: DS.Space.xxs) {
                ForEach(0..<7, id: \.self) { i in
                    Capsule().fill(i < into ? Color.qIce : Color.qField).frame(height: 6)
                }
            }
        }
        .accessibilityElement(children: .combine)
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
