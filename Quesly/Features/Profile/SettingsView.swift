import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        @Bindable var store = store
        Form {
            Section("Daily reminder") {
                Toggle("Remind me to answer", isOn: $store.remindersEnabled)
                if store.remindersEnabled {
                    DatePicker("Time", selection: $store.reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            Section {
                Toggle("Private account", isOn: $store.isPrivateAccount)
            } header: {
                Text("Privacy")
            } footer: {
                Text("Only your followers will see your answers in their Friends feed.")
            }
            Section("About") {
                Link("Terms of Service", destination: URL(string: "https://quesly.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://quesly.app/privacy")!)
                LabeledContent("Version", value: Bundle.main.appVersion)
            }
            Section {
                Button("Sign Out") { confirmSignOut = true }
                    .foregroundStyle(Color.qGreen)
                Button("Delete Account", role: .destructive) { confirmDelete = true }
            }
        }
        .tint(Color.qGreen)
        .queslyBackHeader("Settings")
        .confirmationDialog("Sign out of Quesly?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { store.signOut() }
        }
        .confirmationDialog("Delete your account and all answers? This can't be undone.",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) { store.deleteAccount() }
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
