import SwiftUI

// MARK: - User

struct AppUser: Identifiable, Codable, Hashable {
    var id: String
    var username: String
    /// Display name shown above @username on the profile. Optional so older saved data still loads.
    var name: String? = nil
    var email: String = ""
    var phone: String = ""
    var location: String = ""
    var bio: String = ""
    /// Bio length in visible characters (an emoji is one). Profiles show 3 lines, then "more".
    static let bioLimit = 150
    /// Hue (0...1) used to tint the generated avatar until real photos are wired up.
    var avatarHue: Double
    var badge: BadgeTier? = nil
    var followers: Int = 0
    var following: Int = 0
    var streak: Int = 0

    var displayName: String {
        guard let name, !name.trimmingCharacters(in: .whitespaces).isEmpty else { return username }
        return name
    }

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

    var assetName: String {
        switch self {
        case .gold: return "badge-crown"
        case .red: return "badge-support"
        case .purple: return "badge-early"
        case .blue: return "badge-story"
        case .green: return "badge-first"
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
/// Word stickers (speech bubbles), one per person per answer. Order everywhere:
/// SAME, AWW, LIKE, DEEP, COOL, HUGS. Art: Assets/Reactions/reaction-<raw>, 50 × 36.
enum ReactionKind: String, Codable, CaseIterable, Identifiable {
    case same, aww, like, deep, cool, hugs

    var id: String { rawValue }

    /// The word on the sticker; also the plain-text fallback.
    var word: String { rawValue.uppercased() }
    var assetName: String { "reaction-\(rawValue)" }
    var label: String { rawValue.capitalized }

    var meaning: String {
        switch self {
        case .same: return "Me too"
        case .aww: return "That's sweet"
        case .like: return "I like it"
        case .deep: return "Made me think"
        case .cool: return "Cool idea"
        case .hugs: return "Sending support"
        }
    }

    /// Saved data from the emoji sets: ❤️/👍 become LIKE, 💚/🔥 SAME, 🥰/😂 AWW, 🥹 HUGS.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "love", "like": self = .like
        case "green", "fire": self = .same
        case "adore", "haha": self = .aww
        case "touched": self = .hugs
        default: self = ReactionKind(rawValue: raw) ?? .like
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
    /// Privately saved by the viewer (the bookmark). Only the viewer sees their saved list.
    var bookmarked: Bool? = nil

    var reshares: Int { reshareCount ?? 0 }
    var isBookmarked: Bool {
        get { bookmarked ?? false }
        set { bookmarked = newValue }
    }

    private enum CodingKeys: String, CodingKey {
        case id, questionId, questionText, authorId, text, createdAt, reactions, myReaction
        case isResharedByMe = "isSaved"   // stored under its old name
        case isPinned, visibility, isEdited, reshareCount, bookmarked
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
    var badgeAsset: String { "badge-\(id)" }
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
