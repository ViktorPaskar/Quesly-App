import SwiftUI

/// What the feed hands to the stories viewer: a snapshot, so the order doesn't shift while viewing.
struct StoryLaunch: Identifiable {
    let id = UUID()
    let stories: [Answer]
    let start: Int
}

// MARK: - Row

/// Peeks stories bar: clean gradient-ring story bubbles for friends who answered today.
struct FriendStoriesRow: View {
    @Environment(AppStore.self) private var store
    var onOpen: (Int) -> Void

    var body: some View {
        let stories = store.friendStories
        if !stories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(Array(stories.enumerated()), id: \.element.id) { index, answer in
                        StoryBubble(user: store.user(answer.authorId),
                                    isSeen: store.seenStoryAuthorIds.contains(answer.authorId)) {
                            onOpen(index)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, 6)
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
            VStack(spacing: 5) {
                Avatar(user: user, size: 54, isSticker: true)
                    .padding(3)
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
                    .font(.ui(11, .medium))
                    .foregroundStyle(isSeen ? Color.qGray : Color.qInk)
                    .lineLimit(1)
                    .frame(width: 62)
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
                // Cinematic deep emerald gradient
                LinearGradient(
                    colors: [Color(hex: 0x053F2B), Color.qGreenDeep, Color(hex: 0x021E14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Ambient Quesly watermark
                QueslyMark(color: Color.white.opacity(0.04))
                    .frame(width: 340)
                    .offset(x: 110, y: -40)
                    .blur(radius: 1)
                    .accessibilityHidden(true)

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
                    peekCard
                    Spacer(minLength: DS.Space.m)
                    ReactionBar(answer: answer)
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, DS.Space.m)
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
                .overlay(Circle().stroke(Color.qLime, lineWidth: 1.8))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(author?.username ?? "")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(.white)
                    // Peeks badge
                    HStack(spacing: 4) {
                        Circle().fill(Color.qLime).frame(width: 5, height: 5)
                        Text("PEEK")
                            .font(.ui(10, .semibold))
                            .tracking(0.8)
                            .foregroundStyle(Color.qLime)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
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

    /// Dimensional glassmorphic card framing the answer
    private var peekCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Branded question chip
            HStack(spacing: 7) {
                QueslyMark(color: .qGreen, cutout: .qLime)
                    .frame(width: 14)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.qLime))
                Text(answer.questionText.uppercased())
                    .font(.ui(12, .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Color.qLime)
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.black.opacity(0.28))
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8))
            )

            // The Answer Text: clean, un-bold, with relaxed line spacing
            Text(answer.text)
                .font(.display(24, .regular))
                .foregroundStyle(.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)

            // Card footer info
            HStack {
                HStack(spacing: 5) {
                    Icon(.sparkleFill, size: 12)
                        .foregroundStyle(Color.qLime)
                    Text("Daily reflection")
                        .font(.ui(12, .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }
                Spacer()
                Text(RelativeTime.short(answer.createdAt))
                    .font(.ui(11, .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.black.opacity(0.22), radius: 24, y: 12)
        )
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
        HStack(spacing: 6) {
            ForEach(ReactionKind.allCases) { kind in
                let isOn = answer.myReaction == kind
                Button {
                    withAnimation(.qSpring) { store.react(kind, on: answer.id) }
                } label: {
                    VStack(spacing: 3) {
                        ReactionSticker(kind: kind, size: 28)
                        Text(kind.label)
                            .font(.ui(9, .semibold))
                            .foregroundStyle(isOn ? Color.qLime : Color.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(isOn ? 0.22 : 0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(isOn ? Color.qLime : Color.white.opacity(0.12), lineWidth: isOn ? 1.5 : 0.8)
                    )
                    .scaleEffect(isOn ? 1.05 : 1)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(kind.label)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.20), radius: 12, y: 6)
        )
        .sensoryFeedback(.selection, trigger: answer.myReaction)
    }
}
