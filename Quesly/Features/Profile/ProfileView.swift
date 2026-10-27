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
    @State private var searchText = ""
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
                QueslyStatsCard()
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
                if tab == .answers && isMe {
                    searchBar
                }
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

    private var searchBar: some View {
        HStack(spacing: 8) {
            Icon(.magnifyingGlass, size: 14)
                .foregroundStyle(Color.qGray)
            TextField("Search answers & questions…", text: $searchText)
                .font(.ui(14))
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Icon(.xCircleFill, size: 14)
                        .foregroundStyle(Color.qGray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.qField)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.qLine, lineWidth: 0.75))
        )
        .padding(.horizontal, DS.Space.screen)
        .padding(.vertical, 8)
    }

    private func answers(for tab: ProfileTab) -> [Answer] {
        switch tab {
        case .answers:
            let all = store.answers(of: userId)
            if searchText.trimmingCharacters(in: .whitespaces).isEmpty { return all }
            let q = searchText.lowercased()
            return all.filter { $0.text.lowercased().contains(q) || $0.questionText.lowercased().contains(q) }
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
            if !searchText.isEmpty {
                EmptyStateView(icon: .magnifyingGlass, title: "No answers found",
                               message: "No answers match \"\(searchText)\".")
            } else {
                EmptyStateView(icon: .chatCircleTextFill, title: "No answers yet",
                               message: isMe ? "Answer today's question to start your story." : "Their answers will show up here.")
            }
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

/// Calendar tab, top block: clean white streak block with circular checkmark/empty days (no text clutter).
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
        VStack(alignment: .leading, spacing: 20) {
            // Header: big count in flame color + label (no verbose clutter)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(streak)")
                    .font(.display(46, .bold))
                    .tracking(-1.5)
                    .foregroundStyle(Color.qFlame)
                    .contentTransition(.numericText())
                Text(streak == 1 ? "day streak" : "days streak")
                    .font(.display(19, .bold))
                    .foregroundStyle(Color.qInk)
                Spacer(minLength: 0)
            }

            // 7-day Mon–Sun tracker: circles with checkmarks for streak days, empty circles with orange border
            weekCirclesRow

            // Clean bottom divider & minimal metric
            Rectangle()
                .fill(Color.qLine)
                .frame(height: 1)

            HStack {
                (Text("Personal best: ").font(.ui(12)).foregroundStyle(Color.qGray)
                    + Text("\(best) \(best == 1 ? "day" : "days")").font(.ui(12.5, .bold)).foregroundStyle(Color.qInk))
                Spacer(minLength: 0)
                (Text("This month: ").font(.ui(12)).foregroundStyle(Color.qGray)
                    + Text("\(answersThisMonth) \(answersThisMonth == 1 ? "day" : "days")").font(.ui(12.5, .bold)).foregroundStyle(Color.qInk))
            }
        }
        .padding(20)
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
        .accessibilityLabel("\(streak) day streak. Best: \(best) days.")
    }

    // MARK: - 7-Day Week Circles Row (Mon–Sun)

    private var weekCirclesRow: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let days = currentWeekDays

        return HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                let isToday = cal.isDate(day, inSameDayAs: today)
                let isDone = store.answeredDays.contains { cal.isDate($0, inSameDayAs: day) }

                VStack(spacing: 8) {
                    ZStack {
                        if isDone {
                            Circle()
                                .fill(Color.qFlame)
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Circle()
                                .strokeBorder(
                                    Color.qFlame,
                                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                                )
                        }
                    }
                    .frame(width: 36, height: 36)

                    Text(weekdayAbbreviation(for: day))
                        .font(.ui(11.5, isToday ? .medium : .regular))
                        .foregroundStyle(isToday ? Color.qFlame : Color.qGray)
                }
                .frame(maxWidth: .infinity)
            }
        }
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

/// Personal stats breakdown (Feature: My Quesly Stats): questions answered, active days,
/// saved answers count, and frequent reflection themes with clean proportional bars.
struct QueslyStatsCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Icon(.chartBarFill, size: 18)
                    .foregroundStyle(Color.qGreen)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.qGreen.opacity(0.12)))
                Text("Reflection stats")
                    .font(.display(18, .bold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Text("All time")
                    .font(.ui(12, .medium))
                    .foregroundStyle(Color.qGray)
            }

            // Metric pills (3 equal columns)
            HStack(spacing: 10) {
                metricBox(value: "\(store.totalQuestionsAnswered)", label: "Answered", icon: .chatCircleTextFill)
                metricBox(value: "\(store.uniqueActiveDays)", label: "Active days", icon: .calendarBlankFill)
                metricBox(value: "\(store.totalSavedCount)", label: "Saved", icon: .bookmarkSimpleFill)
            }

            Rectangle().fill(Color.qLine).frame(height: 1)

            // Top reflection themes
            VStack(alignment: .leading, spacing: 8) {
                Text("TOP REFLECTION TOPICS")
                    .font(.ui(11, .bold))
                    .tracking(0.7)
                    .foregroundStyle(Color.qGray)

                // Segmented proportion bar
                GeometryReader { geo in
                    HStack(spacing: 3) {
                        Capsule().fill(Color.qGreen).frame(width: geo.size.width * 0.45)
                        Capsule().fill(Color.qLime).frame(width: geo.size.width * 0.30)
                        Capsule().fill(Color(hex: 0x4285F4)).frame(width: max(0, geo.size.width * 0.25 - 6))
                    }
                }
                .frame(height: 7)

                // Legend
                HStack(spacing: 14) {
                    legendItem(color: Color.qGreen, text: "Stories 45%")
                    legendItem(color: Color.qLime, text: "Wisdom 30%")
                    legendItem(color: Color(hex: 0x4285F4), text: "Daily 25%")
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .outlinedBlock()
    }

    private func metricBox(value: String, label: String, icon: QIcon) -> some View {
        VStack(spacing: 3) {
            Icon(icon, size: 14)
                .foregroundStyle(Color.qBrandText)
            Text(value)
                .font(.display(20, .bold))
                .foregroundStyle(Color.qInk)
            Text(label)
                .font(.ui(11, .medium))
                .foregroundStyle(Color.qGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.qField))
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
                .font(.ui(12, .medium))
                .foregroundStyle(Color.qInk2)
        }
    }
}
