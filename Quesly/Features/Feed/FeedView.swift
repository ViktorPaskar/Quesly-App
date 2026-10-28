import SwiftUI

/// World / Friends feeds on white: wordmark + streak, Threads-style tabs, then flat answer rows
/// as white rounded cards 8 pt apart on a light gray canvas. World opens with the question card; Friends with your own answer.
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

    // Twitter/X style collapsing header on scroll
    @State private var isHeaderHidden = false
    @State private var lastScrollY: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
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

            // Twitter/X style collapsing header on scroll
            VStack(spacing: 0) {
                headerView
                if !network.isOnline {
                    OfflineBanner()
                }
            }
            .background(Color.qBackground.ignoresSafeArea(edges: .top))
            .offset(y: isHeaderHidden ? -100 : 0)
            .opacity(isHeaderHidden ? 0 : 1)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isHeaderHidden)
        .background(Color.qBackground)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: scope) { _, _ in
            lastScrollY = 0
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isHeaderHidden = false
            }
        }
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

    private var headerView: some View {
        VStack(spacing: 0) {
            ZStack {
                Image("brand-wordmark")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(1900.0 / 602.0, contentMode: .fit)
                    .frame(height: 28)
                    .foregroundStyle(Color.qInk)
                    .accessibilityLabel("Quesly")
                HStack {
                    Spacer()
                    Button { showStreak = true } label: { StreakChip(days: shownStreak ?? store.streak) }
                        .buttonStyle(.pressable)
                        .accessibilityHint("Opens your streak calendar")
                }
            }
            .padding(.horizontal, DS.Space.s)
            .frame(height: 44)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

            FullWidthFeedScopeBar(scope: $scope)
        }
        .background(Color.qBackground)
    }

    private func handleScroll(currentY: CGFloat) {
        guard lastScrollY != 0 else {
            lastScrollY = currentY
            return
        }

        if currentY >= -10 {
            if isHeaderHidden {
                Task { @MainActor in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isHeaderHidden = false
                    }
                }
            }
            lastScrollY = currentY
            return
        }

        let diff = currentY - lastScrollY
        if diff < -24 {
            if !isHeaderHidden {
                Task { @MainActor in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isHeaderHidden = true
                    }
                }
            }
            lastScrollY = currentY
        } else if diff > 24 {
            if isHeaderHidden {
                Task { @MainActor in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isHeaderHidden = false
                    }
                }
            }
            lastScrollY = currentY
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
                    if scope == self.scope {
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: FeedScrollOffsetKey.self,
                                value: geo.frame(in: .named("feedScrollSpace_\(scope.rawValue)")).minY
                            )
                        }
                        .frame(height: 0)
                    }

                    Color.clear.frame(height: 84).id("top")

                    TodayQuestionBanner(question: store.todayQuestion,
                                        answeredCount: store.answeredTodayCount) {
                        showQuestion = true
                    }

                    if scope == .friends && !store.friendStories.isEmpty {
                        FriendStoriesRow { index in
                            storyLaunch = StoryLaunch(stories: store.friendStories, start: index)
                        }
                        .outlinedBlock()
                        .padding(.horizontal, DS.Space.s)
                        .padding(.bottom, gap)
                    }

                    if let mine {
                        AnswerCard(answer: mine, isHighlighted: highlightsMine)
                            .outlinedBlock()
                            .padding(.horizontal, DS.Space.s)
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
                                    .outlinedBlock()
                                    .padding(.horizontal, DS.Space.s)
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
            .coordinateSpace(name: "feedScrollSpace_\(scope.rawValue)")
            .onPreferenceChange(FeedScrollOffsetKey.self) { currentY in
                if scope == self.scope {
                    handleScroll(currentY: currentY)
                }
            }
            .refreshable { await store.reloadFeed() }
            .onChange(of: scrollToTopSignal) { _, _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    isHeaderHidden = false
                }
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
    private let gap: CGFloat = DS.Space.xs

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
                .foregroundStyle(Color.qGreen)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.qGreen.opacity(0.10)))
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

/// Opening hero card: today's question with tactile lime keyword sticker, watermark, time-left pill, and integrated action dock.
struct TodayQuestionBanner: View {
    @Environment(AppStore.self) private var store
    let question: DailyQuestion
    var answeredCount: Int = 0
    var onTap: () -> Void = {}

    private var words: [String] {
        question.text.split(separator: " ").map(String.init)
    }

