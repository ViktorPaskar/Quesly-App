import SwiftUI

/// Profile "Memories": your streak plus the month as a calendar. Answered days are filled —
/// tap one to reread that day's question and answer. Days saved by a streak freeze show ❄️.
struct MemoriesCard: View {
    @Environment(AppStore.self) private var store
    @State private var monthOffset = 0
    @State private var opened: Answer?
    @State private var showsFreezeInfo = false

    private let calendar = Calendar.current
    private static let monthsBack = 12

    private var month: Date {
        let start = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        return calendar.date(byAdding: .month, value: monthOffset, to: start) ?? start
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            header
            monthBar
            MonthGrid(month: month, answered: store.answeredDays, frozen: store.frozenDays) { day in
                opened = store.myAnswer(on: day)
            }
            legend
        }
        .padding(DS.Space.m)
        .background(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous).fill(Color.qField))
        .sheet(item: $opened) { answer in
            MemoryDetailSheet(answer: answer)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            guard DemoConfig.opensMemory, opened == nil else { return }
            opened = store.myAnswers.first { $0.id == "h2" }
        }
    }

    // MARK: Parts

    private var header: some View {
        HStack(alignment: .center, spacing: DS.Space.xs) {
            Icon(.fireFill, size: 20).foregroundStyle(Color.qFlame)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(store.streak)-day streak")
                    .font(.ui(17, .semibold))
                    .foregroundStyle(Color.qInk)
                Text(store.hasAnsweredToday ? "See you tomorrow" : "Answer today to keep it")
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
            }
            Spacer(minLength: DS.Space.xs)
            Button { showsFreezeInfo = true } label: {
                HStack(spacing: DS.Space.xxs) {
                    Icon(.snowflake, size: 13, weight: .semibold)
                    Text("\(store.streakFreezes)").font(.ui(15, .semibold))
                }
                .foregroundStyle(Color.qIce)
                .padding(.horizontal, DS.Space.s)
                .frame(height: 32)
                .background(Capsule().fill(Color.qIceSoft))
                .frame(minHeight: DS.hitTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("\(store.streakFreezes) streak freezes")
            .accessibilityHint("Explains streak freezes")
            .popover(isPresented: $showsFreezeInfo) { freezeInfo }
        }
    }

    private var freezeInfo: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            IconLabel("Streak freeze", icon: .snowflake, size: 18)
                .font(.ui(17, .semibold))
                .foregroundStyle(Color.qIce)
            Text("Miss a day and a freeze keeps your streak alive automatically. You earn one for every 7-day streak — up to \(AppStore.maxFreezes).")
                .font(.ui(15))
                .foregroundStyle(Color.qInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Space.m)
        .frame(width: 290)
        .presentationCompactAdaptation(.popover)
    }

    private var monthBar: some View {
        HStack(spacing: 0) {
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.ui(15, .semibold))
                .foregroundStyle(Color.qInk)
            Spacer()
            monthButton(.caretLeftBold, label: "Previous month", enabled: monthOffset > -Self.monthsBack) { monthOffset -= 1 }
            monthButton(.caretRightBold, label: "Next month", enabled: monthOffset < 0) { monthOffset += 1 }
        }
        .padding(.top, DS.Space.xxs)
    }

    private func monthButton(_ icon: QIcon, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.qSmooth) { action() } } label: {
            Icon(icon, size: 15)
                .foregroundStyle(enabled ? Color.qInk : Color.qGray.opacity(0.4))
                .frame(width: DS.hitTarget, height: 36)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private var legend: some View {
        HStack(spacing: DS.Space.m) {
            HStack(spacing: DS.Space.xxs) {
                Circle().fill(Color.qGreen).frame(width: 10, height: 10)
                Text("Answered")
            }
            HStack(spacing: DS.Space.xxs) {
                Icon(.snowflake, size: 11).foregroundStyle(Color.qIce)
                Text("Freeze")
            }
            Spacer()
            Text("Tap a day to reread it")
        }
        .font(.ui(12))
        .foregroundStyle(Color.qGray)
        .padding(.top, DS.Space.xxs)
        .accessibilityHidden(true)
    }
}

// MARK: - Month grid

