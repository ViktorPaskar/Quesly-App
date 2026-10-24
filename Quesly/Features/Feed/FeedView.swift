import SwiftUI

struct FeedView: View {
    @Environment(AppStore.self) private var store
    @State private var scope: FeedScope = DemoConfig.initialFeedScope
    @State private var showQuestion = false
    @Environment(NetworkMonitor.self) private var network
    @Environment(\.scrollToTopSignal) private var scrollToTopSignal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onDiscover: () -> Void = {}
    private var tour: DemoTour { DemoTour.shared }

    @State private var storyLaunch: StoryLaunch?
    // "Feed unlocked" moment after posting: cards reveal one by one, the streak ticks up.
    @State private var revealCount = Int.max
    @State private var shownStreak: Int?
    @State private var highlightsMine = false
    @State private var unlockHaptic = 0

    var body: some View {
        VStack(spacing: 0) {
            // Logo centred with the streak on the right; the World/Friends switch sits below it.
            ZStack {
                QueslyLogo(height: 20, markColor: .qGreen, textColor: .qInk, background: .qLime)
                HStack {
                    Spacer()
                    StreakChip(days: shownStreak ?? store.streak)
                }
            }
            .padding(.horizontal, DS.Space.screen)
            .frame(height: 48)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            PillTabs(items: FeedScope.allCases, selection: $scope, title: \.rawValue)
                .padding(.bottom, DS.Space.xxs)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            if !network.isOnline {
                OfflineBanner().transition(.move(edge: .top).combined(with: .opacity))
            }

            // Swipe sideways between the two feeds.
            TabView(selection: $scope) {
                ForEach(FeedScope.allCases) { s in
                    feedPage(s).tag(s)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.qSmooth, value: network.isOnline)
        }
        .background(Color.qCanvas)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showQuestion) {
            DailyQuestionView(onSubmitted: {
                                  showQuestion = false
                                  store.unlockCelebrationAt = .now.addingTimeInterval(0.5)
                              },
                              onClose: { showQuestion = false })
        }
        .fullScreenCover(item: $storyLaunch) { launch in
            StoryViewer(stories: launch.stories, start: launch.start)
        }
        .sensoryFeedback(.success, trigger: unlockHaptic)
        .task(id: store.unlockCelebrationAt) { await celebrateUnlock() }
        .task {
            guard DemoConfig.opensStory, storyLaunch == nil else { return }
            storyLaunch = StoryLaunch(stories: store.friendStories, start: 0)
        }
        .onChange(of: tour.feedScope) { _, s in if let s { withAnimation(.qSmooth) { scope = s } } }
        .onChange(of: tour.showStory) { _, on in
            storyLaunch = on ? StoryLaunch(stories: store.friendStories, start: 0) : nil
        }
    }

