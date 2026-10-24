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

struct AnswerCard: View {
    @Environment(AppStore.self) private var store
    let answer: Answer
    var showsQuestion = false
    var showsAuthor = true
    /// Shown in your profile for someone else's answer you reposted.
    var isRepost = false
    /// Demo/screenshot hook: start with the reaction tray open.
    var opensTray = false
    /// Brief brand tint, used when your own answer lands in the feed after posting.
    var isHighlighted = false
    /// Your own answer pinned on top of the feeds.
    var isPinnedMine = false
    /// Profile row: small author line, date and private counts as one meta line under the text,
    /// and no action row on your own answers (share, copy, edit and delete live in the long-press menu).
    var isCompact = false

    @State private var isTrayOpen = false
    @State private var isSharing = false
    @State private var isEditing = false
    @State private var isReporting = false
    @State private var showReactions = false
    @State private var confirmDelete = false
    @State private var popTrigger = 0

    private var author: AppUser? { store.user(answer.authorId) }
    private var isMine: Bool { answer.authorId == store.me.id }

    /// Card grid (all on the 4-pt scale, one 16-pt inset on every side):
    /// header row — 40-pt avatar, name + time centred on it, "…" on the right edge;
    /// 12 pt; the answer at full card width, aligned with the avatar's left edge;
    /// 4 pt; the action row — glyphs (not their 44-pt hit areas) aligned to the same edges.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isRepost {
                IconLabel("You reposted", icon: .repost, size: DS.Icon.caption)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qGray)
                    .padding(.bottom, DS.Space.s)
            }
            if isPinnedMine {
                IconLabel("Your answer", icon: .pushPinFill, size: DS.Icon.caption)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qBrandText)
                    .padding(.bottom, DS.Space.s)
            }
            if showsQuestion { questionLine.padding(.bottom, DS.Space.s) }
            if showsAuthor {
                Group { if isCompact { compactHeader } else { header } }
                    .padding(.bottom, isCompact ? DS.Space.xs : DS.Space.s)
            }

            Text(answer.text)
                .font(.ui(17))
                .lineSpacing(3)
                .foregroundStyle(Color.qInk)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { doubleTapReact() }
                .overlay { DoubleTapPop(kind: .love, trigger: popTrigger) }
                .contextMenu { menuItems } preview: { preview }

            if isCompact && !showsAuthor { meta.padding(.top, DS.Space.xs) }
            if !(isCompact && isMine) { actions.padding(.top, DS.Space.xxs) }
        }
        .padding(.horizontal, DS.Space.m)
        .padding(.top, DS.Space.m)
        .padding(.bottom, isCompact && isMine ? DS.Space.m : DS.Space.xxs)   // the action row brings its own air
        .background(isHighlighted ? Color.qMint : Color.clear)
        .sheet(isPresented: $isSharing) {
            ShareStorySheet(answer: answer)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $isEditing) {
            EditAnswerSheet(answer: answer)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isReporting) {
            ReportSheet(answer: answer)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showReactions) {
            ReactionsSheet(answer: answer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("Delete this answer?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.deleteAnswer(answer.id) }
        }
        .onAppear { if opensTray { isTrayOpen = true } }
        .onChange(of: opensTray) { _, open in withAnimation(.qSpring) { isTrayOpen = open } }
    }

    private var questionLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
            Text(answer.questionText)
                .font(.ui(13, .semibold))
                .foregroundStyle(Color.qBrandText)
                .lineLimit(2)
            Spacer(minLength: DS.Space.xs)
            if !showsAuthor && !isCompact {
                Text(RelativeTime.dayLabel(answer.createdAt))
                    .font(.ui(13)).foregroundStyle(Color.qGray)
            }
        }
    }

    /// Avatar, then name · badge · time on one line, vertically centred on the avatar.
    private var header: some View {
        HStack(alignment: .center, spacing: DS.Space.s) {
            NavigationLink(value: Route.profile(answer.authorId)) {
                HStack(alignment: .center, spacing: DS.Space.s) {
                    Avatar(user: author, size: 40)
                    HStack(spacing: 6) {
                        Text(author?.username ?? "unknown")
                            .font(.ui(15, .semibold))
                            .foregroundStyle(Color.qInk)
                            .lineLimit(1)
                        if let badge = author?.badge {
                            HexBadge(color: badge.color, icon: badge.icon).frame(width: 14, height: 14)
                        }
                        Text(RelativeTime.short(answer.createdAt) + (answer.isEdited ? " · edited" : ""))
                            .font(.ui(15)).foregroundStyle(Color.qGray)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(author?.username ?? "") profile")
            Spacer(minLength: DS.Space.xs)
            if !isMine && !store.isFollowing(answer.authorId) {
                FollowPill(isFollowing: false, compact: true) { store.toggleFollow(answer.authorId) }
                    .transition(.opacity)
            }
            moreMenu
        }
        .animation(.qSpring, value: store.isFollowing(answer.authorId))
    }

    /// Compact author line: 28-pt avatar, "name · 9m", "…" on the right.
    private var compactHeader: some View {
        HStack(spacing: DS.Space.xs) {
            NavigationLink(value: Route.profile(answer.authorId)) {
                HStack(spacing: DS.Space.xs) {
                    Avatar(user: author, size: 28)
                    (Text(author?.username ?? "unknown").font(.ui(15, .semibold)).foregroundStyle(Color.qInk)
                        + Text(" · " + RelativeTime.short(answer.createdAt)).font(.ui(15)).foregroundStyle(Color.qGray))
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(author?.username ?? "") profile")
            Spacer(minLength: DS.Space.xs)
            moreMenu
        }
    }

    /// "Oct 23 · 55 reactions · 6 reposts". Counts only on your own answers (only you see them);
    /// tapping them opens who reacted.
    private var meta: some View {
        var parts = [RelativeTime.dayLabel(answer.createdAt)]
        if isMine && answer.totalReactions > 0 {
            parts.append(answer.totalReactions == 1 ? "1 reaction" : "\(answer.totalReactions) reactions")
        }
        if isMine && answer.reshares > 0 {
            parts.append(answer.reshares == 1 ? "1 repost" : "\(answer.reshares) reposts")
        }
        if answer.isEdited { parts.append("edited") }
        let opens = isMine && answer.totalReactions > 0
        return Text(parts.joined(separator: " · "))
            .font(.ui(13))
            .foregroundStyle(Color.qGray)
            .lineLimit(1)
            .frame(minHeight: 20)
            .contentShape(Rectangle())
            .onTapGesture { if opens { showReactions = true } }
            .accessibilityAddTraits(opens ? .isButton : [])
            .accessibilityHint(opens ? "Only you can see this. Shows who reacted" : "")
    }

    /// Shared by the "…" menu and the long-press context menu.
    @ViewBuilder
    private var menuItems: some View {
        if !isMine {
            Button {
                withAnimation(.qSpring) { store.react(.love, on: answer.id) }
            } label: {
                Label(answer.myReaction == .love ? "Remove love" : "Love it",
                      systemImage: (answer.myReaction == .love ? QIcon.heartFill : QIcon.heart).rawValue)
            }
        }
        if isMine {
            Button { isSharing = true } label: { Label("Share", systemImage: QIcon.paperPlaneTilt.rawValue) }
            Button { UIPasteboard.general.string = answer.text } label: { Label("Copy text", systemImage: QIcon.copy.rawValue) }
            Divider()
            if answer.isEditable() {
                // "Edit · 12 min left": the window is visible, so it never closes by surprise.
                let minutesLeft = max(1, Int(ceil((Answer.editWindow - Date.now.timeIntervalSince(answer.createdAt)) / 60)))
                Button { isEditing = true } label: {
                    Label("Edit · \(minutesLeft) min left", systemImage: QIcon.pencilSimple.rawValue)
                }
            }
            Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: QIcon.trash.rawValue) }
        } else {
            Button(role: .destructive) { isReporting = true } label: { Label("Report or block", systemImage: QIcon.flag.rawValue) }
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

    private var moreMenu: some View {
        Menu {
            menuItems
        } label: {
            Icon(.dotsThreeBold, size: DS.Icon.action)
                .foregroundStyle(Color.qGray)
                .glyphHitArea()
        }
        .accessibilityLabel("More")
    }

    /// react · repost · share on the left, bookmark on the right (under "…").
    /// Glyphs sit on the card's 16-pt edges; each keeps a full 44-pt tap area.
    private var actions: some View {
        HStack(spacing: DS.Space.xl) {
            if isMine {
                // Nothing until the first reaction: an empty counter reads like a verdict.
                if answer.totalReactions > 0 { authorReactions }
                if answer.reshares > 0 { authorReshares }
            } else {
                ReactionControl(answer: answer, isTrayOpen: $isTrayOpen) { kind in
                    withAnimation(.qSpring) { store.react(kind, on: answer.id) }
                }
                if !isTrayOpen {
                    iconButton(.repost, tint: answer.isResharedByMe ? .qBrandText : .qGray,
                               label: answer.isResharedByMe ? "Remove from your profile" : "Repost to your profile") {
                        withAnimation(.qSpring) { store.toggleReshare(answer.id) }
                    }
                    .pop(on: answer.isResharedByMe)
                    .sensoryFeedback(.success, trigger: answer.isResharedByMe) { _, on in on }
                }
            }
            if !isTrayOpen {
                iconButton(.paperPlaneTilt, tint: .qGray, label: "Share outside Quesly") { isSharing = true }
            }
            Spacer(minLength: 0)
            if !isMine && !isTrayOpen {
                iconButton(answer.isBookmarked ? .bookmarkSimpleFill : .bookmarkSimple,
                           tint: answer.isBookmarked ? .qBrandText : .qGray,
                           label: answer.isBookmarked ? "Remove from saved" : "Save to your profile") {
                    withAnimation(.qSpring) { store.toggleBookmark(answer.id) }
                }
                .pop(on: answer.isBookmarked)
                .sensoryFeedback(.selection, trigger: answer.isBookmarked)
            }
        }
        .frame(minHeight: DS.hitTarget)
        .animation(.qSpring, value: isTrayOpen)
    }

    /// Only the author sees how often the answer was reposted — never by whom.
    private var authorReshares: some View {
        HStack(spacing: 6) {
            Icon(.repost, size: DS.Icon.inline).foregroundStyle(Color.qGray)
            Text("\(answer.reshares)")
                .font(.ui(15, .semibold))
                .foregroundStyle(Color.qInk)
                .contentTransition(.numericText())
                .lineLimit(1)
                .fixedSize()
            Icon(.lockSimpleFill, size: DS.Icon.caption).foregroundStyle(Color.qGray.opacity(0.7))
        }
        .frame(minHeight: DS.hitTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reposted \(answer.reshares) times. Only you can see this")
    }

    /// Only the author sees reaction totals — and who reacted.
    private var authorReactions: some View {
        Button { showReactions = true } label: {
            HStack(spacing: 6) {
                HStack(spacing: -6) {
                    ForEach(answer.topReactions.prefix(3)) { kind in
                        ReactionSticker(kind: kind, size: 24)
                    }
                }
                Text("\(answer.totalReactions)")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                    .contentTransition(.numericText())
                .lineLimit(1)
                .fixedSize()
                Icon(.lockSimpleFill, size: DS.Icon.caption).foregroundStyle(Color.qGray.opacity(0.7))
            }
            .frame(minHeight: DS.hitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(answer.totalReactions) reactions. Only you can see this. Show who reacted")
    }

    private func iconButton(_ icon: QIcon, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Icon(icon, size: DS.Icon.action)
                .foregroundStyle(tint)
                .glyphHitArea()
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(label)
    }

    private func doubleTapReact() {
        guard !isMine else { return }
        popTrigger += 1
        if answer.myReaction != .love {
            withAnimation(.qSpring) { store.react(.love, on: answer.id) }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
