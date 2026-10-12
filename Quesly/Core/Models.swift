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
}

// MARK: - Question

struct DailyQuestion: Identifiable, Codable, Hashable {
    var id: String
    var text: String
    /// Words / phrases rendered in lime on the full-screen question.
    var highlights: [String] = []
}

// MARK: - Answer

enum ReactionKind: String, Codable, CaseIterable, Identifiable {
    case love, fire, smile, clap

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .love: return "heart"
        case .fire: return "flame"
        case .smile: return "face.smiling"
        case .clap: return "hands.clap"
        }
    }

    var filledSymbol: String {
        switch self {
        case .love: return "heart.fill"
        case .fire: return "flame.fill"
        case .smile: return "face.smiling.inverse"
        case .clap: return "hands.clap.fill"
        }
    }

    var color: Color {
        switch self {
        case .love: return .qHeart
        case .fire: return .qFire
        case .smile: return .qSmile
        case .clap: return .qClap
        }
    }
}

struct Answer: Identifiable, Codable, Hashable {
    var id: String
    var questionId: String
    var questionText: String
    var authorId: String
    var text: String
    var createdAt: Date
    var reactions: [ReactionKind: Int] = [:]
    var myReactions: Set<ReactionKind> = []
    var isSaved: Bool = false
    var isPinned: Bool = false

    func count(_ kind: ReactionKind) -> Int { reactions[kind, default: 0] }
}

// MARK: - Notifications

struct AppNotification: Identifiable, Codable, Hashable {
    enum Kind: String, Codable { case reaction, badge, posted, follow }

    var id: String
    var kind: Kind
    var actorId: String?
    var message: String
    var date: Date
}

// MARK: - Achievements

struct Achievement: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var symbol: String
    var color: Color
    var progress: Int
    var goal: Int
    /// Achievements awarded manually (e.g. "The Crowned One") have no progress bar.
    var isSpecial: Bool = false

    var isUnlocked: Bool { progress >= goal }
}
