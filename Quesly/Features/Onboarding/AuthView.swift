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
    @State private var showForgotPassword = false
    @State private var forgotPasswordSent = false
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
                    // Just the brand, centred: no tagline promising numbers we don't have yet.
                    VStack(spacing: 14) {
                        QueslyLogo(height: 38, markColor: .qLime, textColor: .qInk, background: .qGreenDeep)
                        Text(mode == .signUp ? "Create your account" : "Welcome back")
                            .font(.display(24, .medium)).foregroundStyle(Color.qInk)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

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
                            Text("I agree to the [Terms of Service](https://quesly.me/terms) and [Privacy Policy](https://quesly.me/privacy)")
                                .font(.ui(13))
                                .foregroundStyle(Color.qInk)
                                .tint(Color.qBrandText)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                    } else {
                        Button("Forgot password?") {
                            showForgotPassword = true
                        }
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
            .alert("Reset Password", isPresented: $showForgotPassword) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                Button("Send Link") {
                    if !email.isEmpty { forgotPasswordSent = true }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your email address and we'll send you a password reset link.")
            }
            .alert("Check Your Email", isPresented: $forgotPasswordSent) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("We've sent password reset instructions to \(email.isEmpty ? "your email" : email).")
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
        Button {
            withAnimation(.qSpring) { configuration.isOn.toggle() }
        } label: {
            HStack(alignment: .center, spacing: DS.Space.s) {
                ZStack {
                    if configuration.isOn {
                        Icon(.checkCircleFill, size: DS.Icon.action)
                            .foregroundStyle(Color.qBrandText)
                    } else {
                        Circle()
                            .strokeBorder(Color.qGray4, lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }
                .frame(width: DS.Icon.action, height: DS.Icon.action)
                configuration.label
                    .multilineTextAlignment(.leading)
            }
            .frame(minHeight: DS.hitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: configuration.isOn)
    }
}

#Preview { AuthView(mode: .signUp).environment(AppStore()) }
