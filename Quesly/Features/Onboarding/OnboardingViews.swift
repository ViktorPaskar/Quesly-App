import SwiftUI

/// Onboarding step 1 after sign-up: follow a few people so the Friends feed isn't empty on day one.
struct FindFriendsView: View {
    @Environment(AppStore.self) private var store
    @State private var query = ""
    /// Snapshot so rows don't jump around while following.
    @State private var people: [AppUser] = []

    private var shown: [AppUser] {
        query.isEmpty ? people : store.searchUsers(query)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                StepDots(current: 0, total: 2)
                Text("Find your people")
                    .font(.quesly(30, .bold))
                    .foregroundStyle(Color.qInk)
                Text("Quesly is better with friends. Follow a few people to fill your Friends feed.")
                    .font(.quesly(16))
                    .foregroundStyle(Color.qGray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            SearchField(text: $query, prompt: "Search by nickname")
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if query.isEmpty {
                        InviteCard(username: store.me.username)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                        SectionLabel("Suggested for you").padding(.horizontal, 24)
                    }
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, user in
                        PersonRow(user: user)
                            .padding(.horizontal, 24)
                            .staggeredAppear(index)
                    }
                }
                .padding(.bottom, 16)
            }

            let count = store.followingIds.count
            GreenButton(title: count > 0 ? "Continue · \(count) following" : "Continue") {
                withAnimation(.qSmooth) { store.finishFindFriends() }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .contentTransition(.numericText())
            .animation(.qSpring, value: count)
        }
        .background(Color.white)
        .onAppear { if people.isEmpty { people = store.suggestedUsers + store.followingUsers } }
    }
}

/// Onboarding step 2: explain *why* before the iOS permission prompt (much higher opt-in).
struct NotificationPrimingView: View {
    @Environment(AppStore.self) private var store
    @State private var ring = false

    var body: some View {
        ZStack {
            Color.qGreen.ignoresSafeArea()
            VStack(spacing: 0) {
                StepDots(current: 1, total: 2, onDark: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                Spacer()

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.qLime, Color.qGreen)
                    .frame(width: 140, height: 140)
                    .background(Circle().fill(Color.qLime.opacity(0.18)))
                    .background(Circle().fill(Color.qLime.opacity(0.08)).scaleEffect(ring ? 1.35 : 1))
                    .symbolEffect(.bounce, options: .repeating.speed(0.5), value: ring)
                    .onAppear {
                        ring = true
                    }
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: ring)

                Text("Never miss\ntoday's question")
                    .font(.quesly(32, .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.top, 36)
                Text("We'll send one gentle reminder a day — when the new question drops. No spam, promise.")
                    .font(.quesly(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 36)
                    .padding(.top, 12)

                NotificationPreview()
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                Spacer()
                VStack(spacing: 6) {
                    LimeButton(title: "Turn on notifications") {
                        withAnimation(.qSmooth) { store.finishNotificationPriming(enable: true) }
                    }
                    Button("Not now") {
                        withAnimation(.qSmooth) { store.finishNotificationPriming(enable: false) }
                    }
                    .font(.quesly(16, .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(height: 48)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
            }
        }
    }
}

/// Fake lock-screen notification shown on the priming screen.
private struct NotificationPreview: View {
    @State private var shown = false

    var body: some View {
        HStack(spacing: 12) {
            QueslyMark(color: .qLime, cutout: .qGreen)
                .frame(width: 20)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.qGreen))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("QUESLY").font(.quesly(12, .semibold)).foregroundStyle(Color.qGray)
                    Spacer()
                    Text("now").font(.quesly(12)).foregroundStyle(Color.qGray)
                }
                Text("Today's question is here ✨").font(.quesly(15, .semibold)).foregroundStyle(Color.qInk)
                Text("What tiny moment made your week better?").font(.quesly(14)).foregroundStyle(Color.qInk.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.white.opacity(0.95)))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .offset(y: shown ? 0 : -30)
        .opacity(shown ? 1 : 0)
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) { shown = true } }
        .accessibilityHidden(true)
    }
}

struct StepDots: View {
    let current: Int
    let total: Int
    var onDark = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? (onDark ? Color.qLime : Color.qGreen) : (onDark ? Color.white.opacity(0.3) : Color.qLine))
                    .frame(width: i == current ? 24 : 8, height: 8)
            }
        }
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

// MARK: - Shared people UI

struct SearchField: View {
    @Binding var text: String
    var prompt: String = "Search"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .medium)).foregroundStyle(Color.qGray)
            TextField(prompt, text: $text)
                .font(.quesly(16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.qGray.opacity(0.6))
                }
                .accessibilityLabel("Clear search")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.qField))
        .animation(.qSpring, value: text.isEmpty)
    }
}

struct PersonRow: View {
    @Environment(AppStore.self) private var store
    let user: AppUser

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: Route.profile(user.id)) {
                HStack(spacing: 12) {
                    Avatar(user: user, size: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(user.username).font(.quesly(16, .semibold)).foregroundStyle(Color.qInk)
                            if let badge = user.badge {
                                HexBadge(color: badge.color, symbol: badge.symbol).frame(width: 15, height: 15)
                            }
                        }
                        Text(user.bio.isEmpty ? "\(user.followers) followers" : user.bio)
                            .font(.quesly(14))
                            .foregroundStyle(Color.qGray)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 8)
            if user.id != store.me.id {
                FollowPill(isFollowing: store.isFollowing(user.id)) { store.toggleFollow(user.id) }
            }
        }
        .padding(.vertical, 8)
    }
}

struct SectionLabel: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(.quesly(13, .semibold))
            .tracking(0.6)
            .foregroundStyle(Color.qGray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}

/// Lime card with an invite link.
struct InviteCard: View {
    let username: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.qLime)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Color.qGreen))
            VStack(alignment: .leading, spacing: 2) {
                Text("Invite your friends").font(.quesly(16, .semibold)).foregroundStyle(Color.qGreen)
                Text("Answer together every day").font(.quesly(14)).foregroundStyle(Color.qGreen.opacity(0.8))
            }
            Spacer()
            ShareLink(item: Invite.text(for: username)) {
                Text("Invite")
                    .font(.quesly(14, .semibold))
                    .foregroundStyle(Color.qLime)
                    .padding(.horizontal, 16)
                    .frame(height: 34)
                    .background(Capsule().fill(Color.qGreen))
            }
            .buttonStyle(.pressable)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.qLime))
    }
}
