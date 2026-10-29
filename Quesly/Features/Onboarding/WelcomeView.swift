import SwiftUI

/// Welcome & First Launch Onboarding screen.
/// Modern 3-step photographic walkthrough inspired by premium apps (Famio, BeReal, Opal):
/// - Segmented top progress bar with "Skip" button
/// - High-resolution commercial studio hero portraits melting smoothly into the clean background
/// - Dynamic floating circular avatars and interactive sticker badges around the phone
/// - Clean Outfit-Regular display typography (never bold)
/// - Seamless social authentication (Apple & Google) and sign-in
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @State private var currentPage = 0
    @State private var authMode: AuthView.Mode?
    @State private var floating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let totalPages = 3

    var body: some View {
        ZStack(alignment: .top) {
            Color.qBackground.ignoresSafeArea()

            // 3-step Interactive Walkthrough Carousel
            TabView(selection: $currentPage) {
                slideOne.tag(0)
                slideTwo.tag(1)
                slideThree.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .top)

            // Top Status & Segmented Progress Bar
            topBar
                .padding(.horizontal, DS.Space.screen)
                .padding(.top, 10)
        }
        .sheet(item: $authMode) { mode in
            AuthView(mode: mode)
                .presentationDetents([.large])
                .presentationCornerRadius(28)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
    }

    // MARK: - Top Progress Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Segmented Indicators
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.qInk : Color.qInk.opacity(0.18))
                        .frame(height: 3.5)
                        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: currentPage)
                }
            }

            // Skip Button
            if currentPage < totalPages - 1 {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        currentPage = totalPages - 1
                    }
                } label: {
                    Text("Skip")
                        .font(.ui(14, .medium))
                        .foregroundStyle(Color.qInk)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Slide 1: Connect through one question a day

    private var slideOne: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Hero Photo with floating friend bubbles
                ZStack(alignment: .bottom) {
                    Image("onboarding-hero-1")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height * 0.54)
                        .clipped()

                    // Soft bottom gradient fade into canvas
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.35),
                            .init(color: Color.qBackground.opacity(0.70), location: 0.72),
                            .init(color: Color.qBackground, location: 0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.54)

                    // Floating circular friend avatars around phone
                    ZStack {
                        floatingAvatar(name: "avatar-u1", size: 48)
                            .offset(x: 100, y: -50 + (floating ? -4 : 3))

                        floatingAvatar(name: "avatar-u2", size: 42)
                            .offset(x: 138, y: 6 + (floating ? 3 : -3))

                        floatingAvatar(name: "avatar-u3", size: 46)
                            .offset(x: 106, y: 62 + (floating ? -3 : 4))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height * 0.54)

                Spacer(minLength: 12)

                // Text block
                VStack(spacing: 10) {
                    Text("Connect through one question a day")
                        .font(.display(28, .regular))
                        .foregroundStyle(Color.qInk)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Every morning at 9 AM, one thoughtful prompt brings your friends and the world together.")
                        .font(.ui(15))
                        .foregroundStyle(Color.qGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, DS.Space.s)
                }
                .padding(.horizontal, DS.Space.screen)

                Spacer(minLength: 20)

                // Continue Button
                primaryContinueButton(title: "Continue") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        currentPage = 1
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, DS.Space.l)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Slide 2: Answer first, then reveal the world

    private var slideTwo: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Hero Photo with question chip & reaction bubbles
                ZStack(alignment: .bottom) {
                    Image("onboarding-hero-2")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height * 0.54)
                        .clipped()

                    // Soft bottom gradient fade into canvas
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.35),
                            .init(color: Color.qBackground.opacity(0.70), location: 0.72),
                            .init(color: Color.qBackground, location: 0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.54)

                    // Floating prompt & reaction chips
                    ZStack {
                        // Daily at 9 AM Prompt pill
                        HStack(spacing: 7) {
                            QueslyMark(color: .qGreen, cutout: .qLime)
                                .frame(width: 14)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Color.qLime))
                            Text("Daily at 9 AM")
                                .font(.ui(12, .semibold))
                                .foregroundStyle(Color.qInk)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(Color.white)
                                .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
                        )
                        .offset(x: -85, y: -45 + (floating ? -3 : 4))

                        // Heart Like Reaction Pill
                        HStack(spacing: 6) {
                            Text("❤️")
                                .font(.system(size: 14))
                            Text("Like")
                                .font(.ui(12, .semibold))
                                .foregroundStyle(Color.qInk)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(Color.white)
                                .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
                        )
                        .offset(x: 105, y: 25 + (floating ? 4 : -3))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height * 0.54)

                Spacer(minLength: 12)

                // Text block
                VStack(spacing: 10) {
                    Text("Answer first, then reveal the world")
                        .font(.display(28, .regular))
                        .foregroundStyle(Color.qInk)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("No mindless doomscrolling. Answer today's question to unlock what the people you care about shared.")
                        .font(.ui(15))
                        .foregroundStyle(Color.qGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, DS.Space.s)
                }
                .padding(.horizontal, DS.Space.screen)

                Spacer(minLength: 20)

                // Continue Button
                primaryContinueButton(title: "Continue") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        currentPage = 2
                    }
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, DS.Space.l)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Slide 3: Build your streak, collect memories

    private var slideThree: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Hero Photo with streak badge & milestones
                ZStack(alignment: .bottom) {
                    Image("onboarding-hero-3")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height * 0.50)
                        .clipped()

                    // Soft bottom gradient fade into canvas
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.35),
                            .init(color: Color.qBackground.opacity(0.70), location: 0.72),
                            .init(color: Color.qBackground, location: 0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.50)

                    // Floating Streak & Milestone Badges
                    ZStack {
                        // Streak Pill
                        HStack(spacing: 6) {
                            Icon(.fireFill, size: 14)
                                .foregroundStyle(Color.qFlame)
                            Text("9 Day streak")
                                .font(.ui(13, .semibold))
                                .foregroundStyle(Color.qInk)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(Color.white)
                                .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
                        )
                        .offset(x: -85, y: -40 + (floating ? -4 : 3))

                        // Milestone Pill
                        HStack(spacing: 6) {
                            Icon(.sparkleFill, size: 13)
                                .foregroundStyle(Color.qBrandText)
                            Text("Milestones")
                                .font(.ui(12, .semibold))
                                .foregroundStyle(Color.qInk)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule().fill(Color.white)
                                .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
                        )
                        .offset(x: 100, y: 20 + (floating ? 3 : -4))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height * 0.50)

                Spacer(minLength: 8)

                // Text block
                VStack(spacing: 8) {
                    Text("Build streaks, collect memories")
                        .font(.display(26, .regular))
                        .foregroundStyle(Color.qInk)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Reflect daily, celebrate milestones, and create a quiet archive of who you were over time.")
                        .font(.ui(14))
                        .foregroundStyle(Color.qGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, DS.Space.s)
                }
                .padding(.horizontal, DS.Space.screen)

                Spacer(minLength: 12)

                // Action buttons: Get started + Apple + Google + I already have an account
                VStack(spacing: 10) {
                    // Primary: Get started
                    primaryContinueButton(title: "Get started") {
                        authMode = .signUp
                    }

                    // Social sign-in options: Apple & Google
                    HStack(spacing: 10) {
                        // Continue with Apple
                        Button {
                            authMode = .signUp
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Apple")
                                    .font(.ui(15, .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Capsule().fill(Color.black))
                        }
                        .buttonStyle(.pressable)

                        // Continue with Google
                        Button {
                            authMode = .signUp
                        } label: {
                            HStack(spacing: 8) {
                                Image("ui-google")
                                    .renderingMode(.original)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 17, height: 17)
                                Text("Google")
                                    .font(.ui(15, .semibold))
                            }
                            .foregroundStyle(Color.qInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Capsule().fill(Color.qBlock))
                            .overlay(Capsule().stroke(Color.qLine, lineWidth: 1))
                        }
                        .buttonStyle(.pressable)
                    }

                    // Secondary: I already have an account
                    Button {
                        authMode = .signIn
                    } label: {
                        Text("I already have an account")
                            .font(.ui(14, .medium))
                            .foregroundStyle(Color.qGray)
                    }
                    .buttonStyle(.plain)
                    .frame(height: 28)
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, DS.Space.m)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Reusable Components

    private func floatingAvatar(name: String, size: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
    }

    private func primaryContinueButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.ui(16, .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Capsule().fill(Color.black))
        }
        .buttonStyle(.pressable)
    }
}

#Preview { WelcomeView().environment(AppStore()) }
