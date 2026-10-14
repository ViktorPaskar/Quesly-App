import SwiftUI

@main
struct QueslyApp: App {
    @State private var store: AppStore
    @State private var network = NetworkMonitor()

    init() {
        DemoConfig.resetPersistedState()
        let store = AppStore()
        DemoConfig.apply(to: store)
        _store = State(initialValue: store)
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(network)
                .tint(.qBrandText)
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
                if !store.isSignedIn {
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
        .task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeInOut(duration: 0.5)) { showSplash = false }
        }
    }

    private func flashThenFeed() {
        showLimeFlash = true
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeInOut(duration: 0.4)) { showLimeFlash = false }
        }
    }
}
