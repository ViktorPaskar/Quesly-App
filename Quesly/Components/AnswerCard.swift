import SwiftUI
import UIKit

enum Route: Hashable {
    case profile(String)
    case menu
    case achievements
    case editProfile
    case following
    case followers
    case settings
    case feedback
    case invite
    case blocked
}

/// One answer. Two layouts on the same 4-pt grid:
/// • feed (default): X-style row: 40-pt avatar, then everything aligned to the name's left edge:
///   16 · name row 20 · 4 · text 16/24 · 16 · action glyphs 24 · 8 · "Reacted by" 20 · 16.
/// • compact (profile): the same row as a reply under the day's question (thread).
struct AnswerCard: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    let answer: Answer
    var showsQuestion = false
    var showsAuthor = true
    /// Demo/screenshot hook: start with the sticker popover open.
    var opensTray = false
    /// Brief brand tint, used when your own answer lands in the feed after posting.
    var isHighlighted = false
    /// Profile row layout (see type comment).
    var isCompact = false

    @State private var isTrayOpen = false
    @State private var isSharingStory = false
    @State private var isEditing = false
    @State private var isReporting = false
    @State private var showReactions = false
    @State private var confirmDelete = false
    @State private var popTrigger = 0
    @State private var stickerPop = 0
    @State private var isTranslated = false

    private var author: AppUser? { store.user(answer.authorId) }
    private var isMine: Bool { answer.authorId == store.me.id }
    private var link: URL { URL(string: "https://quesly.me/a/\(answer.id)")! }
    /// Profile rows use the profile's 20-pt margins; feed cards 16.
    private var inset: CGFloat { isCompact ? DS.Space.screen : DS.Space.screen }

    var body: some View {
        Group {
            if isCompact { compactBody } else { feedBody }
        }
        .padding(.horizontal, inset)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHighlighted ? Color.qAqua : Color.clear)
        // Tap anywhere on the card closes the sticker popover.
        .overlay {
            if isTrayOpen {
                Color.black.opacity(0.001).onTapGesture { withAnimation(.qSpring) { isTrayOpen = false } }
            }
        }
        // The popover floats 8 pt above the card, 8 pt from the screen's left edge.
        // The popover rises from this card's own action row and sits just above it.
        .overlayPreferenceValue(ActionRowAnchor.self) { anchor in
            GeometryReader { geo in
                if isTrayOpen, let anchor {
                    ReactionPopover(selected: answer.myReaction) { pick($0) }
                        .padding(.horizontal, DS.Space.m)
                        .frame(width: geo.size.width)
                        .offset(y: geo[anchor].minY + 10 - ReactionPopover.height - DS.Space.xxs)
                        .transition(.scale(scale: 0.6, anchor: .bottomLeading).combined(with: .opacity))
                }
            }
        }
        .zIndex(isTrayOpen ? 10 : 0)
        .animation(.qSpring, value: isTrayOpen)
        .sheet(isPresented: $isSharingStory) {
            ShareStorySheet(answer: answer).presentationDetents([.large])
        }
        .sheet(isPresented: $isEditing) {
            EditAnswerSheet(answer: answer).presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isReporting) {
            ReportSheet(answer: answer).presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showReactions) {
            ReactionsSheet(answer: answer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
        .confirmationDialog("Delete this answer?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.deleteAnswer(answer.id) }
        }
        .onAppear { if opensTray { isTrayOpen = true } }
        .onChange(of: opensTray) { _, open in withAnimation(.qSpring) { isTrayOpen = open } }
    }

    // MARK: Layouts

    private var feedBody: some View {
        HStack(alignment: .top, spacing: 12) {
            avatar
            VStack(alignment: .leading, spacing: 0) {
                nameRow.padding(.top, -1)
                answerText(size: 15.5, lineHeight: 22).padding(.top, 4)
                actions
                    .anchorPreference(key: ActionRowAnchor.self, value: .bounds) { $0 }
                    .padding(.top, 10)
                reactionsLine.padding(.top, 8)
            }
        }
    }

    /// 42-pt photo with the quick-follow "+" (see `FollowableAvatar`).
    private var avatar: some View {
        NavigationLink(value: Route.profile(answer.authorId)) { FollowableAvatar(user: author, size: 42) }
            .buttonStyle(.plain)
            .accessibilityLabel("\(author?.username ?? "") profile")
    }

    /// Profile row as a thread: the day's question is the post, the answer is the reply under it.
    /// The question gets a Quesly avatar and a date line, so a 10-day-old answer still reads in
    /// context; a hairline thread joins the two avatars.
    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: DS.Space.s) {
                VStack(spacing: 0) {
                    QueslyMark(color: .qLime, cutout: .qGreen)
                        .frame(width: 24)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.qGreen))
                    // Touches both photos: question above, answer below.
                    Rectangle().fill(Color.qLine).frame(width: 2).frame(maxHeight: .infinity)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DS.Space.xs) {
                        Text(questionDayLabel)
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Color.qGray)
                        Spacer(minLength: DS.Space.xs)
                        moreMenu
                    }
                    .frame(height: 20)
                    Text(answer.questionText)
                        .font(.ui(15, .medium))
                        .foregroundStyle(Color.qInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, DS.Space.m)
            }
            // Height comes from the question text, so the thread line spans exactly to the photo below.
            .fixedSize(horizontal: false, vertical: true)
            feedBody
        }
    }

    private var questionDayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(answer.createdAt) { return "Today" }
        if cal.isDateInYesterday(answer.createdAt) { return "Yesterday" }
        return answer.createdAt.formatted(.dateTime.month(.abbreviated).day())
    }

    private func answerText(size: CGFloat, lineHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(isTranslated ? translatedText(for: answer.text) : answer.text)
                .font(.ui(size))
                .lineSpacing(lineHeight - size * 1.21)   // Inter's natural line is ≈ 1.21 × size
                .foregroundStyle(Color.qInk)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { doubleTapReact() }
                .overlay { DoubleTapPop(kind: .like, trigger: popTrigger) }
                .contextMenu { menuItems } preview: { preview }

            if !isMine {
                HStack(spacing: 4) {
                    if isTranslated {
                        Text("Translated ·")
                            .font(.ui(12))
                            .foregroundStyle(Color.qGray)
                        Button("See original") {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isTranslated = false
                            }
                        }
                        .font(.ui(12, .semibold))
                        .foregroundStyle(Color.qBrandText)
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isTranslated = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "translate")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Translate")
                                    .font(.ui(12, .medium))
                            }
                            .foregroundStyle(Color.qBrandText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    private func translatedText(for original: String) -> String {
        if original.localizedCaseInsensitiveContains("marathon") {
            return "Пробежал свой первый полумарафон прошлой весной"
        }
        if original.localizedCaseInsensitiveContains("anatomy") {
            return "Сдала экзамен по анатомии после того, как однажды завалила его"
        }
        if original.localizedCaseInsensitiveContains("plants") {
            return "Все мои растения живы. Все 23 штуки 🌿"
        }
        if original.localizedCaseInsensitiveContains("running") {
            return "Наконец-то начал бегать по утрам и продержался целый месяц"
        }
        return "«" + original + "» (Translated)"
    }

    // MARK: Header rows

    private var timeText: String {
        RelativeTime.short(answer.createdAt) + (answer.isEdited ? " · edited" : "")
    }

    /// 20-pt row: name 15/600 + time 14/400 gray, inline Follow or "You" pill, "…" on the right edge.
    private var nameRow: some View {
        HStack(spacing: 6) {
            NavigationLink(value: Route.profile(answer.authorId)) {
                HStack(spacing: 5) {
                    Text(author?.username ?? "unknown")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(Color.qInk)

                    if !isCompact || answer.isEdited {
                        Text("·")
                            .font(.ui(14))
                            .foregroundStyle(Color.qGray)
                        Text(isCompact ? "edited" : timeText)
                            .font(.ui(14))
                            .foregroundStyle(Color.qGray)
                    }
                }
                .lineLimit(1)
            }
            .buttonStyle(.plain)

            if isMine && !isCompact {
                Text("You")
                    .font(.ui(11, .semibold))
                    .foregroundStyle(Color.qGreenDeep)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color(hex: 0xEDF8F3)))
            }

            if (answer.isHidden ?? false) {
                HStack(spacing: 3) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Hidden")
                        .font(.ui(11, .medium))
                }
                .foregroundStyle(Color.qGray)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.qField))
            } else if answer.visibility == .onlyMe {
                HStack(spacing: 3) {
                    Icon(.lockSimpleFill, size: 10)
                    Text("Private")
                        .font(.ui(11, .medium))
                }
                .foregroundStyle(Color.qGray)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.qField))
            }

            Spacer(minLength: 8)

            if !isCompact { moreMenu }
        }
        .frame(height: 20)
    }

    /// 20-pt glyph in a 44-pt zone that takes no extra room in the row.
    private var moreMenu: some View {
        Menu { menuItems } label: {
            Icon(.dotsThreeBold, size: 20)
                .foregroundStyle(Color.qGray)
                .frame(width: DS.hitTarget, height: DS.hitTarget)
                .contentShape(Rectangle())
                .padding(-12)
        }
        .accessibilityLabel("More")
    }

    // MARK: Menu

    @ViewBuilder
    private var menuItems: some View {
        Button { UIPasteboard.general.url = link } label: { Label("Copy link", image: QIcon.link.assetName) }
        if isMine {
            Button { isSharingStory = true } label: { Label("Share as story", systemImage: QIcon.paperPlaneTilt.rawValue) }
            Button {
                withAnimation(.qSmooth) { store.toggleHideMyAnswer(answer.id) }
            } label: {
                Label((answer.isHidden ?? false) ? "Show in feed" : "Hide from feed",
                      systemImage: (answer.isHidden ?? false) ? "eye" : "eye.slash")
            }
            if answer.isEditable() {
                // "Edit · 12 min left": the window is visible, so it never closes by surprise.
                let minutesLeft = max(1, Int(ceil((Answer.editWindow - Date.now.timeIntervalSince(answer.createdAt)) / 60)))
                Button { isEditing = true } label: {
                    Label("Edit · \(minutesLeft) min left", systemImage: QIcon.pencilSimple.rawValue)
                }
            }
            Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: QIcon.trash.rawValue) }
        } else {
            Button { withAnimation(.qSmooth) { store.hideAnswer(answer.id) } } label: {
                Label("Not interested", image: QIcon.notInterested.assetName)
            }
            Button(role: .destructive) { isReporting = true } label: { Label("Report", image: QIcon.flag.assetName) }
        }
    }

    /// Lifted card shown above the context menu.
    private var preview: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            HStack(spacing: DS.Space.xs) {
                Avatar(user: author, size: 32)
                Text(author?.username ?? "")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                Spacer(minLength: 0)
            }
            Text(answer.questionText)
                .font(.ui(13, .semibold))
                .foregroundStyle(Color.qBrandText)
            Text(answer.text)
                .font(.ui(17))
                .foregroundStyle(Color.qInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Space.l)
        .frame(width: 340, alignment: .leading)
        .background(Color.qSurface)
        .environment(store)
    }

    // MARK: Actions

    /// React · Repost · Share, then Save on the right. Each is a 44-pt zone around a 24-pt glyph;
    /// the row is pulled out by the zone's 10 pt so the glyphs sit exactly on the text edges.
    @ViewBuilder
    private var actions: some View {
        if isMine { ownActions } else { viewerActions }
    }

    /// Your own answer: prominent 1-tap "Share to Peeks" pill + repost count + link share.
    private var ownActions: some View {
        HStack(spacing: 16) {
            Button { isSharingStory = true } label: {
                HStack(spacing: 6) {
                    Icon(.paperPlaneTiltFill, size: 12)
                    Text("Share to Peeks")
                        .font(.ui(13, .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(Capsule().fill(Color.qGreen))
                .shadow(color: Color.qGreen.opacity(0.18), radius: 4, y: 1.5)
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Share answer as peek")

            if answer.reshares > 0 {
                HStack(spacing: 4) {
                    Icon(.repost, size: 19)
                    Text("\(answer.reshares)").font(.ui(13.5, .medium)).monospacedDigit()
                }
                .foregroundStyle(Color.qGray)
            }

            ShareLink(item: link) {
                Icon(.shareForward, size: 20)
                    .foregroundStyle(Color.qGray)
                    .frame(height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Share outside Quesly")

            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }

    private var viewerActions: some View {
        HStack(spacing: 22) {
            reactButton

            zoneButton(label: answer.isResharedByMe ? "Reposted, tap to undo" : "Repost") {
                withAnimation(.qSpring) { store.toggleReshare(answer.id) }
            } glyph: {
                HStack(spacing: 5) {
                    Icon(answer.isResharedByMe ? .repostActive : .repost, size: 20)
                        .foregroundStyle(answer.isResharedByMe ? Color.qGreen : Color.qGray)
                    if answer.reshares > 0 {
                        Text("\(answer.reshares)")
                            .font(.ui(13.5, .medium))
                            .foregroundStyle(answer.isResharedByMe ? Color.qGreen : Color.qGray)
                            .monospacedDigit()
                    }
                }
            }
            .pop(on: answer.isResharedByMe)
            .sensoryFeedback(.success, trigger: answer.isResharedByMe) { _, on in on }

            ShareLink(item: link) {
                Icon(.shareForward, size: 20)
                    .foregroundStyle(Color.qGray)
                    .frame(height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Share outside Quesly")

            Spacer(minLength: 0)

            zoneButton(label: answer.isBookmarked ? "Saved" : "Save answer") {
                withAnimation(.qSpring) { store.toggleBookmark(answer.id) }
            } glyph: {
                Icon(answer.isBookmarked ? .bookmarkSimpleFill : .bookmarkSimple, size: 20)
                    .foregroundStyle(answer.isBookmarked ? Color.qGreen : Color.qGray)
            }
            .pop(on: answer.isBookmarked)
            .sensoryFeedback(.selection, trigger: answer.isBookmarked)
        }
        .padding(.top, 2)
    }

    private var reactButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.qSpring) { isTrayOpen.toggle() }
        } label: {
            HStack(spacing: 5) {
                if let mine = answer.myReaction, !isTrayOpen {
                    ReactionSticker(kind: mine, size: 22)
                        .id(mine)
                        .keyframeAnimator(initialValue: 1.0, trigger: stickerPop) { view, scale in
                            view.scaleEffect(scale)
                        } keyframes: { _ in
                            SpringKeyframe(1.25, duration: 0.12)
                            SpringKeyframe(0.95, duration: 0.12)
                            SpringKeyframe(1.0, duration: 0.2)
                        }
                } else {
                    Icon(.smiley, size: 20)
                        .foregroundStyle(isTrayOpen ? Color.qInk : Color.qGray)
                }

                if answer.totalReactions > 0 {
                    Text("\(answer.totalReactions)")
                        .font(.ui(13.5, .medium))
                        .foregroundStyle(answer.myReaction != nil ? Color.qInk : Color.qGray)
                        .monospacedDigit()
                }
            }
            .frame(height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(answer.myReaction.map { "Your reaction: \($0.label). Change reaction" } ?? "React")
    }

    private func zoneButton<G: View>(label: String, action: @escaping () -> Void, @ViewBuilder glyph: () -> G) -> some View {
        Button(action: action) {
            glyph()
                .frame(height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(label)
    }

    private func pick(_ kind: ReactionKind) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            store.react(kind, on: answer.id)
            isTrayOpen = false
        }
        stickerPop += 1
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func doubleTapReact() {
        popTrigger += 1
        if answer.myReaction != .like {
            withAnimation(.qSpring) { store.react(.like, on: answer.id) }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: Reactions line

    /// Yours: the counter pill (only you see numbers). Others': faces and names, never a number.
    @ViewBuilder
    private var reactionsLine: some View {
        if isMine {
            if answer.totalReactions > 0 { counterPill }
        } else if let line = store.reactedBy(answer) {
            ReactedByLine(line: line)
        }
    }

    /// Top 3 stickers · total · chevron. Opens who reacted.
    private var counterPill: some View {
        Button { showReactions = true } label: {
            HStack(spacing: DS.Space.xs) {
                let top = Array(answer.topReactions.prefix(3))
                HStack(spacing: -8) {
                    ForEach(Array(top.enumerated()), id: \.element) { index, kind in
                        ReactionSticker(kind: kind, size: 30)
                            .zIndex(Double(top.count - index))
                    }
                }
                Text("\(answer.totalReactions)")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                    .monospacedDigit()
                Icon(.caretRightBold, size: 16).foregroundStyle(Color.qGray)
            }
            .padding(.leading, 6)
            .padding(.trailing, 10)
            .frame(height: 36)
            .background(Capsule().fill(Color.qField))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(answer.totalReactions) reactions. See who reacted")
    }
}

/// Bounds of an answer's action row, so the sticker popover can sit right above it.
private struct ActionRowAnchor: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) { value = value ?? nextValue() }
}

/// "Reacted by you, funnnyyy1 and others" with up to two faces, or stickers + "People reacted"
/// when nobody you follow reacted.
struct ReactedByLine: View {
    let line: AppStore.ReactedBy

    var body: some View {
        HStack(spacing: 6) {
            if line.names.isEmpty {
                HStack(spacing: -6) {
                    ForEach(Array(line.stickers.enumerated()), id: \.element) { index, kind in
                        ReactionSticker(kind: kind, size: 20)
                            .zIndex(Double(line.stickers.count - index))
                    }
                }
                Text("People reacted")
            } else {
                HStack(spacing: -6) {
                    ForEach(line.faces.prefix(2)) { user in
                        Avatar(user: user, size: 18)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    }
                }
                if let top = line.stickers.first {
                    ReactionSticker(kind: top, size: 20)
                }
                sentence
            }
        }
        .font(.ui(12.5))
        .foregroundStyle(Color.qGray)
        .lineLimit(1)
        .frame(height: 18)
        .accessibilityElement(children: .combine)
    }

    private var sentence: Text {
        func bold(_ s: String) -> Text { Text(s).font(.ui(12.5, .semibold)).foregroundStyle(Color.qInk) }
        var t = Text("Reacted by ")
        let n = line.names
        switch (n.count, line.hasOthers) {
        case (1, false): t = t + bold(n[0])
        case (1, true): t = t + bold(n[0]) + Text(" and others")
        case (_, false): t = t + bold(n[0]) + Text(" and ") + bold(n[1])
        default: t = t + bold(n[0]) + Text(", ") + bold(n[1]) + Text(" and others")
        }
        return t
    }
}

// MARK: - Edit

struct EditAnswerSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let answer: Answer
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(answer.questionText.uppercased())
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qBrandText)
                TextEditor(text: $text)
                    .font(.ui(17))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qField))
                    .onChange(of: text) { _, new in
                        if new.count > AppStore.maxAnswerLength { text = String(new.prefix(AppStore.maxAnswerLength)) }
                    }
                HStack {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        let left = max(0, Int(Answer.editWindow - ctx.date.timeIntervalSince(answer.createdAt)))
                        Label { Text(String(format: "%d:%02d left to edit", left / 60, left % 60)) } icon: { Icon(.timer, size: DS.Icon.inline) }
                            .font(.ui(13))
                            .foregroundStyle(left < 60 ? Color.qFlame : Color.qGray)
                            .monospacedDigit()
                    }
                    Spacer()
                    Text("\(text.count)/\(AppStore.maxAnswerLength)")
                        .font(.ui(13)).foregroundStyle(Color.qGray).monospacedDigit()
                }
                GreenButton(title: "Save changes", isEnabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && answer.isEditable()) {
                    store.editAnswer(answer.id, text: text)
                    dismiss()
                }
            }
            .padding(20)
            .navigationTitle("Edit answer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .onAppear { text = answer.text }
    }
}

// MARK: - Report / block

struct ReportSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let answer: Answer
    @State private var sentReason: ReportReason?
    @State private var confirmBlock = false

    private var author: AppUser? { store.user(answer.authorId) }

    var body: some View {
        NavigationStack {
            Group {
                if sentReason == nil { reasons } else { thanks }
            }
            .animation(.qSmooth, value: sentReason)
            .navigationTitle(sentReason == nil ? "Report answer" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .confirmationDialog("Block @\(author?.username ?? "")?", isPresented: $confirmBlock, titleVisibility: .visible) {
                Button("Block", role: .destructive) {
                    store.block(answer.authorId)
                    dismiss()
                }
            } message: {
                Text("You won't see their answers, and they won't be notified.")
            }
        }
    }

    private var reasons: some View {
        List {
            Section {
                ForEach(ReportReason.allCases) { reason in
                    Button {
                        store.report(answer.id, reason: reason)
                        sentReason = reason
                    } label: {
                        HStack {
                            Text(reason.rawValue).font(.ui(16)).foregroundStyle(Color.qInk)
                            Spacer()
                            Icon(.caretRightBold, size: DS.Icon.caption)
                                .foregroundStyle(Color.qGray)
                        }
                    }
                }
            } header: {
                Text("Why are you reporting this?").font(.ui(13))
            } footer: {
                Text("Reports are anonymous. Quesly is a kind place. We review every report.")
                    .font(.ui(13))
            }
            Section {
                Button(role: .destructive) { confirmBlock = true } label: {
                    Text("Block @\(author?.username ?? "")")
                        .font(.ui(16))
                }
            }
        }
    }

    private var thanks: some View {
        VStack(spacing: 16) {
            Spacer()
            Icon(.shieldCheckFill, size: 60)
                .foregroundStyle(Color.qBrandText)
                .pop(on: sentReason)
            Text("Thanks for letting us know").font(.ui(22, .semibold))
            Text("We'll review this answer. You can also block this person so you never see their answers again.")
                .font(.ui(15)).foregroundStyle(Color.qGray).multilineTextAlignment(.center)
                .padding(.horizontal, DS.Space.screen)
            Spacer()
            Button(role: .destructive) { confirmBlock = true } label: {
                Text("Block @\(author?.username ?? "")")
                    .font(.ui(16, .semibold))
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Capsule().stroke(Color.red.opacity(0.5)))
            }
            .padding(.horizontal, DS.Space.screen)
            GreenButton(title: "Done") { dismiss() }.padding(.horizontal, DS.Space.screen).padding(.bottom, 12)
        }
    }
}
