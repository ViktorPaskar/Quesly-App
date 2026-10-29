import SwiftUI

/// Profile "Memories": calendar of answers with interactive inspection of any day's response.
struct MemoriesCard: View {
    @Environment(AppStore.self) private var store
    @State private var monthOffset = 0
    @Binding var selectedDate: Date?
    var showsHeader = true

    private let calendar = Calendar.current
    private static let monthsBack = 12

    private var month: Date {
        let start = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        return calendar.date(byAdding: .month, value: monthOffset, to: start) ?? start
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            if showsHeader { header }
            monthBar
            MonthGrid(month: month, answered: store.answeredDays, selected: selectedDate) { day in
                withAnimation(.qSpring) {
                    if let sel = selectedDate, calendar.isDate(sel, inSameDayAs: day) {
                        selectedDate = nil
                    } else {
                        selectedDate = day
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.qBlock)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
    }

    // MARK: Parts

    private var header: some View {
        HStack(alignment: .center, spacing: DS.Space.s) {
            IconChip(icon: .fireFill, tint: .qFlame, fill: Color.qFlameSoft)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(store.streak)-day streak")
                    .font(.ui(17, .semibold))
                    .foregroundStyle(Color.qInk)
                Text(store.hasAnsweredToday ? "See you tomorrow" : "Answer today to keep it")
                    .font(.ui(13))
                    .foregroundStyle(Color.qGray)
            }
            Spacer(minLength: 0)
        }
    }

    private var answeredCountInMonth: Int {
        let cal = Calendar.current
        return store.answeredDays.filter { cal.isDate($0, equalTo: month, toGranularity: .month) }.count
    }

    private var monthBar: some View {
        HStack(spacing: 8) {
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.ui(17, .semibold))
                .foregroundStyle(Color.qInk)
                .lineLimit(1)

            if answeredCountInMonth > 0 {
                Text("\(answeredCountInMonth) answered")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Color.qBrandText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.qMint.opacity(0.35)))
            }

            Spacer(minLength: 0)
            monthButton(.caretLeftBold, label: "Previous month", enabled: monthOffset > -Self.monthsBack) { monthOffset -= 1 }
            monthButton(.caretRightBold, label: "Next month", enabled: monthOffset < 0) { monthOffset += 1 }
        }
        .padding(.top, DS.Space.xxs)
    }

    private func monthButton(_ icon: QIcon, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(.qSmooth) { action() } } label: {
            Icon(icon, size: DS.Icon.inline)
                .foregroundStyle(enabled ? Color.qGreen : Color.qGray4)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

// MARK: - Selected Day Answer Preview Card

struct DayReflectionCard: View {
    let answer: Answer
    var onDismiss: (() -> Void)? = nil
    @State private var isSharing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                IconChip(icon: .calendar, tint: .qGreen, fill: Color.qMint.opacity(0.35))
                VStack(alignment: .leading, spacing: 1) {
                    Text(answer.createdAt.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Color.qBrandText)
                    Text("Daily Reflection")
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Color.qInk)
                }

                Spacer()

                if let onDismiss {
                    Button(action: onDismiss) {
                        Icon(.xCircleFill, size: 16)
                            .foregroundStyle(Color.qGray)
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(answer.questionText)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Color.qInk2)
                    .lineLimit(2)

                Text("“\(answer.text)”")
                    .font(.display(16, .regular))
                    .foregroundStyle(Color.qInk)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.qField)
            )

            HStack {
                if answer.totalReactions > 0 {
                    HStack(spacing: 4) {
                        Icon(.heartFill, size: 12)
                            .foregroundStyle(Color.qPink)
                        Text("\(answer.totalReactions)")
                            .font(.ui(12, .semibold))
                            .foregroundStyle(Color.qGray)
                    }
                }

                Spacer()

                Button { isSharing = true } label: {
                    HStack(spacing: 4) {
                        Icon(.paperPlaneTiltFill, size: 11)
                        Text("Share to Peeks")
                            .font(.ui(12.5, .semibold))
                    }
                    .foregroundStyle(Color.qGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.qMint.opacity(0.28)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.qBlock)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.qLine, lineWidth: 1)
                )
        )
        .sheet(isPresented: $isSharing) {
            ShareStorySheet(answer: answer).presentationDetents([.large])
        }
    }
}

// MARK: - Month grid

private struct MonthGrid: View {
    let month: Date
    let answered: Set<Date>
    let selected: Date?
    let onOpen: (Date) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var days: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
    }

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
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Color.qGray)
                    .frame(height: 24)
            }
            ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 44) }
            ForEach(days, id: \.self) { day in
                DayCell(day: day,
                        state: state(for: day, today: today),
                        isToday: day == today,
                        isSelected: selected.map { calendar.isDate($0, inSameDayAs: day) } ?? false,
                        onOpen: { onOpen(day) })
            }
        }
        .id(month)
        .transition(.opacity)
    }

    private func state(for day: Date, today: Date) -> DayCell.Kind {
        if answered.contains(day) { return .answered }
        return day > today ? .future : .missed
    }
}

private struct DayCell: View {
    enum Kind { case answered, missed, future }

    let day: Date
    let state: Kind
    let isToday: Bool
    let isSelected: Bool
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
        .frame(height: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(state == .answered ? .isButton : [])
    }

    private var circle: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return ZStack {
            switch state {
            case .answered:
                shape.fill(isSelected ? Color.qGreenDeep : (isToday ? Color.qLime : Color.qGreen))
                if isToday {
                    shape.strokeBorder(Color.qGreen.opacity(0.28), lineWidth: 1)
                }
                VStack(spacing: 2) {
                    Text(number)
                        .font(.ui(13, .semibold))
                        .foregroundStyle(isToday && !isSelected ? Color.qGreen : .white)
                    Circle()
                        .fill(isToday && !isSelected ? Color.qGreen : Color.qLime)
                        .frame(width: 4, height: 4)
                }
            case .missed:
                if isToday {
                    shape.strokeBorder(Color.qGreen, lineWidth: 1.5)
                    Text(number).font(.ui(13, .semibold)).foregroundStyle(Color.qInk)
                } else {
                    shape.fill(Color.qField)
                    Text(number).font(.ui(13, .medium)).foregroundStyle(Color.qGray)
                }
            case .future:
                Text(number).font(.ui(13)).foregroundStyle(Color(hex: 0xC7C7CC))
            }
        }
        .frame(width: 36, height: 36)
        .overlay(
            isSelected
                ? RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.qGreen, lineWidth: 2)
                    .frame(width: 42, height: 42)
                : nil
        )
    }

    private var accessibilityText: String {
        let date = day.formatted(.dateTime.weekday(.wide).day().month(.wide))
        switch state {
        case .answered: return "\(date), answered. Open"
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
                    HStack(spacing: 8) {
                        Icon(.paperPlaneTiltFill, size: 14)
                        Text("Share as story")
                            .font(.ui(16, .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Capsule().fill(Color.qGreen))
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