    private func feedPage(_ scope: FeedScope) -> some View {
        let answers = store.feed(scope)
        let othersCount = answers.filter { $0.authorId != store.me.id }.count
        return ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        Color.clear.frame(height: 0).id("top")

                        FriendStoriesRow { index in
                            storyLaunch = StoryLaunch(stories: store.friendStories, start: index)
                        }

                        // Scrolls away with the content instead of permanently taking ~130 pt.
                        TodayQuestionBanner(question: store.todayQuestion) {
                            if !store.hasAnsweredToday { showQuestion = true }
                        }

                        if !store.hasAnsweredToday {
                            AnswerPrompt { showQuestion = true }
                        }
                        if store.freezeJustUsed != nil {
                            FreezeUsedNote(streak: store.streak) {
                                withAnimation(.qSmooth) { store.freezeJustUsed = nil }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        if let error = store.feedError {
                            ErrorStateView(message: error) {
                                Task { await store.reloadFeed() }
                            }
                        } else if store.isLoadingFeed && othersCount == 0 {
                            ForEach(0..<4, id: \.self) { _ in AnswerCardSkeleton() }
                        } else {
                            ForEach(Array(answers.enumerated()), id: \.element.id) { index, answer in
                                let isShown = index < revealCount
                                Group {
                                    AnswerCard(answer: answer,
                                               opensTray: (DemoConfig.opensReactionTray || tour.openTray)
                                                   && answer.id == answers.first(where: { $0.authorId != store.me.id })?.id,
                                               isHighlighted: highlightsMine && answer.authorId == store.me.id,
                                               isPinnedMine: answer.authorId == store.me.id)
                                }
                                // Each answer is its own white card on the gray canvas.
                                .background(Color.qBlock)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
                                .padding(.horizontal, DS.Space.s)
                                .padding(.top, DS.Space.xs)
                                .opacity(isShown ? 1 : 0)
                                .offset(y: isShown ? 0 : 16)
                                .staggeredAppear(index)
                            }
                        }

                        if store.feedError != nil || store.isLoadingFeed {
                            EmptyView()
                        } else if scope == .friends && othersCount == 0 {
                            EmptyStateView(icon: .userFill,
                                           title: "Your friends are quiet",
                                           message: "None of the people you follow answered yet. Invite friends or discover new people.") {
                                VStack(spacing: DS.Space.s) {
                                    ShareLink(item: Invite.text(for: store.me.username)) {
                                        Text("Invite friends")
                                            .font(.ui(16, .semibold))
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity).frame(height: 50)
                                            .background(Capsule().fill(Color.qGreen))
                                    }
                                    .buttonStyle(.pressable)
                                    Button("Discover people", action: onDiscover)
                                        .font(.ui(16))
                                        .foregroundStyle(Color.qBrandText)
                                        .frame(height: DS.hitTarget)
                                }
                            }
                        } else if othersCount > 0 {
                            CaughtUpFooter(count: othersCount, scope: scope) {
                                withAnimation(.qSmooth) { proxy.scrollTo("top", anchor: .top) }
                            }
                            .id("end")
                        }
                    }
                    .padding(.bottom, DS.Space.s)
                    .animation(.qSmooth, value: scope)
                }
                .refreshable { await store.reloadFeed() }
                .onChange(of: scrollToTopSignal) { _, _ in
                    withAnimation(.qSmooth) { proxy.scrollTo("top", anchor: .top) }
                }
                .task {
                    guard DemoConfig.scrollsFeedToEnd else { return }
                    try? await Task.sleep(for: .milliseconds(800))
                    proxy.scrollTo("end", anchor: .bottom)
                }
            }
    }

    /// The moment the day's answers unlock: your card lands first and glows, the others
    /// follow one by one, the streak ticks up with a success haptic.
    private func celebrateUnlock() async {
        guard let at = store.unlockCelebrationAt else { return }
        // Cleared only at the end: changing the task id earlier would cancel this task.
        defer { store.unlockCelebrationAt = nil }
        let streak = store.streak
        if !reduceMotion {
            revealCount = 1
            shownStreak = max(0, streak - 1)
        }
        highlightsMine = true
        let wait = at.timeIntervalSinceNow
        if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }

        unlockHaptic += 1
        withAnimation(.qSpring) { shownStreak = nil }
        if !reduceMotion {
            for step in 2...max(2, store.feed(scope).count + 1) {
                try? await Task.sleep(for: .milliseconds(90))
                withAnimation(.qSmooth) { revealCount = step }
            }
        }
        revealCount = .max
        try? await Task.sleep(for: .seconds(1.6))
        withAnimation(.qSmooth) { highlightsMine = false }
    }
}

/// One-time note after a streak freeze covered a missed day.
private struct FreezeUsedNote: View {
    let streak: Int
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.s) {
            Icon(.snowflake, size: DS.Icon.inline, weight: .semibold)
                .foregroundStyle(Color.qIce)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.qBackground))
            VStack(alignment: .leading, spacing: 2) {
                Text("Streak saved")
                    .font(.ui(16, .semibold))
                    .foregroundStyle(Color.qInk)
                Text("You missed yesterday, so a streak freeze kept your \(streak)-day streak alive.")
                    .font(.ui(15))
                    .foregroundStyle(Color.qGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Icon(.xBold, size: DS.Icon.caption)
                    .foregroundStyle(Color.qGray)
                    .frame(width: DS.hitTarget, height: DS.hitTarget)
                    .contentShape(Rectangle())
            }
            .padding(.trailing, -DS.Space.s)
            .padding(.top, -DS.Space.s)
            .accessibilityLabel("Dismiss")
        }
        .padding(DS.Space.m)
        .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qIceSoft))
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, DS.Space.s)
    }
}

/// The end of a finite feed — Quesly's answer to infinite scrolling.
struct CaughtUpFooter: View {
    let count: Int
    let scope: FeedScope
    var onBackToTop: () -> Void

