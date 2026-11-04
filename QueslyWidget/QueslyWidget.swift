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

/// Tells a style view whether it is drawn in the medium size.
struct WidgetSizeReader<Content: View>: View {
    @Environment(\.widgetFamily) private var family
    @ViewBuilder let content: (Bool) -> Content

    var body: some View { content(family == .systemMedium) }
}

/// Paper keeps the original kind, so widgets people already placed carry over. It also owns the Lock Screen sizes.
struct PaperEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuestionEntry

    var body: some View {
        content
            .containerBackground(for: .widget) {
                if family == .systemSmall || family == .systemMedium { Color.white } else { Color.clear }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryRectangular: QuestionWidgetRectangularView(model: entry.model)
        case .accessoryCircular: QuestionWidgetCircularView(model: entry.model)
        case .accessoryInline: QuestionWidgetInlineView(model: entry.model)
        case .systemMedium: PaperWidgetView(model: entry.model, isMedium: true)
        default: PaperWidgetView(model: entry.model)
        }
    }
}

struct PaperWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetBridge.widgetKind, provider: QuestionProvider()) { entry in
            PaperEntryView(entry: entry)
        }
        .configurationDisplayName("Paper")
        .description("Just today's question. After you answer, your own words.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct BrightWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetBridge.brightKind, provider: QuestionProvider()) { entry in
            WidgetSizeReader { BrightWidgetView(model: entry.model, isMedium: $0) }
                .containerBackground(entry.model.answered ? WidgetPalette.mint : WidgetPalette.lime, for: .widget)
        }
        .configurationDisplayName("Bright")
        .description("Today's question on lime. Turns mint once you've answered.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetBridge.streakKind, provider: QuestionProvider()) { entry in
            WidgetSizeReader { StreakWidgetView(model: entry.model, isMedium: $0) }
                .containerBackground(WidgetPalette.flame, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Your streak, big, and how long is left to answer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct QueslyWidgetBundle: WidgetBundle {
    var body: some Widget {
        PaperWidget()
        BrightWidget()
        StreakWidget()
    }
}
