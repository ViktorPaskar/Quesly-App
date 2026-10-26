import SwiftUI

/// World / Friends feeds on white: wordmark + streak, Threads-style tabs, then flat answer rows
/// as white strips 6 pt apart on a light gray canvas. World opens with the question card; Friends with your own answer.
struct FeedView: View {
    @Environment(AppStore.self) private var store
    @State private var scope: FeedScope = DemoConfig.initialFeedScope
    @State private var showQuestion = false
    @State private var showStreak = false
    @Environment(NetworkMonitor.self) private var network
    @Environment(\.scrollToTopSignal) private var scrollToTopSignal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onDiscover: () -> Void = {}
    private var tour: DemoTour { DemoTour.shared }

    @State private var storyLaunch: StoryLaunch?
    // "Feed unlocked" moment after posting: rows reveal one by one, the streak ticks up.
    @State private var revealCount = Int.max
    @State private var shownStreak: Int?
    @State private var highlightsMine = false
    @State private var unlockHaptic = 0

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Image("brand-wordmark")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(1900.0 / 602.0, contentMode: .fit)
                    .frame(height: 20)
                    .foregroundStyle(Color.qInk)
                    .accessibilityLabel("Quesly")
                HStack {
                    Spacer()
                    Button { showStreak = true } label: { StreakChip(days: shownStreak ?? store.streak) }
                        .buttonStyle(.pressable)
                        .accessibilityHint("Opens your streak calendar")
                }
            }
            .padding(.horizontal, DS.Space.m)
            .frame(height: 44)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            UnderlineTabs(items: FeedScope.allCases, selection: $scope, title: \.rawValue)
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
            // Light gray behind the list; each answer is a white strip, 6 pt apart.
            .background(Color.qFeedCanvas)
        }
        .background(Color.qBackground)
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
        .sheet(isPresented: $showStreak) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: DS.Space.s) {
                        StreakCard()
                        MemoriesCard(showsHeader: false)
                    }
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.vertical, DS.Space.m)
                }
                .background(Color.qBackground)
                .navigationTitle("Your streak")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
        let mine = answers.first { $0.authorId == store.me.id }
        let others = answers.filter { $0.authorId != store.me.id }
        let trayTarget = others.first?.id
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    Color.clear.frame(height: 0).id("top")

                    if scope == .world {
                        TodayQuestionBanner(question: store.todayQuestion) {
                            if !store.hasAnsweredToday { showQuestion = true }
                        }
                    }
                    if !store.hasAnsweredToday {
                        AnswerPrompt { showQuestion = true }
                    }

                    if let mine {
                        Text("Your answer")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Color.qGray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.Space.m)
                            .padding(.top, DS.Space.s)
                        AnswerCard(answer: mine, isHighlighted: highlightsMine)
                            .background(Color.qBackground)
                            .padding(.bottom, gap)
                    }

                    if let error = store.feedError {
                        ErrorStateView(message: error) {
                            Task { await store.reloadFeed() }
                        }
                    } else if store.isLoadingFeed && others.isEmpty {
                        ForEach(0..<4, id: \.self) { _ in AnswerCardSkeleton() }
                    } else {
                        ForEach(Array(others.enumerated()), id: \.element.id) { index, answer in
                            let isShown = index + 1 < revealCount
                            VStack(spacing: 0) {
                                AnswerCard(answer: answer,
                                           opensTray: (DemoConfig.opensReactionTray || tour.openTray) && answer.id == trayTarget)
                                    .background(Color.qBackground)
                                    .padding(.bottom, gap)
                            }
                            .zIndex(Double(index))
                            .opacity(isShown ? 1 : 0)
                            .offset(y: isShown ? 0 : 16)
                            .staggeredAppear(index)
                        }
                    }

                    if store.feedError != nil || store.isLoadingFeed {
                        EmptyView()
                    } else if scope == .friends && others.isEmpty {
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
                    } else if !others.isEmpty {
                        CaughtUpFooter(count: others.count, scope: scope) {
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

    /// Space between answer strips; the gray canvas shows through.
    private let gap: CGFloat = 6

    /// The moment the day's answers unlock: your answer lands first and glows, the others
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
                .background(Capsule().fill(Color.qField))
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

/// 🔥 streak counter (feed and profile headers): gray pill, flame 16, number in Outfit.
struct StreakChip: View {
    let days: Int
    var fill: Color = .qField

    var body: some View {
        HStack(spacing: DS.Space.xxs) {
            Icon(.fireFill, size: 16)
                .foregroundStyle(Color.qFlame)
                .pop(on: days)
            Text("\(days)")
                .font(.display(15, .bold))
                .foregroundStyle(Color.qInk)
                .contentTransition(.numericText())
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .frame(height: 32)
        .background(Capsule().fill(fill))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days) day streak")
    }
}

/// World's opening card: today's question on brand green.
struct TodayQuestionBanner: View {
    let question: DailyQuestion
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            // Laid out like an answer card: Quesly is the author, the question is the post.
            HStack(alignment: .top, spacing: DS.Space.s) {
                QueslyMark(color: .qGreen, cutout: .qLime)
                    .frame(width: 24)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.qLime))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Quesly")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(Color.qLime)
                        .frame(height: 20)
                        .padding(.top, -2)
                    Text(question.text)
                        .font(.display(20, .medium))
                        .lineSpacing(2)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, DS.Space.xxs)
                }
            }
            .padding(DS.Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qGreen))
            .padding(.horizontal, DS.Space.m)
            .padding(.top, DS.Space.m)
            .padding(.bottom, DS.Space.xxs)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
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
