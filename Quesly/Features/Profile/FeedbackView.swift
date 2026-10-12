import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rating = 0
    @State private var topics: Set<String> = []
    @State private var message = ""
    @State private var sent = false

    private let allTopics = ["Daily Questions", "Reactions", "Interface", "Notifications", "Performance", "Other"]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 14) {
                    Text("How would you rate your experience\nwith Quesly?")
                        .font(.quesly(14, .medium))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 14) {
                        ForEach(1...5, id: \.self) { i in
                            Button { rating = i } label: {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(i <= rating ? Color.qGreen : Color.qLine)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(i) stars")
                        }
                    }
                    .sensoryFeedback(.selection, trigger: rating)
                }
                Divider()

                VStack(spacing: 14) {
                    Text("What would you like to see improved?").font(.quesly(14, .medium))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
                        ForEach(allTopics, id: \.self) { topic in
                            let on = topics.contains(topic)
                            Button {
                                if on { topics.remove(topic) } else { topics.insert(topic) }
                            } label: {
                                Text(topic)
                                    .font(.quesly(11, .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .foregroundStyle(on ? .white : Color.qGreen)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 32)
                                    .background(Capsule().fill(on ? Color.qGreen : .white))
                                    .overlay(Capsule().stroke(Color.qGreen, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Divider()

                VStack(spacing: 12) {
                    Text("Anything else you'd like to tell us? (not required)").font(.quesly(14, .medium))
                    TextField("Start typing here", text: $message, axis: .vertical)
                        .font(.quesly(14))
                        .lineLimit(8...12)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.qLine))
                }

                GreenButton(title: "Send", isEnabled: rating > 0) { sent = true }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.white)
        .queslyBackHeader("Feedback")
        .alert("Thank you! 💚", isPresented: $sent) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your feedback helps us make Quesly better.")
        }
    }
}
