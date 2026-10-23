import SwiftUI

/// Full-screen "Today's Question" → "Answer" flow from the prototype.
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
    private var words: [String] { question.text.uppercased().split(separator: " ").map(String.init) }

    var body: some View {
        ZStack {
            Color.qGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 16)
                if isComposing { composer } else { questionText }
                Spacer(minLength: 16)
                if isComposing {
                    VisibilityPicker(selection: $visibility)
                        .padding(.bottom, 16)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    DayProgress()
                        .padding(.horizontal, DS.Space.xl)
                        .padding(.bottom, 16)
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
                LimeButton(title: isComposing ? "Submit" : "Answer",
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
            QueslyLogo(height: 18, background: .clear)
            HStack {
                Spacer()
                if let onClose {
                Button(action: onClose) {
                    Icon(.xBold, size: DS.Icon.inline, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white.opacity(0.12)))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
                .padding(.trailing, -4)
                }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, DS.Space.xl)
        .padding(.top, 8)
    }

    /// Editorial, left-aligned question: the day's progress line, then the words arrive one by one.
    /// The key word becomes a tilted lime "sticker" with green ink.
    private var questionText: some View {
        let highlighted = question.keyWords
        return VStack(alignment: .leading, spacing: DS.Space.l) {
            DayProgress()
            WrappingHStack(spacing: 10, lineSpacing: 4, centered: false) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    let isHot = highlighted.contains(word.filter(\.isLetter))
                    Text(word)
                        .font(.display(42, .heavy))
                        .foregroundStyle(isHot ? Color.qGreen : .white)
                        .padding(.horizontal, isHot ? 8 : 0)
                        .background {
                            if isHot {
                                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.qLime)
                            }
                        }
                        .rotationEffect(.degrees(isHot ? -3 : 0))
                        .opacity(index < revealed || reduceMotion ? 1 : 0)
                        .offset(y: index < revealed || reduceMotion ? 0 : 14)
                        .blur(radius: index < revealed || reduceMotion ? 0 : 6)
                        .animation(.qSmooth.delay(0.15 + Double(index) * 0.07), value: revealed)
                        // The key word lands last, like a sticker being slapped on.
                        .scaleEffect(isHot && revealed == 0 && !reduceMotion ? 1.6 : 1)
                        .animation(.spring(response: 0.38, dampingFraction: 0.5)
                            .delay(0.25 + Double(words.count) * 0.07), value: revealed)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(question.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Space.xl)
        .transition(.asymmetric(insertion: .opacity, removal: .scale(scale: 0.85).combined(with: .opacity)))
    }

    /// Writing happens on the green itself: the question stays on top, the answer is typed in
    /// large white type, with a quiet counter line underneath. No card, no second surface.
    private var composer: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            Text(question.text.uppercased())
                .font(.display(20, .bold))
                .foregroundStyle(Color.qLime)
                .fixedSize(horizontal: false, vertical: true)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Be honest, keep it short…")
                        .font(.display(26, .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.display(26, .medium))
                    .lineSpacing(2)
                    .foregroundStyle(.white)
                    .tint(Color.qLime)
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
            .padding(.horizontal, -5)
            .frame(height: 200)

            Rectangle().fill(.white.opacity(0.14)).frame(height: 1)
            HStack(spacing: 8) {
                CharacterRing(progress: Double(text.count) / Double(AppStore.maxAnswerLength))
                    .frame(width: 16, height: 16)
                Text("\(text.count)/\(AppStore.maxAnswerLength)")
                    .font(.ui(13))
                    .foregroundStyle(text.count >= AppStore.maxAnswerLength ? Color.qFlame : .white.opacity(0.7))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Spacer()
                if !text.isEmpty {
                    Text("Draft saved")
                        .font(.ui(13))
                        .foregroundStyle(.white.opacity(0.7))
                        .transition(.opacity)
                }
            }
            .animation(.qSmooth, value: text.isEmpty)
        }
        .padding(.horizontal, DS.Space.xl)
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                                removal: .opacity))
    }

    private func revealWords() {
        guard revealed == 0 else { return }
        revealed = words.count
    }

    private func submit() {
        guard canSubmit else { shake += 1; return }
        editorFocused = false
        store.submitAnswer(text, visibility: visibility)
        onSubmitted()
    }
}

/// Today's date and how much of the question's day is left, as a thin lime line that fills
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
                        .foregroundStyle(.white)
                    Spacer()
                    Text("New question in \(AppStore.timeLeftString(now: ctx.date))")
                        .font(.ui(15))
                        .foregroundStyle(.white.opacity(0.7))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.14))
                        Capsule().fill(Color.qLime)
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
/// placeholder bars (never the real words), with a lock pill — answer first, then read.
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
                        .scaleEffect(1 - CGFloat(index) * 0.05, anchor: .top)
                        .offset(y: CGFloat(index) * 12)
                        .opacity(1 - Double(index) * 0.25)
                }
                lockPill
                    .offset(y: 62)
            }
            .padding(.bottom, CGFloat(answers.count - 1) * 12)
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
                // The card is always white (it sits on green), so its ink is fixed too.
                Text(user?.username ?? "")
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Color(hex: 0x16181A))
                Capsule().fill(Color.black.opacity(0.08)).frame(height: 10)
                Capsule().fill(Color.black.opacity(0.08)).frame(width: 150, height: 10)
            }
        }
        .padding(DS.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.white))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
    }

    private var lockPill: some View {
        IconLabel("Answer to unlock", icon: .lockSimpleFill, size: DS.Icon.caption)
            .font(.ui(13, .semibold))
            .foregroundStyle(Color.qLime)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(Capsule().fill(Color.qGreen))
            .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
    }
}

/// "12,483 people answered today" with friends' faces — the nudge to join in.
private struct AnsweredTodayProof: View {
    let count: Int
    let friends: [AppUser]

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            if !friends.isEmpty {
                AvatarStack(users: friends, size: 28, ring: .qGreen)
            }
            Group {
                if let first = friends.first {
                    Text("**\(first.username)** and \((count - 1).formatted()) others answered")
                } else {
                    Text("**\(count.formatted())** people answered today")
                }
            }
            .font(.ui(15))
            .foregroundStyle(.white.opacity(0.85))
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
                        .foregroundStyle(on ? Color.qGreen : .white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .background {
                            if on {
                                Capsule().fill(Color.qLime).matchedGeometryEffect(id: "vis", in: ns)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(.white.opacity(0.14)))
        .sensoryFeedback(.selection, trigger: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Who can see your answer")
    }
}

struct CharacterRing: View {
    var progress: Double

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: min(1, progress))
                .stroke(progress >= 1 ? Color.qFlame : Color.qLime,
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
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 3), y: 0))
    }
}

/// Simple flow layout that wraps words onto new lines, centered or left-aligned.
struct WrappingHStack: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 4
    var centered = true

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * lineSpacing
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX + (centered ? (bounds.width - row.width) / 2 : 0)
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                                      proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for (i, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(i)
            rows[rows.count - 1] = row
        }
        return rows
    }
}

#Preview { DailyQuestionView().environment(AppStore()) }
