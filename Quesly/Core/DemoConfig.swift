import Foundation

/// Debug-only hook used by CI to open a specific screen for screenshots:
/// `SIMCTL_CHILD_QUESLY_SCREEN=feed xcrun simctl launch booted app.quesly.ios`
enum DemoConfig {
    enum Screen: String {
        case welcome, findFriends, notifyPrime, question, composer
        case feed, friends, otherProfile, share
        case discover, notifications, profile, saved, menu, achievements
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
        case .findFriends:
            store.signUp(username: MockData.me.username, email: MockData.me.email)
        case .notifyPrime:
            store.signUp(username: MockData.me.username, email: MockData.me.email)
            store.finishFindFriends()
        case .question, .composer:
            store.signIn(email: MockData.me.email)
        default:
            store.signIn(email: MockData.me.email)
            store.submitAnswer(MockData.sampleAnswers[store.todayQuestion.id] ?? "")
        }
    }

    static var initialTab: MainTab {
        switch screen {
        case .discover: return .discover
        case .notifications: return .notifications
        case .profile, .saved, .achievements, .menu: return .profile
        default: return .feed
        }
    }

    static var initialRoute: Route? {
        switch screen {
        case .achievements: return .achievements
        case .menu: return .menu
        case .otherProfile:
            let first = MockData.answers(for: AppStore.question(for: .now)).first
            return .profile(first?.authorId ?? "u5")
        default: return nil
        }
    }

    static var startsComposing: Bool { screen == .composer }
    static var composerSample: String {
        guard screen == .composer else { return "" }
        return MockData.sampleAnswers[AppStore.question(for: .now).id] ?? ""
    }
    static var initialFeedScope: FeedScope { screen == .friends ? .friends : .world }
    static var showsSavedTab: Bool { screen == .saved }
    static var opensShareSheet: Bool { screen == .share }
}
