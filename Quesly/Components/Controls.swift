import SwiftUI

/// Lime pill CTA used on green screens ("Answer", "Submit").
struct LimeButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                if let systemImage { Image(systemName: systemImage).font(.system(size: 15, weight: .bold)) }
            }
            .font(.quesly(17, .bold))
            .foregroundStyle(Color.qGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Capsule().fill(Color.qLime.opacity(isEnabled ? 1 : 0.4)))
            .shadow(color: Color.qLime.opacity(isEnabled ? 0.35 : 0), radius: 16, y: 6)
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
                .font(.quesly(17, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(Color.qGreen.opacity(isEnabled ? 1 : 0.35)))
        }
        .buttonStyle(.pressable)
        .disabled(!isEnabled)
    }
}

/// Small Follow / Following pill.
struct FollowPill: View {
    let isFollowing: Bool
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isFollowing {
                    Image(systemName: "checkmark").font(.system(size: compact ? 10 : 11, weight: .bold))
                        .transition(.scale.combined(with: .opacity))
                }
                Text(isFollowing ? "Following" : "Follow")
            }
            .font(.quesly(compact ? 12 : 13, .semibold))
            .foregroundStyle(isFollowing ? Color.qGreen : .white)
            .padding(.horizontal, compact ? 10 : 14)
            .frame(height: compact ? 26 : 32)
            .background(Capsule().fill(isFollowing ? Color.qMint : Color.qGreen))
            .contentShape(Capsule())
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
                    VStack(spacing: 10) {
                        Text(title(item))
                            .font(.quesly(15, isActive ? .semibold : .medium))
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
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.qInk)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")
            Text(title).font(.quesly(20, .semibold)).foregroundStyle(Color.qInk)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.white)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.qLine).frame(height: 1) }
    }
}

/// Centered title header used on tab roots.
struct TitleHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ZStack {
            Text(title).font(.quesly(20, .semibold)).foregroundStyle(Color.qInk)
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
    let symbol: String
    let title: String
    let message: String
    @ViewBuilder var actions: () -> Actions
    @State private var bob = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Color.qGreen)
                .frame(width: 84, height: 84)
                .background(Circle().fill(Color.qLime))
                .offset(y: bob ? -4 : 4)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: bob)
                .onAppear { bob = true }
            Text(title).font(.quesly(20, .semibold)).foregroundStyle(Color.qInk)
            Text(message)
                .font(.quesly(15))
                .foregroundStyle(Color.qGray)
                .multilineTextAlignment(.center)
            actions().padding(.top, 6)
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

extension EmptyStateView where Actions == EmptyView {
    init(symbol: String, title: String, message: String) {
        self.init(symbol: symbol, title: title, message: message) { EmptyView() }
    }
}

/// Shared invite text + link.
enum Invite {
    static func text(for username: String) -> String {
        "Join me on Quesly — one question a day, millions of stories ✨ Add me: @\(username) https://quesly.app/u/\(username)"
    }
}
