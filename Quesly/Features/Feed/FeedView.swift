import SwiftUI

struct FeedView: View {
    @Environment(AppStore.self) private var store
    @State private var scope: FeedScope = DemoConfig.initialFeedScope
    @State private var showQuestion = false
    @Environment(NetworkMonitor.self) private var network
    @Environment(\.scrollToTopSignal) private var scrollToTopSignal
    var onDiscover: () -> Void = {}

    var body: some View {
        let answers = store.feed(scope)
        let othersCount = answers.filter { $0.authorId != store.me.id }.count
        VStack(spacing: 0) {
            ZStack {
                QueslyLogo(height: 20, markColor: .qInk, textColor: .qInk, background: .qBackground)
                HStack {
                    Spacer()
                    StreakChip(days: store.streak)
                }
                .padding(.horizontal, DS.Space.screen)
            }
            .frame(height: 48)

            UnderlineTabs(items: FeedScope.allCases, selection: $scope, title: \.rawValue)

            if !network.isOnline {
                OfflineBanner().transition(.move(edge: .top).combined(with: .opacity))
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Scrolls away with the content instead of permanently taking ~130 pt.
                        TodayQuestionBanner(question: store.todayQuestion) {
                            if !store.hasAnsweredToday { showQuestion = true }
                        }
                        .id("top")

                        if !store.hasAnsweredToday {
                            AnswerPrompt { showQuestion = true }
                        }
                        if let error = store.feedError {
                            ErrorStateView(message: error) {
                                Task { await store.reloadFeed() }
                            }
                        } else if store.isLoadingFeed && othersCount == 0 {
                            ForEach(0..<4, id: \.self) { _ in AnswerCardSkeleton() }
                        } else {
                            ForEach(Array(answers.enumerated()), id: \.element.id) { index, answer in
                                AnswerCard(answer: answer, opensTray: DemoConfig.opensReactionTray
                                           && answer.id == answers.first(where: { $0.authorId != store.me.id })?.id)
                                    .staggeredAppear(index)
                                Rectangle().fill(Color.qLine).frame(height: 1).padding(.leading, 72)
                            }
                        }

                        if store.feedError != nil || store.isLoadingFeed {
                            EmptyView()
                        } else if scope == .friends && othersCount == 0 {
                            EmptyStateView(icon: .usersThreeFill,
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
                                        .font(.ui(16, .medium))
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
            .animation(.qSmooth, value: network.isOnline)
        }
        .background(Color.qBackground)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showQuestion) {
            DailyQuestionView(onSubmitted: { showQuestion = false },
                              onClose: { showQuestion = false })
        }
    }
}

/// The end of a finite feed — Quesly's answer to infinite scrolling.
struct CaughtUpFooter: View {
    let count: Int
    let scope: FeedScope
    var onBackToTop: () -> Void

    var body: some View {
        VStack(spacing: DS.Space.s) {
            Icon(.checkBold, size: 22)
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
                    Icon(.clock, size: 15)
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

/// 🔥 streak counter in the feed header — a gentle nudge to come back tomorrow.
struct StreakChip: View {
    let days: Int

    var body: some View {
        HStack(spacing: 4) {
            Icon(.fireFill, size: 18)
                .foregroundStyle(Color.qFlame)
                .pop(on: days)
            Text("\(days)")
                .font(.ui(15, .bold))
                .foregroundStyle(Color.qInk)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Capsule().fill(Color.qField))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days) day streak")
    }
}

struct TodayQuestionBanner: View {
    let question: DailyQuestion
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                QueslyMark(color: .qGreen, cutout: .qLime)
                    .frame(width: 24)
                    .frame(width: 44, height: 44)
                    .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qLime))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Today's Question")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Color.qLime)
                        Spacer()
                        TimelineView(.periodic(from: .now, by: 60)) { ctx in
                            HStack(spacing: 4) {
                                Icon(.clock, size: 13)
                                Text("\(AppStore.timeLeftString(now: ctx.date)) left")
                            }
                            .font(.ui(13, .medium))
                            .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    Text(question.text.uppercased())
                        .font(.display(17, .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
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
                        .font(.ui(14))
                        .foregroundStyle(Color.qGreen.opacity(0.8))
                }
                Spacer()
                Icon(.arrowRightBold, size: 18)
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
            Icon(.wifiSlash, size: 16, weight: .semibold)
            Text("You're offline. Showing saved answers.").font(.ui(13, .medium))
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
