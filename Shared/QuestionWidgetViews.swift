import SwiftUI

/// Everything a widget needs to draw itself, derived from the date + the app's snapshot.
struct QuestionWidgetModel: Equatable {
    var question: String
    var answered: Bool
    var streak: Int
    var friendsAnswered: Int
    var friendNames: [String]
    var timeLeft: String

    static func make(date: Date, snapshot: WidgetSnapshot?, calendar: Calendar = .current) -> Self {
        let today = calendar.startOfDay(for: date)
        let daysSinceSnapshot = snapshot.map {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.day), to: today).day ?? 99
        } ?? 99
        let isToday = daysSinceSnapshot == 0
        // A streak survives until the end of the day after the last answer.
        let streak = (snapshot?.isSignedIn ?? false) && daysSinceSnapshot <= 1 ? (snapshot?.streak ?? 0) : 0
        return .init(
            question: QuestionBank.item(for: date).text,
            answered: isToday && (snapshot?.answeredToday ?? false),
            streak: streak,
            friendsAnswered: isToday ? (snapshot?.friendsAnswered ?? 0) : 0,
            friendNames: isToday ? (snapshot?.friendNames ?? []) : [],
            timeLeft: QuestionBank.timeLeftString(now: date)
        )
    }

    static let placeholder = QuestionWidgetModel(
        question: "If you had one superpower, what would it be?",
        answered: true, streak: 8, friendsAnswered: 3, friendNames: ["camille_b", "theo_runs"], timeLeft: "9h")

    /// "camille_b and 2 others answered" / "3 friends answered".
    var friendsLine: String? {
        guard friendsAnswered > 0 else { return nil }
        if let first = friendNames.first {
            return friendsAnswered == 1 ? "\(first) answered" : "\(first) and \(friendsAnswered - 1) more answered"
        }
        return "\(friendsAnswered) friends answered"
    }
}

/// Brand values for the widget. The widget can't see the app's design tokens, so the few it needs live here.
enum WidgetPalette {
    static let green = Color(red: 7 / 255, green: 88 / 255, blue: 61 / 255)    // qGreen #07583D
    static let lime = Color(red: 212 / 255, green: 1, blue: 0)                   // qLime  #D4FF00
    static let flame = Color(red: 1, green: 106 / 255, blue: 26 / 255)           // qFlame #FF6A1A

    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .headline) -> Font {
        .custom("Outfit-Bold", size: size, relativeTo: style)
    }
}

// MARK: - Home Screen

/// Small: the question, then either a nudge to answer or your streak.
struct QuestionWidgetSmallView: View {
    let model: QuestionWidgetModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetEyebrow()
            Text(model.question.uppercased())
                .font(WidgetPalette.display(16))
                .foregroundStyle(.white)
                .lineLimit(5)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            if model.answered {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundStyle(WidgetPalette.flame)
                    Text("\(model.streak)").fontWeight(.bold)
                    if model.friendsAnswered > 0 {
                        Text("· \(model.friendsAnswered) friends").foregroundStyle(.white.opacity(0.75))
                    }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            } else {
                HStack(spacing: 4) {
                    Text("Answer")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WidgetPalette.lime)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Medium: the question on the left, streak / call to action on the right.
struct QuestionWidgetMediumView: View {
    let model: QuestionWidgetModel

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                WidgetEyebrow()
                Text(model.question.uppercased())
                    .font(WidgetPalette.display(19))
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if let line = model.friendsLine, model.answered {
                    Text(line)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 4) {
                if model.answered {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(WidgetPalette.flame)
                    Text("\(model.streak)")
                        .font(WidgetPalette.display(34, relativeTo: .largeTitle))
                        .foregroundStyle(.white)
                    Text("day streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                } else {
                    Spacer(minLength: 0)
                    Text("Answer")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(WidgetPalette.green)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(Capsule().fill(WidgetPalette.lime))
                    Text("\(model.timeLeft) left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                    if model.streak > 0 {
                        Label("\(model.streak)", systemImage: "flame.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(WidgetPalette.flame)
                    }
                }
            }
            .frame(width: 96)
            .frame(maxHeight: .infinity)
        }
    }
}

private struct WidgetEyebrow: View {
    var body: some View {
        Text("TODAY'S QUESTION")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(WidgetPalette.lime)
    }
}

// MARK: - Lock Screen

struct QuestionWidgetRectangularView: View {
    let model: QuestionWidgetModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(model.answered ? "ANSWERED" : "TODAY'S QUESTION")
                if model.streak > 0 {
                    Spacer(minLength: 0)
                    Image(systemName: "flame.fill")
                    Text("\(model.streak)")
                }
            }
            .font(.system(size: 11, weight: .bold))
            Text(model.question)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuestionWidgetCircularView: View {
    let model: QuestionWidgetModel

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.18))
            VStack(spacing: 0) {
                Image(systemName: model.answered ? "flame.fill" : "flame")
                    .font(.system(size: 15, weight: .semibold))
                Text("\(model.streak)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
        }
    }
}

struct QuestionWidgetInlineView: View {
    let model: QuestionWidgetModel

    var body: some View {
        if model.answered {
            Text("🔥 \(model.streak) · \(model.friendsLine ?? "See you tomorrow")")
        } else {
            Text("Today's question is waiting")
        }
    }
}
