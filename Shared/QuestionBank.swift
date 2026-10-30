import Foundation

/// The daily questions, shared by the app and the widget so both pick the same question for a date.
/// Replace with the API once the backend exists (the widget then reads it from `WidgetSnapshot`).
enum QuestionBank {
    struct Item: Hashable {
        let id: String
        let text: String
        /// Words / phrases rendered in lime on the full-screen question.
        let highlights: [String]
    }

    static let items: [Item] = [
        .init(id: "q-dayoff", text: "If you only had one day off, what would you do?", highlights: ["day off,"]),
        .init(id: "q-happy", text: "What's a small thing that makes you happy every day?", highlights: ["happy"]),
        .init(id: "q-live", text: "If you could live anywhere in the world, where would it be?", highlights: ["anywhere"]),
        .init(id: "q-power", text: "If you had one superpower, what would it be?", highlights: ["superpower,"]),
        .init(id: "q-advice", text: "What's the best advice you've ever received?", highlights: ["advice"]),
        .init(id: "q-song", text: "Which song always puts you in a good mood?", highlights: ["good mood?"]),
        .init(id: "q-proud", text: "What's something you're quietly proud of?", highlights: ["proud"]),
        .init(id: "q-tiny", text: "What tiny moment made your week better?", highlights: ["moment"]),
        .init(id: "q-learn", text: "What's one skill you'd love to learn this year?", highlights: ["skill"]),
        .init(id: "q-meal", text: "What meal feels like home to you?", highlights: ["home"]),
    ]

    static func index(for date: Date, calendar: Calendar = .current) -> Int {
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        return abs(day) % max(1, items.count)
    }

    static func item(for date: Date) -> Item { items[index(for: date)] }

    /// Midnight, when the next question drops.
    static func nextQuestionDate(after date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
    }

    /// "14h" / "35m" until the next question drops.
    static func timeLeftString(now: Date = .now) -> String {
        let seconds = max(0, nextQuestionDate(after: now).timeIntervalSince(now))
        let hours = Int(seconds) / 3600
        if hours >= 1 { return "\(hours)h" }
        return "\(max(1, Int(seconds) / 60))m"
    }
}
