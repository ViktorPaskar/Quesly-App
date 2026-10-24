import SwiftUI

/// Profile: centred identity, stats, streak and badges in white blocks on the canvas, then answers.
struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let userId: String
    var isTabRoot = false
    @State private var confirmBlock = false
    @State private var list: ListKind = .answers

    /// Your profile: your answers (plus reposts) or your private Saved list.
    enum ListKind: String, CaseIterable, Identifiable {
        case answers = "Answers", saved = "Saved"
        var id: String { rawValue }
    }

    private var isMe: Bool { userId == store.me.id }

    var body: some View {
        let user = store.user(userId)
        let answers = store.answers(of: userId)
        // Answers mixes your own with the ones you reposted, newest first.
        let items: [Answer] = !isMe ? answers
            : list == .saved ? store.bookmarkedAnswers
            : (answers + store.resharedAnswers).sorted { $0.createdAt > $1.createdAt }

        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 0) {
                ProfileHeader(user: user, isMe: isMe)
                    .padding(.horizontal, DS.Space.m)
                    .padding(.top, DS.Space.xs)

                HStack(spacing: 6) {
                    if isMe {
                        PillTabs(items: ListKind.allCases, selection: $list, title: \.rawValue)
                    } else {
                        Text("Answers").font(.ui(17, .semibold)).foregroundStyle(Color.qInk)
                        Text("\(answers.count)").font(.ui(15)).foregroundStyle(Color.qGray)
                    }
                    Spacer()
                }
                .padding(.horizontal, DS.Space.m)
                .padding(.top, DS.Space.xl)
                .padding(.bottom, DS.Space.xxs)
                .id("list")

                // Same white cards as the feed.
                LazyVStack(spacing: DS.Space.xs) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, answer in
                        let other = answer.authorId != userId
                        AnswerCard(answer: answer, showsQuestion: true, showsAuthor: other,
                                   isRepost: other && list == .answers)
                            .background(Color.qBlock)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
                            .staggeredAppear(index)
                    }
                    if items.isEmpty {
                        EmptyStateView(
                            icon: list == .saved ? .bookmarkSimpleFill : .chatCircleTextFill,
                            title: list == .saved ? "Nothing saved yet" : "No answers yet",
                            message: list == .saved ? "Tap the bookmark on an answer to keep it here. Only you can see this list."
                                : isMe ? "Answer today's question to start your story." : "Their answers will show up here.")
                    }
                }
                .padding(.horizontal, DS.Space.m)
                .padding(.top, DS.Space.xs)
                .animation(.qSmooth, value: list)
            }
            .padding(.bottom, DS.Space.m)
        }
        .task {
            guard DemoConfig.scrollsProfileToList else { return }
            try? await Task.sleep(for: .milliseconds(500))
            proxy.scrollTo("list", anchor: .top)
        }
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

/// Profile top: identity centred on the canvas, one stats block, then (on your own profile)
/// the streak and badges. Everything sits on one 16pt grid.
struct ProfileHeader: View {
    @Environment(AppStore.self) private var store
    let user: AppUser?
    let isMe: Bool
    @State private var appeared = false

    private var followingCount: Int { isMe ? store.followingUsers.count : (user?.following ?? 0) }

