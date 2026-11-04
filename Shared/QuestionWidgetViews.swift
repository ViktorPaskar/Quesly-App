import SwiftUI

/// Everything a widget needs to draw itself, derived from the date + the app's snapshot.
struct QuestionWidgetModel: Equatable {
    var question: String
    var answered: Bool
    var streak: Int
    var friendsAnswered: Int
    var friendNames: [String]
    var timeLeft: String
    var myAnswer: String? = nil
    var highlights: [String] = []

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
            timeLeft: QuestionBank.timeLeftString(now: date),
            myAnswer: isToday ? snapshot?.myAnswer : nil,
            highlights: QuestionBank.item(for: date).highlights
        )
    }

    static let placeholder = QuestionWidgetModel(
        question: "If you had one superpower, what would it be?",
        answered: true,
        streak: 8,
        friendsAnswered: 3,
        friendNames: ["camille_b", "theo_runs"],
        timeLeft: "9h",
        myAnswer: "Teleportation, so I could visit my family anytime",
        highlights: ["superpower"]
    )

    /// The question with its key words on a lime marker.
    var highlightedQuestion: AttributedString {
        var text = AttributedString(question)
        for word in highlights {
            if let range = text.range(of: word, options: .caseInsensitive) {
                text[range].backgroundColor = WidgetPalette.lime
                text[range].foregroundColor = WidgetPalette.green
            }
        }
        return text
    }

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
    static let green = Color(red: 8 / 255, green: 86 / 255, blue: 59 / 255)      // #08563B
    static let lime = Color(red: 212 / 255, green: 1, blue: 0)                    // #D4FF00
    static let mint = Color(red: 207 / 255, green: 253 / 255, blue: 229 / 255)  // #CFFDE5
    static let ink = Color(red: 16 / 255, green: 26 / 255, blue: 21 / 255)
    static let gray = Color(red: 115 / 255, green: 125 / 255, blue: 120 / 255)
    static let flame = Color(red: 255 / 255, green: 79 / 255, blue: 61 / 255)    // #FF4F3D (Poppy Coral)
    static let sage = Color(red: 155 / 255, green: 217 / 255, blue: 181 / 255)   // #9BD9B5
    static let pink = Color(red: 255 / 255, green: 143 / 255, blue: 192 / 255)   // #FF8FC0

    static func question(_ size: CGFloat) -> Font {
        .custom("Outfit-Medium", size: size, relativeTo: .headline)
    }

    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .headline) -> Font {
        .custom("Outfit-SemiBold", size: size, relativeTo: style)
    }
}

// MARK: - Home Screen Widgets: a series of three styles, chosen in the iOS widget gallery

/// Paper: a white sheet with just the question. After answering it shows what you wrote.
struct PaperWidgetView: View {
    let model: QuestionWidgetModel
    var isMedium = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if model.answered, let answer = model.myAnswer {
                Text("Your answer today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(WidgetPalette.gray)
                Text(answer)
                    .font(WidgetPalette.question(isMedium ? 24 : 18))
                    .foregroundStyle(WidgetPalette.ink)
                    .minimumScaleFactor(0.75)
            } else {
                Text(model.highlightedQuestion)
                    .font(WidgetPalette.question(isMedium ? 27 : 18))
                    .foregroundStyle(WidgetPalette.ink)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
            Text(model.answered ? "\(model.streak) days in a row" : "\(model.timeLeft) left")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WidgetPalette.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Bright: the question on solid lime. Turns mint once you've answered.
struct BrightWidgetView: View {
    let model: QuestionWidgetModel
    var isMedium = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.question)
                .font(WidgetPalette.question(isMedium ? 27 : 19))
                .foregroundStyle(WidgetPalette.green)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
            Text(model.answered ? (model.friendsLine ?? "Answered") : "\(model.timeLeft) left")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WidgetPalette.green)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Streak: the big number on coral, for people who want to keep the chain going.
struct StreakWidgetView: View {
    let model: QuestionWidgetModel
    var isMedium = false

    private var status: String { model.answered ? "Done today" : "Answer in \(model.timeLeft)" }

    private var counter: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(model.streak)")
                .font(WidgetPalette.display(64, relativeTo: .largeTitle))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("day streak")
                .font(.system(size: 15, weight: .medium))
        }
    }

    var body: some View {
        Group {
            if isMedium {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading) {
                        counter
                        Spacer(minLength: 0)
                        Text(status).font(.system(size: 12, weight: .medium))
                    }
                    VStack(alignment: .leading) {
                        Text(model.question)
                            .font(WidgetPalette.question(19))
                            .minimumScaleFactor(0.75)
                        Spacer(minLength: 0)
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { day in
                                Circle()
                                    .fill(.white.opacity(day < model.streak ? 1 : 0.3))
                                    .frame(width: 13, height: 13)
                            }
                        }
                        .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading) {
                    counter
                    Spacer(minLength: 0)
                    Text(status).font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
        .frame(maxHeight: .infinity, alignment: .topLeading)
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