    var body: some View {
        let highlighted = question.keyWords
        let hasAnswered = store.hasAnsweredToday
        let friends = store.friendsAnsweredToday

        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    // Top metadata row
                    HStack(spacing: DS.Space.xs) {
                        MascotCoin(hasAnswered: hasAnswered)
                        Text("TODAY'S QUESTION")
                            .font(.ui(12, .bold))
                            .tracking(0.6)
                            .lineLimit(1)
                            .foregroundStyle(Color.qLime)
                        Spacer(minLength: DS.Space.xs)
                        if hasAnswered {
                            HStack(spacing: 5) {
                                Icon(.checkBold, size: 11)
                                Text("Answered")
                                    .font(.ui(12, .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color.qLime)
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(Capsule().fill(Color.white.opacity(0.14)))
                        } else {
                            HStack(spacing: 4) {
                                Icon(.clock, size: 12, weight: .semibold)
                                Text("\(AppStore.timeLeftString()) left")
                                    .font(.ui(12, .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(.horizontal, 10)
                            .frame(height: 26)
                            .background(Capsule().fill(.white.opacity(0.14)))
                        }
                    }
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

                    // The Question Headline with Tactile Sticker
                    WrappingHStack(spacing: 6, lineSpacing: 4, centered: false) {
                        ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                            let clean = word.uppercased().filter(\.isLetter)
                            let isHot = highlighted.contains(clean)
                            Text(word)
                                .font(.display(24, .bold))
                                .foregroundStyle(isHot ? Color.qGreen : .white)
                                .padding(.horizontal, isHot ? 8 : 0)
                                .padding(.vertical, isHot ? 1 : 0)
                                .background {
                                    if isHot {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.qLime)
                                            .shadow(color: .black.opacity(0.14), radius: 4, y: 2)
                                    }
                                }
                                .rotationEffect(.degrees(isHot ? -2 : 0))
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(18)

                if !hasAnswered {
                    // Integrated Action Dock flush with edges and bottom
                    HStack(spacing: DS.Space.xs) {
                        HStack(spacing: 8) {
                            if !friends.isEmpty {
                                AvatarStack(users: friends, size: 24, ring: Color.qGreenDeep)
                            } else {
                                Icon(.fireFill, size: 14)
                                    .foregroundStyle(Color.qFlame)
                            }
                            Text(answeredCount > 0
                                 ? "\(answeredCount) answered" + (friends.isEmpty ? "" : " · \(friends.count) friends")
                                 : "Be the first to answer")
                                .font(.ui(13, .medium))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        HStack(spacing: 5) {
                            Text("Answer")
                                .font(.ui(13, .bold))
                            Icon(.arrowRightBold, size: 11)
                        }
                        .foregroundStyle(Color.qGreenDeep)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(Capsule().fill(Color.qLime))
                        .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.qGreenDeep.opacity(0.60))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.qGreen)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.qGreen.opacity(0.18), radius: 14, y: 6)
            .padding(.horizontal, DS.Space.s)
            .padding(.top, DS.Space.s)
            .padding(.bottom, DS.Space.xs)
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
    }
}

/// Full-width Twitter (X) style tabs ("World" and "Friends") with sliding active indicator and edge-to-edge layout
struct FullWidthFeedScopeBar: View {
    @Binding var scope: FeedScope
    @Namespace private var ns

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(FeedScope.allCases) { item in
                    let isSelected = item == scope
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            scope = item
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(item.rawValue)
                                .font(.ui(15, isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color.qInk : Color.qGray)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)

                            // Twitter/X style active underline indicator
                            ZStack {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 3.5)
                                if isSelected {
                                    Capsule()
                                        .fill(Color.qGreen)
                                        .frame(width: 54, height: 3.5)
                                        .matchedGeometryEffect(id: "scopeIndicator", in: ns)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            Rectangle()
                .fill(Color.qLine)
                .frame(height: 1)
        }
        .background(Color.qBackground)
        .sensoryFeedback(.selection, trigger: scope)
    }
}

struct FeedScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Dynamic Quesly mascot badge with subtle resting curiosity pulse
struct MascotCoin: View {
    let hasAnswered: Bool
    @State private var breathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        QueslyMark(color: .qGreen, cutout: .qLime)
            .frame(width: 17)
            .frame(width: 28, height: 28)
            .background(Circle().fill(Color.qLime))
            .shadow(color: Color.black.opacity(0.12), radius: 3, y: 1)
            .scaleEffect(!hasAnswered && !reduceMotion && breathing ? 1.06 : 1.0)
            .onAppear {
                guard !hasAnswered, !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    breathing = true
                }
            }
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
