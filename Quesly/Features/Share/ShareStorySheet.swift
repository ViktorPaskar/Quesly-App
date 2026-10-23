import SwiftUI
import UIKit

/// "Instant Story Export": renders the answer as a 9:16 card for Instagram / TikTok stories.
struct ShareStorySheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    let answer: Answer

    @State private var theme: StoryCard.Theme = .green
    @State private var rendered: UIImage?
    @State private var appeared = false
    @State private var savedToPhotos = false

    private static let canvas = CGSize(width: 360, height: 640)

    var body: some View {
        let card = StoryCard(answer: answer, author: store.user(answer.authorId), theme: theme)

        VStack(spacing: 20) {
            HStack {
                Text("Share as story").font(.ui(20, .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Icon(.xCircleFill, size: 30)
                        .foregroundStyle(Color.qGray.opacity(0.45))
                }
                .accessibilityLabel("Close")
            }

            card
                .frame(width: Self.canvas.width, height: Self.canvas.height)
                .scaleEffect(0.72)
                .frame(width: Self.canvas.width * 0.72, height: Self.canvas.height * 0.72)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).stroke(Color.qLine, lineWidth: 1))
                .rotation3DEffect(.degrees(appeared ? 0 : 12), axis: (x: 1, y: 0, z: 0))
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)
                .id(theme)
                .transition(.opacity)

            HStack(spacing: 12) {
                ForEach(StoryCard.Theme.allCases) { t in
                    Button {
                        withAnimation(.qSpring) { theme = t }
                    } label: {
                        Circle()
                            .fill(t.swatch)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.qLine, lineWidth: 1))
                            .padding(4)
                            .overlay(Circle().stroke(theme == t ? Color.qBrandText : .clear, lineWidth: 2.5))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("\(t.rawValue) theme")
                }
            }
            .sensoryFeedback(.selection, trigger: theme)

            Spacer(minLength: 0)

            if let rendered {
                ShareLink(item: Image(uiImage: rendered),
                          preview: SharePreview("My Quesly answer", image: Image(uiImage: rendered))) {
                    Text("Share to stories")
                        .font(.ui(17, .semibold))
                        .foregroundStyle(Color.qGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Capsule().fill(Color.qLime))
                }
                .buttonStyle(.pressable)
                Button {
                    UIImageWriteToSavedPhotosAlbum(rendered, nil, nil, nil)
                    withAnimation(.qSpring) { savedToPhotos = true }
                } label: {
                    Text(savedToPhotos ? "Saved to Photos" : "Save to Photos")
                        .font(.ui(16, .medium))
                        .foregroundStyle(Color.qBrandText)
                        .frame(height: 44)
                }
                .disabled(savedToPhotos)
                .sensoryFeedback(.success, trigger: savedToPhotos)
            }
        }
        .padding(20)
        .onAppear {
            render()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) { appeared = true }
        }
        .onChange(of: theme) { _, _ in
            savedToPhotos = false
            render()
        }
    }

    private func render() {
        let renderer = ImageRenderer(content:
            StoryCard(answer: answer, author: store.user(answer.authorId), theme: theme)
                .frame(width: Self.canvas.width, height: Self.canvas.height))
        renderer.scale = max(displayScale, 3)
        rendered = renderer.uiImage
    }
}

/// The exported 9:16 story card: flat brand colour, logo, question and the answer card.
struct StoryCard: View {
    enum Theme: String, CaseIterable, Identifiable {
        case green = "Green", lime = "Lime", light = "Light"
        var id: String { rawValue }

        var background: Color {
            switch self {
            case .green: return .qGreen
            case .lime: return .qLime
            case .light: return Color(hex: 0xF4F7F5)
            }
        }
        var ink: Color { self == .green ? .white : .qGreen }
        var swatch: Color { background }
    }

    let answer: Answer
    let author: AppUser?
    var theme: Theme = .green

    var body: some View {
        ZStack {
            theme.background

            VStack(alignment: .leading, spacing: 0) {
                QueslyLogo(height: 18, markColor: theme == .lime ? .qGreen : .qLime, textColor: theme.ink,
                           background: .clear)
                    .padding(.top, 52)

                Spacer()

                Text("TODAY'S QUESTION")
                    .font(.custom("Outfit-Bold", fixedSize: 12))
                    .foregroundStyle(theme == .green ? Color.qLime : Color.qGreen.opacity(0.75))
                    .padding(.bottom, 12)
                Text(answer.questionText.uppercased())
                    .font(.custom("Outfit-ExtraBold", fixedSize: 26))
                    .foregroundStyle(theme.ink)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 16) {
                    Text(answer.text)
                        .font(.custom("Outfit-Medium", fixedSize: 21))
                        .foregroundStyle(Color.qInk)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 12) {
                        Avatar(user: author, size: 30)
                        Text("@\(author?.username ?? "")")
                            .font(.custom("Outfit-SemiBold", fixedSize: 15))
                            .foregroundStyle(Color.qGreen)
                        Spacer()
                        Text(answer.createdAt.formatted(.dateTime.day().month(.abbreviated)))
                            .font(.custom("Outfit-Regular", fixedSize: 13))
                            .foregroundStyle(Color.qGray)
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(.white))

                Spacer()

                HStack(spacing: 8) {
                    Text("Answer yourself on Quesly")
                        .font(.custom("Outfit-SemiBold", fixedSize: 15))
                    Icon(.arrowUpRightBold, size: 15)
                }
                .foregroundStyle(theme == .green ? Color.qGreen : Color.qLime)
                .padding(.horizontal, 20)
                .frame(height: 42)
                .background(Capsule().fill(theme == .green ? Color.qLime : Color.qGreen))
                .padding(.bottom, 52)
            }
            .padding(.horizontal, 28)
        }
        .clipped()
    }
}
