import SwiftUI

/// Full-screen "Today's Question" → "Answer" flow.
/// Clean, tactile editorial canvas: generous whitespace, elegant typography, and a focused writing card.
struct DailyQuestionView: View {
    @Environment(AppStore.self) private var store
    /// Called after a successful submit.
    var onSubmitted: () -> Void = {}
    /// Shown when the flow is presented over the feed (lets the user close it).
    var onClose: (() -> Void)? = nil

    @State private var isComposing = DemoConfig.startsComposing
    @State private var text = DemoConfig.composerSample
    @State private var visibility: AnswerVisibility = .everyone
    @State private var revealed = 0
    @State private var shake = 0
    @FocusState private var editorFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var question: DailyQuestion { store.todayQuestion }

    var body: some View {
        ZStack {
            Color.qBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Spacer(minLength: 16)

                if isComposing { composer } else { questionText }

                Spacer(minLength: 16)

                if isComposing {
                    VisibilityPicker(selection: $visibility)
                        .padding(.bottom, 14)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    DayProgress()
                        .padding(.horizontal, DS.Space.xl)
                        .padding(.bottom, 14)
                } else {
                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        LockedFriendsPreview(answers: Array(store.friendStories.prefix(3)),
                                             users: store.friendsAnsweredToday)
                        AnsweredTodayProof(count: store.answeredTodayCount,
                                           friends: store.friendsAnsweredToday)
                    }
                    .padding(.horizontal, DS.Space.xl)
                    .padding(.bottom, DS.Space.l)
                    .transition(.opacity)
                }

                GreenButton(title: isComposing ? "Submit answer" : "Answer",
                            isEnabled: !isComposing || canSubmit) {
                    if isComposing {
                        submit()
                    } else {
                        withAnimation(.qSmooth) { isComposing = true }
                        editorFocused = true
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, DS.Space.s)
                .modifier(ShakeEffect(shakes: CGFloat(shake)))
                .sensoryFeedback(.warning, trigger: shake)
            }
        }
        .onTapGesture { editorFocused = false }
        .onAppear {
            visibility = store.defaultVisibility
            // Resume an unfinished answer (the draft survives app restarts).
            if text.isEmpty, !store.draft.isEmpty {
                text = store.draft
                isComposing = true
            }
            revealWords()
        }
        .task { if DemoTour.isOn { await playTour() } }
    }

    /// Demo walkthrough: read the question, type an answer, submit.
    private func playTour() async {
        await DemoTour.pause(4)
        withAnimation(.qSmooth) { isComposing = true }
        await DemoTour.pause(1)
        for ch in MockData.sampleAnswers[question.id] ?? "Walking home with my favourite song on." {
            text.append(ch)
            await DemoTour.pause(0.045)
        }
        await DemoTour.pause(1.2)
        submit()
    }

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var header: some View {
        ZStack {
            QueslyLogo(height: 32, markColor: .qGreen, textColor: .qInk, background: .qLime)
            HStack {
                Spacer()
                if let onClose {
                    Button(action: onClose) {
                        Icon(.xBold, size: DS.Icon.inline, weight: .semibold)
                            .foregroundStyle(Color.qInk)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.qField))
                            .overlay(Circle().stroke(Color.qLine, lineWidth: 1))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close")
                    .padding(.trailing, -4)
                }
            }
        }
        .frame(height: 48)
        .padding(.horizontal, DS.Space.xl)
        .padding(.top, 16)
    }

    /// Editorial, left-aligned question: the day's progress line, then the question in bold sentence case.
    private var questionText: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            DayProgress()

            Text(question.text)
                .font(.display(34, .heavy))
                .foregroundStyle(Color.qInk)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(revealed > 0 || reduceMotion ? 1 : 0)
                .offset(y: revealed > 0 || reduceMotion ? 0 : 12)
                .animation(.qSmooth, value: revealed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Space.xl)
        .transition(.asymmetric(insertion: .opacity, removal: .scale(scale: 0.95).combined(with: .opacity)))
    }

    /// Writing happens inside a focused, tactile journal card.
    private var composer: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Circle().fill(Color.qGreen).frame(width: 7, height: 7)
                    Text("TODAY'S QUESTION")
                        .font(.ui(11, .bold))
                        .tracking(0.8)
                        .foregroundStyle(Color.qBrandText)
                }

                Text(question.text)
                    .font(.display(19, .bold))
                    .foregroundStyle(Color.qInk)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Rectangle().fill(Color.qLine).frame(height: 1)

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Write your honest answer…")
                            .font(.ui(18, .regular))
                            .foregroundStyle(Color.qGray.opacity(0.7))
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $text)
                        .font(.ui(18, .medium))
                        .lineSpacing(4)
                        .foregroundStyle(Color.qInk)
                        .tint(Color.qGreen)
                        .scrollContentBackground(.hidden)
                        .focused($editorFocused)
                        .onChange(of: text) { _, newValue in
                            if newValue.count > AppStore.maxAnswerLength {
                                text = String(newValue.prefix(AppStore.maxAnswerLength))
                                shake += 1
                            }
                            if !DemoConfig.isActive { store.draft = text }
                        }
                }
                .frame(minHeight: 140, maxHeight: 180)

                Rectangle().fill(Color.qLine).frame(height: 1)

                HStack(spacing: 8) {
                    CharacterRing(progress: Double(text.count) / Double(AppStore.maxAnswerLength))
                        .frame(width: 16, height: 16)
                    Text("\(text.count)/\(AppStore.maxAnswerLength)")
                        .font(.ui(13))
                        .foregroundStyle(text.count >= AppStore.maxAnswerLength ? Color.qFlame : Color.qGray)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Spacer()
                    if !text.isEmpty {
                        HStack(spacing: 4) {
                            Icon(.checkBold, size: 12)
                            Text("Draft saved")
                                .font(.ui(12))
                        }
                        .foregroundStyle(Color.qBrandText)
                        .transition(.opacity)
                    }
                }
                .animation(.qSmooth, value: text.isEmpty)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.qBlock)
                    .shadow(color: Color.black.opacity(0.06), radius: 18, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.qLine, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, DS.Space.xl)
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.96)),
                                removal: .opacity))
    }

    private func revealWords() {
        guard revealed == 0 else { return }
        revealed = 1
    }

    private func submit() {
        guard canSubmit else { shake += 1; return }
        editorFocused = false
        store.submitAnswer(text, visibility: visibility)
        onSubmitted()
    }
}

