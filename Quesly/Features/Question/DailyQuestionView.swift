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
    @FocusState private var editorFocused: Bool

    private var question: DailyQuestion { store.todayQuestion }

    var body: some View {
        ZStack {
            Color.qGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 16)
                if isComposing { composer } else { questionText }
                Spacer(minLength: 16)
                if isComposing {
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Text("**\(AppStore.timeLeftString(now: context.date).uppercased())** left until the next question")
                            .font(.quesly(11))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 16)
                }
                LimeButton(title: isComposing ? "Submit" : "Answer", isEnabled: !isComposing || canSubmit) {
                    if isComposing {
                        submit()
                    } else {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { isComposing = true }
                        editorFocused = true
                    }
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 12)
            }
        }
        .onTapGesture { editorFocused = false }
    }

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 14) {
                QueslyLogo(height: 16)
                VStack(spacing: 6) {
                    Text("TODAY'S QUESTION")
                        .font(.quesly(9, .bold))
                        .foregroundStyle(Color.qLime)
                    Rectangle().fill(Color.qLime).frame(width: 90, height: 1.5)
                }
            }
            if let onClose {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.top, 12)
    }

    private var questionText: some View {
        Text(QuestionText.attributed(question))
            .font(.quesly(30, .bold))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 36)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private var composer: some View {
        VStack(spacing: 0) {
            Text(question.text.uppercased())
                .font(.quesly(15, .bold))
                .foregroundStyle(Color.qGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .padding(.bottom, 14)
                .background(Color.qLime)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Type your answer…")
                        .font(.quesly(16))
                        .foregroundStyle(Color.qGray)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                TextEditor(text: $text)
                    .font(.quesly(16))
                    .foregroundStyle(Color.qInk)
                    .scrollContentBackground(.hidden)
                    .focused($editorFocused)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > AppStore.maxAnswerLength {
                            text = String(newValue.prefix(AppStore.maxAnswerLength))
                        }
                    }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .frame(height: 190)

            HStack(spacing: 6) {
                CharacterRing(progress: Double(text.count) / Double(AppStore.maxAnswerLength))
                    .frame(width: 12, height: 12)
                Text("\(text.count)/\(AppStore.maxAnswerLength)")
                    .font(.quesly(10, .medium))
                    .foregroundStyle(Color.qInk)
                    .monospacedDigit()
                Spacer()
            }
            .padding(14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 28)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func submit() {
        guard canSubmit else { return }
        editorFocused = false
        store.submitAnswer(text)
        onSubmitted()
    }
}

struct CharacterRing: View {
    var progress: Double

    var body: some View {
        ZStack {
            Circle().stroke(Color.qLine, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: min(1, progress))
                .stroke(progress >= 1 ? Color.qHeart : Color.qGreen,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeOut(duration: 0.15), value: progress)
    }
}

#Preview { DailyQuestionView().environment(AppStore()) }
