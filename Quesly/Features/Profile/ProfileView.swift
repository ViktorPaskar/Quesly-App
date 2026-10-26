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
                    ProfileHeader(user: user, isMe: isMe) { withAnimation(.qSmooth) { tab = .calendar } }
                        .padding(.horizontal, DS.Space.screen)
                        .padding(.top, DS.Space.xs)
                        .padding(.bottom, DS.Space.xl)
                        .onGeometryChange(for: Bool.self) { geo in
                            geo.frame(in: .scrollView).minY < -56
                        } action: { shows in
                            withAnimation(.qSmooth) { showsMiniTitle = shows }
                        }
                    // Scroll target: the point where the tabs pin.
                    Color.clear.frame(height: 0).id("tabs")

                    Section {
                        content
                            .padding(.top, tab == .calendar ? DS.Space.m : 0)
                            .frame(maxWidth: .infinity, minHeight: 360, alignment: .top)
                            .contentShape(Rectangle())
                            .simultaneousGesture(swipe)
                            .animation(.qSmooth, value: tab)
                    } header: {
                        UnderlineTabs(items: tabs, selection: $tab, title: \.title,
                                      indicator: 1, inactive: Color(hex: 0x999999), hairline: .qLine)
                            .background(Color.qBackground)
                    }
                }
                .padding(.bottom, DS.Space.m)
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
            .padding(.horizontal, DS.Space.screen)
        } else {
            let items = answers(for: tab)
            // On white, answers are rows split by inset hairlines (Threads), not floating cards.
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, answer in
                    if index > 0 {
                        Rectangle().fill(Color.qLine).frame(height: 1).padding(.horizontal, DS.Space.screen)
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
        .padding(.horizontal, 10)   // 44-pt zones: glyphs land on the 20-pt margin
        .frame(height: 44)
        .background(Color.qBackground)
    }
}

/// Profile top, left-aligned like Threads: name and @nick beside the photo, bio, the numbers
/// as one line of text, then two equal actions.
struct ProfileHeader: View {
    @Environment(AppStore.self) private var store
    let user: AppUser?
    let isMe: Bool
    /// Tapping your streak opens the Calendar tab.
    var onStreak: () -> Void = {}
    @State private var appeared = false
    @Environment(.dynamicTypeSize) private var typeSize

    private var streak: Int { isMe ? store.streak : (user?.streak ?? 0) }

    private var followingCount: Int { isMe ? store.followingUsers.count : (user?.following ?? 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: DS.Space.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(user?.displayName ?? "")
                        .font(.display(28, .bold))
                        .tracking(-0.4)
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
                    .foregroundStyle(Color.qInk2)
                    .lineSpacing(4)
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

    /// "@nick".
    private var nickLine: some View {
        HStack(spacing: DS.Space.xxs) {
            Text("@\(user?.username ?? "")")
                .foregroundStyle(Color.qGray)
                .lineLimit(1)
        }
        .font(.ui(15))
    }

    // MARK: Stats

    /// Four equal columns on the content width, big number over a small label:
    /// 🔥 streak · answers · followers · following. Each column starts on the same grid line.
    /// At accessibility text sizes the four columns become a 2 × 2 grid so labels never truncate.
    private var stats: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .leading),
                            count: typeSize.isAccessibilitySize ? 2 : 4)
        return LazyVGrid(columns: columns, alignment: .leading, spacing: DS.Space.s) {
            streakStat
            stat(store.answers(of: user?.id ?? "").count, "Answers", route: nil)
            stat(user?.followers ?? 0, "Followers", route: isMe ? .followers : nil)
            stat(followingCount, "Following", route: isMe ? .following : nil)
        }
    }

    private func number(_ value: Int) -> some View {
        Text(value.formatted(.number.notation(.compactName)))
            .font(.ui(20, .bold))
            .foregroundStyle(Color.qGreen)
            .monospacedDigit()
            .contentTransition(.numericText())
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.ui(13)).foregroundStyle(Color.qGray)
    }

    /// The flame sits before the number, so the figures of all four columns share one baseline.
    @ViewBuilder
    private var streakStat: some View {
        let content = VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: DS.Space.xxs) {
                Icon(.fireFill, size: 18).foregroundStyle(Color.qFlame)
                number(streak)
            }
            label("Day streak")
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, minHeight: DS.hitTarget, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streak) day streak")
        if isMe {
            Button(action: onStreak) { content }
                .buttonStyle(.pressable)
                .accessibilityHint("Opens your calendar")
        } else {
            content
        }
    }

    @ViewBuilder
    private func stat(_ value: Int, _ title: String, route: Route?) -> some View {
        let content = VStack(alignment: .leading, spacing: 2) {
            number(value)
            label(title)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, minHeight: DS.hitTarget, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        if let route {
            NavigationLink(value: route) { content }.buttonStyle(.pressable)
        } else {
            content
        }
    }

    // MARK: Actions

    private var actions: some View {
        HStack(spacing: DS.Space.xs) {
            if isMe {
                NavigationLink(value: Route.editProfile) { pill("Edit profile") }
                    .buttonStyle(.pressable)
                ShareLink(item: Invite.text(for: store.me.username)) { pill("Share profile") }
                    .buttonStyle(.pressable)
            } else if let user {
                let following = store.isFollowing(user.id)
                Button { store.toggleFollow(user.id) } label: {
                    pill(following ? "Following" : "Follow", style: following ? .gray : .green)
                }
                .buttonStyle(.pressable)
                .sensoryFeedback(.success, trigger: following)
                .animation(.qSpring, value: following)
                ShareLink(item: Invite.text(for: user.username)) { pill("Share profile") }
                    .buttonStyle(.pressable)
            }
        }
    }

    /// Green with lime text for the one main action (Follow); light gray for everything else.
    private enum PillStyle { case green, gray }

    private func pill(_ title: String, style: PillStyle = .gray) -> some View {
        Text(title)
            .font(.ui(15, .semibold))
            .foregroundStyle(style == .green ? Color.qLime : Color.qInk)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Capsule().fill(style == .green ? Color.qGreen : Color.qField))
            .frame(minHeight: DS.hitTarget)
            .contentShape(Rectangle())
    }
}