    var body: some View {
        VStack(spacing: DS.Space.s) {
            Icon(.checkBold, size: DS.Icon.action)
                .foregroundStyle(Color.qBrandText)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.qMint))
            Text("You're all caught up")
                .font(.display(22, .semibold))
                .foregroundStyle(Color.qInk)
            Text("You've read all \(count) \(scope == .friends ? "answers from friends" : "answers") for today.")
                .font(.ui(15))
                .foregroundStyle(Color.qGray)
                .multilineTextAlignment(.center)
            TimelineView(.periodic(from: .now, by: 60)) { ctx in
                Label {
                    Text("Next question in **\(AppStore.timeLeftString(now: ctx.date))**")
                } icon: {
                    Icon(.clock, size: DS.Icon.inline)
                }
                .font(.ui(15))
                .foregroundStyle(Color.qInk)
                .padding(.horizontal, DS.Space.m)
                .frame(height: 36)
                .background(Capsule().fill(Color.qBlock))
            }
            .padding(.top, DS.Space.xxs)
            Button("Back to top", action: onBackToTop)
                .font(.ui(15, .semibold))
                .foregroundStyle(Color.qBrandText)
                .frame(minHeight: DS.hitTarget)
        }
        .padding(.horizontal, DS.Space.xxl)
        .padding(.top, DS.Space.xxl)
        .padding(.bottom, DS.Space.xl)
        .frame(maxWidth: .infinity)
    }
}

/// 🔥 streak counter in the feed header — a gentle nudge to come back tomorrow.
struct StreakChip: View {
    let days: Int
    /// White on the gray feed canvas; a light gray fill on white screens.
    var fill: Color = .qBlock

    var body: some View {
        HStack(spacing: 4) {
            Icon(.fireFill, size: DS.Icon.inline)
                .foregroundStyle(Color.qFlame)
                .pop(on: days)
            Text("\(days)")
                .font(.ui(15, .semibold))
                .foregroundStyle(Color.qInk)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Capsule().fill(fill))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days) day streak")
    }
}

struct TodayQuestionBanner: View {
    let question: DailyQuestion
    var onTap: () -> Void = {}
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                if !typeSize.isAccessibilitySize {
                    QueslyMark(color: .qGreen, cutout: .qLime)
                        .frame(width: 30)
                        .frame(width: 44, height: 44)
                        .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qLime))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Question")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Color.qLime)
                    Text(question.text.uppercased())
                        .font(.display(17, .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, DS.Space.m)
            .padding(.vertical, DS.Space.m)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qGreen))
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.s)
            .padding(.bottom, DS.Space.xxs)
        }
        .buttonStyle(.pressable)
    }
}

/// Shown at the top of the feed until the user has answered today's question.
private struct AnswerPrompt: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("You haven't answered yet")
                        .font(.ui(16, .semibold))
                        .foregroundStyle(Color.qGreen)
                    Text("Share your story to join today's conversation")
                        .font(.ui(15))
                        .foregroundStyle(Color.qGreen.opacity(0.8))
                }
                Spacer()
                Icon(.arrowRightBold, size: DS.Icon.inline)
                    .foregroundStyle(Color.qLime)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.qGreen))
                    .foregroundStyle(Color.qGreen)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qLime))
            .padding(16)
        }
        .buttonStyle(.pressable)
    }
}

#Preview {
    NavigationStack { FeedView() }.environment(AppStore()).environment(NetworkMonitor())
}

/// Shown at the top of the feed when there is no connection.
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: DS.Space.xs) {
            Icon(.info, size: DS.Icon.inline, weight: .semibold)
            Text("You're offline. Showing saved answers.").font(.ui(13))
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.qInk)
        .padding(.horizontal, DS.Space.screen)
        .frame(height: 36)
        .background(Color.qField)
        .accessibilityElement(children: .combine)
    }
}

/// Placeholder row with the same rhythm as `AnswerCard` while answers load.
struct AnswerCardSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.s) {
            Circle().fill(Color.qField).frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                bar(width: 120, height: 12)
                bar(width: nil, height: 14)
                bar(width: 220, height: 14)
            }
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.vertical, DS.Space.m)
        .opacity(dim ? 0.5 : 1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { dim = true }
        }
        .accessibilityLabel("Loading")
    }

    private func bar(width: CGFloat?, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: DS.Radius.s / 2, style: .continuous)
            .fill(Color.qField)
            .frame(maxWidth: width ?? .infinity)
            .frame(height: height)
    }
}

/// Generic error state with a retry action.
struct ErrorStateView: View {
    let message: String
    var retry: () -> Void

    var body: some View {
        EmptyStateView(icon: .xCircleFill, title: "Something went wrong", message: message) {
            Button(action: retry) {
                Text("Try again")
                    .font(.ui(16, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Space.xl)
                    .frame(height: DS.hitTarget)
                    .background(Capsule().fill(Color.qGreen))
            }
            .buttonStyle(.pressable)
        }
    }
}
