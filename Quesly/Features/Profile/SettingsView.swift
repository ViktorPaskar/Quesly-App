import SwiftUI

/// Single, native grouped settings screen (replaces the old "Profile menu → Settings" two-level path).
struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                NavigationLink(value: Route.editProfile) {
                    HStack(spacing: DS.Space.s) {
                        Avatar(user: store.me, size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.me.username).font(.ui(17, .semibold)).foregroundStyle(Color.qInk)
                            Text("Edit profile").font(.ui(15)).foregroundStyle(Color.qGray)
                        }
                    }
                    .padding(.vertical, DS.Space.xxs)
                }
            }

            Section("Activity") {
                row("Achievements", .medalFill, tint: Color(hex: 0xE2A72E), route: .achievements)
                row("Invite friends", .paperPlaneTiltFill, tint: Color(hex: 0xE84FA5), route: .invite)
            }

            Section {
                Toggle(isOn: $store.remindersEnabled) {
                    label("Daily reminder", .bellFill, tint: Color(hex: 0xFF9F0A))
                }
                if store.remindersEnabled {
                    DatePicker("Time", selection: $store.reminderTime, displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("One reminder a day, when you haven't answered yet.")
            }

            Section {
                Toggle(isOn: $store.isPrivateAccount) {
                    label("Private account", .lockSimpleFill, tint: Color(hex: 0x5E5CE6))
                }
                row("Blocked people", .prohibitFill, tint: Color(hex: 0xE5484D), route: .blocked,
                    value: store.blockedIds.isEmpty ? nil : "\(store.blockedIds.count)")
            } header: {
                Text("Privacy & safety")
            } footer: {
                Text("A private account shows your answers only to people you approve.")
            }

            Section("Support") {
                row("Send feedback", .chatCircleTextFill, tint: Color(hex: 0x2D7BF0), route: .feedback)
                Link(destination: URL(string: "https://quesly.app/terms")!) {
                    label("Terms of Service", .copy, tint: .gray)
                }
                Link(destination: URL(string: "https://quesly.app/privacy")!) {
                    label("Privacy Policy", .shieldCheckFill, tint: .gray)
                }
            }

            Section {
                Button("Sign out") { confirmSignOut = true }
                    .foregroundStyle(Color.qBrandText)
                Button("Delete account", role: .destructive) { confirmDelete = true }
            } footer: {
                Text("Quesly \(Bundle.main.appVersion)")
                    .frame(maxWidth: .infinity)
                    .padding(.top, DS.Space.m)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.qCanvas)
        .tint(Color.qGreen)
        .queslyBackHeader("Settings")
        .confirmationDialog("Sign out of Quesly?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { store.signOut() }
        }
        .confirmationDialog("Delete your account and all answers? This can't be undone.",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) { store.deleteAccount() }
        }
    }

    private func row(_ title: String, _ icon: QIcon, tint: Color, route: Route, value: String? = nil) -> some View {
        NavigationLink(value: route) {
            HStack {
                label(title, icon, tint: tint)
                if let value {
                    Spacer()
                    Text(value).foregroundStyle(Color.qGray)
                }
            }
        }
    }

    /// Settings-style label: white glyph on a small colored rounded square (iOS Settings pattern).
    private func label(_ title: String, _ icon: QIcon, tint: Color) -> some View {
        Label {
            Text(title).foregroundStyle(Color.qInk)
        } icon: {
            Icon(icon, size: 15)
                .foregroundStyle(.white)
                .frame(width: 29, height: 29)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(tint))
        }
    }
}

extension Bundle {
    var appVersion: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
