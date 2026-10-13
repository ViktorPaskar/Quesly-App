import SwiftUI

enum MainTab: CaseIterable {
    case feed, discover, notifications, profile

    var icon: Ph {
        switch self {
        case .feed: return .house
        case .discover: return .magnifyingGlass
        case .notifications: return .bell
        case .profile: return .user
        }
    }

    var activeIcon: Ph {
        switch self {
        case .feed: return .houseFill
        case .discover: return .magnifyingGlassBold
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
    @State private var demoShare = DemoConfig.opensShareSheet

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                stack(.feed) { FeedView(onDiscover: { select(.discover) }) }
                stack(.discover) { DiscoverView() }
                stack(.notifications) { NotificationsView() }
                stack(.profile) { ProfileView(userId: store.me.id, isTabRoot: true) }
            }
            tabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $demoShare) {
            if let answer = store.todaysAnswer { ShareStorySheet(answer: answer) }
        }
    }

    private func stack<Content: View>(_ t: MainTab, @ViewBuilder root: () -> Content) -> some View {
        NavigationStack(path: binding(for: t)) {
            root().withQueslyRoutes()
        }
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
            withAnimation(.qSmooth) { paths[t] = NavigationPath() } // re-tap pops to root
        } else {
            withAnimation(.easeOut(duration: 0.18)) { tab = t }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { t in
                let active = tab == t
                Button { select(t) } label: {
                    VStack(spacing: 5) {
                        Icon(active ? t.activeIcon : t.icon, size: 27)
                            .foregroundStyle(active ? Color.qGreen : Color.qInk.opacity(0.55))
                            .pop(on: active)
                            .overlay(alignment: .topTrailing) {
                                if t == .notifications && store.unreadNotifications > 0 && !active {
                                    Text("\(min(store.unreadNotifications, 9))")
                                        .font(.custom("Outfit-Bold", fixedSize: 10))
                                        .foregroundStyle(Color.qGreen)
                                        .frame(minWidth: 16, minHeight: 16)
                                        .background(Circle().fill(Color.qLime))
                                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                                        .offset(x: 8, y: -6)
                                        .transition(.scale)
                                }
                            }
                        ZStack {
                            if active {
                                Capsule().fill(Color.qGreen)
                                    .frame(width: 18, height: 4)
                                    .matchedGeometryEffect(id: "tabIndicator", in: ns)
                            }
                        }
                        .frame(height: 4)
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
        .animation(.qSpring, value: tab)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Color.qLine).frame(height: 1) }
        .sensoryFeedback(.selection, trigger: tab)
    }
}

extension View {
    func withQueslyRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .profile(let id): ProfileView(userId: id)
            case .menu: ProfileMenuView()
            case .achievements: AchievementsView()
            case .editProfile: EditProfileView()
            case .following: FollowListView(kind: .following)
            case .followers: FollowListView(kind: .followers)
            case .settings: SettingsView()
            case .feedback: FeedbackView()
            case .invite: InviteFriendsView()
            case .blocked: BlockedUsersView()
            }
        }
    }
}

#Preview {
    MainTabView().environment(AppStore())
}
