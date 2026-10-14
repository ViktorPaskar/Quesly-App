import WidgetKit
import SwiftUI

struct QuestionEntry: TimelineEntry {
    let date: Date
    let model: QuestionWidgetModel
}

/// Refreshes hourly (the "left" countdown) and exactly at midnight, when the next question drops.
struct QuestionProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuestionEntry {
        QuestionEntry(date: .now, model: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuestionEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuestionEntry>) -> Void) {
        let now = Date.now
        let calendar = Calendar.current
        let midnight = QuestionBank.nextQuestionDate(after: now)
        var dates = [now, midnight]
        for hour in 1...6 {
            if let date = calendar.date(byAdding: .hour, value: hour, to: now), date < midnight { dates.append(date) }
        }
        let entries = dates.sorted().map(entry(at:))
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(at date: Date) -> QuestionEntry {
        QuestionEntry(date: date, model: .make(date: date, snapshot: WidgetBridge.load()))
    }
}

struct QuestionWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuestionEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                if family == .systemSmall || family == .systemMedium {
                    WidgetPalette.green
                } else {
                    Color.clear
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemMedium: QuestionWidgetMediumView(model: entry.model)
        case .accessoryRectangular: QuestionWidgetRectangularView(model: entry.model)
        case .accessoryCircular: QuestionWidgetCircularView(model: entry.model)
        case .accessoryInline: QuestionWidgetInlineView(model: entry.model)
        default: QuestionWidgetSmallView(model: entry.model)
        }
    }
}

struct QuestionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetBridge.widgetKind, provider: QuestionProvider()) { entry in
            QuestionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's question")
        .description("Today's question, your streak and how many friends already answered.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

@main
struct QueslyWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuestionWidget()
    }
}
