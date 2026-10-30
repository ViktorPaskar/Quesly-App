import SwiftUI

/// What the feed hands to the stories viewer: a snapshot, so the order doesn't shift while viewing.
struct StoryLaunch: Identifiable {
    let id = UUID()
    let stories: [Answer]
    let start: Int
}

// MARK: - Row

/// Peeks stories bar for both World and Friends feeds:
/// - Always starts with "My Peek": shows avatar with '+' if unanswered (tap to write answer), or gradient ring if answered (tap to view story).
/// - Followed by friends' or community members' stories for today.
struct PeeksStoriesBar: View {
    @Environment(AppStore.self) private var store
    let scope: FeedScope
    var onAddAnswer: () -> Void
    var onOpenStory: ([Answer], Int) -> Void

    private var feedStories: [Answer] {
        if scope == .friends {
            return store.friendStories.filter { $0.authorId != store.me.id }
        } else {
            // World scope: community answers for today (excluding my own)
            return store.todayAnswers.filter { $0.authorId != store.me.id }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    // MARK: 1. My Peek (Always First)
                    myPeekBubble

                    // MARK: 2. Feed stories (Friends or World)
                    ForEach(Array(feedStories.enumerated()), id: \.element.id) { index, answer in
                        StoryBubble(
                            user: store.user(answer.authorId),
                            isSeen: store.seenStoryAuthorIds.contains(answer.authorId)
                        ) {
                            onOpenStory(feedStories, index)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, 6)
                .padding(.bottom, 10)
            }

            Rectangle()
                .fill(Color.qLine.opacity(0.65))
                .frame(height: 0.5)
        }
    }

    private var myPeekBubble: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .bottomTrailing) {
                Button {
                    if let myAnswer = store.todaysAnswer {
                        onOpenStory([myAnswer], 0)
                    } else {
                        onAddAnswer()
                    }
                } label: {
                    Avatar(user: store.me, size: 58, isSticker: true)
                        .padding(2.5)
                        .background {
                            if store.hasAnsweredToday {
                                Circle().strokeBorder(
                                    LinearGradient(
                                        colors: [Color.qGreen, Color.qLime],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2.2
                                )
                            } else {
                                Circle().strokeBorder(Color.qLine, lineWidth: 1.5)
                            }
                        }
                }
                .buttonStyle(.pressable)

                // Instagram-style circular '+' badge to add a Peek
                Button {
                    onAddAnswer()
                } label: {
                    Circle()
                        .fill(Color.qLime)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundStyle(Color.qGreenDeep)
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                .buttonStyle(.pressable)
                .offset(x: 2, y: 2)
                .accessibilityLabel("Add Peek")
            }

            Text("Your Peek")
                .font(.ui(11.5))
                .foregroundStyle(Color.qInk)
                .lineLimit(1)
                .frame(width: 66)
        }
    }
}

/// Backwards compatibility alias
struct FriendStoriesRow: View {
    @Environment(AppStore.self) private var store
    var onOpen: (Int) -> Void

    var body: some View {
        PeeksStoriesBar(
            scope: .friends,
            onAddAnswer: {},
            onOpenStory: { stories, index in onOpen(index) }
        )
    }
}

private struct StoryBubble: View {
    let user: AppUser?
    let isSeen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Avatar(user: user, size: 58, isSticker: true)
                    .padding(2.5)
                    .background {
                        if isSeen {
                            Circle().strokeBorder(Color.qLine, lineWidth: 1.5)
                        } else {
                            Circle().strokeBorder(
                                LinearGradient(
                                    colors: [Color.qGreen, Color.qLime],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.2
                            )
                        }
                    }

                Text(user?.username.replacingOccurrences(of: "@", with: "") ?? "")
                    .font(.ui(11.5))
                    .foregroundStyle(isSeen ? Color.qGray : Color.qInk)
                    .lineLimit(1)
                    .frame(width: 66)
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(user?.username ?? "") answered today" + (isSeen ? ", seen" : ""))
    }
}

// MARK: - Viewer

