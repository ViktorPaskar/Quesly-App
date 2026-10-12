import SwiftUI

struct FeedView: View {
    @Environment(AppStore.self) private var store
    @State private var scope: FeedScope = DemoConfig.initialFeedScope
    @State private var showQuestion = false

    var body: some View {
        let answers = store.feed(scope)
        VStack(spacing: 0) {
            QueslyLogo(height: 18, markColor: .qInk, textColor: .qInk, background: .white)
                .padding(.top, 6)
                .padding(.bottom, 14)

            UnderlineTabs(items: FeedScope.allCases, selection: $scope, title: \.rawValue)

            TodayQuestionBanner(question: store.todayQuestion) {
                if !store.hasAnsweredToday { showQuestion = true }
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    if !store.hasAnsweredToday {
                        AnswerPrompt { showQuestion = true }
                    }
                    ForEach(answers) { answer in
                        AnswerCard(answer: answer)
                        Divider().padding(.leading, 16)
                    }
                    if answers.isEmpty {
                        ContentUnavailableView(
                            "No answers yet",
                            systemImage: "person.2",
                            description: Text(scope == .friends
                                              ? "Follow people from the World feed to see their stories here."
                                              : "Be the first to answer today's question.")
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.bottom, 12)
            }
            .refreshable { store.refreshDay() }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showQuestion) {
            DailyQuestionView(onSubmitted: { showQuestion = false },
                              onClose: { showQuestion = false })
        }
    }
}

struct TodayQuestionBanner: View {
    let question: DailyQuestion
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                QueslyMark(color: .qGreen, cutout: .qLime)
                    .frame(width: 22)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.qLime))

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Today's Question")
                            .font(.quesly(10, .medium))
                            .foregroundStyle(Color.qLime)
                        Spacer()
                        TimelineView(.periodic(from: .now, by: 60)) { ctx in
                            HStack(spacing: 3) {
                                Text("Left \(AppStore.timeLeftString(now: ctx.date))")
                                Image(systemName: "clock.fill").font(.system(size: 8))
                            }
                            .font(.quesly(10))
                            .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    Text(question.text.uppercased())
                        .font(.quesly(13, .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.qGreen)
        }
        .buttonStyle(.plain)
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
                        .font(.quesly(14, .semibold))
                        .foregroundStyle(Color.qGreen)
                    Text("Share your story to join today's conversation")
                        .font(.quesly(12))
                        .foregroundStyle(Color.qGreen.opacity(0.8))
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.qGreen)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.qLime))
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { FeedView() }.environment(AppStore())
}
