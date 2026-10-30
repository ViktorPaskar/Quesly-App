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
        answered: true,
        streak: 8,
        friendsAnswered: 3,
        friendNames: ["camille_b", "theo_runs"],
        timeLeft: "9h"
    )

    /// "camille_b and 2 others answered" / "3 friends answered".
    var friendsLine: String? {
        guard friendsAnswered > 0 else { return nil }
        if let first = friendNames.first {
            return friendsAnswered == 1 ? "\(first) answered" : "\(first) & \(friendsAnswered - 1) more"
        }
        return "\(friendsAnswered) friends answered"
    }
}

/// Brand values for the widget. The widget can't see the app's design tokens, so the few it needs live here.
enum WidgetPalette {
    static let obsidian = Color(red: 5 / 255, green: 52 / 255, blue: 36 / 255)   // #053424
    static let green = Color(red: 8 / 255, green: 86 / 255, blue: 59 / 255)      // #08563B
    static let lime = Color(red: 212 / 255, green: 1, blue: 0)                    // #D4FF00
    static let flame = Color(red: 255 / 255, green: 79 / 255, blue: 61 / 255)    // #FF4F3D (Poppy Coral)
    static let sage = Color(red: 155 / 255, green: 217 / 255, blue: 181 / 255)   // #9BD9B5
    static let pink = Color(red: 255 / 255, green: 143 / 255, blue: 192 / 255)   // #FF8FC0

    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .headline) -> Font {
        .custom("Outfit-SemiBold", size: size, relativeTo: style)
    }
}

// MARK: - Home Screen Widgets (Modern, Inviting, Editorial)

/// Small: the question with natural sentence case, and either a sleek answer button or streak pill.
struct QuestionWidgetSmallView: View {
    let model: QuestionWidgetModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetEyebrow()

            Text(model.question)
                .font(WidgetPalette.display(16))
                .foregroundStyle(.white)
                .lineLimit(4)
                .lineSpacing(2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            if model.answered {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(WidgetPalette.flame)
                    Text("\(model.streak)d")
                        .fontWeight(.bold)
                    if model.friendsAnswered > 0 {
                        Text("· \(model.friendsAnswered) friends")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .frame(height: 26)
                .background(Capsule().fill(Color.white.opacity(0.14)))
                .lineLimit(1)
            } else {
                HStack(spacing: 5) {
                    Text("Reflect")
                        .font(.system(size: 12.5, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10.5, weight: .bold))
                }
                .foregroundStyle(WidgetPalette.obsidian)
                .padding(.horizontal, 13)
                .frame(height: 28)
                .background(Capsule().fill(WidgetPalette.lime))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Medium: the question on the left, elegant streak/CTA badge on the right.
struct QuestionWidgetMediumView: View {
    let model: QuestionWidgetModel

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                WidgetEyebrow()

                Text(model.question)
                    .font(WidgetPalette.display(18.5))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .lineSpacing(2.5)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                if let line = model.friendsLine, model.answered {
                    HStack(spacing: 5) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text(line)
                            .font(.system(size: 11.5, weight: .medium))
                    }
                    .foregroundStyle(WidgetPalette.sage)
                    .padding(.horizontal, 9)
                    .frame(height: 24)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side stats/action
            VStack(spacing: 5) {
                if model.answered {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(WidgetPalette.flame)

                    Text("\(model.streak)")
                        .font(WidgetPalette.display(34, relativeTo: .largeTitle))
                        .foregroundStyle(.white)

                    Text("day streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))

                    Text("Done ✓")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(WidgetPalette.lime)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                } else {
                    Spacer(minLength: 0)

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("\(model.timeLeft) left")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.8))

                    Text("Answer")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(WidgetPalette.obsidian)
                        .padding(.horizontal, 16)
                        .frame(height: 34)
                        .background(Capsule().fill(WidgetPalette.lime))

                    if model.streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(WidgetPalette.flame)
                            Text("\(model.streak)")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white)
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
        HStack(spacing: 5) {
            Circle()
                .fill(WidgetPalette.lime)
                .frame(width: 5, height: 5)
            Text("TODAY'S QUESTION")
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(WidgetPalette.sage)
        }
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
            .font(.system(size: 10.5, weight: .bold))
            .tracking(0.5)

            Text(model.question)
                .font(.system(size: 13.5, weight: .semibold))
                .lineLimit(3)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuestionWidgetCircularView: View {
    let model: QuestionWidgetModel

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.18))
            VStack(spacing: 1) {
                Image(systemName: model.answered ? "flame.fill" : "flame")
                    .font(.system(size: 15, weight: .semibold))
                Text("\(model.streak)")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
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
