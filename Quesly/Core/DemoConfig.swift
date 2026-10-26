import Foundation
import Observation

/// Debug-only hook used by CI to open a specific screen for screenshots:
/// `SIMCTL_CHILD_QUESLY_SCREEN=feed xcrun simctl launch booted app.quesly.ios`
enum DemoConfig {
    enum Screen: String {
        case welcome, findFriends, notifyPrime, question, composer
        case feed, feedEnd, feedError, offline, tray, friends, otherProfile, share, reactions, story
        case discover, notifications, profile, profileList, profileReposts, profileSaved, memory, menu, settings, editProfile, achievements
        case widgets
        /// Auto-playing walkthrough recorded to video by CI: question → answer → feed → react → story → tabs → settings.
        case tour
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
        case .question, .composer, .tour:
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
        case .profile, .profileList, .profileReposts, .profileSaved, .memory, .achievements, .menu, .settings, .editProfile: return .profile
        default: return .feed
        }
    }

    static var initialRoute: Route? {
        switch screen {
        case .achievements: return .achievements
        case .menu: return .menu
        case .settings: return .settings
        case .editProfile: return .editProfile
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
    static var opensShareSheet: Bool { screen == .share }
    static var opensReactionsSheet: Bool { screen == .reactions }
    static var opensStory: Bool { screen == .story }
    static var opensMemory: Bool { screen == .memory }
    static var scrollsProfileToList: Bool { [.profileList, .profileReposts, .profileSaved, .memory].contains(screen) }
    /// Which profile tab a demo launch opens on.
    static var initialProfileTab: ProfileTab {
        switch screen {
        case .profileReposts: return .reposts
        case .profileSaved: return .saved
        case .memory: return .calendar
        default: return .answers
        }
    }
    static var showsWidgetGallery: Bool { screen == .widgets }
    static var scrollsFeedToEnd: Bool { screen == .feedEnd }
    static var forcesOffline: Bool { screen == .offline }
    static var forcedFeedError: String? { screen == .feedError ? "We couldn't load today's answers." : nil }
    /// Opens the reaction tray on the first answer that isn't mine.
    static var opensReactionTray: Bool { screen == .tray }
}

/// Drives the `tour` demo: views watch these flags and act as if the user had tapped.
@MainActor @Observable
final class DemoTour {
    static let shared = DemoTour()
    static var isOn: Bool { DemoConfig.screen == .tour }

    var openTray = false
    var feedScope: FeedScope?
    var showStory = false

    static func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }
}
