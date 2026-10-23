import SwiftUI

/// What the feed hands to the stories viewer: a snapshot, so the order doesn't shift while viewing.
struct StoryLaunch: Identifiable {
    let id = UUID()
    let stories: [Answer]
    let start: Int
}

// MARK: - Row

/// "Friends today": one ring per friend who answered, Instagram-stories style. Unseen rings are lime
/// (the brand's "answered today" ring) with a thin green edge so they read on white.
struct FriendStoriesRow: View {
    @Environment(AppStore.self) private var store
    var onOpen: (Int) -> Void

    var body: some View {
        let stories = store.friendStories
        if !stories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: DS.Space.s) {
                    ForEach(Array(stories.enumerated()), id: \.element.id) { index, answer in
                        StoryBubble(user: store.user(answer.authorId),
                                    isSeen: store.seenStoryAuthorIds.contains(answer.authorId)) {
                            onOpen(index)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, DS.Space.s)
                .padding(.bottom, DS.Space.xxs)
            }
        }
    }
}

private struct StoryBubble: View {
    let user: AppUser?
    let isSeen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Avatar(user: user, size: 58)
                    .padding(5)
                    .background {
                        if isSeen {
                            Circle().strokeBorder(Color.qLine, lineWidth: 1.5)
                        } else {
                            Circle().strokeBorder(Color.qLime, lineWidth: 3.5)
                                .overlay(Circle().strokeBorder(Color.qGreen.opacity(0.35), lineWidth: 0.75))
                        }
                    }
                Text(user?.username ?? "")
                    .font(.ui(12, isSeen ? .regular : .medium))
                    .foregroundStyle(isSeen ? Color.qGray : Color.qInk)
                    .lineLimit(1)
                    .frame(width: 72)
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
                Color.qGreen.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    progressBars
                    header.padding(.top, DS.Space.s)
                    Spacer(minLength: DS.Space.l)
                    content
                    Spacer(minLength: DS.Space.l)
                    ReactionBar(answer: answer)
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, DS.Space.s)
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                if location.x < geo.size.width * 0.3 { previous() } else { next() }
            }
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
        HStack(spacing: DS.Space.xxs) {
            ForEach(stories.indices, id: \.self) { i in
                GeometryReader { g in
                    Capsule().fill(Color.white.opacity(0.3))
                        .overlay(alignment: .leading) {
                            Capsule().fill(Color.qLime).frame(width: g.size.width * fill(i))
                        }
                }
                .frame(height: 3)
            }
        }
        .padding(.top, DS.Space.xs)
        .accessibilityHidden(true)
    }

    private var header: some View {
        HStack(spacing: DS.Space.s) {
            Avatar(user: author, size: 36)
            VStack(alignment: .leading, spacing: 0) {
                Text(author?.username ?? "")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(.white)
                Text(RelativeTime.short(answer.createdAt))
                    .font(.ui(13))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Button { dismiss() } label: {
                Icon(.xBold, size: DS.Icon.row)
                    .foregroundStyle(.white)
                    .frame(width: DS.hitTarget, height: DS.hitTarget)
                    .contentShape(Rectangle())
            }
            .padding(.trailing, -DS.Space.s)
            .accessibilityLabel("Close")
        }
        .accessibilityElement(children: .contain)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            Text(answer.questionText.uppercased())
                .font(.ui(13, .semibold))
                .foregroundStyle(Color.qLime)
            Text(answer.text)
                .font(.display(28, .semibold))
                .foregroundStyle(.white)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .id(answer.id)
        .transition(.opacity)
        .accessibilityElement(children: .combine)
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

/// The four positive reactions as large targets on the story.
private struct ReactionBar: View {
    @Environment(AppStore.self) private var store
    let answer: Answer

    var body: some View {
        HStack(spacing: DS.Space.s) {
            ForEach(ReactionKind.allCases) { kind in
                let isOn = answer.myReaction == kind
                Button {
                    withAnimation(.qSpring) { store.react(kind, on: answer.id) }
                } label: {
                    ReactionSticker(kind: kind, size: 34)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                                .fill(Color.white.opacity(isOn ? 0.22 : 0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                                .strokeBorder(isOn ? Color.qLime : .clear, lineWidth: 2)
                        )
                        .scaleEffect(isOn ? 1.04 : 1)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(kind.label)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: answer.myReaction)
    }
}
