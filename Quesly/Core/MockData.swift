import Foundation

/// Seed content mirroring the Figma prototype. Replace with API calls once the backend exists.
enum MockData {
    /// Shared with the widget (`Shared/QuestionBank.swift`), so both show the same question for a date.
    static let questions: [DailyQuestion] = QuestionBank.items.map {
        DailyQuestion(id: $0.id, text: $0.text, highlights: $0.highlights)
    }

    static let me = AppUser(
        id: "me",
        username: "misslilly_57",
        name: "Lilly Laurent",
        email: "amanda57@gmail.com",
        phone: "+33 123 45 67 89",
        location: "Paris, France",
        bio: "I love slow mornings, deep talks, and people who are real. Sometimes I overthink, sometimes I just laugh it off. Living in Paris, learning to enjoy the in-between moments ☕️",
        avatarHue: 0.08,
        badge: .gold,
        followers: 255,
        following: 487,
        streak: 3
    )

    static let users: [AppUser] = [
        .init(id: "u1", username: "van.derss2", name: "Vanessa Ders", bio: "Grandma's stories > everything.", avatarHue: 0.55, badge: .red, followers: 120, following: 98, streak: 6),
        .init(id: "u2", username: "alexo91", name: "Alex Moreau", bio: "Plants, coffee and long walks 🌿", avatarHue: 0.32, badge: .purple, followers: 342, following: 210, streak: 12),
        .init(id: "u3", username: "funnnnyyy1", name: "Hugo Bernard", bio: "Chasing mountains.", avatarHue: 0.12, followers: 88, following: 140, streak: 2),
        .init(id: "u4", username: "mr.smith", name: "Mark Smith", bio: "Side projects all day.", avatarHue: 0.62, badge: .blue, followers: 501, following: 77, streak: 21),
        .init(id: "u5", username: "john.john", name: "John Walker", bio: "There's a coin and a coffee. I enjoy the little things in life.", avatarHue: 0.02, badge: .red, followers: 342, following: 89, streak: 4),
        .init(id: "u6", username: "chill_mara", name: "Mara Lenoir", bio: "Gamer, dreamer.", avatarHue: 0.85, followers: 60, following: 61, streak: 1),
        .init(id: "u7", username: "AnnaViva", name: "Anna Viva", bio: "Dancing through Lyon 💃", avatarHue: 0.95, badge: .green, followers: 77, following: 120, streak: 9),
        .init(id: "u8", username: "arturo_sun", name: "Arturo Sol", bio: "Sunsets collector.", avatarHue: 0.1, followers: 51, following: 44, streak: 3),
        .init(id: "u9", username: "koko_lilly", name: "Lilly Kovac", bio: "Art student, Bordeaux.", avatarHue: 0.75, followers: 33, following: 50, streak: 5),
        .init(id: "u10", username: "nata.ver", name: "Natalia Vernet", bio: "Books & bikes.", avatarHue: 0.0, followers: 21, following: 18, streak: 2),
        .init(id: "u11", username: "leo.martin", name: "Léo Martin", bio: "Paris • film photography", avatarHue: 0.45, followers: 410, following: 300, streak: 7),
        .init(id: "u12", username: "camille_b", name: "Camille Blanc", bio: "Always hungry, always curious.", avatarHue: 0.9, badge: .purple, followers: 980, following: 410, streak: 15),
        .init(id: "u13", username: "yasmine.k", name: "Yasmine Karim", bio: "Med student. Coffee-powered.", avatarHue: 0.05, followers: 220, following: 180, streak: 4),
        .init(id: "u14", username: "theo_runs", name: "Théo Roux", bio: "Marathon in progress 🏃", avatarHue: 0.58, badge: .blue, followers: 150, following: 120, streak: 30),
    ]

    /// Users that `me` follows (drives the Friends feed).
    static let followingIds: Set<String> = ["u2", "u3", "u4", "u5", "u8", "u9", "u10"]

