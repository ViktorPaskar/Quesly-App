import SwiftUI

struct AuthView: View {
    enum Mode: String, Identifiable {
        case signUp, signIn
        var id: String { rawValue }
    }

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var mode: Mode

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var acceptedTerms = false
    @State private var showPassword = false
    @FocusState private var focused: Field?

    private enum Field { case username, email, password }

    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".") && email.count >= 5
    }

    private var canSubmit: Bool {
        switch mode {
        case .signUp:
            return username.trimmingCharacters(in: .whitespaces).count >= 3 && isEmailValid
                && password.count >= 8 && acceptedTerms
        case .signIn:
            return isEmailValid && !password.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    QueslyLogo(height: 22, markColor: .qGreen, textColor: .qGreen, background: .white)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(mode == .signUp ? "Create your account" : "Welcome back")
                            .font(.display(26, .bold)).foregroundStyle(Color.qInk)
                        Text(mode == .signUp
                             ? "One question a day. Join millions of stories."
                             : "Today's question is waiting for you.")
                            .font(.ui(15)).foregroundStyle(Color.qGray)
                    }

                    if mode == .signUp {
                        labeled("Nickname") {
                            TextField("your_nickname", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textContentType(.username)
                                .focused($focused, equals: .username)
                                .submitLabel(.next)
                                .onSubmit { focused = .email }
                                .queslyField()
                        }
                    }

                    labeled("Email Address") {
                        TextField("you@example.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .focused($focused, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focused = .password }
                            .queslyField()
                    }

                    labeled("Password") {
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("At least 8 characters", text: $password)
                                } else {
                                    SecureField("At least 8 characters", text: $password)
                                }
                            }
                            .textContentType(mode == .signUp ? .newPassword : .password)
                            .textInputAutocapitalization(.never)
                            .focused($focused, equals: .password)
                            .submitLabel(.go)
                            .onSubmit(submit)

                            Button { showPassword.toggle() } label: {
                                Icon(showPassword ? .eyeSlash : .eye, size: DS.Icon.action)
                                    .foregroundStyle(Color.qGray)
                            }
                            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                        }
                        .queslyField()
                    }

                    if mode == .signUp {
                        Toggle(isOn: $acceptedTerms) {
                            Text("I agree to the Terms of Service and Privacy Policy")
                                .font(.ui(13)).foregroundStyle(Color.qInk)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                    } else {
                        Button("Forgot password?") {}
                            .font(.ui(13))
                            .foregroundStyle(Color.qBrandText)
                    }

                    GreenButton(title: mode == .signUp ? "Sign Up" : "Sign In", isEnabled: canSubmit, action: submit)
                        .padding(.top, 8)

                    HStack {
                        Spacer()
                        Text(mode == .signUp ? "Already have an account?" : "New to Quesly?")
                            .foregroundStyle(Color.qGray)
                        Button(mode == .signUp ? "Sign In" : "Sign Up") {
                            withAnimation { mode = mode == .signUp ? .signIn : .signUp }
                        }
                        .foregroundStyle(Color.qBrandText)
                        .fontWeight(.semibold)
                        Spacer()
                    }
                    .font(.ui(15))
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.qBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Icon(.xBold, size: DS.Icon.row).foregroundStyle(Color.qInk)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        switch mode {
        case .signUp: store.signUp(username: username, email: email)
        case .signIn: store.signIn(email: email)
        }
        dismiss()
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.ui(12)).foregroundStyle(Color.qGray)
            content()
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(alignment: .top, spacing: 12) {
                Icon(configuration.isOn ? .checkCircleFill : .checkBold, size: DS.Icon.action)
                    .opacity(configuration.isOn ? 1 : 0.35)
                    .foregroundStyle(configuration.isOn ? Color.qBrandText : Color.qGray)
                configuration.label
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview { AuthView(mode: .signUp).environment(AppStore()) }
