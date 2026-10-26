import SwiftUI
import UIKit

@main
struct QueslyApp: App {
    @State private var store: AppStore
    @State private var network = NetworkMonitor()

    init() {
        Self.styleNavigationBars()
        DemoConfig.resetPersistedState()
        let store = AppStore()
        DemoConfig.apply(to: store)
        _store = State(initialValue: store)
    }

    @Environment(\.scenePhase) private var scenePhase

    /// Large titles (Discover, Notifications) in the brand display face; collapsed titles stay SF Pro.
    private static func styleNavigationBars() {
        let edge = UINavigationBarAppearance()
        edge.configureWithTransparentBackground()
        let standard = UINavigationBarAppearance()
        standard.configureWithDefaultBackground()
        if let outfit = UIFont(name: "Outfit-Bold", size: 34) {
            let large = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: outfit)
            edge.largeTitleTextAttributes = [.font: large]
            standard.largeTitleTextAttributes = [.font: large]
        }
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = standard
        bar.compactAppearance = standard
        bar.scrollEdgeAppearance = edge
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(network)
                .tint(.qBrandText)
                .statusBarHidden(DemoConfig.isActive)
                // Light theme only for now (founder decision, 23.10.2026); dark tokens stay for later.
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshDay() }
        }
    }
}

/// Core user journey: Splash → Welcome → Sign up / in → Daily Question → Answer → Main tabs.
struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var showSplash = true
    @State private var showLimeFlash = false

    var body: some View {
        ZStack {
            Group {
                if DemoConfig.showsWidgetGallery {
                    WidgetGalleryView()
                } else if !store.isSignedIn {
                    WelcomeView()
                } else if store.onboarding == .findFriends {
                    NavigationStack { FindFriendsView().withQueslyRoutes().toolbar(.hidden, for: .navigationBar) }
                        .transition(.move(edge: .trailing))
                } else if store.onboarding == .notifications {
                    NotificationPrimingView()
                        .transition(.move(edge: .trailing))
                } else if !store.hasAnsweredToday {
                    DailyQuestionView(onSubmitted: flashThenFeed)
                } else {
                    MainTabView()
                }
            }
            .transition(.opacity)

            if showLimeFlash {
                LimeTransitionView().transition(.opacity).zIndex(1)
            }
            if showSplash {
                SplashView().transition(.opacity).zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: store.isSignedIn)
        .animation(.qSmooth, value: store.onboarding)
        .animation(.easeInOut(duration: 0.35), value: store.hasAnsweredToday)
        .sensoryFeedback(.success, trigger: showLimeFlash) { _, shown in shown }
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeInOut(duration: 0.5)) { showSplash = false }
        }
    }

    private func flashThenFeed() {
        store.unlockCelebrationAt = .now.addingTimeInterval(2.0) // when the flash has faded
        showLimeFlash = true
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeInOut(duration: 0.4)) { showLimeFlash = false }
        }
    }
}
