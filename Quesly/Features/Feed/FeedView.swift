import SwiftUI

struct FeedView: View {
    @Environment(AppStore.self) private var store
    @State private var scope: FeedScope = DemoConfig.initialFeedScope
    @State private var showQuestion = false
    var onDiscover: () -> Void = {}

    var body: some View {
        let answers = store.feed(scope)
        VStack(spacing: 0) {
            ZStack {
                QueslyLogo(height: 20, markColor: .qInk, textColor: .qInk, background: .white)
                HStack {
                    Spacer()
                    StreakChip(days: store.streak)
                }
                .padding(.horizontal, DS.Space.screen)
            }
            .frame(height: 48)

            UnderlineTabs(items: FeedScope.allCases, selection: $scope, title: \.rawValue)
                .padding(.top, 4)

            TodayQuestionBanner(question: store.todayQuestion) {
                if !store.hasAnsweredToday { showQuestion = true }
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    if !store.hasAnsweredToday {
                        AnswerPrompt { showQuestion = true }
                    }
                    ForEach(Array(answers.enumerated()), id: \.element.id) { index, answer in
                        AnswerCard(answer: answer)
                            .staggeredAppear(index)
                        Rectangle().fill(Color.qLine).frame(height: 1).padding(.leading, 76)
                    }
                    if scope == .friends && answers.filter({ $0.authorId != store.me.id }).isEmpty {
                        EmptyStateView(icon: .usersThreeFill,
                                       title: "Your friends are quiet",
                                       message: "None of the people you follow answered yet. Invite friends or discover new people.") {
                            VStack(spacing: 12) {
                                ShareLink(item: Invite.text(for: store.me.username)) {
                                    Label { Text("Invite friends") } icon: { Icon(.paperPlaneTiltFill, size: 18) }
                                        .font(.ui(16, .semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(Capsule().fill(Color.qGreen))
                                }
                                .buttonStyle(.pressable)
                                Button("Discover people", action: onDiscover)
                                    .font(.ui(16, .medium))
                                    .foregroundStyle(Color.qGreen)
                                    .frame(height: 44)
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
                .animation(.qSmooth, value: scope)
            }
            .refreshable {
                try? await Task.sleep(for: .milliseconds(600))
                store.refreshDay()
            }
        }
        .background(Color.qBackground)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showQuestion) {
            DailyQuestionView(onSubmitted: { showQuestion = false },
                              onClose: { showQuestion = false })
        }
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
                        .font(.ui(15, .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qGreen))
            .padding(.horizontal, DS.Space.screen)
            .padding(.vertical, 12)
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
    NavigationStack { FeedView() }.environment(AppStore())
}