/// Full-screen answers from friends: tap right/left to move, swipe down to close, auto-advances.
struct StoryViewer: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    let stories: [Answer]
    @State private var index: Int
    @State private var progress: Double = 0
    @State private var dragY: CGFloat = 0
    @State private var showShareSheet = false

    private static let duration: Double = 6

    init(stories: [Answer], start: Int) {
        self.stories = stories
        _index = State(initialValue: min(max(0, start), max(0, stories.count - 1)))
    }

    /// Live copy from the store so reactions update in place.
    private var answer: Answer { store.answer(stories[index].id) ?? stories[index] }
    private var author: AppUser? { store.user(answer.authorId) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Cinematic deep emerald gradient
                LinearGradient(
                    colors: [Color(hex: 0x053F2B), Color.qGreenDeep, Color(hex: 0x021E14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Soft ambient lime glow
                Circle()
                    .fill(Color.qLime.opacity(0.10))
                    .frame(width: 260, height: 260)
                    .blur(radius: 50)
                    .offset(y: -20)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 0) {
                    progressBars
                    header.padding(.top, DS.Space.s)
                    Spacer(minLength: DS.Space.m)
                    storyAnswerCard
                    Spacer(minLength: DS.Space.m)
                    reactionDock
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, DS.Space.m)
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                if location.x < geo.size.width * 0.3 { previous() } else { next() }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareStorySheet(answer: answer).presentationDetents([.large])
        }
        .offset(y: max(0, dragY))
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onChanged { dragY = $0.translation.height }
                .onEnded { value in
                    if value.translation.height > 120 { dismiss() } else { withAnimation(.qSpring) { dragY = 0 } }
                }
        )
        .task(id: index) { await play() }
        .statusBarHidden()
        .accessibilityAction(named: "Next answer") { next() }
        .accessibilityAction(named: "Previous answer") { previous() }
    }

    // MARK: Parts

    private var progressBars: some View {
        HStack(spacing: 5) {
            ForEach(stories.indices, id: \.self) { i in
                GeometryReader { g in
                    Capsule().fill(Color.white.opacity(0.25))
                        .overlay(alignment: .leading) {
                            Capsule().fill(Color.qLime).frame(width: g.size.width * fill(i))
                        }
                }
                .frame(height: 3.5)
            }
        }
        .padding(.top, DS.Space.xs)
        .accessibilityHidden(true)
    }

    private var header: some View {
        HStack(spacing: DS.Space.s) {
            Avatar(user: author, size: 38)
                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
            VStack(alignment: .leading, spacing: 2) {
                Text(author?.username ?? "")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(.white)
                Text(RelativeTime.short(answer.createdAt))
                    .font(.ui(12))
                    .foregroundStyle(.white.opacity(0.72))
            }
            Spacer()
            Button { dismiss() } label: {
                Circle()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 36, height: 36)
                    .overlay(Icon(.xBold, size: 13).foregroundStyle(.white))
            }
            .accessibilityLabel("Close")
        }
        .accessibilityElement(children: .contain)
    }

    /// Pure, authentic Answer Card matching the Feed card design
    private var storyAnswerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Feed Question Header
            HStack(spacing: 8) {
                QueslyMark(color: .qGreen, cutout: .qLime)
                    .frame(width: 13)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.qLime))

                Text("TODAY'S QUESTION")
                    .font(.ui(11, .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Color.qBrandText)

                Spacer(minLength: 0)

                HStack(spacing: 4) {
                    Icon(.sparkleFill, size: 10)
                        .foregroundStyle(Color.qGreen)
                    Text("Daily reflection")
                        .font(.ui(11, .medium))
                        .foregroundStyle(Color.qGray)
                }
            }

            // Question Headline
            Text(answer.questionText)
                .font(.ui(15, .semibold))
                .foregroundStyle(Color.qInk)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Color.qLine)
                .frame(height: 1)

            // The Answer Text: deep ink, generous and expressive display font
            Text(answer.text)
                .font(.display(24, .regular))
                .foregroundStyle(Color.qInk)
                .lineSpacing(4.5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)

            // Card Footer: Author identity & relative timestamp
            HStack(spacing: 8) {
                Avatar(user: author, size: 24)
                Text(author?.displayName ?? author?.username ?? "")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk)

                Spacer(minLength: 0)

                Text(RelativeTime.short(answer.createdAt))
                    .font(.ui(11.5))
                    .foregroundStyle(Color.qGray)
            }
            .padding(.top, 2)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.qLine, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 24, y: 10)
        .id(answer.id)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
    }

    /// Symmetrical reaction slider dock with large center reaction & share button
    private var reactionDock: some View {
        HStack(spacing: 8) {
            // Symmetrical Share Button on the left
            Button {
                showShareSheet = true
            } label: {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Icon(.shareForward, size: 16)
                            .foregroundStyle(Color.white)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share to other apps")

            // Symmetrical Slider Reactions (Left: Small/Medium, Center: Large Hero, Right: Medium/Small)
            let reactions = ReactionKind.allCases
            // reactions are: same, aww, like, deep, cool, hugs
            HStack(spacing: 6) {
                ForEach(Array(reactions.enumerated()), id: \.element) { index, kind in
                    let isHero = (kind == .like) || (answer.myReaction == kind)
                    let distance = abs(index - 2) // distance from center (index 2 = like)
                    let scale: CGFloat = isHero ? 1.25 : (distance == 1 ? 0.95 : 0.82)
                    let stickerSize: CGFloat = isHero ? 38 : (distance == 1 ? 30 : 25)
                    let isSelected = answer.myReaction == kind

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                            store.react(kind, on: answer.id)
                        }
                    } label: {
                        ZStack {
                            if isSelected || isHero {
                                Circle()
                                    .fill(isSelected ? Color.qLime.opacity(0.3) : Color.white.opacity(0.16))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle().stroke(isSelected ? Color.qLime : Color.white.opacity(0.2), lineWidth: 1.5)
                                    )
                            }
                            ReactionSticker(kind: kind, size: stickerSize)
                        }
                        .frame(width: 44, height: 48)
                        .scaleEffect(scale)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(kind.label)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.38))
                .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
        )
        .sensoryFeedback(.selection, trigger: answer.myReaction)
    }

    private func fill(_ i: Int) -> CGFloat {
        if i < index { return 1 }
        if i == index { return CGFloat(progress) }
        return 0
    }

    // MARK: Playback

    private func play() async {
        store.markStorySeen(stories[index].authorId)
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { progress = 0 }
        // VoiceOver users move manually; auto-advance would cut the reading short.
        guard !voiceOver else { progress = 1; return }
        try? await Task.sleep(for: .milliseconds(30))
        withAnimation(.linear(duration: Self.duration)) { progress = 1 }
        do { try await Task.sleep(for: .seconds(Self.duration)) } catch { return }
        next()
    }

    private func next() {
        if index < stories.count - 1 {
            withAnimation(.qSmooth) { index += 1 }
        } else {
            dismiss()
        }
    }

    private func previous() {
        guard index > 0 else { return }
        withAnimation(.qSmooth) { index -= 1 }
    }
}
