import SwiftUI

/// Single, native grouped settings screen.
/// Follows strict Apple HIG & Revolut elegance:
/// - Rounded grouped list sections on clean canvas
/// - Monochromatic or brand-tinted icons with subtle rounded squircle glyphs
/// - Clean font weights and balanced row heights
struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    // App Preferences & Social state
    @State private var syncContacts = true
    @State private var streakAlerts = true
    @State private var showInDiscover = true
    @State private var showCopiedAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: DS.Space.xl) {
                // Profile Header Card
                profileCard

                // Connected Accounts & Social Sharing
                socialSection

                // Preferences & Rituals
                preferencesSection

                // Privacy & Security
                privacySection

                // Support & Legal
                supportSection

                // Account Actions
                accountSection
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.s)
            .padding(.bottom, 60)
        }
        .background(Color.qCanvas)
        .queslyBackHeader("Settings")
        .confirmationDialog("Sign out of Quesly?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { store.signOut() }
        }
        .confirmationDialog("Delete your account and all answers? This can't be undone.",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) { store.deleteAccount() }
        }
        .overlay(alignment: .top) {
            if showCopiedAlert {
                Text("Profile link copied to clipboard")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.qInk))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 10)
            }
        }
    }

    // MARK: - Profile Header Card

    private var profileCard: some View {
        NavigationLink(value: Route.editProfile) {
            HStack(spacing: DS.Space.m) {
                Avatar(user: store.me, size: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.me.username)
                        .font(.ui(16, .semibold))
                        .foregroundStyle(Color.qInk)
                    Text("Edit personal details")
                        .font(.ui(13))
                        .foregroundStyle(Color.qGray)
                }

                Spacer()

                Icon(.caretRightBold, size: 12)
                    .foregroundStyle(Color.qGray4)
            }
            .padding(DS.Space.m)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Connected Accounts & Social Sharing

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            sectionHeader("CONNECTED ACCOUNTS & SOCIAL")

            VStack(spacing: 0) {
                // Instagram
                settingsRow(
                    icon: .cameraFill,
                    tint: Color(hex: 0xE1306C),
                    title: "Instagram",
                    detail: "@\(store.me.instagram.isEmpty ? "lilly.laurent" : store.me.instagram)"
                )

                divider

                // TikTok
                settingsRow(
                    icon: .sparkleFill,
                    tint: Color.qInk,
                    title: "TikTok",
                    detail: "@\(store.me.tiktok.isEmpty ? "lilly" : store.me.tiktok)"
                )

                divider

                // Threads
                settingsRow(
                    icon: .chatCircleTextFill,
                    tint: Color.qInk,
                    title: "Threads",
                    detail: "@\(store.me.threads.isEmpty ? "lilly.laurent" : store.me.threads)"
                )

                divider

                // Contacts Sync Toggle
                HStack(spacing: DS.Space.s) {
                    iconSquare(.userPlusFill, tint: Color.qGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Find contacts")
                            .font(.ui(15, .medium))
                            .foregroundStyle(Color.qInk)
                        Text("Discover friends from address book")
                            .font(.ui(11.5))
                            .foregroundStyle(Color.qGray)
                    }
                    Spacer()
                    Toggle("", isOn: $syncContacts)
                        .labelsHidden()
                        .tint(Color.qGreen)
                }
                .padding(DS.Space.m)

                divider

                // Share profile link
                Button {
                    UIPasteboard.general.string = "https://quesly.me/@\(store.me.username)"
                    withAnimation(.qSpring) { showCopiedAlert = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showCopiedAlert = false }
                    }
                } label: {
                    HStack(spacing: DS.Space.s) {
                        iconSquare(.link, tint: Color.qGreen)
                        Text("Share profile link")
                            .font(.ui(15, .medium))
                            .foregroundStyle(Color.qInk)
                        Spacer()
                        Text("Copy link")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Color.qBrandText)
                    }
                    .padding(DS.Space.m)
                }
                .buttonStyle(.plain)
            }
            .background(cardBackground)
        }
    }

    // MARK: - Preferences & Rituals

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            sectionHeader("DAILY RITUAL & ALERTS")

            VStack(spacing: 0) {
                // Daily reminder toggle
                HStack(spacing: DS.Space.s) {
                    iconSquare(.bellFill, tint: Color.qGreen)
                    Text("Daily reminder")
                        .font(.ui(15, .medium))
                        .foregroundStyle(Color.qInk)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.remindersEnabled },
                        set: { store.remindersEnabled = $0 }
                    ))
                        .labelsHidden()
                        .tint(Color.qGreen)
                }
                .padding(DS.Space.m)

                if store.remindersEnabled {
                    divider

                    HStack(spacing: DS.Space.s) {
                        iconSquare(.clock, tint: Color.qGreen)
                        Text("Reminder time")
                            .font(.ui(15, .medium))
                            .foregroundStyle(Color.qInk)
                        Spacer()
                        DatePicker("", selection: Binding(
                            get: { store.reminderTime },
                            set: { store.reminderTime = $0 }
                        ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .tint(Color.qGreen)
                    }
                    .padding(DS.Space.m)
                }

                divider

                // Streak alerts toggle
                HStack(spacing: DS.Space.s) {
                    iconSquare(.fireFill, tint: Color.qFlame)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Streak protection")
                            .font(.ui(15, .medium))
                            .foregroundStyle(Color.qInk)
                        Text("Alert when streak is about to expire")
                            .font(.ui(11.5))
                            .foregroundStyle(Color.qGray)
                    }
                    Spacer()
                    Toggle("", isOn: $streakAlerts)
                        .labelsHidden()
                        .tint(Color.qGreen)
                }
                .padding(DS.Space.m)

                divider

                // Invite friends
                NavigationLink(value: Route.invite) {
                    settingsRow(icon: .paperPlaneTiltFill, tint: Color.qGreen, title: "Invite friends")
                }
                .buttonStyle(.plain)
            }
            .background(cardBackground)
        }
    }

    // MARK: - Privacy & Safety

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            sectionHeader("PRIVACY & SAFETY")

            VStack(spacing: 0) {
                // Private account toggle
                HStack(spacing: DS.Space.s) {
                    iconSquare(.lockSimpleFill, tint: Color.qBrandText)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Private account")
                            .font(.ui(15, .medium))
                            .foregroundStyle(Color.qInk)
                        Text("Only approved people see answers")
                            .font(.ui(11.5))
                            .foregroundStyle(Color.qGray)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.isPrivateAccount },
                        set: { store.isPrivateAccount = $0 }
                    ))
                        .labelsHidden()
                        .tint(Color.qGreen)
                }
                .padding(DS.Space.m)

                divider

                // Discover feed visibility
                HStack(spacing: DS.Space.s) {
                    iconSquare(.eye, tint: Color.qGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show in Discover")
                            .font(.ui(15, .medium))
                            .foregroundStyle(Color.qInk)
                        Text("Recommend your answers to public")
                            .font(.ui(11.5))
                            .foregroundStyle(Color.qGray)
                    }
                    Spacer()
                    Toggle("", isOn: $showInDiscover)
                        .labelsHidden()
                        .tint(Color.qGreen)
                }
                .padding(DS.Space.m)

                divider

                // Blocked people
                NavigationLink(value: Route.blocked) {
                    settingsRow(
                        icon: .prohibitFill,
                        tint: Color.qFlame,
                        title: "Blocked people",
                        detail: store.blockedIds.isEmpty ? nil : "\(store.blockedIds.count)"
                    )
                }
                .buttonStyle(.plain)
            }
            .background(cardBackground)
        }
    }

    // MARK: - Support & Legal

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            sectionHeader("SUPPORT & ABOUT")

            VStack(spacing: 0) {
                NavigationLink(value: Route.feedback) {
                    settingsRow(icon: .chatCircleTextFill, tint: Color.qBrandText, title: "Send feedback")
                }
                .buttonStyle(.plain)

                divider

                Link(destination: URL(string: "https://quesly.me/terms")!) {
                    settingsRow(icon: .copy, tint: Color.qGray, title: "Terms of Service")
                }

                divider

                Link(destination: URL(string: "https://quesly.me/privacy")!) {
                    settingsRow(icon: .shieldCheckFill, tint: Color.qGray, title: "Privacy Policy")
                }
            }
            .background(cardBackground)
        }
    }

    // MARK: - Account Actions

    private var accountSection: some View {
        VStack(spacing: 0) {
            Button {
                confirmSignOut = true
            } label: {
                HStack {
                    Text("Sign out")
                        .font(.ui(15, .medium))
                        .foregroundStyle(Color.qInk)
                    Spacer()
                }
                .padding(DS.Space.m)
            }
            .buttonStyle(.plain)

            divider

            Button {
                confirmDelete = true
            } label: {
                HStack(spacing: 8) {
                    Icon(.trash, size: 16)
                        .foregroundStyle(Color.qFlame)
                    Text("Delete account")
                        .font(.ui(15, .medium))
                        .foregroundStyle(Color.qFlame)
                    Spacer()
                }
                .padding(DS.Space.m)
            }
            .buttonStyle(.plain)
        }
        .background(cardBackground)
        .overlay(alignment: .bottom) {
            Text("Quesly \(Bundle.main.appVersion)")
                .font(.ui(11))
                .foregroundStyle(Color.qGray4)
                .offset(y: 28)
        }
    }

    // MARK: - Helpers & Components

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.ui(11, .semibold))
            .tracking(0.6)
            .foregroundStyle(Color.qGray)
            .padding(.leading, 4)
    }

    private func settingsRow(icon: QIcon, tint: Color, title: String, detail: String? = nil) -> some View {
        HStack(spacing: DS.Space.s) {
            iconSquare(icon, tint: tint)
            Text(title)
                .font(.ui(15, .medium))
                .foregroundStyle(Color.qInk)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
            }
            Icon(.caretRightBold, size: 12)
                .foregroundStyle(Color.qGray4)
        }
        .padding(DS.Space.m)
        .contentShape(Rectangle())
    }

    private func iconSquare(_ icon: QIcon, tint: Color) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(tint.opacity(0.12))
            .frame(width: 28, height: 28)
            .overlay(
                Icon(icon, size: 14)
                    .foregroundStyle(tint)
            )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.qLine)
            .frame(height: 1)
            .padding(.leading, 48)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.qBlock)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.qLine, lineWidth: 1)
            )
    }
}

// MARK: - Bundle Helper

extension Bundle {
    var appVersion: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
