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
                VStack(spacing: 16) {
                    Text("How would you rate your experience\nwith Quesly?")
                        .font(.ui(16, .medium))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { i in
                            Button { rating = i } label: {
                                Icon(.starFill, size: 32)
                                    .foregroundStyle(i <= rating ? Color.qBrandText : Color.qLine)
                                    .scaleEffect(i <= rating ? 1.1 : 1)
                                    .animation(.qSpring.delay(Double(i) * 0.04), value: rating)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(i) stars")
                        }
                    }
                    .sensoryFeedback(.selection, trigger: rating)
                }
                Divider()

                VStack(spacing: 16) {
                    Text("What would you like to see improved?").font(.ui(16, .medium))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
                        ForEach(allTopics, id: \.self) { topic in
                            let on = topics.contains(topic)
                            Button {
                                if on { topics.remove(topic) } else { topics.insert(topic) }
                            } label: {
                                Text(topic)
                                    .font(.ui(13, .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .foregroundStyle(on ? .white : Color.qBrandText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(Capsule().fill(on ? Color.qGreen : Color.qBackground))
                                    .overlay(Capsule().stroke(Color.qBrandText, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Divider()

                VStack(spacing: 12) {
                    Text("Anything else you'd like to tell us? (not required)").font(.ui(16, .medium))
                    TextField("Start typing here", text: $message, axis: .vertical)
                        .font(.ui(16))
                        .lineLimit(8...12)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: DS.Radius.m).stroke(Color.qLine))
                }

                GreenButton(title: "Send", isEnabled: rating > 0) { sent = true }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.qBackground)
        .queslyBackHeader("Feedback")
        .alert("Thank you! 💚", isPresented: $sent) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your feedback helps us make Quesly better.")
        }
    }
}
