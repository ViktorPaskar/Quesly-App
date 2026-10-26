import SwiftUI

/// Lime pill CTA used on green screens ("Answer", "Submit").
struct LimeButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
            .font(.ui(17, .semibold))
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
            Text(isFollowing ? "Following" : "Follow")
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

/// Text tabs with a sliding underline; equal widths, 44pt tall, hairline underneath.
struct UnderlineTabs<Item: Hashable & Identifiable>: View {
    let items: [Item]
    @Binding var selection: Item
    let title: KeyPath<Item, String>
    /// Feed: 1.5 pt indicator, ink3 inactive, 0.5 pt hairline at 12 % black. Profile: 1 pt, #999.
    var indicator: CGFloat = 1.5
    var inactive: Color = .qGray
    var hairline: Color = Color.black.opacity(0.12)
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let on = item == selection
                Button { withAnimation(.qSmooth) { selection = item } } label: {
                    Text(item[keyPath: title])
                        .font(.ui(15, .semibold))
                        .foregroundStyle(on ? Color.qInk : inactive)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, DS.Space.xxs)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.hitTarget)
                        .overlay(alignment: .bottom) {
                            if on {
                                Rectangle().fill(Color.qInk)
                                    .frame(height: indicator)
                                    .matchedGeometryEffect(id: "line", in: ns)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .background(alignment: .bottom) { Rectangle().fill(hairline).frame(height: 0.5) }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Compact segmented switch ("World / Friends"): the active segment is a brand-green pill
/// that glides between options.
struct PillTabs<T: Hashable & Identifiable>: View {
    let items: [T]
    @Binding var selection: T
    let title: (T) -> String
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isActive = item == selection
                Button {
                    withAnimation(.qSpring) { selection = item }
                } label: {
                    Text(title(item))
                        .font(.ui(14, .semibold))
                        .foregroundStyle(isActive ? Color.white : Color.qGray)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background {
                            if isActive {
                                Capsule().fill(Color.qGreen)
                                    .matchedGeometryEffect(id: "pill", in: ns)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.qField))
        .frame(minHeight: DS.hitTarget)
        .fixedSize()
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Navigation header with a back chevron, on the gray canvas like the screens it sits on.
struct BackHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 8) {
            Button { dismiss() } label: {
                Icon(.caretLeftBold, size: DS.Icon.action)
                    .foregroundStyle(Color.qInk)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")
            Text(title).font(.ui(20, .semibold)).foregroundStyle(Color.qInk)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.qCanvas)
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
        "Join me on Quesly: one question a day, millions of stories ✨ Add me: @\(username) https://quesly.app/u/\(username)"
    }
}
