import SwiftUI

struct ArchiveView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case yours = "Your Answers"
        case saved = "Saved Answers"
        var id: String { rawValue }
    }

    @Environment(AppStore.self) private var store
    @State private var tab: Tab = .yours

    var body: some View {
        let items = tab == .yours ? store.myAnswers : store.savedAnswers
        VStack(spacing: 0) {
            Text("Archive")
                .font(.quesly(18, .medium))
                .foregroundStyle(Color.qInk)
                .padding(.vertical, 12)

            UnderlineTabs(items: Tab.allCases, selection: $tab, title: \.rawValue)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { answer in
                        AnswerCard(answer: answer, showsQuestion: true, showsAuthor: tab == .saved)
                        Divider().padding(.leading, 16)
                    }
                    if items.isEmpty {
                        ContentUnavailableView(
                            tab == .yours ? "No answers yet" : "Nothing saved",
                            systemImage: tab == .yours ? "text.bubble" : "bookmark",
                            description: Text(tab == .yours
                                              ? "Your answers will live here, day after day."
                                              : "Tap the bookmark on any answer to keep it here.")
                        )
                        .padding(.top, 60)
                    }
                }
            }
        }
        .background(Color.white)
        .toolbar(.hidden, for: .navigationBar)
    }
}
