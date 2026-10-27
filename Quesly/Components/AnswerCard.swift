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

    private var author: AppUser? { store.user(answer.authorId) }
    private var isMine: Bool { answer.authorId == store.me.id }
    private var link: URL { URL(string: "https://quesly.me/a/\(answer.id)")! }
    /// Profile rows use the profile's 20-pt margins; feed cards 16.
    private var inset: CGFloat { isCompact ? DS.Space.screen : DS.Space.m }

    var body: some View {
        Group {
            if isCompact { compactBody } else { feedBody }
        }
        .padding(.horizontal, inset)
        .padding(.vertical, DS.Space.m)
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
        HStack(alignment: .top, spacing: DS.Space.s) {
            avatar
            VStack(alignment: .leading, spacing: 0) {
                nameRow.padding(.top, -2)       // cap height on the avatar's top edge
                answerText(size: 16, lineHeight: 24).padding(.top, DS.Space.xxs)
                actions
                    .anchorPreference(key: ActionRowAnchor.self, value: .bounds) { $0 }
                    .padding(.top, 6)          // 16 to the glyphs, minus the 44-pt zone's 10
                reactionsLine.padding(.top, DS.Space.xs)
            }
        }
    }

    /// 40-pt photo with the quick-follow "+" (see `FollowableAvatar`).
    private var avatar: some View {
        NavigationLink(value: Route.profile(answer.authorId)) { FollowableAvatar(user: author, size: 40) }
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
        Text(answer.text)
            .font(.ui(size))
            .lineSpacing(lineHeight - size * 1.21)   // Inter's natural line is ≈ 1.21 × size
            .foregroundStyle(Color.qInk)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { doubleTapReact() }
            .overlay { DoubleTapPop(kind: .like, trigger: popTrigger) }
            .contextMenu { menuItems } preview: { preview }
    }

    // MARK: Header rows

    private var timeText: String {
        RelativeTime.short(answer.createdAt) + (answer.isEdited ? " · edited" : "")
    }

    /// 20-pt row: name 15/600 + time 15/400 ink3, inline Follow or "Your answer" pill, "…" on the right edge.
    private var nameRow: some View {
        HStack(spacing: DS.Space.xs) {
            NavigationLink(value: Route.profile(answer.authorId)) {
                HStack(spacing: 6) {
                    Text(author?.username ?? "unknown").font(.ui(15, .semibold)).foregroundStyle(Color.qInk)
                    if !isCompact || answer.isEdited {
                        Text(isCompact ? "edited" : timeText).font(.ui(15)).foregroundStyle(Color.qGray)
                    }
                }
                .lineLimit(1)
            }
            .buttonStyle(.plain)
            if isMine && !isCompact {
                Text("Your answer")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Color.qInk2)
                    .padding(.horizontal, DS.Space.xs)
                    .frame(height: 20)
                    .background(Capsule().fill(Color.qField))
                    .overlay(Capsule().stroke(Color.qLine, lineWidth: 0.8))
                    .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            }
            Spacer(minLength: DS.Space.xs)
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

    /// Your own answer: prominent 1-tap "Share to Stories" pill + link share + repost count.
    private var ownActions: some View {
        HStack(spacing: DS.Space.xs) {
            Button { isSharingStory = true } label: {
                HStack(spacing: 6) {
                    Icon(.paperPlaneTiltFill, size: 12)
                    Text("Share to Stories")
                        .font(.ui(13, .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(Capsule().fill(Color.qGreen))
                .shadow(color: Color.qGreen.opacity(0.18), radius: 4, y: 1.5)
                .frame(minHeight: DS.hitTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Share answer as story")

            ShareLink(item: link) {
                Icon(.shareForward, size: 22)
                    .foregroundStyle(Color.qGray)
                    .frame(width: DS.hitTarget, height: DS.hitTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Share outside Quesly")

            if answer.reshares > 0 {
                HStack(spacing: DS.Space.xxs) {
                    Icon(.repost, size: 22)
                    Text("\(answer.reshares)").font(.ui(15, .semibold)).monospacedDigit()
                }
                .foregroundStyle(Color.qGray)
                .padding(.horizontal, DS.Space.xs)
                .frame(height: DS.hitTarget)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Reposted \(answer.reshares) times. Only you can see this")
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, -10)
    }

    private var viewerActions: some View {
        HStack(spacing: 0) {
            reactButton
            zoneButton(label: answer.isResharedByMe ? "Reposted, tap to undo" : "Repost") {
                withAnimation(.qSpring) { store.toggleReshare(answer.id) }
            } glyph: {
                Icon(answer.isResharedByMe ? .repostActive : .repost, size: 24)
                    .foregroundStyle(answer.isResharedByMe ? Color.qGreen : Color.qGray)
            }
            .pop(on: answer.isResharedByMe)
            .sensoryFeedback(.success, trigger: answer.isResharedByMe) { _, on in on }
            ShareLink(item: link) {
                Icon(.shareForward, size: 24)
                    .foregroundStyle(Color.qGray)
                    .frame(width: DS.hitTarget, height: DS.hitTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Share outside Quesly")
            Spacer(minLength: 0)
            zoneButton(label: answer.isBookmarked ? "Saved" : "Save answer") {
                withAnimation(.qSpring) { store.toggleBookmark(answer.id) }
            } glyph: {
                Icon(answer.isBookmarked ? .bookmarkSimpleFill : .bookmarkSimple, size: 24)
                    .foregroundStyle(answer.isBookmarked ? Color.qGreen : Color.qGray)
            }
            .pop(on: answer.isBookmarked)
            .sensoryFeedback(.selection, trigger: answer.isBookmarked)
        }
        .padding(.horizontal, -10)
        .padding(.bottom, -10)
    }

    /// Smiley, or the sticker you gave (34 pt, left edge on the text edge). While the popover is
    /// open the smiley sits on a 44-pt gray disc.
    private var reactButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.qSpring) { isTrayOpen.toggle() }
        } label: {
            ZStack(alignment: .leading) {
                if isTrayOpen {
                    Circle().fill(Color.qField)
                }
                if let mine = answer.myReaction, !isTrayOpen {
                    ReactionSticker(kind: mine, size: 34)
                        .id(mine)
                        .padding(.leading, 10)
                        .keyframeAnimator(initialValue: 1.0, trigger: stickerPop) { view, scale in
                            view.scaleEffect(scale)
                        } keyframes: { _ in
                            SpringKeyframe(1.25, duration: 0.12)
                            SpringKeyframe(0.95, duration: 0.12)
                            SpringKeyframe(1.0, duration: 0.2)
                        }
                } else {
                    Icon(.smiley, size: 24)
                        .foregroundStyle(isTrayOpen ? Color.qInk : Color.qGray)
                        .frame(width: DS.hitTarget, height: DS.hitTarget)
                }
            }
            .frame(width: DS.hitTarget, height: DS.hitTarget, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(answer.myReaction.map { "Your reaction: \($0.label). Change reaction" } ?? "React")
    }

    private func zoneButton<G: View>(label: String, action: @escaping () -> Void, @ViewBuilder glyph: () -> G) -> some View {
        Button(action: action) {
            glyph()
                .frame(width: DS.hitTarget, height: DS.hitTarget)
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
                HStack(spacing: 2) {
                    ForEach(answer.topReactions.prefix(3)) { ReactionSticker(kind: $0, size: 32) }
                }
                Text("\(answer.totalReactions)")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                    .monospacedDigit()
                Icon(.caretRightBold, size: 16).foregroundStyle(Color.qGray)
            }
            .padding(.leading, DS.Space.xs)
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
        HStack(spacing: DS.Space.xs) {
            if line.names.isEmpty {
                HStack(spacing: 2) {
                    ForEach(line.stickers) { ReactionSticker(kind: $0, size: 30) }
                }
                Text("People reacted")
            } else {
                HStack(spacing: -6) {
                    ForEach(line.faces) { user in
                        Avatar(user: user, size: 20)
                            .overlay(Circle().stroke(Color.qBackground, lineWidth: 2))
                    }
                }
                if let top = line.stickers.first {
                    ReactionSticker(kind: top, size: 26)
                }
                sentence
            }
        }
        .font(.ui(13))
        .foregroundStyle(Color.qInk2)
        .lineLimit(1)
        .frame(height: 20)
        .accessibilityElement(children: .combine)
    }

    private var sentence: Text {
        func bold(_ s: String) -> Text { Text(s).font(.ui(13, .semibold)).foregroundStyle(Color.qInk) }
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
