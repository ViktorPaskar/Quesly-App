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
        case .blue: return .lightningFill
        case .green: return .leafFill
        }
    }
}

// MARK: - Question

struct DailyQuestion: Identifiable, Codable, Hashable {
    var id: String
    var text: String
    /// Words / phrases rendered in lime on the full-screen question.
    var highlights: [String] = []
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
    var icon: QIcon { self == .everyone ? .globeHemisphereWestFill : .usersFill }
}

struct Answer: Identifiable, Codable, Hashable {
    static let editWindow: TimeInterval = 5 * 60

    var id: String
    var questionId: String
    var questionText: String
    var authorId: String
    var text: String
    var createdAt: Date
    var reactions: [ReactionKind: Int] = [:]
    var myReaction: ReactionKind? = nil
    var isSaved: Bool = false
    var isPinned: Bool = false
    var visibility: AnswerVisibility = .everyone
    var isEdited: Bool = false

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
