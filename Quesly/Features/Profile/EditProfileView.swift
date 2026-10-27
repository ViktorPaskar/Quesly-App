import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AppUser = MockData.me
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
                                Icon(.cameraFill, size: DS.Icon.caption)
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

                VStack(alignment: .leading, spacing: DS.Space.m) {
                    field("Name") {
                        TextField("Your name", text: Binding(get: { draft.name ?? "" }, set: { draft.name = $0 }))
                            .textContentType(.name)
                    }
                    field("Nickname") {
                        TextField("Nickname", text: $draft.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    field("Location") {
                        TextField("City, Country", text: $draft.location)
                    }

                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        HStack {
                            Text("About").font(.ui(13)).foregroundStyle(Color.qGray)
                            Spacer()
                            // Characters as people see them: an emoji counts as one.
                            Text("\(draft.bio.count)/\(AppUser.bioLimit)")
                                .font(.ui(13))
                                .foregroundStyle(draft.bio.count >= AppUser.bioLimit ? Color.qFlame : Color.qGray)
                                .monospacedDigit()
                        }
                        TextField("Tell people about yourself", text: $draft.bio, axis: .vertical)
                            .lineLimit(2...4)
                            .onChange(of: draft.bio) { _, new in
                                if new.count > AppUser.bioLimit { draft.bio = String(new.prefix(AppUser.bioLimit)) }
                            }
                            .font(.ui(16))
                            .padding(DS.Space.s)
                            .background(RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous).fill(Color.qField))
                    }
                }
                .padding(DS.Space.m)
                .outlinedBlock()

                GreenButton(title: "Save", isEnabled: draft.username.count >= 3) {
                    store.updateProfile(draft)
                    dismiss()
                }
                .padding(.top, DS.Space.xxs)
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.bottom, DS.Space.l)
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
            content().queslyField(fill: .qField)
        }
    }
}
