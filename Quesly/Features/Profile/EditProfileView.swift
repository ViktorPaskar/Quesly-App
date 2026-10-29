import SwiftUI
import PhotosUI

/// Clean, editorial profile editor with required indicators (*), account credentials (Email & Password),
/// and responsive validation.
struct EditProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: AppUser = MockData.me
    @State private var photoItem: PhotosPickerItem?
    @State private var loaded = false
    @State private var isImporting = false
    @State private var importError: String?

    // Change Email & Password sheet states
    @State private var showChangeEmail = false
    @State private var newEmail = ""
    @State private var showChangePassword = false
    @State private var oldPassword = ""
    @State private var newPassword = ""

    private var isValid: Bool {
        let hasName = !(draft.name ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        let hasUsername = draft.username.trimmingCharacters(in: .whitespaces).count >= 3
        let hasBio = !draft.bio.trimmingCharacters(in: .whitespaces).isEmpty
        return hasName && hasUsername && hasBio
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Avatar Photo Section
                avatarSection
                    .padding(.top, 4)

                // Public Profile Information
                profileCard

                // Account & Security Section
                accountCard

                // Save CTA
                GreenButton(title: "Save changes", isEnabled: isValid) {
                    store.updateProfile(draft)
                    dismiss()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.qBackground)
        .queslyBackHeader("Edit profile")
        .onAppear {
            guard !loaded else { return }
            draft = store.me
            if draft.bio.count > AppUser.bioLimit {
                draft.bio = String(draft.bio.prefix(AppUser.bioLimit))
            }
            loaded = true
        }
        .sheet(isPresented: $showChangeEmail) { changeEmailSheet }
        .sheet(isPresented: $showChangePassword) { changePasswordSheet }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: DS.Space.s) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Avatar(user: draft, size: 92)
                    .overlay {
                        if isImporting {
                            Circle().fill(.black.opacity(0.35))
                            ProgressView().tint(.white)
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Icon(.cameraFill, size: DS.Icon.caption)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.qGreen))
                            .overlay(Circle().stroke(Color.qCanvas, lineWidth: 2))
                    }
            }
            .accessibilityLabel("Change photo")

            HStack(spacing: DS.Space.m) {
                PhotosPicker("Change photo", selection: $photoItem, matching: .images)
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color.qBrandText)

                if store.myPhoto != nil {
                    Button("Remove", role: .destructive) {
                        withAnimation(.qSmooth) { store.removePhoto() }
                    }
                    .font(.ui(15, .semibold))
                }
            }

            if let importError {
                Text(importError)
                    .font(.ui(13))
                    .foregroundStyle(Color.qFlame)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            importPhoto(item)
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Name *
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 3) {
                    Text("Name")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Color.qInk)
                    Text("*")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Color.qFlame)
                }
                TextField("Your full name", text: Binding(get: { draft.name ?? "" }, set: { draft.name = $0 }))
                    .textContentType(.name)
                    .queslyField(fill: .qField)
            }

            // Nickname *
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 3) {
                    Text("Nickname")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Color.qInk)
                    Text("*")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Color.qFlame)
                }
                HStack(spacing: 4) {
                    Text("@")
                        .font(.ui(16, .semibold))
                        .foregroundStyle(Color.qGray)
                    TextField("username", text: $draft.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .queslyField(fill: .qField)
            }

            // Location (optional)
            VStack(alignment: .leading, spacing: 6) {
                Text("Location (optional)")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk2)
                HStack(spacing: 6) {
                    Icon(.globeHemisphereWestFill, size: 16)
                        .foregroundStyle(Color.qGray)
                    TextField("City, Country", text: $draft.location)
                }
                .queslyField(fill: .qField)
            }

            // About *
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 3) {
                        Text("About")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Color.qInk)
                        Text("*")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Color.qFlame)
                    }
                    Spacer()
                    Text("\(draft.bio.count)/\(AppUser.bioLimit)")
                        .font(.ui(12))
                        .foregroundStyle(draft.bio.count >= AppUser.bioLimit ? Color.qFlame : Color.qGray)
                        .monospacedDigit()
                }
                TextField("Tell people about yourself…", text: $draft.bio, axis: .vertical)
                    .lineLimit(3...5)
                    .onChange(of: draft.bio) { _, new in
                        if new.count > AppUser.bioLimit { draft.bio = String(new.prefix(AppUser.bioLimit)) }
                    }
                    .font(.ui(15))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qField))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                            .stroke(Color.qLine, lineWidth: 1)
                    )
            }
        }
        .padding(18)
        .outlinedBlock()
    }

    // MARK: - Account & Security Card

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACCOUNT & SECURITY")
                .font(.ui(11, .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.qBrandText)

            VStack(spacing: 0) {
                // Email Row
                HStack(spacing: 12) {
                    Icon(.chatCircleTextFill, size: 18)
                        .foregroundStyle(Color.qGreen)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.qGreen.opacity(0.10)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email")
                            .font(.ui(13))
                            .foregroundStyle(Color.qGray)
                        Text(draft.email.isEmpty ? "user@quesly.app" : draft.email)
                            .font(.ui(15, .semibold))
                            .foregroundStyle(Color.qInk)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button("Change") {
                        newEmail = draft.email
                        showChangeEmail = true
                    }
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Color.qBrandText)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule().fill(Color.qField))
                }
                .padding(.vertical, 12)

                Rectangle().fill(Color.qLine).frame(height: 1)

                // Password Row
                HStack(spacing: 12) {
                    Icon(.lockSimpleFill, size: 18)
                        .foregroundStyle(Color.qGreen)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.qGreen.opacity(0.10)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Password")
                            .font(.ui(13))
                            .foregroundStyle(Color.qGray)
                        Text("••••••••••••")
                            .font(.ui(15, .semibold))
                            .foregroundStyle(Color.qInk)
                    }

                    Spacer()

                    Button("Change") {
                        oldPassword = ""
                        newPassword = ""
                        showChangePassword = true
                    }
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Color.qBrandText)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule().fill(Color.qField))
                }
                .padding(.vertical, 12)
            }
        }
        .padding(18)
        .outlinedBlock()
    }

    // MARK: - Change Email Sheet

    private var changeEmailSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Enter your new email address. We'll send a confirmation link.")
                    .font(.ui(15))
                    .foregroundStyle(Color.qGray)

                VStack(alignment: .leading, spacing: 6) {
                    Text("New email")
                        .font(.ui(13, .semibold))
                    TextField("you@domain.com", text: $newEmail)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .queslyField(fill: .qField)
                }

                Spacer()

                GreenButton(title: "Update email", isEnabled: newEmail.contains("@") && newEmail.contains(".")) {
                    draft.email = newEmail
                    store.updateProfile(draft)
                    showChangeEmail = false
                }
            }
            .padding(DS.Space.screen)
            .background(Color.qBackground)
            .navigationTitle("Change email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showChangeEmail = false }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(28)
    }

    // MARK: - Change Password Sheet

    private var changePasswordSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Choose a strong password with at least 8 characters.")
                    .font(.ui(15))
                    .foregroundStyle(Color.qGray)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Current password")
                        .font(.ui(13, .semibold))
                    SecureField("Current password", text: $oldPassword)
                        .queslyField(fill: .qField)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("New password")
                        .font(.ui(13, .semibold))
                    SecureField("New password", text: $newPassword)
                        .queslyField(fill: .qField)
                }

                Spacer()

                GreenButton(title: "Save new password", isEnabled: newPassword.count >= 6) {
                    showChangePassword = false
                }
            }
            .padding(DS.Space.screen)
            .background(Color.qBackground)
            .navigationTitle("Change password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showChangePassword = false }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(28)
    }

    // MARK: - Helpers

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
}