    /// Other people's answers per question: (authorId, text, minutesAgo).
    private static let feedAnswers: [String: [(String, String, Double)]] = [
        "q-dayoff": [
            ("u5", "Call my best friend and spend the whole day together", 1),
            ("u1", "Visit my grandma and listen to her stories aaaaall day", 3),
            ("u2", "Go to the huge botanical garden 🌿", 5),
            ("u3", "Do an insane 10-mile hike up the mountain trail I keep putting off", 10),
            ("u4", "Work on my side hustle project non-stop. I need to make serious progress! 🚀", 13),
            ("u12", "Croissant tour across Paris. Rating every single one 🥐", 18),
            ("u7", "Long morning run, healthy brunch, yoga session and early bed :)", 22),
        ],
        "q-happy": [
            ("u2", "The first sip of coffee while the apartment is still quiet ☕️", 2),
            ("u5", "When my dog loses his mind because I came home after 5 minutes", 4),
            ("u9", "Fresh sheets. Every. Single. Time.", 8),
            ("u11", "Golden hour light on the Seine on my way home", 11),
            ("u3", "Finding a song I haven't heard in years on shuffle", 15),
            ("u13", "My little sister's voice messages, they're always 4 minutes long", 20),
        ],
        "q-live": [
            ("u8", "Lisbon. Tiles, trams and sunsets every evening 🌅", 2),
            ("u4", "Tokyo, just to be surrounded by order and ramen", 6),
            ("u2", "A small village in the Alps with a huge garden", 9),
            ("u12", "Napoli, for the pizza and the chaos", 12),
            ("u10", "Copenhagen. Bikes everywhere and cozy cafés", 17),
            ("u7", "Barcelona, so I can dance until 3am and nap at the beach", 25),
        ],
        "q-power": [
            ("u3", "Teleportation. No more 2-hour train rides to see my parents", 3),
            ("u14", "Never get tired. Imagine the running PRs 🏃", 7),
            ("u5", "Pause time for 10 minutes every morning", 9),
            ("u9", "Speaking every language in the world", 14),
            ("u6", "Infinite phone battery. Simple but life-changing", 19),
            ("u13", "Healing people with a touch. Med school would be way easier", 23),
        ],
        "q-advice": [
            ("u1", "\"Don't compare your chapter 1 to someone's chapter 20\", my mom", 2),
            ("u4", "Done is better than perfect", 5),
            ("u11", "Take the photo. You won't regret having it", 8),
            ("u2", "Drink water before deciding anything important", 12),
            ("u12", "Say yes to the weird invitations", 16),
            ("u7", "You can't pour from an empty cup", 21),
        ],
        "q-song": [
            ("u7", "September by Earth, Wind & Fire. Instant smile", 1),
            ("u5", "Mr. Blue Sky. Every morning on the metro", 4),
            ("u9", "Anything by Stromae, honestly", 9),
            ("u3", "Dancing Queen. No explanation needed 💃", 13),
            ("u12", "Les Champs-Élysées, I'm a cliché and I'm proud", 18),
            ("u10", "Here Comes the Sun 🌞", 24),
        ],
        "q-proud": [
            ("u14", "I ran my first half marathon last spring", 2),
            ("u13", "Passed my anatomy exam after failing it once", 6),
            ("u2", "My plants are alive. All 23 of them 🌿", 10),
            ("u5", "I finally called my dad after 2 years", 14),
            ("u9", "Sold my first painting!", 19),
            ("u4", "Shipped my app to 100 users", 26),
        ],
        "q-tiny": [
            ("u8", "A stranger held the door and smiled like they meant it", 2),
            ("u5", "My barista remembered my order 🥹", 5),
            ("u1", "Grandma learned to send voice messages", 9),
            ("u11", "Found 20€ in an old jacket", 12),
            ("u3", "Rainy evening, blanket, new book", 16),
            ("u12", "Friend sent me a meme that was exactly my life", 22),
        ],
        "q-learn": [
            ("u9", "Ceramics. I want to make my own plates", 3),
            ("u4", "Swift! Building my own apps", 6),
            ("u7", "Salsa, properly this time", 9),
            ("u13", "Sign language", 13),
            ("u2", "Italian, so I can order like a local 🇮🇹", 18),
            ("u14", "Cooking something other than pasta", 24),
        ],
        "q-meal": [
            ("u1", "Grandma's borscht with way too much sour cream", 2),
            ("u12", "Croque-monsieur at midnight", 5),
            ("u5", "Dad's barbecue on Sundays", 8),
            ("u13", "Mom's couscous, nothing comes close", 12),
            ("u2", "Tomato soup and grilled cheese on a rainy day", 17),
            ("u8", "Bacalhau à Brás, like in Porto", 23),
        ],
    ]