private struct MonthGrid: View {
    let month: Date
    let answered: Set<Date>
    let frozen: Set<Date>
    let onOpen: (Date) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var days: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
    }

    /// Empty cells before the 1st, respecting the locale's first weekday.
    private var leadingBlanks: Int {
        (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    var body: some View {
        let today = calendar.startOfDay(for: .now)
        LazyVGrid(columns: columns, spacing: DS.Space.xxs) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.ui(12, .medium))
                    .foregroundStyle(Color.qGray)
                    .frame(height: 20)
            }
            ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 40) }
            ForEach(days, id: \.self) { day in
                DayCell(day: day,
                        state: state(for: day, today: today),
                        isToday: day == today,
                        onOpen: { onOpen(day) })
            }
        }
        .id(month)
        .transition(.opacity)
    }

    private func state(for day: Date, today: Date) -> DayCell.Kind {
        if answered.contains(day) { return .answered }
        if frozen.contains(day) { return .frozen }
        return day > today ? .future : .missed
    }
}

private struct DayCell: View {
    enum Kind { case answered, frozen, missed, future }

    let day: Date
    let state: Kind
    let isToday: Bool
    let onOpen: () -> Void

    private var number: String { day.formatted(.dateTime.day()) }

    var body: some View {
        Group {
            if state == .answered {
                Button(action: onOpen) { circle }
                    .buttonStyle(.pressable)
            } else {
                circle
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(state == .answered ? .isButton : [])
    }

    private var circle: some View {
        ZStack {
            switch state {
            case .answered:
                Circle().fill(Color.qGreen)
                Text(number).font(.ui(13, .semibold)).foregroundStyle(.white)
            case .frozen:
                Circle().fill(Color.qIceSoft)
                Icon(.snowflake, size: 14, weight: .semibold).foregroundStyle(Color.qIce)
            case .missed:
                Text(number).font(.ui(13)).foregroundStyle(Color.qGray)
            case .future:
                Text(number).font(.ui(13)).foregroundStyle(Color.qGray.opacity(0.45))
            }
        }
        .frame(width: 36, height: 36)
        .overlay {
            if isToday && state != .answered {
                Circle().strokeBorder(Color.qBrandText, lineWidth: 1.5)
            }
        }
    }

    private var accessibilityText: String {
        let date = day.formatted(.dateTime.weekday(.wide).day().month(.wide))
        switch state {
        case .answered: return "\(date), answered. Open"
        case .frozen: return "\(date), saved by a streak freeze"
        case .missed: return isToday ? "\(date), today, not answered yet" : "\(date), not answered"
        case .future: return date
        }
    }
}

// MARK: - Detail

/// One past day: the question, your answer and how people reacted.
struct MemoryDetailSheet: View {
    let answer: Answer
    @State private var isSharing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                IconLabel(answer.createdAt.formatted(.dateTime.weekday(.wide).day().month(.wide)),
                          icon: .calendar, size: 14)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qGray)
                Text(answer.questionText)
                    .font(.display(22, .semibold))
                    .foregroundStyle(Color.qBrandText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(answer.text)
                    .font(.ui(20))
                    .foregroundStyle(Color.qInk)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                if answer.totalReactions > 0 {
                    HStack(spacing: DS.Space.xs) {
                        HStack(spacing: -6) {
                            ForEach(answer.topReactions.prefix(3)) { ReactionSticker(kind: $0, size: 22) }
                        }
                        Text("\(answer.totalReactions) reactions")
                            .font(.ui(15))
                            .foregroundStyle(Color.qGray)
                    }
                }
                Button { isSharing = true } label: {
                    Text("Share as story")
                        .font(.ui(16, .semibold))
                        .foregroundStyle(Color.qBrandText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(Color.qMint))
                }
                .buttonStyle(.pressable)
                .padding(.top, DS.Space.xs)
            }
            .padding(.horizontal, DS.Space.screen)
            .padding(.top, DS.Space.xl)
            .padding(.bottom, DS.Space.l)
        }
        .background(Color.qSurface)
        .sheet(isPresented: $isSharing) {
            ShareStorySheet(answer: answer).presentationDetents([.large])
        }
    }
}
