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
                            .padding(.bottom, 12)
                        SectionLabel("Suggested for you")
                            .padding(.horizontal, DS.Space.screen)
                            .padding(.bottom, 6)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { index, user in
                            if index > 0 {
                                Rectangle().fill(Color.qLine.opacity(0.65)).frame(height: 0.5)
                            }
                            PersonRow(user: user)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .staggeredAppear(index)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                            .fill(Color.qBlock)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                            .strokeBorder(Color.qLine.opacity(0.65), lineWidth: 0.5)
                    )
                    .padding(.horizontal, DS.Space.screen)
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
                Spacer(minLength: 12)

                NotificationHeroArt()

                Text("Never miss a question —\nor a friend's answer")
                    .font(.display(28, .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.qInk)
                    .padding(.top, 20)
                Text("Get notified when the daily question drops at 9:00 AM, and the moment your friends share their honest thoughts.")
                    .font(.ui(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.qGray)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)

                NotificationPreview()
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, 24)

                Spacer(minLength: 16)
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
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Central branded squircle tile
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.qGreen, Color.qGreenDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.2
                            )
                    )

                // Pure bell
                Icon(.bellRingingFill, size: 36)
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulsed && !reduceMotion ? 1.05 : 1.0)

                // Quesly mini-coin anchored to top-right (base 11.svg: lime bubble with dark green eyes)
                ZStack {
                    Circle().fill(Color.qLime)
                        .frame(width: 26, height: 26)
                    QueslyMark(color: .qLime, cutout: .qGreenDeep)
                        .frame(width: 14)
                }
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
                .offset(x: 6, y: -6)
            }

            // Clean floating time & friend alert badge
            HStack(spacing: 6) {
                Circle().fill(Color.qLime).frame(width: 6, height: 6)
                Text("Daily drop at 9:00 AM · Friend alerts")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Color.qInk)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.qBlock))
            .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulsed = true
            }
        }
    }
}

/// Realistic lock-screen notification preview showing both key notifications:
/// 1) Daily Question drop, and 2) Friend answering the question!
private struct NotificationPreview: View {
    @State private var shown = false

    var body: some View {
        VStack(spacing: 8) {
            // Notification 1: Daily Question Drop
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.qLime)
                        .frame(width: 38, height: 38)
                    QueslyMark(color: .qLime, cutout: .qGreenDeep)
                        .frame(width: 22)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("QUESLY").font(.ui(11, .bold)).foregroundStyle(Color.qGray)
                        Spacer()
                        Text("9:00 AM").font(.ui(11)).foregroundStyle(Color.qGray)
                    }
                    Text("Today's question is here ✨")
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Color.qInk)
                    Text("What meal feels like home to you?")
                        .font(.ui(13))
                        .foregroundStyle(Color.qInk2)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .fill(Color.qBlock)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                            .stroke(Color.qLine, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
            )

            // Notification 2: Friend Answered
            HStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.qSage.opacity(0.4))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Text("CB")
                                .font(.ui(13, .bold))
                                .foregroundStyle(Color.qGreenDeep)
                        )
                    Circle()
                        .fill(Color.qLime)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("QUESLY").font(.ui(11, .bold)).foregroundStyle(Color.qGray)
                        Spacer()
                        Text("now").font(.ui(11)).foregroundStyle(Color.qGray)
                    }
                    Text("camille_b answered ✨")
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Color.qInk)
                    Text("“My mom's crêpes on Sunday mornings 🥞”")
                        .font(.ui(13))
                        .foregroundStyle(Color.qInk2)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .fill(Color.qBlock)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                            .stroke(Color.qLine, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
            )
        }
        .offset(y: shown ? 0 : -16)
        .opacity(shown ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                shown = true
            }
        }
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
                        HStack(spacing: 5) {
                            Text(user.username)
                                .font(.ui(15, .semibold))
                                .foregroundStyle(Color.qInk)

                            if store.isFriend(user.id) {
                                HStack(spacing: 3) {
                                    Icon(.userFill, size: 8)
                                    Text("Friend")
                                }
                                .font(.ui(10.5, .semibold))
                                .foregroundStyle(Color.qGreenDeep)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.qSage.opacity(0.40)))
                            }
                        }
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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
