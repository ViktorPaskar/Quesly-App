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
    @State private var isImporting = false
    @State private var importError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: DS.Space.s) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Avatar(user: draft, size: 96)
                            .overlay {
                                if isImporting {
                                    Circle().fill(.black.opacity(0.35))
                                    ProgressView().tint(.white)
                                }
                            }
                            .overlay(alignment: .bottomTrailing) {
                                Icon(.cameraFill, size: 14)
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(Color.qGreen))
                                    .overlay(Circle().stroke(Color.qCanvas, lineWidth: 2))
                            }
                    }
                    .accessibilityLabel("Change photo")
                    HStack(spacing: DS.Space.l) {
                        PhotosPicker("Change photo", selection: $photoItem, matching: .images)
                            .font(.ui(15, .semibold))
                            .foregroundStyle(Color.qBrandText)
                        if store.myPhoto != nil {
                            Button("Remove", role: .destructive) { withAnimation(.qSmooth) { store.removePhoto() } }
                                .font(.ui(15, .semibold))
                        }
                    }
                    if let importError {
                        Text(importError).font(.ui(13)).foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Space.xs)
                .onChange(of: photoItem) { _, item in
                    guard let item else { return }
                    importPhoto(item)
                }

                field("Nickname") {
                    TextField("Nickname", text: $draft.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                field("Email address") {
                    TextField("Email", text: $draft.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                field("Phone number") {
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
                            .foregroundStyle(Color.qBrandText)
                    }
                    HStack {
                        if showPassword { TextField("", text: $password) } else { SecureField("", text: $password) }
                        Button { showPassword.toggle() } label: {
                            Icon(showPassword ? .eyeSlash : .eye, size: 22).foregroundStyle(Color.qGray)
                        }
                    }
                    .queslyField(fill: .qBlock)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("About").font(.ui(13)).foregroundStyle(Color.qGray)
                    TextField("Tell people about yourself", text: $draft.bio, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.ui(16))
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qBlock))
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
        .background(Color.qCanvas)
        .queslyBackHeader("Edit profile")
        .onAppear {
            guard !loaded else { return }
            draft = store.me
            loaded = true
        }
    }

    private func importPhoto(_ item: PhotosPickerItem) {
        isImporting = true
        importError = nil
        Task {
            defer { isImporting = false; photoItem = nil }
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    importError = "This photo can't be used. Try another one."
                    return
                }
                withAnimation(.qSmooth) { store.setPhoto(data) }
            } catch {
                importError = "Couldn't load the photo. Check your connection and try again."
            }
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.ui(13)).foregroundStyle(Color.qGray)
            content().queslyField(fill: .qBlock)
        }
    }
}