    var body: some View {
        VStack(spacing: DS.Space.s) {
            identity.staggeredAppear(0)
            stats.staggeredAppear(1)
            if isMe {
                StreakCard().staggeredAppear(2)
                BadgesStrip().block().staggeredAppear(3)
            }
        }
        .onAppear { withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.05)) { appeared = true } }
    }

    // MARK: Identity

    private var identity: some View {
        VStack(spacing: 0) {
            Avatar(user: user, size: 96)
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

            HStack(spacing: DS.Space.xs) {
                Text(user?.username ?? "")
                    .font(.display(26, .bold))
                    .foregroundStyle(Color.qInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let badge = user?.badge {
                    HexBadge(color: badge.color, icon: badge.icon).frame(width: 20, height: 20)
                }
            }
            .padding(.top, DS.Space.s)

            if let location = user?.location, !location.isEmpty {
                IconLabel(location, icon: .mapPinFill, size: DS.Icon.caption)
                    .font(.ui(15))
                    .foregroundStyle(Color.qGray)
                    .lineLimit(1)
                    .padding(.top, DS.Space.xxs)
            }

            if let bio = user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.ui(15))
                    .foregroundStyle(Color.qInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, DS.Space.s)
                    .padding(.top, DS.Space.s)
            }

            actions.padding(.top, DS.Space.l)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, DS.Space.xs)
    }

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
                    pill(following ? "Following" : "Follow", filled: !following)
                }
                .buttonStyle(.pressable)
                .sensoryFeedback(.success, trigger: following)
                .animation(.qSpring, value: following)
                ShareLink(item: Invite.text(for: user.username)) { pill("Share profile") }
                    .buttonStyle(.pressable)
            }
        }
    }

    private func pill(_ title: String, filled: Bool = false) -> some View {
        Text(title)
            .font(.ui(15, .semibold))
            .foregroundStyle(filled ? Color.white : Color.qInk)
            .frame(maxWidth: .infinity)
            .frame(height: DS.hitTarget)
            .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                .fill(filled ? Color.qGreen : Color.qBlock))
    }

    // MARK: Stats

    /// One block, three equal columns split by hairlines, like the balance row in a banking app.
    private var stats: some View {
        HStack(spacing: 0) {
            if isMe {
                let count = store.answers(of: store.me.id).count
                stat(count, count == 1 ? "Answer" : "Answers", route: nil)
            } else {
                stat(user?.streak ?? 0, "Day streak", route: nil)
            }
            hairline
            stat(user?.followers ?? 0, "Followers", route: isMe ? .followers : nil)
            hairline
            stat(followingCount, "Following", route: isMe ? .following : nil)
        }
        .padding(.vertical, DS.Space.m)
        .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qBlock))
    }

    private var hairline: some View {
        Rectangle().fill(Color.qLine).frame(width: 1, height: 32)
    }

    @ViewBuilder
    private func stat(_ value: Int, _ label: String, route: Route?) -> some View {
        let content = VStack(spacing: 2) {
            CountUpText(value: value)
                .font(.display(22, .bold))
                .foregroundStyle(Color.qInk)
            Text(label)
                .font(.ui(13))
                .foregroundStyle(Color.qGray)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        if let route {
            NavigationLink(value: route) { content }.buttonStyle(.pressable)
        } else {
            content
        }
    }
}

/// Your streak as a picture: the last seven days as a chain of dots (answered, frozen, missed,
/// today), progress to the next freeze, and a row that opens the full calendar of memories.
struct StreakCard: View {
    @Environment(AppStore.self) private var store
    @State private var showsCalendar = false
    @State private var showsFreezeInfo = false

    private let calendar = Calendar.current

