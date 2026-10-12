import SwiftUI

/// Lime pill CTA used on green screens ("Answer", "Submit").
struct LimeButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.quesly(16, .semibold))
                .foregroundStyle(Color.qGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Capsule().fill(Color.qLime.opacity(isEnabled ? 1 : 0.45)))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
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
                .font(.quesly(16, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Capsule().fill(Color.qGreen.opacity(isEnabled ? 1 : 0.4)))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

/// Two-tab underline switcher ("World / Friends", "Your Answers / Saved Answers").
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
                    withAnimation(.snappy(duration: 0.25)) { selection = item }
                } label: {
                    VStack(spacing: 8) {
                        Text(title(item))
                            .font(.quesly(14, isActive ? .semibold : .regular))
                            .foregroundStyle(isActive ? activeColor : Color.qGray)
                        ZStack {
                            Rectangle().fill(Color.clear).frame(height: 3)
                            if isActive {
                                Rectangle().fill(activeColor).frame(height: 3)
                                    .matchedGeometryEffect(id: "underline", in: ns)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
    }
}

/// White navigation header with a back chevron, matching the Figma screens.
struct BackHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.qInk)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Back")
            Text(title).font(.quesly(18, .medium)).foregroundStyle(Color.qInk)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(alignment: .bottom) { Divider() }
    }
}

extension View {
    /// Hides the system nav bar and shows the Figma-style back header instead.
    func queslyBackHeader(_ title: String) -> some View {
        self
            .safeAreaInset(edge: .top, spacing: 0) { BackHeader(title: title) }
            .toolbar(.hidden, for: .navigationBar)
    }
}

/// Small helper to render the question with brand highlights (lime words).
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
