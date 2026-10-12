import SwiftUI
import UIKit

/// "Instant Story Export": renders the answer as a 9:16 card for Instagram / TikTok stories.
struct ShareStorySheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    let answer: Answer

    @State private var rendered: UIImage?

    var body: some View {
        let card = StoryCard(answer: answer, author: store.user(answer.authorId))

        VStack(spacing: 20) {
            HStack {
                Text("Share as story").font(.quesly(17, .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.qGray.opacity(0.5))
                }
                .accessibilityLabel("Close")
            }

            card
                .frame(width: 270, height: 480)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)

            Spacer(minLength: 0)

            if let rendered {
                ShareLink(item: Image(uiImage: rendered),
                          preview: SharePreview("Quesly answer", image: Image(uiImage: rendered))) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.quesly(16, .semibold))
                        .foregroundStyle(Color.qGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(Color.qLime))
                }
                Button {
                    UIImageWriteToSavedPhotosAlbum(rendered, nil, nil, nil)
                    dismiss()
                } label: {
                    Text("Save to Photos")
                        .font(.quesly(15, .medium))
                        .foregroundStyle(Color.qGreen)
                        .frame(height: 44)
                }
            }
        }
        .padding(20)
        .onAppear {
            let renderer = ImageRenderer(content: card.frame(width: 360, height: 640))
            renderer.scale = max(displayScale, 3)
            rendered = renderer.uiImage
        }
    }
}

struct StoryCard: View {
    let answer: Answer
    let author: AppUser?

    var body: some View {
        ZStack {
            BrandGradientBackground(animate: true)
            VStack(spacing: 0) {
                QueslyLogo(height: 16, background: .clear)
                    .padding(.top, 36)
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    Text(answer.questionText.uppercased())
                        .font(.quesly(14, .bold))
                        .foregroundStyle(Color.qGreen)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.qLime)
                    Text(answer.text)
                        .font(.quesly(17))
                        .foregroundStyle(Color.qInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .padding(.bottom, 20)
                    HStack(spacing: 8) {
                        Avatar(user: author, size: 24)
                        Text("@\(author?.username ?? "")")
                            .font(.quesly(12, .semibold))
                            .foregroundStyle(Color.qGreen)
                    }
                    .padding([.horizontal, .bottom], 16)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 24)
                Spacer()
                Text("ONE QUESTION A DAY. MILLIONS OF STORIES")
                    .font(.quesly(9, .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 32)
            }
        }
    }
}
