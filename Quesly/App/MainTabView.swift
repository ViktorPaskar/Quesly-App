import SwiftUI

enum MainTab: CaseIterable {
    case feed, archive, notifications, profile

    var symbol: String {
        switch self {
        case .feed: return "house"
        case .archive: return "folder"
        case .notifications: return "bell"
        case .profile: return "person"
        }
    }

    var title: String {
        switch self {
        case .feed: return "Feed"
        case .archive: return "Archive"
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

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                stack(.feed) { FeedView() }
                stack(.archive) { ArchiveView() }
                stack(.notifications) { NotificationsView() }
                stack(.profile) { ProfileView(userId: store.me.id, isTabRoot: true) }
            }
            tabBar
        }
        .ignoresSafeArea(.keyboard)
    }

    private func stack<Content: View>(_ t: MainTab, @ViewBuilder root: () -> Content) -> some View {
        NavigationStack(path: binding(for: t)) {
            root().withQueslyRoutes()
        }
        .opacity(tab == t ? 1 : 0)
        .allowsHitTesting(tab == t)
        .accessibilityHidden(tab != t)
    }

    private func binding(for t: MainTab) -> Binding<NavigationPath> {
        Binding(get: { paths[t] ?? NavigationPath() }, set: { paths[t] = $0 })
    }

    private var tabBar: some View {
        HStack {
            ForEach(MainTab.allCases, id: \.self) { t in
                Button {
                    if tab == t {
                        paths[t] = NavigationPath() // re-tap pops to root
                    } else {
                        tab = t
                    }
                } label: {
                    Image(systemName: tab == t && t == .profile ? "person.fill" : t.symbol)
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(tab == t ? (t == .profile ? Color(hex: 0x6CC417) : Color.qGreen) : Color.qInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(t.title)
                .accessibilityAddTraits(tab == t ? .isSelected : [])
            }
        }
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Divider() }
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
            }
        }
    }
}

#Preview {
    MainTabView().environment(AppStore())
}
