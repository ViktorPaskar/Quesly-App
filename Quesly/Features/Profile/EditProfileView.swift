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
                            Icon(.cameraFill, size: 14)
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

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Password").font(.ui(13)).foregroundStyle(Color.qGray)
                        Spacer()
                        Button("Change your password") {}
                            .font(.ui(13, .medium))
                            .foregroundStyle(Color.qGreen)
                    }
                    HStack {
                        if showPassword { TextField("", text: $password) } else { SecureField("", text: $password) }
                        Button { showPassword.toggle() } label: {
                            Icon(showPassword ? .eyeSlash : .eye, size: 22).foregroundStyle(Color.qGray)
                        }
                    }
                    .queslyField()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("About").font(.ui(13)).foregroundStyle(Color.qGray)
                    TextField("Tell people about yourself", text: $draft.bio, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.ui(16))
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: DS.Radius.m).stroke(Color.qLine))
                }

                GreenButton(title: "Save", isEnabled: draft.username.count >= 3) {
                    store.updateProfile(draft)
                    dismiss()
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.qBackground)
        .queslyBackHeader("Edit Profile")
        .onAppear {
            guard !loaded else { return }
            draft = store.me
            loaded = true
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.ui(13)).foregroundStyle(Color.qGray)
            content().queslyField()
        }
    }
}
