import SwiftUI

// MARK: - User

struct AppUser: Identifiable, Codable, Hashable {
    var id: String
    var username: String
    var email: String = ""
    var phone: String = ""
    var location: String = ""
    var bio: String = ""
    /// Hue (0...1) used to tint the generated avatar until real photos are wired up.
    var avatarHue: Double
    var badge: BadgeTier? = nil
    var followers: Int = 0
    var following: Int = 0
    var streak: Int = 0

    var initials: String {
        let letters = username.filter { $0.isLetter }
        return String(letters.prefix(2)).uppercased()
    }
}

/// Small badge shown next to usernames (the hexagon from the designs).
enum BadgeTier: String, Codable, CaseIterable {
    case gold, red, purple, blue, green

    var color: Color {
        switch self {
        case .gold: return Color(hex: 0xE2A72E)
        case .red: return Color(hex: 0xE5484D)
        case .purple: return Color(hex: 0x9B5CF6)
        case .blue: return Color(hex: 0x2D7BF0)
        case .green: return Color(hex: 0x6CC417)
        }
    }

    var icon: QIcon {
        switch self {
        case .gold: return .crownSimpleFill
        case .red: return .fireFill
        case .purple: return .sparkleFill
        case .blue: return .sparkleFill
        case .green: return .leafFill
        }
    }
}

// MARK: - Question

struct DailyQuestion: Identifiable, Codable, Hashable {
    var id: String
    var text: String
    /// The key word (or pair) rendered as a lime sticker on the full-screen question.
    var highlights: [String] = []

    private static let stopWords: Set<String> = [
        "WHAT", "WHATS", "WHICH", "WHO", "WHERE", "WHEN", "WHY", "HOW", "IF", "YOU", "YOUR", "YOURE",
        "YOUD", "YOUVE", "THE", "A", "AN", "AND", "OR", "TO", "OF", "IN", "ON", "FOR", "WITH", "THAT",
        "THIS", "IS", "ARE", "WAS", "IT", "BE", "WOULD", "COULD", "DO", "DID", "HAD", "HAVE", "ONE",
        "EVER", "ALWAYS", "EVERY", "THING", "SOMETHING", "MAKES", "MADE", "FEELS", "LIKE", "ABOUT"
    ]

    /// Upper-cased words to highlight, punctuation stripped. Uses `highlights` when set (the
    /// question generator picks the emotional heart of the question); otherwise falls back to the
    /// longest word that isn't a question word, pronoun or filler.
    var keyWords: Set<String> {
        let clean = { (w: Substring) in w.uppercased().filter(\.isLetter) }
        if let first = highlights.first {
            return Set(first.split(separator: " ").map(clean))
        }
        let candidate = text.split(separator: " ").map(clean)
            .filter { !Self.stopWords.contains($0) }
            .max { $0.count < $1.count }
        return candidate.map { Set([$0]) } ?? []
    }
}

// MARK: - Answer

/// Positive-only reactions. One reaction per person per answer (like iMessage tapbacks).
/// Drawn as 3D stickers (`ReactionSticker`); SAME is the Quesly-only word reaction.
enum ReactionKind: String, Codable, CaseIterable, Identifiable {
    case love, green, adore, touched, like, same

    var id: String { rawValue }

    /// Plain-text fallback for strings (notifications, accessibility).
    var emoji: String {
        switch self {
        case .love: return "❤️"
        case .green: return "💚"
        case .adore: return "🥰"
        case .touched: return "🥹"
        case .like: return "👍"
        case .same: return "SAME"
        }
    }

    /// 3D image in Assets.xcassets/Reactions; nil for the word sticker.
    var assetName: String? {
        switch self {
        case .love: return "reaction-heart"
        case .green: return "reaction-green-heart"
        case .adore: return "reaction-hearts"
        case .touched: return "reaction-tears"
        case .like: return "reaction-thumbs"
        case .same: return nil
        }
    }

    var label: String {
        switch self {
        case .love: return "Love"
        case .green: return "Green heart"
        case .adore: return "Adore"
        case .touched: return "Touched"
        case .like: return "Like"
        case .same: return "Same"
        }
    }

    /// Saved data from before the new set: 🔥 becomes SAME, 😂 becomes 🥰.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "fire": self = .same
        case "haha": self = .adore
        default: self = ReactionKind(rawValue: raw) ?? .love
        }
    }
}

enum AnswerVisibility: String, Codable, CaseIterable, Identifiable {
    case everyone, friends
    var id: String { rawValue }

    var title: String { self == .everyone ? "Everyone" : "Friends" }
    var icon: QIcon { self == .everyone ? .globeHemisphereWestFill : .userFill }
}

struct Answer: Identifiable, Codable, Hashable {
    /// Long enough to fix a typo or rethink a line, short enough that people reacting see what
    /// was really posted. Edited answers are marked "edited".
    static let editWindow: TimeInterval = 15 * 60

    var id: String
    var questionId: String
    var questionText: String
    var authorId: String
    var text: String
    var createdAt: Date
    var reactions: [ReactionKind: Int] = [:]
    var myReaction: ReactionKind? = nil
    /// The viewer reposted this answer to their own profile. Anonymous: the author only ever
    /// sees how many times it was reposted (`reshares`), never by whom.
    var isResharedByMe: Bool = false
    var isPinned: Bool = false
    var visibility: AnswerVisibility = .everyone
    var isEdited: Bool = false
    /// Optional so answers saved before reposts existed still decode.
    var reshareCount: Int? = nil

    var reshares: Int { reshareCount ?? 0 }

    private enum CodingKeys: String, CodingKey {
        case id, questionId, questionText, authorId, text, createdAt, reactions, myReaction
        case isResharedByMe = "isSaved"   // stored under its old name
        case isPinned, visibility, isEdited, reshareCount
    }

    func count(_ kind: ReactionKind) -> Int { reactions[kind, default: 0] }
    var totalReactions: Int { reactions.values.reduce(0, +) }
    /// Reaction kinds ordered by popularity, for the author's summary chip.
    var topReactions: [ReactionKind] {
        ReactionKind.allCases.filter { count($0) > 0 }.sorted { count($0) > count($1) }
    }

    func isEditable(now: Date = .now) -> Bool { now.timeIntervalSince(createdAt) < Self.editWindow }
}

// MARK: - Notifications

struct AppNotification: Identifiable, Codable, Hashable {
    enum Kind: String, Codable { case reaction, badge, posted, follow }

    var id: String
    var kind: Kind
    var actorId: String?
    var message: String
    var date: Date
    var answerId: String? = nil
    var reaction: ReactionKind? = nil
}

/// Several reactions on the same answer collapsed into one row.
struct NotificationGroup: Identifiable, Hashable {
    var id: String
    var kind: AppNotification.Kind
    var actorIds: [String]
    var reactions: [ReactionKind]
    var answerId: String?
    var message: String
    var date: Date
}

// MARK: - Achievements

struct Achievement: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var icon: QIcon
    var color: Color
    var progress: Int
    var goal: Int
    /// Achievements awarded manually (e.g. "The Crowned One") have no progress bar.
    var isSpecial: Bool = false

    var isUnlocked: Bool { progress >= goal }
}

// MARK: - Moderation

enum ReportReason: String, CaseIterable, Identifiable {
    case bullying = "Bullying or harassment"
    case hate = "Hate speech or symbols"
    case selfHarm = "Self-harm or suicide"
    case sexual = "Nudity or sexual content"
    case spam = "Spam or scam"
    case other = "Something else"

    var id: String { rawValue }
}
