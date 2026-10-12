import Foundation

/// Seed content mirroring the Figma prototype. Replace with API calls once the backend exists.
enum MockData {
    static let questions: [DailyQuestion] = [
        .init(id: "q-dayoff", text: "If you only had one day off, what would you do?", highlights: ["day off,", "you do?"]),
        .init(id: "q-happy", text: "What's a small thing that makes you happy every day?", highlights: ["happy"]),
        .init(id: "q-live", text: "If you could live anywhere in the world, where would it be?", highlights: ["anywhere", "world,"]),
        .init(id: "q-power", text: "If you had one superpower, what would it be?", highlights: ["superpower,"]),
        .init(id: "q-advice", text: "What's the best advice you've ever received?", highlights: ["best advice"]),
        .init(id: "q-song", text: "Which song always puts you in a good mood?", highlights: ["song", "good mood?"]),
        .init(id: "q-proud", text: "What's something you're quietly proud of?", highlights: ["proud"]),
        .init(id: "q-tiny", text: "What tiny moment made your week better?", highlights: ["tiny moment"]),
        .init(id: "q-learn", text: "What's one skill you'd love to learn this year?", highlights: ["skill"]),
        .init(id: "q-meal", text: "What meal feels like home to you?", highlights: ["home"]),
    ]

    static let me = AppUser(
        id: "me",
        username: "misslilly_57",
        email: "amanda57@gmail.com",
        phone: "+33 123 45 67 89",
        location: "Metz, France",
        bio: "I love slow mornings, deep talks, and people who are real. Sometimes I overthink, sometimes I just laugh it off. Living in Paris, learning to enjoy the in-between moments ☕️",
        avatarHue: 0.08,
        badge: .gold,
        followers: 255,
        following: 487,
        streak: 3
    )

    static let users: [AppUser] = [
        .init(id: "u1", username: "van.derss2", bio: "Grandma's stories > everything.", avatarHue: 0.55, badge: .red, followers: 120, following: 98, streak: 6),
        .init(id: "u2", username: "alexo91", bio: "Plants, coffee and long walks 🌿", avatarHue: 0.32, badge: .purple, followers: 342, following: 210, streak: 12),
        .init(id: "u3", username: "funnnnyyy1", bio: "Chasing mountains.", avatarHue: 0.12, followers: 88, following: 140, streak: 2),
        .init(id: "u4", username: "mr.smith", bio: "Side projects all day.", avatarHue: 0.62, badge: .blue, followers: 501, following: 77, streak: 21),
        .init(id: "u5", username: "john.john", bio: "There's a coin and a coffee. I enjoy the little things in life.", avatarHue: 0.02, badge: .red, followers: 342, following: 89, streak: 4),
        .init(id: "u6", username: "chill_mara", bio: "Gamer, dreamer.", avatarHue: 0.85, followers: 60, following: 61, streak: 1),
        .init(id: "u7", username: "AnnaViva", avatarHue: 0.95, badge: .green, followers: 77, following: 120, streak: 9),
        .init(id: "u8", username: "arturo_sun", avatarHue: 0.1, followers: 51, following: 44, streak: 3),
        .init(id: "u9", username: "koko_lilly", avatarHue: 0.75, followers: 33, following: 50, streak: 5),
        .init(id: "u10", username: "nata.ver", avatarHue: 0.0, followers: 21, following: 18, streak: 2),
    ]

    /// Users that `me` follows (drives the Friends feed).
    static let followingIds: Set<String> = ["u2", "u3", "u4", "u5", "u8", "u9", "u10"]

    static func answers(for question: DailyQuestion, now: Date = .now) -> [Answer] {
        func ago(_ minutes: Double) -> Date { now.addingTimeInterval(-minutes * 60) }
        let q = question
        var list: [Answer] = [
            .init(id: "a-u1", questionId: q.id, questionText: q.text, authorId: "u1",
                  text: "Visit my grandma and listen to her stories aaaaall day", createdAt: ago(3),
                  reactions: [.love: 1], myReactions: [.love]),
            .init(id: "a-u2", questionId: q.id, questionText: q.text, authorId: "u2",
                  text: "Go to the huge botanical garden 🌿", createdAt: ago(5),
                  reactions: [.fire: 2], isSaved: true),
            .init(id: "a-u3", questionId: q.id, questionText: q.text, authorId: "u3",
                  text: "Do an insane 10-mile hike up the mountain trail I keep putting off", createdAt: ago(10)),
            .init(id: "a-u4", questionId: q.id, questionText: q.text, authorId: "u4",
                  text: "Work on my side hustle project non-stop. I need to make serious progress! 🚀", createdAt: ago(13)),
            .init(id: "a-u5", questionId: q.id, questionText: q.text, authorId: "u5",
                  text: "Call my best friend and spend the whole day together", createdAt: ago(1)),
            .init(id: "a-u6", questionId: q.id, questionText: q.text, authorId: "u6",
                  text: "Finally beat that game I started last year. No distractions, just pure gaming", createdAt: ago(16)),
            .init(id: "a-u7", questionId: q.id, questionText: q.text, authorId: "u7",
                  text: "Long morning run, healthy brunch, yoga session and early bed :)", createdAt: ago(22)),
        ]
        list.sort { $0.createdAt > $1.createdAt }
        return list
    }

    /// Past answers of `me`, shown in Profile and Archive.
    static func myHistory(now: Date = .now) -> [Answer] {
        let cal = Calendar.current
        func daysAgo(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now) ?? now }
        return [
            .init(id: "h1", questionId: "q-happy", questionText: "What's a small thing that makes you happy every day?", authorId: "me",
                  text: "When I hear my favorite song randomly playing in a cafe... It feels awesome", createdAt: daysAgo(1),
                  reactions: [.love: 14, .fire: 22, .smile: 30, .clap: 7]),
            .init(id: "h2", questionId: "q-power", questionText: "If you had one superpower, what would it be?", authorId: "me",
                  text: "Teleportation ✨ so I could visit my family anytime without packing or flights", createdAt: daysAgo(2),
                  reactions: [.love: 2, .fire: 31, .smile: 3, .clap: 5]),
            .init(id: "h3", questionId: "q-live", questionText: "If you could live anywhere in the world, where would it be?", authorId: "me",
                  text: "Somewhere by the sea 🌊 where mornings start with coffee on the balcony", createdAt: daysAgo(3),
                  reactions: [.love: 68, .fire: 15, .smile: 21, .clap: 10]),
        ]
    }

    static func notifications(now: Date = .now) -> [AppNotification] {
        func ago(_ minutes: Double) -> Date { now.addingTimeInterval(-minutes * 60) }
        return [
            .init(id: "n1", kind: .reaction, actorId: "u7", message: "reacted to your answer", date: ago(30)),
            .init(id: "n2", kind: .reaction, actorId: "u4", message: "reacted to your answer", date: ago(48)),
            .init(id: "n3", kind: .follow, actorId: "u2", message: "started following you", date: ago(60)),
            .init(id: "n4", kind: .reaction, actorId: "u9", message: "reacted to your answer", date: ago(120)),
            .init(id: "n5", kind: .reaction, actorId: "u5", message: "reacted to your answer", date: ago(130)),
            .init(id: "n6", kind: .badge, actorId: nil, message: "**3 days in a row!** A new badge is ready", date: ago(300)),
            .init(id: "n7", kind: .reaction, actorId: "u3", message: "reacted to your answer", date: ago(360)),
            .init(id: "n8", kind: .reaction, actorId: "u10", message: "reacted to your answer", date: ago(380)),
        ]
    }
}