/// Calendar tab, top block: the streak. Warm peach card with the flame's own orange, so it stands
/// apart from the green brand blocks: a flame medallion and the big number, the last seven days
/// as little flames, and the road to the next milestone with your best and this month's count.
///
/// The feed (and so the profile) only opens after today's answer, so the streak shown here is
/// always at least 1. Three moods: first day, fresh start after a gap, and a running streak.
struct StreakCard: View {
    @Environment(AppStore.self) private var store
    private let calendar = Calendar.current
    private static let milestones = [3, 7, 14, 30, 50, 100, 200, 365]
    private static let flameDeep = Color(hex: 0xC2410C)

    private var streak: Int { store.streak }
    private var best: Int { max(store.bestStreak, streak) }
    private var isFirstDay: Bool { store.answeredDays.count <= 1 }

    private var message: String {
        if !store.hasAnsweredToday { return streak > 0 ? "Answer today to keep it going." : "Answer today's question to light the first flame." }
        if isFirstDay { return "Your first flame. Come back tomorrow to keep it going." }
        if streak == 1 { return "Fresh start. Your best is \(best) days." }
        if streak > 1 && streak >= best { return "Your longest streak yet. See you tomorrow." }
        return "See you tomorrow."
    }

    private var answersThisMonth: Int {
        store.answeredDays.filter { calendar.isDate($0, equalTo: .now, toGranularity: .month) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: DS.Space.m) {
                medallion
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(streak)")
                            .font(.display(40, .bold))
                            .tracking(-0.5)
                            .foregroundStyle(Color.qInk)
                            .contentTransition(.numericText())
                        Text(streak == 1 ? "day streak" : "day streak")
                            .font(.display(17, .semibold))
                            .foregroundStyle(Color.qInk)
                    }
                    Text(message)
                        .font(.ui(13))
                        .foregroundStyle(Color.qInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            week
                .padding(.top, DS.Space.l)

            milestone
                .padding(DS.Space.m)
                .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.white.opacity(0.7)))
                .padding(.top, DS.Space.l)
        }
        .padding(DS.Space.m)
        .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qPeach))
        .accessibilityElement(children: .combine)
    }

    /// Flame on a white disc with a soft orange ring; a "best" star when you're on your record.
    private var medallion: some View {
        Icon(.fireFill, size: 30)
            .foregroundStyle(Color.qFlame)
            .frame(width: 60, height: 60)
            .background(Circle().fill(.white))
            .overlay(Circle().strokeBorder(Color.qFlame.opacity(0.18), lineWidth: 4))
            .overlay(alignment: .bottomTrailing) {
                if streak > 1 && streak >= best {
                    Icon(.starFill, size: 11)
                        .foregroundStyle(Color.qGreen)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.qLimeSoft))
                        .overlay(Circle().stroke(Color.qPeach, lineWidth: 2))
                        .offset(x: 2, y: 2)
                        .accessibilityLabel("Personal best")
                }
            }
    }

    // MARK: Last seven days

    private var week: some View {
        let today = calendar.startOfDay(for: .now)
        let days = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        return HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                let isToday = day == today
                let done = store.answeredDays.contains(day)
                VStack(spacing: DS.Space.xs) {
                    ZStack {
                        if done {
                            Circle().fill(Color.qFlame)
                            Icon(.fireFill, size: 16).foregroundStyle(.white)
                        } else {
                            Circle().strokeBorder(Color.qFlame.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [2, 3]))
                        }
                    }
                    .frame(width: 34, height: 34)
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.ui(12, .semibold))
                        .foregroundStyle(isToday ? Color.qInk : Color.qGray)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Last 7 days: \(days.filter { store.answeredDays.contains($0) }.count) answered")
    }

    // MARK: Next milestone

    private var milestone: some View {
        let next = Self.milestones.first { $0 > streak } ?? (streak + 100)
        let prev = Self.milestones.last { $0 <= streak } ?? 0
        let progress = CGFloat(streak - prev) / CGFloat(max(1, next - prev))
        let left = next - streak
        return VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack(alignment: .firstTextBaseline) {
                Text("Next goal · \(next) days")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Text(left == 1 ? "1 day to go" : "\(left) days to go")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Self.flameDeep)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.qFlame.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: 0xFFB347), .qFlame], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * progress))
                }
            }
            .frame(height: 8)
            HStack(spacing: DS.Space.m) {
                stat("\(best)", best == 1 ? "day best" : "days best")
                stat("\(answersThisMonth)", answersThisMonth == 1 ? "answer this month" : "answers this month")
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        (Text(value).font(.ui(13, .semibold)).foregroundStyle(Color.qInk)
            + Text(" " + label).font(.ui(13)).foregroundStyle(Color.qGray))
            .lineLimit(1)
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