/// Today's date and how much of the question's day is left, as a calm line that fills
/// toward midnight. Calm and informative, never a ticking countdown.
private struct DayProgress: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { ctx in
            let start = Calendar.current.startOfDay(for: ctx.date)
            let end = AppStore.nextQuestionDate(after: ctx.date)
            let elapsed = ctx.date.timeIntervalSince(start) / max(1, end.timeIntervalSince(start))
            VStack(spacing: DS.Space.xs) {
                HStack {
                    Text(ctx.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Color.qInk)
                    Spacer()
                    Text("New question in \(AppStore.timeLeftString(now: ctx.date))")
                        .font(.ui(14, .medium))
                        .foregroundStyle(Color.qGray)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.qLine)
                        Capsule().fill(Color.qGreen)
                            .frame(width: max(4, geo.size.width * min(1, elapsed)))
                    }
                }
                .frame(height: 4)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("New question in \(AppStore.timeLeftString(now: ctx.date))")
        }
    }
}

/// Friends' answers waiting behind the gate: a fanned stack of cards whose text is drawn as
/// placeholder bars, with a lock pill — answer first, then read.
private struct LockedFriendsPreview: View {
    let answers: [Answer]
    let users: [AppUser]
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !answers.isEmpty {
            ZStack(alignment: .top) {
                ForEach(Array(answers.enumerated().reversed()), id: \.element.id) { index, answer in
                    card(answer, user: users.first { $0.id == answer.authorId })
                        .scaleEffect(1 - CGFloat(index) * 0.04, anchor: .top)
                        .offset(y: CGFloat(index) * 10)
                        .opacity(1 - Double(index) * 0.22)
                }
                lockPill
                    .offset(y: 58)
            }
            .padding(.bottom, CGFloat(answers.count - 1) * 10)
            .offset(y: shown || reduceMotion ? 0 : 24)
            .opacity(shown || reduceMotion ? 1 : 0)
            .onAppear { withAnimation(.qSpring.delay(0.6)) { shown = true } }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(answers.count) friends answered. Answer to see what they said.")
        }
    }

    private func card(_ answer: Answer, user: AppUser?) -> some View {
        HStack(alignment: .top, spacing: DS.Space.s) {
            Avatar(user: user, size: 36)
            VStack(alignment: .leading, spacing: 8) {
                Text(user?.username ?? "")
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Color.qInk)
                Capsule().fill(Color.qLine).frame(height: 10)
                Capsule().fill(Color.qLine).frame(width: 140, height: 10)
            }
        }
        .padding(DS.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                .fill(Color.qBlock)
                .shadow(color: Color.black.opacity(0.06), radius: 14, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }

    private var lockPill: some View {
        IconLabel("Answer to unlock", icon: .lockSimpleFill, size: DS.Icon.caption)
            .font(.ui(13, .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(Capsule().fill(Color.qGreen))
            .shadow(color: Color.qGreen.opacity(0.3), radius: 8, y: 3)
    }
}

/// "12,483 people answered today" with friends' faces — the nudge to join in.
private struct AnsweredTodayProof: View {
    let count: Int
    let friends: [AppUser]

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            if !friends.isEmpty {
                AvatarStack(users: friends, size: 28, ring: .white)
            }
            Group {
                if let first = friends.first {
                    Text("**\(first.username)** and \((count - 1).formatted()) others answered")
                } else {
                    Text("**\(count.formatted())** people answered today")
                }
            }
            .font(.ui(14))
            .foregroundStyle(Color.qInk2)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// "Everyone / Friends" segmented capsule.
struct VisibilityPicker: View {
    @Binding var selection: AnswerVisibility
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AnswerVisibility.allCases) { option in
                let on = option == selection
                Button {
                    withAnimation(.qSpring) { selection = option }
                } label: {
                    Text(option.title)
                        .font(.ui(14, .semibold))
                        .foregroundStyle(on ? .white : Color.qGray)
                        .padding(.horizontal, 18)
                        .frame(height: 36)
                        .background {
                            if on {
                                Capsule().fill(Color.qGreen).matchedGeometryEffect(id: "vis", in: ns)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.qField))
        .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Who can see your answer")
    }
}

struct CharacterRing: View {
    var progress: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.qLine, lineWidth: 3)
            Circle()
                .trim(from: 0, to: min(1, progress))
                .stroke(progress >= 1 ? Color.qFlame : Color.qGreen,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeOut(duration: 0.15), value: progress)
    }
}

/// Horizontal shake used when the answer is empty or hits the limit.
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: -6 * sin(shakes * 2 * .pi), y: 0))
    }
}

#Preview { DailyQuestionView().environment(AppStore()) }
