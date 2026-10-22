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
        // Content scrolls under the floating bar; the inset keeps the last row reachable.
        ZStack {
            stack(.feed) { FeedView(onDiscover: { select(.discover) }) }
            stack(.discover) { DiscoverView() }
            stack(.notifications) { NotificationsView() }
            stack(.profile) { ProfileView(userId: store.me.id, isTabRoot: true) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
        .ignoresSafeArea(.keyboard)
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

    /// Floating frosted capsule, icons only. The active tab is a brand-green pill with a lime
    /// filled glyph (lime only ever sits on green); the pill glides between tabs.
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { t in
                let active = tab == t
                Button { select(t) } label: {
                    ZStack {
                        if active {
                            Capsule()
                                .fill(Color.qGreen)
                                .frame(width: 64, height: 44)
                                .matchedGeometryEffect(id: "tabBubble", in: ns)
                        }
                        Icon(active ? t.activeIcon : t.icon, size: 22, weight: active ? .semibold : .regular)
                            .foregroundStyle(active ? Color.qLime : Color.qGray)
                            .pop(on: active)
                            .overlay(alignment: .topTrailing) {
                                if t == .notifications && store.unreadNotifications > 0 && !active {
                                    Text("\(min(store.unreadNotifications, 9))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(minWidth: 17, minHeight: 17)
                                        .background(Circle().fill(Color.qFlame))
                                        .overlay(Circle().stroke(Color.qBackground, lineWidth: 2))
                                        .offset(x: 8, y: -6)
                                        .transition(.scale)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(t.title)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(.horizontal, 6)
        .background(Capsule().fill(.regularMaterial))
        .overlay(Capsule().strokeBorder(Color.qLine.opacity(0.8), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 6)
        .padding(.horizontal, DS.Space.xl)
        .padding(.bottom, DS.Space.xxs)
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
