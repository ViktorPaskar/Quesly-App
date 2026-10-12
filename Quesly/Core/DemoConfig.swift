import Foundation

/// Debug-only hook used by CI to open a specific screen for screenshots:
/// `SIMCTL_CHILD_QUESLY_SCREEN=feed xcrun simctl launch booted app.quesly.ios`
enum DemoConfig {
    enum Screen: String {
        case welcome, question, composer, feed, friends, archive, notifications, profile, achievements, menu
    }

    static var screen: Screen? {
        #if DEBUG
        ProcessInfo.processInfo.environment["QUESLY_SCREEN"].flatMap(Screen.init(rawValue:))
        #else
        nil
        #endif
    }

    static var isActive: Bool { screen != nil }

    /// Starts every demo launch from a clean slate.
    static func resetPersistedState() {
        guard isActive else { return }
        UserDefaults.standard.removeObject(forKey: AppStore.defaultsKey)
    }

    @MainActor
    static func apply(to store: AppStore) {
        guard let screen else { return }
        switch screen {
        case .welcome:
            return
        case .question, .composer:
            store.signIn(email: MockData.me.email)
        default:
            store.signIn(email: MockData.me.email)
            store.submitAnswer(MockData.sampleAnswers[store.todayQuestion.id] ?? "")
        }
    }

    static var initialTab: MainTab {
        switch screen {
        case .archive: return .archive
        case .notifications: return .notifications
        case .profile, .achievements, .menu: return .profile
        default: return .feed
        }
    }

    static var initialRoute: Route? {
        switch screen {
        case .achievements: return .achievements
        case .menu: return .menu
        default: return nil
        }
    }

    static var startsComposing: Bool { screen == .composer }
    static var composerSample: String {
        guard screen == .composer else { return "" }
        return MockData.sampleAnswers[AppStore.question(for: .now).id] ?? ""
    }
    static var initialFeedScope: FeedScope { screen == .friends ? .friends : .world }
}
