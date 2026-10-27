import SwiftUI

enum MainTab: CaseIterable {
    case feed, discover, notifications, profile

    var icon: QIcon {
        switch self {
        case .feed: return .house
        case .discover: return .magnifyingGlass
        case .notifications: return .bell
        case .profile: return .user
        }
    }

    var activeIcon: QIcon {
        switch self {
        case .feed: return .houseFill
        case .discover: return .magnifyingGlass
        case .notifications: return .bellFill
        case .profile: return .userFill
        }
    }

    var title: String {
        switch self {
        case .feed: return "Feed"
        case .discover: return "Discover"
        case .notifications: return "Notifications"
        case .profile: return "Profile"
        }
    }
}

struct MainTabView: View {
    @Environment(AppStore.self) private var store
    @State private var tab: MainTab = DemoConfig.initialTab
    @State private var paths: [MainTab: NavigationPath] = {
        guard let route = DemoConfig.initialRoute else { return [:] }
        var path = NavigationPath()
        path.append(route)
        return [DemoConfig.initialTab: path]
    }()
    @Namespace private var ns
    /// Incremented when the active tab is tapped again at its root → that tab scrolls to top.
    @State private var reselect: [MainTab: Int] = [:]
    @State private var demoShare = DemoConfig.opensShareSheet
    @State private var demoReactions = DemoConfig.opensReactionsSheet

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                stack(.feed) { FeedView(onDiscover: { select(.discover) }) }
                stack(.discover) { DiscoverView() }
                stack(.notifications) { NotificationsView() }
                stack(.profile) { ProfileView(userId: store.me.id, isTabRoot: true) }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                tabBar
            }
        }
        .ignoresSafeArea(.keyboard)
        .task { if DemoTour.isOn { await playTour() } }
        .sheet(isPresented: $demoShare) {
            if let answer = store.todaysAnswer { ShareStorySheet(answer: answer) }
        }
        .sheet(isPresented: $demoReactions) {
            if let answer = store.myAnswers.first(where: { $0.totalReactions > 0 }) {
                ReactionsSheet(answer: answer).presentationDetents([.medium, .large])
            }
        }
    }

    private func stack<Content: View>(_ t: MainTab, @ViewBuilder root: () -> Content) -> some View {
        NavigationStack(path: binding(for: t)) {
            root().withQueslyRoutes()
        }
        .environment(\.scrollToTopSignal, reselect[t] ?? 0)
        .opacity(tab == t ? 1 : 0)
        .scaleEffect(tab == t ? 1 : 0.985)
        .allowsHitTesting(tab == t)
        .accessibilityHidden(tab != t)
    }

    /// Demo walkthrough after the answer is posted: react, swipe to Friends, watch a story,
    /// then visit notifications, discover, profile and settings.
    private func playTour() async {
        let tour = DemoTour.shared
        while !store.hasAnsweredToday { await DemoTour.pause(0.3) }
        await DemoTour.pause(5)
        tour.openTray = true
        await DemoTour.pause(1.8)
        if let other = store.feed(.world).first(where: { $0.authorId != store.me.id }) {
            withAnimation(.qSpring) { store.react(.aww, on: other.id) }
        }
        await DemoTour.pause(0.6)
        tour.openTray = false
        await DemoTour.pause(1.5)
        tour.feedScope = .friends
        await DemoTour.pause(2.5)
        tour.showStory = true
        await DemoTour.pause(6)
        tour.showStory = false
        await DemoTour.pause(1.5)
        for t in [MainTab.notifications, .discover, .profile] {
            select(t)
            await DemoTour.pause(3)
        }
        withAnimation(.qSmooth) { paths[.profile, default: NavigationPath()].append(Route.settings) }
        // The recorder drops trailing frames that don't change, so end on a visible step:
        // stay on Settings, then go back to the profile.
        await DemoTour.pause(4)
        withAnimation(.qSmooth) { paths[.profile] = NavigationPath() }
        await DemoTour.pause(2)
    }

    private func binding(for t: MainTab) -> Binding<NavigationPath> {
        Binding(get: { paths[t] ?? NavigationPath() }, set: { paths[t] = $0 })
    }

    private func select(_ t: MainTab) {
        if tab == t {
            if (paths[t]?.isEmpty ?? true) {
                reselect[t, default: 0] += 1                     // at root: scroll to top
            } else {
                withAnimation(.qSmooth) { paths[t] = NavigationPath() } // re-tap pops to root
            }
        } else {
            withAnimation(.easeOut(duration: 0.18)) { tab = t }
        }
    }

    /// Floating capsule dock: sliding brand-green pill with lime glyph, and the user's own mini sticker avatar on Profile.
    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(MainTab.allCases, id: \.self) { t in
                let active = tab == t
                Button { select(t) } label: {
                    ZStack {
                        if active {
                            Capsule()
                                .fill(Color.qGreen)
                                .frame(width: 58, height: 42)
                                .matchedGeometryEffect(id: "tabBubble", in: ns)
                        }
                        Icon(active ? t.activeIcon : t.icon, size: 22, weight: active ? .semibold : .regular)
                            .foregroundStyle(active ? Color.qLime : Color.qInk2)
                            .pop(on: active)
                            .overlay(alignment: .topTrailing) {
                                if t == .notifications && store.unreadNotifications > 0 && !active {
                                    Text("\(min(store.unreadNotifications, 9))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(minWidth: 16, minHeight: 16)
                                        .background(Circle().fill(Color.qFlame))
                                        .overlay(Circle().stroke(Color.qBackground, lineWidth: 2))
                                        .offset(x: 8, y: -6)
                                        .transition(.scale)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(t.title)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 58)
        .background(
            Capsule()
                .fill(Color.qBackground)
                .shadow(color: .black.opacity(0.10), radius: 18, y: 6)
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.qLine, lineWidth: 1)
        )
        .padding(.horizontal, 28)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .animation(.qSpring, value: tab)
        .sensoryFeedback(.selection, trigger: tab)
    }
}

extension View {
    func withQueslyRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .profile(let id): ProfileView(userId: id)
            case .menu, .settings: SettingsView()
            case .achievements: AchievementsView()
            case .editProfile: EditProfileView()
            case .following: FollowListView(kind: .following)
            case .followers: FollowListView(kind: .followers)
            case .feedback: FeedbackView()
            case .invite: InviteFriendsView()
            case .blocked: BlockedUsersView()
            }
        }
    }
}

#Preview {
    MainTabView().environment(AppStore()).environment(NetworkMonitor())
}

private struct ScrollToTopSignalKey: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    /// Changes whenever the user re-taps the current tab while at its root.
    var scrollToTopSignal: Int {
        get { self[ScrollToTopSignalKey.self] }
        set { self[ScrollToTopSignalKey.self] = newValue }
    }
}
