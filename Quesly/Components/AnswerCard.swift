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
}

struct AnswerCard: View {
    @Environment(AppStore.self) private var store
    let answer: Answer
    var showsQuestion = false
    var showsAuthor = true

    @State private var isSharing = false
    @State private var confirmDelete = false
    @State private var reported = false

    private var author: AppUser? { store.user(answer.authorId) }
    private var isMine: Bool { answer.authorId == store.me.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsQuestion {
                HStack(alignment: .firstTextBaseline) {
                    Text("• \(answer.questionText)")
                        .font(.quesly(11, .semibold))
                        .foregroundStyle(Color.qGreen)
                        .lineLimit(1)
                    Spacer()
                    if !showsAuthor {
                        Text(RelativeTime.dayLabel(answer.createdAt))
                            .font(.quesly(11)).foregroundStyle(Color.qGray)
                    }
                }
            }

            HStack(alignment: .top, spacing: 12) {
                if showsAuthor {
                    NavigationLink(value: Route.profile(answer.authorId)) {
                        Avatar(user: author, size: 42,
                               showsAddButton: !isMine && !store.isFollowing(answer.authorId))
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if showsAuthor { header }
                    Text(answer.text)
                        .font(.quesly(15))
                        .foregroundStyle(Color.qInk)
                        .fixedSize(horizontal: false, vertical: true)
                    actions.padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .sheet(isPresented: $isSharing) {
            ShareStorySheet(answer: answer)
                .presentationDetents([.large])
        }
        .confirmationDialog("Delete this answer?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.deleteAnswer(answer.id) }
        }
        .alert("Thanks for letting us know", isPresented: $reported) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Our team will review this answer. Quesly is a kind place.")
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            if answer.isPinned && isMine {
                Image(systemName: "pin.fill").font(.system(size: 10)).foregroundStyle(Color.qGreen)
            }
            NavigationLink(value: Route.profile(answer.authorId)) {
                Text(author?.username ?? "unknown")
                    .font(.quesly(13, .semibold))
                    .foregroundStyle(isMine ? Color.qGreen : Color.qInk)
            }
            .buttonStyle(.plain)
            if let badge = author?.badge {
                HexBadge(color: badge.color, symbol: "star.fill").frame(width: 14, height: 14)
            }
            Text(RelativeTime.short(answer.createdAt))
                .font(.quesly(12)).foregroundStyle(Color.qGray)
            Spacer()
            Menu {
                Button { UIPasteboard.general.string = answer.text } label: {
                    Label("Copy text", systemImage: "doc.on.doc")
                }
                Button { isSharing = true } label: {
                    Label("Share as story", systemImage: "square.and.arrow.up")
                }
                if isMine {
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } else {
                    Button(role: .destructive) { reported = true } label: {
                        Label("Report", systemImage: "flag")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.qGray.opacity(0.7))
                    .frame(width: 28, height: 20)
            }
            .accessibilityLabel("More")
        }
    }

    private var actions: some View {
        HStack(spacing: 14) {
            ForEach(ReactionKind.allCases) { kind in
                ReactionButton(kind: kind,
                               count: answer.count(kind),
                               isOn: answer.myReactions.contains(kind)) {
                    store.toggleReaction(kind, on: answer.id)
                }
            }
            Spacer()
            Button { store.toggleSave(answer.id) } label: {
                Image(systemName: answer.isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 17))
                    .foregroundStyle(answer.isSaved ? Color.qGreen : Color.qGray)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(answer.isSaved ? "Remove from saved" : "Save")
            .sensoryFeedback(.selection, trigger: answer.isSaved)

            Button { isSharing = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.qGray)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share")
        }
    }
}

struct ReactionButton: View {
    let kind: ReactionKind
    let count: Int
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isOn || count > 0 ? kind.filledSymbol : kind.symbol)
                    .font(.system(size: 17))
                    .foregroundStyle(isOn || count > 0 ? kind.color : Color.qGray)
                    .symbolEffect(.bounce, value: isOn)
                if count > 0 {
                    Text("\(count)")
                        .font(.quesly(11, .medium))
                        .foregroundStyle(kind.color)
                        .contentTransition(.numericText())
                }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isOn)
        .accessibilityLabel("\(kind.rawValue), \(count)")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