    private var week: [Date] {
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            weekStrip.padding(.top, DS.Space.l)
            freezeProgress.padding(.top, DS.Space.l)
            Rectangle().fill(Color.qLine).frame(height: 1)
                .padding(.top, DS.Space.m)
            calendarRow
        }
        .padding(.horizontal, DS.Space.m)
        .padding(.top, DS.Space.m)
        .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qBlock))
        .sheet(isPresented: $showsCalendar) {
            NavigationStack {
                ScrollView { MemoriesCard().padding(DS.Space.m) }
                    .background(Color.qCanvas)
                    .navigationTitle("Memories")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            guard DemoConfig.opensMemory else { return }
            showsCalendar = true
        }
    }

    private var header: some View {
        HStack(spacing: DS.Space.s) {
            IconChip(icon: .fireFill, tint: .qFlame, fill: Color.qFlameSoft)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(store.streak)-day streak")
                    .font(.ui(17, .semibold))
                    .foregroundStyle(Color.qInk)
                Text(store.hasAnsweredToday ? "See you tomorrow" : "Answer today to keep it")
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
            }
            Spacer(minLength: DS.Space.xs)
            Button { showsFreezeInfo = true } label: {
                HStack(spacing: DS.Space.xxs) {
                    Icon(.snowflake, size: DS.Icon.caption, weight: .semibold)
                    Text("\(store.streakFreezes)").font(.ui(15, .semibold))
                }
                .foregroundStyle(Color.qIce)
                .padding(.horizontal, DS.Space.s)
                .frame(height: 32)
                .background(Capsule().fill(Color.qIceSoft))
                .frame(minHeight: DS.hitTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("\(store.streakFreezes) streak freezes")
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

    // MARK: Week

    private enum DayState { case answered, frozen, today, missed }

    private func state(_ day: Date) -> DayState {
        if store.answeredDays.contains(day) { return .answered }
        if store.frozenDays.contains(day) { return .frozen }
        return calendar.isDateInToday(day) ? .today : .missed
    }

    private func kept(_ day: Date?) -> Bool {
        guard let day else { return false }
        let s = state(day)
        return s == .answered || s == .frozen
    }

    private var weekStrip: some View {
        let days = week
        return HStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                let isToday = calendar.isDateInToday(day)
                VStack(spacing: DS.Space.xs) {
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.ui(12, isToday ? .semibold : .regular))
                        .foregroundStyle(isToday ? Color.qInk : Color.qGray)
                    dot(state(day))
                        .frame(maxWidth: .infinity)
                        .background {
                            // The chain: a bar joins neighbouring kept days.
                            HStack(spacing: 0) {
                                chainHalf(kept(day) && kept(i > 0 ? days[i - 1] : nil))
                                chainHalf(kept(day) && kept(i < days.count - 1 ? days[i + 1] : nil))
                            }
                            .frame(height: 6)
                        }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Last 7 days: \(days.filter { store.answeredDays.contains($0) }.count) answered")
    }

    private func chainHalf(_ on: Bool) -> some View {
        Rectangle().fill(on ? Color.qGreen : .clear)
    }

    @ViewBuilder
    private func dot(_ state: DayState) -> some View {
        let size: CGFloat = 34
        switch state {
        case .answered:
            Icon(.checkBold, size: DS.Icon.caption, weight: .bold)
                .foregroundStyle(Color.qLime)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.qGreen))
        case .frozen:
            Icon(.snowflake, size: DS.Icon.caption, weight: .semibold)
                .foregroundStyle(Color.qIce)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.qIceSoft))
                .overlay(Circle().stroke(Color.qGreen, lineWidth: 2))
        case .today:
            Circle()
                .strokeBorder(Color.qGreen, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                .background(Circle().fill(Color.qBlock))
                .frame(width: size, height: size)
        case .missed:
            Circle().fill(Color.qField).frame(width: size, height: size)
        }
    }

    // MARK: Freeze progress

    private var freezeProgress: some View {
        let full = store.streakFreezes >= AppStore.maxFreezes
        let into = store.streak % 7
        let left = 7 - into
        return VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack {
                Text(full ? "Freezes full" : "Next freeze")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Text(full ? "\(AppStore.maxFreezes) of \(AppStore.maxFreezes)" : left == 1 ? "1 day to go" : "\(left) days to go")
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.qField)
                    Capsule().fill(Color.qIce)
                        .frame(width: geo.size.width * (full ? 1 : CGFloat(into) / 7))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
    }

    private var calendarRow: some View {
        Button { showsCalendar = true } label: {
            HStack(spacing: DS.Space.s) {
                Icon(.calendar, size: DS.Icon.row)
                    .foregroundStyle(Color.qBrandText)
                Text("Memories")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Text("\(store.answeredDays.count) days")
                    .font(.ui(15))
                    .foregroundStyle(Color.qGray)
                Icon(.caretRightBold, size: DS.Icon.caption)
                    .foregroundStyle(Color.qGray)
            }
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityHint("Opens your calendar of answers")
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
