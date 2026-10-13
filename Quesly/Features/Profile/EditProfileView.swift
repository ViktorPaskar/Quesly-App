import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AppUser = MockData.me
    @State private var password = "••••••••••"
    @State private var showPassword = false
    @State private var photoItem: PhotosPickerItem?
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Avatar(user: draft, size: 96)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.qGray)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(.white))
                                .overlay(Circle().stroke(Color.qLine))
                        }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .accessibilityLabel("Change photo")

                field("Nickname") {
                    TextField("Nickname", text: $draft.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                field("Email Address") {
                    TextField("Email", text: $draft.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                field("Phone Number") {
                    TextField("Phone", text: $draft.phone).keyboardType(.phonePad)
                }
                field("Location") {
                    TextField("City, Country", text: $draft.location)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Password").font(.quesly(13)).foregroundStyle(Color.qGray)
                        Spacer()
                        Button("Change your password") {}
                            .font(.quesly(13, .medium))
                            .foregroundStyle(Color.qGreen)
                    }
                    HStack {
                        if showPassword { TextField("", text: $password) } else { SecureField("", text: $password) }
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye").foregroundStyle(Color.qGray)
                        }
                    }
                    .queslyField()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("About").font(.quesly(13)).foregroundStyle(Color.qGray)
                    TextField("Tell people about yourself", text: $draft.bio, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.quesly(16))
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.qLine))
                }

                GreenButton(title: "Save", isEnabled: draft.username.count >= 3) {
                    store.updateProfile(draft)
                    dismiss()
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
        .queslyBackHeader("Edit Profile")
        .onAppear {
            guard !loaded else { return }
            draft = store.me
            loaded = true
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.quesly(13)).foregroundStyle(Color.qGray)
            content().queslyField()
        }
    }
}
