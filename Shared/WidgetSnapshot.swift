import Foundation

/// What the app tells the widget: written to the shared App Group on every change.
struct WidgetSnapshot: Codable, Equatable {
    /// Start of the day this snapshot describes.
    var day: Date
    var isSignedIn: Bool
    var answeredToday: Bool
    var streak: Int
    var friendsAnswered: Int
    /// Up to two names for "camille_b and 2 others answered".
    var friendNames: [String]
}

enum WidgetBridge {
    static let appGroup = "group.app.quesly.ios"
    static let widgetKind = "QueslyQuestion"
    private static let key = "quesly.widget.snapshot"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Stores the snapshot; returns `true` when it changed (only then is a widget reload worth it).
    @discardableResult
    static func save(_ snapshot: WidgetSnapshot) -> Bool {
        guard load() != snapshot, let data = try? JSONEncoder().encode(snapshot) else { return false }
        defaults?.set(data, forKey: key)
        return true
    }
}
