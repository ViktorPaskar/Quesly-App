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

    @State private var isTrayOpen = false
    @State private var isSharing = false
    @State private var isEditing = false
    @State private var isReporting = false
    @State private var showReactions = false
    @State private var confirmDelete = false
    @State private var popTrigger = 0

    private var author: AppUser? { store.user(answer.authorId) }
    private var isMine: Bool { answer.authorId == store.me.id }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            if showsQuestion { questionLine }

            HStack(alignment: .top, spacing: DS.Space.s) {
                if showsAuthor {
                    NavigationLink(value: Route.profile(answer.authorId)) {
                        Avatar(user: author, size: 40)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("\(author?.username ?? "") profile")
                }

                VStack(alignment: .leading, spacing: DS.Space.xxs) {
                    if showsAuthor { header }
                    Text(answer.text)
                        .font(.ui(17))
                        .lineSpacing(2)
                        .foregroundStyle(Color.qInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) { doubleTapReact() }
                        .overlay { DoubleTapPop(emoji: ReactionKind.love.emoji, trigger: popTrigger) }
                    actions
                }
            }
        }
        .padding(.horizontal, DS.Space.screen)
        .padding(.top, DS.Space.m)
        .padding(.bottom, DS.Space.xxs)
        .background(Color.qBackground)
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
    }

    private var questionLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Space.xs) {
            Text(answer.questionText)
                .font(.ui(13, .semibold))
                .foregroundStyle(Color.qBrandText)
                .lineLimit(2)
            Spacer(minLength: DS.Space.xs)
            if !showsAuthor {
                Text(RelativeTime.dayLabel(answer.createdAt))
                    .font(.ui(13)).foregroundStyle(Color.qGray)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            NavigationLink(value: Route.profile(answer.authorId)) {
                Text(author?.username ?? "unknown")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qInk)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            if let badge = author?.badge {
                HexBadge(color: badge.color, icon: badge.icon).frame(width: 14, height: 14)
            }
            Text(RelativeTime.short(answer.createdAt) + (answer.isEdited ? " · edited" : ""))
                .font(.ui(15)).foregroundStyle(Color.qGray)
                .lineLimit(1)
            if answer.visibility == .friends {
                Icon(.usersFill, size: 13)
                    .foregroundStyle(Color.qGray)
                    .accessibilityLabel("Friends only")
            }
            Spacer(minLength: DS.Space.xxs)
            if !isMine && !store.isFollowing(answer.authorId) {
                FollowPill(isFollowing: false, compact: true) { store.toggleFollow(answer.authorId) }
                    .transition(.opacity)
            }
            moreMenu
        }
        .frame(minHeight: 24)
        .animation(.qSpring, value: store.isFollowing(answer.authorId))
    }

    private var moreMenu: some View {
        Menu {
            Button { isSharing = true } label: { Label("Share as story", systemImage: QIcon.paperPlaneTilt.rawValue) }
            Button { UIPasteboard.general.string = answer.text } label: { Label("Copy text", systemImage: QIcon.copy.rawValue) }
            if isMine {
                if answer.isEditable() {
                    Button { isEditing = true } label: { Label("Edit", systemImage: QIcon.pencilSimple.rawValue) }
                }
                Button(role: .destructive) { confirmDelete = true } label: { Label("Delete", systemImage: QIcon.trash.rawValue) }
            } else {
                Button(role: .destructive) { isReporting = true } label: { Label("Report or block", systemImage: QIcon.flag.rawValue) }
            }
        } label: {
            Icon(.dotsThreeBold, size: 20)
                .foregroundStyle(Color.qGray)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .padding(.trailing, -6)
        .accessibilityLabel("More")
    }

    /// Threads-style action row: react · share ··· save. Icons only, 44-pt targets.
    private var actions: some View {
        HStack(spacing: DS.Space.m) {
            if isMine {
                authorReactions
            } else {
                ReactionControl(answer: answer, isTrayOpen: $isTrayOpen) { kind in
                    withAnimation(.qSpring) { store.react(kind, on: answer.id) }
                }
            }
            if !isTrayOpen {
                iconButton(.paperPlaneTilt, tint: .qGray, label: "Share") { isSharing = true }
                Spacer(minLength: 0)
                iconButton(answer.isSaved ? .bookmarkSimpleFill : .bookmarkSimple,
                           tint: answer.isSaved ? .qBrandText : .qGray,
                           label: answer.isSaved ? "Remove from saved" : "Save") {
                    withAnimation(.qSpring) { store.toggleSave(answer.id) }
                }
                .pop(on: answer.isSaved)
                .sensoryFeedback(.selection, trigger: answer.isSaved)
            }
        }
        .frame(minHeight: DS.hitTarget)
        .animation(.qSpring, value: isTrayOpen)
    }

    /// Only the author sees reaction totals — and who reacted.
    private var authorReactions: some View {
        Button { showReactions = true } label: {
            HStack(spacing: 6) {
                if answer.totalReactions == 0 {
                    Icon(.heart, size: 22).foregroundStyle(Color.qGray.opacity(0.6))
                    Text("No reactions yet").font(.ui(15)).foregroundStyle(Color.qGray)
                } else {
                    HStack(spacing: -4) {
                        ForEach(answer.topReactions.prefix(3)) { kind in
                            Text(kind.emoji).font(.system(size: 17))
                        }
                    }
                    Text("\(answer.totalReactions)")
                        .font(.ui(15, .semibold))
                        .foregroundStyle(Color.qInk)
                        .contentTransition(.numericText())
                }
                Icon(.lockSimpleFill, size: 11).foregroundStyle(Color.qGray.opacity(0.7))
            }
            .frame(minHeight: DS.hitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .disabled(answer.totalReactions == 0)
        .accessibilityLabel(answer.totalReactions == 0
            ? "No reactions yet"
            : "\(answer.totalReactions) reactions. Only you can see this. Show who reacted")
    }

    private func iconButton(_ icon: QIcon, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Icon(icon, size: 22)
                .foregroundStyle(tint)
                .frame(minWidth: 32, minHeight: DS.hitTarget)
                .contentShape(Rectangle())
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
                    .font(.ui(14, .bold))
                    .foregroundStyle(Color.qGreen)
                TextEditor(text: $text)
                    .font(.ui(18))
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qField))
                    .onChange(of: text) { _, new in
                        if new.count > AppStore.maxAnswerLength { text = String(new.prefix(AppStore.maxAnswerLength)) }
                    }
                HStack {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        let left = max(0, Int(Answer.editWindow - ctx.date.timeIntervalSince(answer.createdAt)))
                        Label { Text(String(format: "%d:%02d left to edit", left / 60, left % 60)) } icon: { Icon(.timer, size: 16) }
                            .font(.ui(13, .medium))
                            .foregroundStyle(left < 60 ? Color.qFlame : Color.qGray)
                            .monospacedDigit()
                    }
                    Spacer()
                    Text("\(text.count)/\(AppStore.maxAnswerLength)")
                        .font(.ui(13, .medium)).foregroundStyle(Color.qGray).monospacedDigit()
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
                            Icon(.caretRightBold, size: 14)
                                .foregroundStyle(Color.qGray)
                        }
                    }
                }
            } header: {
                Text("Why are you reporting this?").font(.ui(13, .medium))
            } footer: {
                Text("Reports are anonymous. Quesly is a kind place — we review every report.")
                    .font(.ui(13))
            }
            Section {
                Button(role: .destructive) { confirmBlock = true } label: {
                    Label { Text("Block @\(author?.username ?? "")") } icon: { Icon(.prohibitFill, size: 18) }
                        .font(.ui(16, .medium))
                }
            }
        }
    }

    private var thanks: some View {
        VStack(spacing: 16) {
            Spacer()
            Icon(.shieldCheckFill, size: 60)
                .foregroundStyle(Color.qGreen)
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
