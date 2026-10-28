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
            VStack(alignment: .leading, spacing: 6) {
                StepDots(current: 0, total: 2)
                    .padding(.bottom, 2)
                Text("Find your people")
                    .font(.display(24, .medium))
                    .foregroundStyle(Color.qInk)
                Text("Quesly is better with friends. Follow a few people to fill your Friends feed.")
                    .font(.ui(14))
                    .foregroundStyle(Color.qGray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, 14)

            SearchField(text: $query, prompt: "Search by nickname")
                .padding(.horizontal, DS.Space.screen)
                .padding(.vertical, 10)

            ScrollView {
                LazyVStack(spacing: 0) {
                    if query.isEmpty {
                        InviteCard(username: store.me.username)
                            .padding(.horizontal, DS.Space.screen)
                            .padding(.bottom, 10)
                        SectionLabel("Suggested for you").padding(.horizontal, DS.Space.screen)
                    }
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, user in
                        PersonRow(user: user)
                            .padding(.horizontal, DS.Space.screen)
                            .staggeredAppear(index)
                    }
                }
                .padding(.bottom, 16)
            }

            let count = store.followingIds.count
            LimeButton(title: count > 0 ? "Continue · \(count) following" : "Continue") {
                withAnimation(.qSmooth) { store.finishFindFriends() }
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.vertical, 10)
            .contentTransition(.numericText())
            .animation(.qSpring, value: count)
        }
        .background(Color.qBackground)
        .onAppear { if people.isEmpty { people = store.suggestedUsers + store.followingUsers } }
    }
}

/// Onboarding step 2: explain *why* before the iOS permission prompt (much higher opt-in).
struct NotificationPrimingView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            Color.qBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                StepDots(current: 1, total: 2, onDark: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, 20)
                Spacer()

                NotificationHeroArt()

                Text("Never miss\ntoday's question")
                    .font(.display(30, .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.qInk)
                    .padding(.top, 28)
                Text("We'll send one gentle reminder a day, when the new question drops. No spam, promise.")
                    .font(.ui(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.qGray)
                    .padding(.horizontal, 36)
                    .padding(.top, 12)

                NotificationPreview()
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, 32)

                Spacer()
                VStack(spacing: 8) {
                    LimeButton(title: "Turn on notifications") {
                        withAnimation(.qSmooth) { store.finishNotificationPriming(enable: true) }
                    }
                    Button("Not now") {
                        withAnimation(.qSmooth) { store.finishNotificationPriming(enable: false) }
                    }
                    .font(.ui(16, .semibold))
                    .foregroundStyle(Color.qGray)
                    .frame(height: 48)
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, 12)
            }
        }
    }
}

/// Dimensional branded hero composition for notification priming:
/// sleek emerald squircle with centered crisp bell, Quesly lime mark, and clean scheduled drop tag.
private struct NotificationHeroArt: View {
    @State private var pulsed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                // Central branded squircle tile
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.qGreen, Color.qGreenDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.32), Color.white.opacity(0.08)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.qGreen.opacity(0.28), radius: 18, y: 10)

                // Pure bell
                Icon(.bellRingingFill, size: 40)
                    .foregroundStyle(.white)
                    .frame(width: 88, height: 88)
                    .scaleEffect(pulsed && !reduceMotion ? 1.05 : 1.0)

                // Quesly mini-coin anchored to top-right
                ZStack {
                    Circle().fill(Color.qLime)
                        .frame(width: 26, height: 26)
                    QueslyMark(color: .qGreen, cutout: .qLime)
                        .frame(width: 14)
                }
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                .offset(x: 6, y: -6)
            }

            // Clean floating time pill
            HStack(spacing: 6) {
                Circle().fill(Color.qLime).frame(width: 6, height: 6)
                Text("Daily at 9:00 AM")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Color.qInk)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.qBlock))
            .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulsed = true
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
                .frame(width: 26)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous).fill(Color.qGreen))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("QUESLY").font(.ui(12, .semibold)).foregroundStyle(Color.qGray)
                    Spacer()
                    Text("now").font(.ui(12)).foregroundStyle(Color.qGray)
                }
                Text("Today's question is here ✨").font(.ui(15, .semibold)).foregroundStyle(Color.qInk)
                Text("What tiny moment made your week better?").font(.ui(14)).foregroundStyle(Color.qInk2)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                .fill(Color.qBlock)
                .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
        .offset(y: shown ? 0 : -20)
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
                    .fill(i == current ? (onDark ? Color.qLime : Color.qBrandText) : (onDark ? Color.white.opacity(0.3) : Color.qLine))
                    .frame(width: i == current ? 20 : 6, height: 4)
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
            Icon(.magnifyingGlass, size: 16).foregroundStyle(Color.qGray)
            TextField(prompt, text: $text)
                .font(.ui(15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Icon(.xCircleFill, size: 16).foregroundStyle(Color.qGray.opacity(0.6))
                }
                .accessibilityLabel("Clear search")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qField))
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
                    Avatar(user: user, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.username)
                            .font(.ui(15, .semibold))
                            .foregroundStyle(Color.qInk)
                        Text(user.bio.isEmpty ? "\(user.followers) followers" : user.bio)
                            .font(.ui(13))
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
        .padding(.vertical, 6)
    }
}

struct SectionLabel: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(.ui(12, .semibold))
            .tracking(0.5)
            .foregroundStyle(Color.qGray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }
}

/// Lime card with an invite link.
struct InviteCard: View {
    let username: String

    var body: some View {
        HStack(spacing: 12) {
            Icon(.paperPlaneTiltFill, size: 16)
                .foregroundStyle(Color.qGreen)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.qGreen.opacity(0.10)))
            VStack(alignment: .leading, spacing: 2) {
                Text("Invite your friends").font(.ui(14, .semibold)).foregroundStyle(Color.qInk)
                Text("Answer together").font(.ui(12)).foregroundStyle(Color.qGray).lineLimit(1)
            }
            Spacer()
            ShareLink(item: Invite.text(for: username)) {
                Text("Invite")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 30)
                    .background(Capsule().fill(Color.qGreen))
            }
            .buttonStyle(.pressable)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                .fill(Color.qBlock)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                .strokeBorder(Color.qLine.opacity(0.65), lineWidth: 0.5)
        )
    }
}
