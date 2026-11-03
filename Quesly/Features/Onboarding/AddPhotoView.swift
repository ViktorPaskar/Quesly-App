import SwiftUI
import PhotosUI

/// Onboarding step 1 (right after the first answer): add a photo so friends recognise you.
/// Only the photo is asked here; name, bio and links wait for the profile nudge later.
struct AddPhotoView: View {
    @Environment(AppStore.self) private var store
    @State private var photoItem: PhotosPickerItem?
    @State private var isImporting = false

    private var hasPhoto: Bool { store.myPhoto != nil }

    var body: some View {
        ZStack {
            Color.qBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                StepDots(current: 0, total: 3, onDark: false)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DS.Space.screen)
                    .padding(.top, 20)

                Spacer(minLength: 12)

                PhotosPicker(selection: $photoItem, matching: .images) {
                    ZStack(alignment: .bottomTrailing) {
                        Avatar(user: store.me, size: 132, isSticker: true)
                            .opacity(isImporting ? 0.5 : 1)
                        Image(systemName: hasPhoto ? "pencil" : "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.qGreen)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.qLime))
                            .overlay(Circle().strokeBorder(Color.qBackground, lineWidth: 3))
                    }
                }
                .buttonStyle(.pressable)
                .accessibilityLabel(hasPhoto ? "Change photo" : "Choose a photo")

                Text("Add a photo")
                    .font(.display(28, .medium))
                    .foregroundStyle(Color.qInk)
                    .padding(.top, 24)
                Text("So your friends know it’s you when your answer shows up in their feed.")
                    .font(.ui(15))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.qGray)
                    .padding(.horizontal, 36)
                    .padding(.top, 8)

                Spacer(minLength: 12)

                VStack(spacing: 4) {
                    if hasPhoto {
                        LimeButton(title: "Continue") { finish() }
                    } else {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Text("Choose a photo")
                                .font(.ui(17, .semibold))
                                .foregroundStyle(Color.qGreen)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Capsule().fill(Color.qLime))
                        }
                        .buttonStyle(.pressable)
                    }
                    Button(hasPhoto ? "Choose another" : "Not now") {
                        if hasPhoto { store.removePhoto() } else { finish() }
                    }
                    .font(.ui(16))
                    .foregroundStyle(Color.qGray)
                    .frame(height: DS.hitTarget)
                }
                .padding(.horizontal, DS.Space.screen)
                .padding(.bottom, 10)
            }
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            isImporting = true
            Task {
                defer { isImporting = false }
                if let data = try? await item.loadTransferable(type: Data.self) {
                    withAnimation(.qSpring) { store.setPhoto(data) }
                }
            }
        }
        .sensoryFeedback(.success, trigger: hasPhoto) { _, now in now }
    }

    private func finish() {
        withAnimation(.qSmooth) { store.finishPhotoStep() }
    }
}
