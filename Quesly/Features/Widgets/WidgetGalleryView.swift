import SwiftUI

/// Debug/screenshot screen: the real widget views (from `Shared/`) at Home and Lock Screen sizes,
/// so CI can verify them visually — the simulator can't screenshot a widget on the Home Screen.
struct WidgetGalleryView: View {
    private let answered = QuestionWidgetModel.placeholder
    private var waiting: QuestionWidgetModel {
        var m = QuestionWidgetModel.placeholder
        m.answered = false
        m.friendsAnswered = 0
        return m
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                caption("Home Screen")
                HStack(spacing: DS.Space.m) {
                    tile { QuestionWidgetSmallView(model: waiting) }
                    tile { QuestionWidgetSmallView(model: answered) }
                }
                tile(width: 338) { QuestionWidgetMediumView(model: answered) }
                tile(width: 338) { QuestionWidgetMediumView(model: waiting) }

                caption("Lock Screen").padding(.top, DS.Space.s)
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
        .background(Color.qField.ignoresSafeArea())
    }

    private func caption(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.ui(13, .semibold))
            .foregroundStyle(Color.qGray)
    }

    /// Home Screen widget frame: brand green, 22 pt corners, system content margins.
    private func tile<Content: View>(width: CGFloat = 161, @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(DS.Space.m)
            .frame(width: width, height: 161)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(WidgetPalette.green))
    }
}
