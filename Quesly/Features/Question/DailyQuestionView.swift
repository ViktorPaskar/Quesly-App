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

    private var question: DailyQuestion { store.todayQuestion }
    private var words: [String] { question.text.uppercased().split(separator: " ").map(String.init) }

    var body: some View {
        ZStack {
            BrandGradientBackground(animate: false)
            Color.qGreen.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 16)
                if isComposing { composer } else { questionText }
                Spacer(minLength: 16)
                if isComposing {
                    VisibilityPicker(selection: $visibility)
                        .padding(.bottom, 14)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        Label {
                            Text("**\(AppStore.timeLeftString(now: context.date))** left until the next question")
                        } icon: {
                            Icon(.hourglassMediumFill, size: 14)
                        }
                        .font(.quesly(13))
                        .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.bottom, 14)
                }
                LimeButton(title: isComposing ? "Submit" : "Answer",
                           icon: isComposing ? .paperPlaneTiltFill : .pencilSimpleFill,
                           isEnabled: !isComposing || canSubmit) {
                    if isComposing {
                        submit()
                    } else {
                        withAnimation(.qSmooth) { isComposing = true }
                        editorFocused = true
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 12)
                .modifier(ShakeEffect(shakes: CGFloat(shake)))
            }
        }
        .onTapGesture { editorFocused = false }
        .onAppear {
            visibility = store.defaultVisibility
            revealWords()
        }
    }

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 14) {
                QueslyLogo(height: 18, background: .clear)
                VStack(spacing: 6) {
                    Text("TODAY'S QUESTION")
                        .font(.quesly(12, .bold))
                        .tracking(1)
                        .foregroundStyle(Color.qLime)
                    Capsule().fill(Color.qLime).frame(width: 110, height: 2)
                }
            }
            if let onClose {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Icon(.xBold, size: 20)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.top, 12)
    }

    /// Question appears word by word; highlighted words glow lime.
    private var questionText: some View {
        let highlighted = Set(question.highlights.flatMap { $0.uppercased().split(separator: " ").map(String.init) })
        return WrappingHStack(spacing: 10, lineSpacing: 6) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                Text(word)
                    .font(.quesly(36, .bold, relativeTo: .largeTitle))
                    .foregroundStyle(highlighted.contains(word) ? Color.qLime : .white)
                    .opacity(index < revealed ? 1 : 0)
                    .offset(y: index < revealed ? 0 : 14)
                    .blur(radius: index < revealed ? 0 : 6)
                    .animation(.qSmooth.delay(0.2 + Double(index) * 0.09), value: revealed)
            }
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(question.text)
        .transition(.asymmetric(insertion: .opacity, removal: .scale(scale: 0.85).combined(with: .opacity)))
    }

    private var composer: some View {
        VStack(spacing: 0) {
            Text(question.text.uppercased())
                .font(.quesly(17, .bold))
                .foregroundStyle(Color.qGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .padding(.bottom, 14)
                .background(Color.qLime)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Be honest, keep it short…")
                        .font(.quesly(18))
                        .foregroundStyle(Color.qGray)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.quesly(18))
                    .lineSpacing(3)
                    .foregroundStyle(Color.qInk)
                    .scrollContentBackground(.hidden)
                    .focused($editorFocused)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > AppStore.maxAnswerLength {
                            text = String(newValue.prefix(AppStore.maxAnswerLength))
                            shake += 1
                        }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .frame(height: 190)

            HStack(spacing: 8) {
                CharacterRing(progress: Double(text.count) / Double(AppStore.maxAnswerLength))
                    .frame(width: 16, height: 16)
                Text("\(text.count)/\(AppStore.maxAnswerLength)")
                    .font(.quesly(13, .medium))
                    .foregroundStyle(text.count >= AppStore.maxAnswerLength ? Color.qFlame : Color.qGray)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Spacer()
            }
            .padding(16)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
        .padding(.horizontal, 24)
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
                    Label { Text(option.title) } icon: { Icon(option.icon, size: 16) }
                        .font(.quesly(14, .semibold))
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
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 3), y: 0))
    }
}

/// Simple flow layout that wraps words onto new lines, centered.
struct WrappingHStack: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 4

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
            var x = bounds.minX + (bounds.width - row.width) / 2
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
