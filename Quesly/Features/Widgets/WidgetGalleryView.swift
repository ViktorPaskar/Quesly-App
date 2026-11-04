import SwiftUI

/// Debug/screenshot screen: the real widget views (from `Shared/`) at Home and Lock Screen sizes,
/// so CI can verify them visually — the simulator can't screenshot a widget on the Home Screen.
struct WidgetGalleryView: View {
    private let answered = QuestionWidgetModel.placeholder
    private var waiting: QuestionWidgetModel {
        var m = QuestionWidgetModel.placeholder
        m.answered = false
        m.friendsAnswered = 0
        m.myAnswer = nil
        return m
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                caption("Paper")
                HStack(spacing: DS.Space.m) {
                    tile(.white) { PaperWidgetView(model: waiting) }
                    tile(.white) { PaperWidgetView(model: answered) }
                }
                tile(.white, medium: true) { PaperWidgetView(model: waiting, isMedium: true) }

                caption("Bright")
                HStack(spacing: DS.Space.m) {
                    tile(WidgetPalette.lime) { BrightWidgetView(model: waiting) }
                    tile(WidgetPalette.mint) { BrightWidgetView(model: answered) }
                }
                tile(WidgetPalette.lime, medium: true) { BrightWidgetView(model: waiting, isMedium: true) }

                caption("Streak")
                HStack(spacing: DS.Space.m) {
                    tile(WidgetPalette.flame) { StreakWidgetView(model: waiting) }
                    tile(WidgetPalette.flame) { StreakWidgetView(model: answered) }
                }
                tile(WidgetPalette.flame, medium: true) { StreakWidgetView(model: waiting, isMedium: true) }

                caption("Lock Screen")
                VStack(alignment: .leading, spacing: DS.Space.m) {
                    QuestionWidgetInlineView(model: answered)
                        .font(.ui(15, .semibold))
                    HStack(spacing: DS.Space.m) {
                        QuestionWidgetRectangularView(model: waiting)
                            .frame(width: 170, height: 72)
                        QuestionWidgetCircularView(model: answered)
                            .frame(width: 72, height: 72)
                    }
                }
                .foregroundStyle(.white)
                .padding(DS.Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color(white: 0.12)))
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.vertical, DS.Space.l)
        }
        .background(Color(white: 0.2).ignoresSafeArea())
    }

    private func caption(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.ui(13, .semibold))
            .foregroundStyle(.white.opacity(0.7))
    }

    /// Home Screen widget frame: 22 pt corners, system content margins.
    private func tile<Content: View>(_ background: Color, medium: Bool = false, @ViewBuilder _ content: () -> Content) -> some View {
        content()
                        .padding(DS.Space.m)
            .frame(width: medium ? 338 : 161, height: 161)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(background))
    }
}