    static func answers(for question: DailyQuestion, now: Date = .now) -> [Answer] {
        let seeds = feedAnswers[question.id] ?? feedAnswers["q-dayoff"]!
        return seeds.enumerated().map { index, seed in
            let (author, text, minutes) = seed
            var answer = Answer(id: "a-\(question.id)-\(author)", questionId: question.id, questionText: question.text,
                                authorId: author, text: text, createdAt: now.addingTimeInterval(-minutes * 60))
            // A few answers start with reactions / saved so the feed looks alive.
            if index == 1 { answer.myReaction = .like; answer.reactions = [.like: 1, .same: 1] }
            if index == 2 { answer.isResharedByMe = true; answer.reshareCount = 4; answer.reactions = [.same: 2] }
            if index == 3 { answer.isBookmarked = true }
            if index == 4 { answer.visibility = .friends }
            return answer
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    /// Sample answers of `me`, one per question, used to build a believable history.
    static let sampleAnswers: [String: String] = [
        "q-dayoff": "One day off? I'd call my friends, take a random road trip and just see where the day takes us",
        "q-happy": "When I hear my favorite song randomly playing in a cafe... It feels awesome",
        "q-live": "Somewhere by the sea 🌊 where mornings start with coffee on the balcony",
        "q-power": "Teleportation ✨ so I could visit my family anytime without packing or flights",
        "q-advice": "\"You don't have to have it all figured out to move forward\", my grandma",
        "q-song": "Anything by ABBA. Instant dance mode in the kitchen 💃",
        "q-proud": "I finally started running in the mornings and kept it up for a month",
        "q-tiny": "A stranger complimented my jacket on the metro and made my whole day",
        "q-learn": "Pottery! I want to make my own coffee mugs",
        "q-meal": "My mom's crêpes on Sunday mornings 🥞",
    ]

    /// Past answers of `me` for the previous days' questions, shown in Profile.
    /// Days (ago) the seed user answered — a believable month for the Memories calendar.
    /// Day 4 is missing but covered by a streak freeze (`frozenDaysAgo`), so the streak runs back to day 8.
    static let answeredDaysAgo = [1, 2, 3, 5, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18, 19, 20, 22, 23, 26, 27, 29]
    static let frozenDaysAgo = [4]

    static func myHistory(now: Date = .now) -> [Answer] {
        let cal = Calendar.current
        let reactions: [[ReactionKind: Int]] = [
            [.like: 14, .same: 22, .aww: 3, .hugs: 7, .cool: 5, .deep: 4],
            [.like: 2, .same: 31, .aww: 12, .hugs: 5],
            [.like: 68, .same: 15, .aww: 1, .deep: 10],
            [.like: 9, .same: 4, .hugs: 2],
        ]
        return answeredDaysAgo.enumerated().map { index, daysAgo in
            let date = cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let q = AppStore.question(for: date)
            return Answer(id: "h\(daysAgo)", questionId: q.id, questionText: q.text, authorId: "me",
                          text: sampleAnswers[q.id] ?? "", createdAt: date, reactions: reactions[min(index, reactions.count - 1)],
                          reshareCount: [6, 11, 3, 1][min(index, 3)])
        }
    }

    static func myFrozenDays(now: Date = .now) -> Set<Date> {
        let cal = Calendar.current
        return Set(frozenDaysAgo.compactMap { cal.date(byAdding: .day, value: -$0, to: cal.startOfDay(for: now)) })
    }

    static func notifications(now: Date = .now) -> [AppNotification] {
        func ago(_ minutes: Double) -> Date { now.addingTimeInterval(-minutes * 60) }
        return [
            .init(id: "n1", kind: .reaction, actorId: "u7", message: "reacted to your answer", date: ago(30), answerId: "h1", reaction: .like),
            .init(id: "n2", kind: .reaction, actorId: "u4", message: "reacted to your answer", date: ago(48), answerId: "h1", reaction: .same),
            .init(id: "n3", kind: .follow, actorId: "u12", message: "started following you", date: ago(60)),
            .init(id: "n4", kind: .reaction, actorId: "u9", message: "reacted to your answer", date: ago(120), answerId: "h1", reaction: .hugs),
            .init(id: "n5", kind: .reaction, actorId: "u5", message: "reacted to your answer", date: ago(130), answerId: "h2", reaction: .aww),
            .init(id: "n6", kind: .badge, actorId: nil, message: "**3 days in a row!** A new badge is ready", date: ago(300)),
            .init(id: "n7", kind: .reaction, actorId: "u3", message: "reacted to your answer", date: ago(360), answerId: "h2", reaction: .same),
            .init(id: "n8", kind: .reaction, actorId: "u10", message: "reacted to your answer", date: ago(380), answerId: "h3", reaction: .like),
            .init(id: "n9", kind: .follow, actorId: "u14", message: "started following you", date: ago(500)),
        ]
    }
}
