import SwiftUI

/// Lime pill CTA used on green screens ("Answer", "Submit").
struct LimeButton: View {
    let title: String
    var icon: QIcon? = nil
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                if let icon { Icon(icon, size: 19) }
            }
            .font(.ui(17, .bold))
            .foregroundStyle(Color.qGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Capsule().fill(Color.qLime.opacity(isEnabled ? 1 : 0.4)))
        }
        .buttonStyle(.pressable)
        .disabled(!isEnabled)
        .animation(.qSpring, value: isEnabled)
    }
}

/// Dark green pill CTA used on white screens ("Send", "Save").
struct GreenButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.ui(17, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(Color.qGreen.opacity(isEnabled ? 1 : 0.35)))
        }
        .buttonStyle(.pressable)
        .disabled(!isEnabled)
    }
}

/// Follow / Following pill. Tinted (not filled) so long lists of people stay calm;
/// the single filled "Follow" lives on someone's profile.
struct FollowPill: View {
    let isFollowing: Bool
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isFollowing {
                    Icon(.checkBold, size: compact ? 11 : 13)
                        .transition(.scale.combined(with: .opacity))
                }
                Text(isFollowing ? "Following" : "Follow")
            }
            .font(.ui(compact ? 13 : 15, .semibold))
            .foregroundStyle(isFollowing ? Color.qInk : Color.qBrandText)
            .padding(.horizontal, compact ? DS.Space.s : DS.Space.m)
            .frame(height: compact ? 28 : 32)
            .background(Capsule().fill(isFollowing ? Color.qBackground : Color.qMint))
            .overlay(Capsule().stroke(isFollowing ? Color.qLine : .clear, lineWidth: 1))
            // Visual height stays compact; the tappable area meets the 44-pt minimum.
            .padding(.vertical, (DS.hitTarget - (compact ? 28 : 32)) / 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable)
        .animation(.qSpring, value: isFollowing)
        .sensoryFeedback(.success, trigger: isFollowing) { _, new in new }
        .accessibilityLabel(isFollowing ? "Following" : "Follow")
    }
}

/// Two-tab underline switcher ("World / Friends", "Answers / Saved").
struct UnderlineTabs<T: Hashable & Identifiable>: View {
    let items: [T]
    @Binding var selection: T
    let title: (T) -> String
    var activeColor: Color = .qGreen
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isActive = item == selection
                Button {
                    withAnimation(.qSpring) { selection = item }
                } label: {
                    VStack(spacing: 12) {
                        Text(title(item))
                            .font(.ui(15, isActive ? .semibold : .medium))
                            .foregroundStyle(isActive ? activeColor : Color.qGray)
                        ZStack {
                            Capsule().fill(Color.qLine).frame(height: 1)
                            if isActive {
                                Capsule().fill(activeColor).frame(height: 3)
                                    .matchedGeometryEffect(id: "underline", in: ns)
                            }
                        }
                        .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// White navigation header with a back chevron, matching the Figma screens.
struct BackHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                Icon(.caretLeftBold, size: 22)
                    .foregroundStyle(Color.qInk)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")
            Text(title).font(.ui(20, .semibold)).foregroundStyle(Color.qInk)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.qBackground)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.qLine).frame(height: 1) }
    }
}

/// Centered title header used on tab roots.
struct TitleHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ZStack {
            Text(title).font(.ui(20, .semibold)).foregroundStyle(Color.qInk)
            HStack { Spacer(); trailing() }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }
}

extension TitleHeader where Trailing == EmptyView {
    init(title: String) { self.init(title: title) { EmptyView() } }
}

extension View {
    /// Hides the system nav bar and shows the Figma-style back header instead.
    func queslyBackHeader(_ title: String) -> some View {
        self
            .safeAreaInset(edge: .top, spacing: 0) { BackHeader(title: title) }
            .toolbar(.hidden, for: .navigationBar)
    }
}

/// Renders the question with brand highlights (lime words).
enum QuestionText {
    static func attributed(_ question: DailyQuestion, base: Color = .white, highlight: Color = .qLime) -> AttributedString {
        var text = AttributedString(question.text.uppercased())
        text.foregroundColor = base
        for phrase in question.highlights {
            if let range = text.range(of: phrase.uppercased()) {
                text[range].foregroundColor = highlight
            }
        }
        return text
    }
}

/// Relative time like the designs: "now", "5m", "2h", "10 Oct".
enum RelativeTime {
    static func short(_ date: Date, now: Date = .now) -> String {
        let s = now.timeIntervalSince(date)
        if s < 60 { return "now" }
        if s < 3600 { return "\(Int(s / 60))m" }
        if s < 86_400 { return "\(Int(s / 3600))h" }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    static func dayLabel(_ date: Date) -> String {
        Calendar.current.isDateInToday(date) ? "Today" : date.formatted(.dateTime.day().month(.abbreviated))
    }
}

/// Friendly empty state with an optional action.
struct EmptyStateView<Actions: View>: View {
    let icon: QIcon
    let title: String
    let message: String
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        VStack(spacing: 16) {
            Icon(icon, size: 30)
                .foregroundStyle(Color.qBrandText)
                .frame(width: 72, height: 72)
                .background(Circle().fill(Color.qMint))
            Text(title).font(.ui(20, .semibold)).foregroundStyle(Color.qInk)
            Text(message)
                .font(.ui(15))
                .foregroundStyle(Color.qGray)
                .multilineTextAlignment(.center)
            actions().padding(.top, 8)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

extension EmptyStateView where Actions == EmptyView {
    init(icon: QIcon, title: String, message: String) {
        self.init(icon: icon, title: title, message: message) { EmptyView() }
    }
}

/// Shared invite text + link.
enum Invite {
    static func text(for username: String) -> String {
        "Join me on Quesly — one question a day, millions of stories ✨ Add me: @\(username) https://quesly.app/u/\(username)"
    }
}
