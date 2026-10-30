import SwiftUI
import PhotosUI

/// Clean, editorial profile editor with Apple HIG & Threads design excellence:
/// - Inset grouped form with clear, elegant rows
/// - Subtle floating camera trigger
/// - Clean inline counter without harsh red alert colors
/// - Native Apple Form styling without cheap gray input blocks
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
            VStack(spacing: DS.Space.xl) {
                // Avatar Photo Section
                avatarSection
                    .padding(.top, DS.Space.xs)

                // Public Profile Information (Clean Grouped Card)
                profileCard

                // Social Links
                socialCard

                // Private Details
                privateInfoCard

                // Account & Security Section
                accountCard

                // Save Action
                GreenButton(title: "Save changes", isEnabled: isValid) {
                    store.updateProfile(draft)
                    dismiss()
                }
                .padding(.top, DS.Space.xs)
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.bottom, 100)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.qCanvas)
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
                ZStack(alignment: .bottomTrailing) {
                    Avatar(user: draft, size: 88)
                        .overlay {
                            if isImporting {
                                Circle().fill(.black.opacity(0.35))
                                ProgressView().tint(.white)
                            }
                        }

                    // Camera Badge
                    Circle()
                        .fill(Color.qGreen)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Icon(.cameraFill, size: 13)
                                .foregroundStyle(Color.white)
                        )
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }
            .accessibilityLabel("Change photo")

            HStack(spacing: DS.Space.m) {
                PhotosPicker("Change photo", selection: $photoItem, matching: .images)
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Color.qBrandText)

                if store.myPhoto != nil {
                    Button("Remove", role: .destructive) {
                        withAnimation(.qSmooth) { store.removePhoto() }
                    }
                    .font(.ui(14, .semibold))
                }
            }

            if let importError {
                Text(importError)
                    .font(.ui(12))
                    .foregroundStyle(Color.qFlame)
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            importPhoto(item)
        }
    }

    // MARK: - Profile Information (Public Info)

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            sectionHeader("PUBLIC INFORMATION")

            VStack(spacing: 0) {
                // Name Row
                formRow(title: "Name") {
                    TextField("Your name", text: Binding(get: { draft.name ?? "" }, set: { draft.name = $0 }))
                        .textContentType(.name)
                        .font(.ui(15))
                        .foregroundStyle(Color.qInk)
                        .multilineTextAlignment(.trailing)
                }

                divider

                // Username Row
                formRow(title: "Username") {
                    handleField(placeholder: "username", text: $draft.username)
                }

                divider

                // Pronouns Row
                formRow(title: "Pronouns") {
                    TextField("she/her, they/them", text: $draft.pronouns)
                        .font(.ui(15))
                        .foregroundStyle(Color.qInk)
                        .multilineTextAlignment(.trailing)
                }

                divider

                // Location Row
                formRow(title: "Location") {
                    TextField("Add location", text: Binding(get: { draft.location }, set: { draft.location = $0 }))
                        .font(.ui(15))
                        .foregroundStyle(Color.qInk)
                        .multilineTextAlignment(.trailing)
                }

                divider

                // Bio Row (Expanded clean area)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("About")
                            .font(.ui(15, .medium))
                            .foregroundStyle(Color.qInk)
                        Spacer()
                        Text("\(draft.bio.count)/\(AppUser.bioLimit)")
                            .font(.ui(12))
                            .foregroundStyle(draft.bio.count >= AppUser.bioLimit ? Color.qFlame : Color.qGray)
                            .monospacedDigit()
                    }

                    TextField("Write a short bio…", text: $draft.bio, axis: .vertical)
                        .font(.ui(14))
                        .foregroundStyle(Color.qInk)
                        .lineLimit(3...5)
                        .lineSpacing(3)
                        .onChange(of: draft.bio) { _, text in
                            if text.count > AppUser.bioLimit {
                                draft.bio = String(text.prefix(AppUser.bioLimit))
                            }
                        }
                }
                .padding(DS.Space.m)
            }
            .background(cardBackground)
        }
    }

    // MARK: - Social Media Handles

    private var socialCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            sectionHeader("SOCIAL PROFILES")

            VStack(spacing: 0) {
                // Instagram
                formRow(icon: .instagram, iconTint: Color(hex: 0xE1306C), title: "Instagram") {
                    handleField(placeholder: "instagram_handle", text: $draft.instagram)
                }

                divider

                // TikTok
                formRow(icon: .tiktok, iconTint: Color.qInk, title: "TikTok") {
                    handleField(placeholder: "tiktok_handle", text: $draft.tiktok)
                }

                divider

                // Threads
                formRow(icon: .threads, iconTint: Color.qInk, title: "Threads") {
                    handleField(placeholder: "threads_handle", text: $draft.threads)
                }

                divider

                // Twitter / X
                formRow(icon: .xTwitter, iconTint: Color.qInk, title: "X (Twitter)") {
                    handleField(placeholder: "twitter_handle", text: $draft.twitter)
                }
            }
            .background(cardBackground)
        }
    }

    // MARK: - Private Information

    private var privateInfoCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack {
                sectionHeader("PRIVATE INFORMATION")
                Spacer()
                HStack(spacing: 4) {
                    Icon(.lockSimpleFill, size: 10)
                    Text("Only visible to you")
                }
                .font(.ui(11))
                .foregroundStyle(Color.qGray)
                .padding(.trailing, 4)
            }

            VStack(spacing: 0) {
                // Birthday
                formRow(title: "Birthday") {
                    TextField("Month Day, Year", text: $draft.birthday)
                        .font(.ui(15))
                        .foregroundStyle(Color.qInk)
                        .multilineTextAlignment(.trailing)
                }

                divider

                // Gender
                formRow(title: "Gender") {
                    TextField("Female, Male, Non-binary…", text: $draft.gender)
                        .font(.ui(15))
                        .foregroundStyle(Color.qInk)
                        .multilineTextAlignment(.trailing)
                }
            }
            .background(cardBackground)
        }
    }

    private func formRow<Content: View>(
        icon: QIcon? = nil,
        iconTint: Color = .qInk,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: icon == nil ? DS.Space.m : DS.Space.s) {
            if let icon {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconTint.opacity(0.12))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Icon(icon, size: 14)
                            .foregroundStyle(iconTint)
                    )
            }

            Text(title)
                .font(.ui(15, .medium))
                .foregroundStyle(Color.qInk)
                .frame(width: icon == nil ? 80 : 95, alignment: .leading)

            content()
        }
        .padding(.horizontal, DS.Space.m)
        .frame(minHeight: 52)
    }

    private func handleField(placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 2) {
            Spacer(minLength: 8)
            Text("@")
                .font(.ui(15))
                .foregroundStyle(Color.qGray)
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.ui(15))
                .foregroundStyle(Color.qInk)
                .multilineTextAlignment(.trailing)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.ui(11, .semibold))
            .tracking(0.6)
            .foregroundStyle(Color.qGray)
            .padding(.leading, 4)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.qBlock)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.qLine, lineWidth: 1)
            )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.qLine)
            .frame(height: 1)
            .padding(.leading, DS.Space.m)
    }

    // MARK: - Account & Security Section

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text("ACCOUNT & SECURITY")
                .font(.ui(11, .semibold))
                .tracking(0.6)
                .foregroundStyle(Color.qGray)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Email
                HStack(spacing: DS.Space.s) {
                    Icon(.paperPlaneTiltFill, size: 16)
                        .foregroundStyle(Color.qGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email")
                            .font(.ui(12))
                            .foregroundStyle(Color.qGray)
                        Text(store.me.email)
                            .font(.ui(14, .medium))
                            .foregroundStyle(Color.qInk)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button("Change") {
                        newEmail = store.me.email
                        showChangeEmail = true
                    }
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Color.qBrandText)
                }
                .padding(DS.Space.m)

                Rectangle().fill(Color.qLine).frame(height: 1).padding(.leading, DS.Space.m)

                // Password
                HStack(spacing: DS.Space.s) {
                    Icon(.lockSimpleFill, size: 16)
                        .foregroundStyle(Color.qGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Password")
                            .font(.ui(12))
                            .foregroundStyle(Color.qGray)
                        Text("••••••••••••")
                            .font(.ui(14, .medium))
                            .foregroundStyle(Color.qInk)
                    }
                    Spacer()
                    Button("Change") { showChangePassword = true }
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Color.qBrandText)
                }
                .padding(DS.Space.m)
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.qBlock)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.qLine, lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Photo import

    private func importPhoto(_ item: PhotosPickerItem) {
        isImporting = true
        importError = nil
        Task {
            defer { isImporting = false }
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    importError = "Could not load image."
                    return
                }
                store.setPhoto(data)
                draft = store.me
            } catch {
                importError = "Error loading photo."
            }
        }
    }

    // MARK: - Change Email Sheet

    private var changeEmailSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                Text("Enter your new email address. We'll send a confirmation link.")
                    .font(.ui(14))
                    .foregroundStyle(Color.qGray)

                TextField("New email", text: $newEmail)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .queslyField(fill: .qField)

                Spacer()

                GreenButton(title: "Update email", isEnabled: newEmail.contains("@") && newEmail.contains(".")) {
                    draft.email = newEmail
                    store.updateProfile(draft)
                    showChangeEmail = false
                }
            }
            .padding(DS.Space.screen)
            .navigationTitle("Change email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showChangeEmail = false }
                        .foregroundStyle(Color.qGray)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Change Password Sheet

    private var changePasswordSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                SecureField("Current password", text: $oldPassword)
                    .queslyField(fill: .qField)

                SecureField("New password", text: $newPassword)
                    .queslyField(fill: .qField)

                Text("Must be at least 8 characters.")
                    .font(.ui(12))
                    .foregroundStyle(Color.qGray)

                Spacer()

                GreenButton(title: "Update password", isEnabled: newPassword.count >= 8) {
                    showChangePassword = false
                }
            }
            .padding(DS.Space.screen)
            .navigationTitle("Change password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showChangePassword = false }
                        .foregroundStyle(Color.qGray)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
