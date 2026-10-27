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
                BadgesStrip()
                    .padding(DS.Space.m)
                    .outlinedBlock()
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
    @Environment(\.dynamicTypeSize) private var typeSize

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
                Avatar(user: user, size: 68, showsBadge: true, isSticker: true)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
            }

            if let bio = user?.bio, !bio.isEmpty {
                ExpandableBio(text: bio).padding(.top, DS.Space.m)
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
    /// answers · followers · following · streak. Each column starts on the same grid line.
    /// At accessibility text sizes the four columns become a 2 × 2 grid so labels never truncate.
    private var stats: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0, alignment: .leading),
                            count: typeSize.isAccessibilitySize ? 2 : 4)
        return LazyVGrid(columns: columns, alignment: .leading, spacing: DS.Space.s) {
            stat(store.answers(of: user?.id ?? "").count, "Answers", route: nil)
            stat(user?.followers ?? 0, "Followers", route: isMe ? .followers : nil)
            stat(followingCount, "Following", route: isMe ? .following : nil)
            streakStat
        }
    }

    private func number(_ value: Int, color: Color = .qInk) -> some View {
        Text(value.formatted(.number.notation(.compactName)))
            .font(.ui(20, .bold))
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText())
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.ui(13)).foregroundStyle(Color.qGray)
    }

    /// Last column; highlighted with the flame icon + orange number so it reads as the interactive ritual stat.
    @ViewBuilder
    private var streakStat: some View {
        let content = VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: DS.Space.xxs) {
                Icon(.fireFill, size: 16).foregroundStyle(Color.qFlame)
                number(streak, color: .qFlame)
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
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, DS.Space.s)
            .foregroundStyle(style == .green ? Color.qLime : Color.qInk)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Capsule().fill(style == .green ? Color.qGreen : Color.qField))
            .frame(minHeight: DS.hitTarget)
            .contentShape(Rectangle())
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// Calendar tab, top block: redesigned clean white streak block (Variant 2: White, without background flame).
struct StreakCard: View {
    @Environment(AppStore.self) private var store

    private var streak: Int { store.streak }
    private var best: Int { max(store.bestStreak, streak) }

    private var answersThisMonth: Int {
        let cal = Calendar.current
        return store.answeredDays.filter { cal.isDate($0, equalTo: .now, toGranularity: .month) }.count
    }

    /// Mon–Sun calendar days of the current week.
    private var currentWeekDays: [Date] {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday start
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today)
        let daysFromMonday = (weekday - 2 + 7) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }.reversed()
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header: big count in flame color, label & compact status chip
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(streak)")
                        .font(.display(44, .bold))
                        .tracking(-1.5)
                        .foregroundStyle(Color.qFlame)
                        .contentTransition(.numericText())
                    Text(streak == 1 ? "day streak" : "days streak")
                        .font(.display(17, .semibold))
                        .foregroundStyle(Color.qInk)
                }

                statusChip
            }

            // 7-day Mon–Sun tracker (Reference 2)
            weekTracker
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.qLine, lineWidth: 1.5)
        )
        .shadow(color: Color.qGreenDeep.opacity(0.04), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streak) day streak. \(store.hasAnsweredToday ? "Answered today." : "Needs answer today.") Best: \(best) days.")
    }

    // MARK: - Status Chip

    @ViewBuilder
    private var statusChip: some View {
        if store.hasAnsweredToday {
            HStack(spacing: 5) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                Text("Active today · Flame secured")
                    .font(.ui(11.5, .semibold))
            }
            .foregroundStyle(Color.qFlame)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.qFlameSoft))
        } else {
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("Answer today to keep streak")
                    .font(.ui(11.5, .bold))
            }
            .foregroundStyle(Color.qGreenDeep)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.qLime))
        }
    }

    // MARK: - 7-Day Week Rhythm (Mon–Sun)

    private var weekTracker: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let days = currentWeekDays

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let isToday = cal.isDate(day, inSameDayAs: today)
                    let isDone = store.answeredDays.contains { cal.isDate($0, inSameDayAs: day) }
                    let isPast = day < today && !isToday

                    VStack(spacing: 5) {
                        ZStack {
                            if isDone {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.qFlame)
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            } else if isToday {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .strokeBorder(Color.qFlame, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                    )
                                Circle().fill(Color.qFlame).frame(width: 6, height: 6)
                            } else if isPast {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.qGray4.opacity(0.35))
                                Circle().fill(Color.qGray.opacity(0.5)).frame(width: 4, height: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.qGray4.opacity(0.3))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)

                        Text(weekdayAbbreviation(for: day))
                            .font(.ui(11, isToday ? .bold : .semibold))
                            .foregroundStyle(isToday ? Color.qBrandText : Color.qGray)
                    }
                }
            }

            Rectangle()
                .fill(Color.qLine)
                .frame(height: 1)

            HStack(spacing: DS.Space.s) {
                stat("Best", "\(best) \(best == 1 ? "day" : "days")")
                Text("·").foregroundStyle(Color.qGray4)
                stat("This month", "\(answersThisMonth) \(answersThisMonth == 1 ? "reflection" : "reflections")")
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.qField)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.qLine, lineWidth: 1)
        )
    }

    private func weekdayAbbreviation(for date: Date) -> String {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        switch weekday {
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return "Sun"
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        (Text(title + ": ").font(.ui(12)).foregroundStyle(Color.qGray)
            + Text(value).font(.ui(12.5, .bold)).foregroundStyle(Color.qInk))
            .lineLimit(1)
    }
}

/// Bio: three lines, then "more" (only when it really is longer). Tap to open or close.
private struct ExpandableBio: View {
    let text: String
    @State private var expanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var clippedHeight: CGFloat = 0

    private func bioText(_ lines: Int?) -> some View {
        Text(text)
            .font(.ui(15))
            .foregroundStyle(Color.qInk2)
            .lineSpacing(4)
            .lineLimit(lines)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var isTruncated: Bool { fullHeight > clippedHeight + 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxs) {
            bioText(expanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)
            if isTruncated {
                Text(expanded ? "less" : "more")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qGray)
            }
        }
        // Measure both versions off-screen to know whether "more" is needed.
        .background {
            ZStack {
                bioText(nil).fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fullHeight = $0 }
                bioText(3).fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { clippedHeight = $0 }
            }
            .hidden()
        }
        .contentShape(Rectangle())
        .onTapGesture { if isTruncated { withAnimation(.qSmooth) { expanded.toggle() } } }
        .accessibilityAddTraits(isTruncated ? .isButton : [])
    }
}

/// Horizontal strip of milestones with a link to all achievements.
struct BadgesStrip: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let items = store.achievements
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: DS.Space.s) {
                IconChip(icon: .medalFill, tint: .qGold, fill: .qGoldSoft)
                Text("Milestones").font(.ui(17, .semibold)).foregroundStyle(Color.qInk)
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
                                HexBadge(asset: item.badgeAsset, isLocked: !item.isUnlocked)
                                    .frame(width: 50, height: 56)
                                Text(item.title)
                                    .font(.ui(12, item.isUnlocked ? .medium : .regular))
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
