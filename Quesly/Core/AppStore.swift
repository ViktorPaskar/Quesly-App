import SwiftUI
import Observation

enum FeedScope: String, CaseIterable, Identifiable {
    case world = "World"
    case friends = "Friends"
    var id: String { rawValue }
}

enum OnboardingStep: String, Codable {
    case findFriends, notifications, done
}

/// Single source of truth for the app. Currently backed by `MockData` + local persistence;
/// swap the bodies of the mutating methods for API calls when the backend is ready.
@MainActor
@Observable
final class AppStore {
    nonisolated static let maxAnswerLength = 200
    nonisolated static let defaultsKey = "quesly.snapshot.v2"

    // MARK: State

    private(set) var isSignedIn = false
    private(set) var onboarding: OnboardingStep = .done
    var me: AppUser = MockData.me
    private(set) var users: [String: AppUser] = [:]
    private(set) var followingIds: Set<String> = []
    private(set) var blockedIds: Set<String> = []
    private(set) var todayAnswers: [Answer] = []
    private(set) var myAnswers: [Answer] = []
    private(set) var notifications: [AppNotification] = []
    private(set) var todayQuestion: DailyQuestion = MockData.questions[0]
    private(set) var notificationsSeenAt: Date = .distantPast

    var remindersEnabled = true { didSet { persist(); NotificationScheduler.reschedule(store: self) } }
    var reminderTime: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: .now) ?? .now {
        didSet { persist(); NotificationScheduler.reschedule(store: self) }
    }
    var isPrivateAccount = false { didSet { persist() } }
    /// Visibility pre-selected in the composer (remembers the last choice).
    var defaultVisibility: AnswerVisibility = .everyone { didSet { persist() } }

    @ObservationIgnored private var isRestoring = false

    init() {
        users = Dictionary(uniqueKeysWithValues: MockData.users.map { ($0.id, $0) })
        followingIds = MockData.followingIds
        refreshDay()
        restore()
    }

    // MARK: Day rotation

    /// Picks today's question and reloads the day's feed. Call when the app becomes active.
    func refreshDay(now: Date = .now) {
        let question = Self.question(for: now)
        guard question.id != todayQuestion.id || todayAnswers.isEmpty else { return }
        todayQuestion = question
        todayAnswers = MockData.answers(for: question, now: now)
        if notifications.isEmpty { notifications = MockData.notifications(now: now) }
    }

    nonisolated static func question(for date: Date) -> DailyQuestion {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return MockData.questions[day % MockData.questions.count]
    }

    nonisolated static func nextQuestionDate(after date: Date = .now) -> Date {
        let cal = Calendar.current
        return cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: date)) ?? date
    }

    /// "14h" / "35m" until the next question drops.
    nonisolated static func timeLeftString(now: Date = .now) -> String {
        let seconds = max(0, nextQuestionDate(after: now).timeIntervalSince(now))
        let hours = Int(seconds) / 3600
        if hours >= 1 { return "\(hours)h" }
        return "\(max(1, Int(seconds) / 60))m"
    }

    // MARK: Auth & onboarding

    func signUp(username: String, email: String) {
        me.username = username.trimmingCharacters(in: .whitespaces)
        me.email = email.trimmingCharacters(in: .whitespaces)
        if myAnswers.isEmpty { myAnswers = MockData.myHistory() }
        onboarding = .findFriends
        isSignedIn = true
        persist()
    }

    func signIn(email: String) {
        if !email.isEmpty { me.email = email }
        if myAnswers.isEmpty { myAnswers = MockData.myHistory() }
        onboarding = .done
        isSignedIn = true
        persist()
        NotificationScheduler.reschedule(store: self)
    }

    func finishFindFriends() {
        onboarding = .notifications
        persist()
    }

    /// Called from the priming screen; only then does iOS show the system prompt.
    func finishNotificationPriming(enable: Bool) {
        remindersEnabled = enable
        if enable { NotificationScheduler.requestAuthorization(store: self) }
        onboarding = .done
        persist()
    }

    func signOut() {
        isSignedIn = false
        persist()
    }

    func deleteAccount() {
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
        me = MockData.me
        myAnswers = []
        followingIds = MockData.followingIds
        blockedIds = []
        onboarding = .done
        isSignedIn = false
    }

    // MARK: Answers

    var todaysAnswer: Answer? {
        myAnswers.first { $0.questionId == todayQuestion.id && Calendar.current.isDateInToday($0.createdAt) }
    }

    var hasAnsweredToday: Bool { todaysAnswer != nil }

    func submitAnswer(_ text: String, visibility: AnswerVisibility? = nil) {
        let trimmed = Self.clean(text)
        guard !trimmed.isEmpty, !hasAnsweredToday else { return }
        let answer = Answer(
            id: UUID().uuidString,
            questionId: todayQuestion.id,
            questionText: todayQuestion.text,
            authorId: me.id,
            text: trimmed,
            createdAt: .now,
            isPinned: true,
            visibility: visibility ?? defaultVisibility
        )
        if let visibility { defaultVisibility = visibility }
        myAnswers.insert(answer, at: 0)
        notifications.insert(.init(id: UUID().uuidString, kind: .posted, actorId: nil,
                                   message: "Your new answer was posted!", date: .now), at: 0)
        persist()
        NotificationScheduler.reschedule(store: self)
    }

    /// Edits are allowed for a few minutes after posting (typos happen).
    func editAnswer(_ id: String, text: String) {
        let trimmed = Self.clean(text)
        guard !trimmed.isEmpty, let i = myAnswers.firstIndex(where: { $0.id == id }),
              myAnswers[i].isEditable() else { return }
        myAnswers[i].text = trimmed
        myAnswers[i].isEdited = true
        persist()
    }

    private static func clean(_ text: String) -> String {
        String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxAnswerLength))
    }

    func feed(_ scope: FeedScope) -> [Answer] {
        var others = todayAnswers.filter { !blockedIds.contains($0.authorId) }
        switch scope {
        case .friends:
            others = others.filter { followingIds.contains($0.authorId) }
        case .world:
            // Friends-only answers appear in World only for people who follow the author.
            others = others.filter { $0.visibility == .everyone || followingIds.contains($0.authorId) }
        }
        if let mine = todaysAnswer { return [mine] + others }
        return others
    }

    func answers(of userId: String) -> [Answer] {
        if userId == me.id { return myAnswers }
        return todayAnswers.filter { $0.authorId == userId }
    }

    func answer(_ id: String) -> Answer? {
        myAnswers.first { $0.id == id } ?? todayAnswers.first { $0.id == id }
    }

    var savedAnswers: [Answer] {
        (todayAnswers + myAnswers).filter { $0.isSaved && !blockedIds.contains($0.authorId) }
    }

    func user(_ id: String) -> AppUser? { id == me.id ? me : users[id] }

    /// Sets the viewer's reaction. Picking the current reaction again removes it.
    func react(_ kind: ReactionKind, on answerId: String) {
        mutateAnswer(answerId) { a in
            if let old = a.myReaction { a.reactions[old] = max(0, a.count(old) - 1) }
            if a.myReaction == kind {
                a.myReaction = nil
            } else {
                a.myReaction = kind
                a.reactions[kind] = a.count(kind) + 1
            }
        }
    }

    func toggleSave(_ answerId: String) {
        mutateAnswer(answerId) { $0.isSaved.toggle() }
    }

    func deleteAnswer(_ answerId: String) {
        myAnswers.removeAll { $0.id == answerId }
        persist()
    }

    private func mutateAnswer(_ id: String, _ change: (inout Answer) -> Void) {
        if let i = todayAnswers.firstIndex(where: { $0.id == id }) { change(&todayAnswers[i]) }
        if let i = myAnswers.firstIndex(where: { $0.id == id }) { change(&myAnswers[i]) }
        persist()
    }

    // MARK: Social

    func isFollowing(_ userId: String) -> Bool { followingIds.contains(userId) }

    func toggleFollow(_ userId: String) {
        if followingIds.contains(userId) {
            followingIds.remove(userId)
            users[userId]?.followers -= 1
        } else {
            followingIds.insert(userId)
            users[userId]?.followers += 1
        }
        persist()
    }

    var followingUsers: [AppUser] {
        followingIds.compactMap { users[$0] }.sorted { $0.username.lowercased() < $1.username.lowercased() }
    }

    /// Mock: people who appear in notifications as followers plus a few others.
    var followerUsers: [AppUser] {
        users.values.filter { !blockedIds.contains($0.id) }.sorted { $0.username.lowercased() < $1.username.lowercased() }
    }

    /// People you don't follow yet, most active first.
    var suggestedUsers: [AppUser] {
        users.values
            .filter { !followingIds.contains($0.id) && !blockedIds.contains($0.id) }
            .sorted { $0.followers > $1.followers }
    }

    func searchUsers(_ query: String) -> [AppUser] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return users.values
            .filter { $0.username.lowercased().contains(q) && !blockedIds.contains($0.id) }
            .sorted { $0.username < $1.username }
    }

    func updateProfile(_ updated: AppUser) {
        me = updated
        persist()
    }

    // MARK: Moderation

    func report(_ answerId: String, reason: ReportReason) {
        // TODO: send to moderation API. Locally we just hide nothing — the answer stays until reviewed.
        _ = (answerId, reason)
    }

    func block(_ userId: String) {
        blockedIds.insert(userId)
        followingIds.remove(userId)
        persist()
    }

    func unblock(_ userId: String) {
        blockedIds.remove(userId)
        persist()
    }

    // MARK: Notifications

    /// Reactions on the same answer are collapsed into a single row ("Anna and 3 others…").
    var groupedNotifications: [NotificationGroup] {
        var groups: [NotificationGroup] = []
        var indexByAnswer: [String: Int] = [:]
        for n in notifications.sorted(by: { $0.date > $1.date }) {
            if let actor = n.actorId, blockedIds.contains(actor) { continue }
            if n.kind == .reaction, let answerId = n.answerId {
                if let i = indexByAnswer[answerId] {
                    if let actor = n.actorId, !groups[i].actorIds.contains(actor) { groups[i].actorIds.append(actor) }
                    if let r = n.reaction, !groups[i].reactions.contains(r) { groups[i].reactions.append(r) }
                    continue
                }
                indexByAnswer[answerId] = groups.count
            }
            groups.append(NotificationGroup(
                id: n.id, kind: n.kind, actorIds: n.actorId.map { [$0] } ?? [],
                reactions: n.reaction.map { [$0] } ?? [], answerId: n.answerId,
                message: n.message, date: n.date))
        }
        return groups
    }

    var unreadNotifications: Int {
        groupedNotifications.filter { $0.date > notificationsSeenAt }.count
    }

    func markNotificationsSeen() {
        notificationsSeenAt = .now
        persist()
    }

    // MARK: Stats & achievements

    var streak: Int {
        let cal = Calendar.current
        let days = Set(myAnswers.map { cal.startOfDay(for: $0.createdAt) })
        var day = cal.startOfDay(for: .now)
        if !days.contains(day) { day = cal.date(byAdding: .day, value: -1, to: day) ?? day }
        var count = 0
        while days.contains(day) {
            count += 1
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }

    struct WeekDay { let date: Date; let answered: Bool; let isToday: Bool }

    /// Monday…Sunday of the current week with whether the user answered that day.
    var currentWeek: [WeekDay] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let today = cal.startOfDay(for: .now)
        let start = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let answeredDays = Set(myAnswers.map { cal.startOfDay(for: $0.createdAt) })
        return (0..<7).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            return WeekDay(date: day, answered: answeredDays.contains(day), isToday: day == today)
        }
    }

    private var weekendsAnswered: Int {
        let cal = Calendar.current
        let weekends = myAnswers.filter { cal.isDateInWeekend($0.createdAt) }
            .map { cal.dateInterval(of: .weekOfYear, for: $0.createdAt)?.start ?? $0.createdAt }
        return Set(weekends).count
    }

    private var reactedCount: Int {
        todayAnswers.filter { $0.myReaction != nil }.count
    }

    var achievements: [Achievement] {
        let answered = myAnswers.count
        return [
            .init(id: "crown", title: "The Crowned One", subtitle: "Given by Quesly for exceptional impact",
                  icon: .crownSimpleFill, color: Color(hex: 0xE2A72E), progress: me.badge == .gold ? 1 : 0, goal: 1, isSpecial: true),
            .init(id: "first", title: "The First Step", subtitle: "You answered your first question",
                  icon: .footprintsFill, color: Color(hex: 0x7ED321), progress: min(answered, 1), goal: 1),
            .init(id: "streak3", title: "Consistent Soul", subtitle: "You answered 3 days in a row",
                  icon: .fireFill, color: Color(hex: 0xF5A623), progress: min(streak, 3), goal: 3),
            .init(id: "vibe", title: "Vibe Connector", subtitle: "Invited 10 friends to join Quesly",
                  icon: .handWavingFill, color: Color(hex: 0xE84FA5), progress: 7, goal: 10),
            .init(id: "streak14", title: "Steady Flow", subtitle: "You answered 14 days in a row",
                  icon: .lightningFill, color: Color(hex: 0x6F8FC0), progress: min(streak, 14), goal: 14),
            .init(id: "weekend", title: "Weekend Reflector", subtitle: "Answered on 5 different weekends",
                  icon: .leafFill, color: Color(hex: 0xB0643A), progress: min(weekendsAnswered, 5), goal: 5),
            .init(id: "voice", title: "Thoughtful Voice", subtitle: "Answered 30 questions total",
                  icon: .chatCircleTextFill, color: Color(hex: 0x3BA3A0), progress: min(answered, 30), goal: 30),
            .init(id: "support", title: "Community Supporter", subtitle: "Reacted to 100 different people's answers",
                  icon: .heartFill, color: Color(hex: 0xE5484D), progress: min(reactedCount, 100), goal: 100),
            .init(id: "story", title: "Storyteller", subtitle: "Shared 10 answers to your stories",
                  icon: .shareNetworkFill, color: Color(hex: 0x9B5CF6), progress: 0, goal: 10),
            .init(id: "early", title: "Early Adopter", subtitle: "Joined Quesly in its first year",
                  icon: .sparkleFill, color: Color(hex: 0x07583D), progress: 1, goal: 1),
        ]
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var isSignedIn: Bool
        var onboarding: OnboardingStep
        var me: AppUser
        var followingIds: Set<String>
        var blockedIds: Set<String>
        var myAnswers: [Answer]
        var savedIds: Set<String>
        var reactions: [String: ReactionKind]
        var remindersEnabled: Bool
        var reminderTime: Date
        var isPrivateAccount: Bool
        var defaultVisibility: AnswerVisibility
        var notificationsSeenAt: Date
    }

    private func persist() {
        guard !isRestoring else { return }
        var reactions: [String: ReactionKind] = [:]
        for a in todayAnswers { if let r = a.myReaction { reactions[a.id] = r } }
        let snapshot = Snapshot(
            isSignedIn: isSignedIn, onboarding: onboarding, me: me, followingIds: followingIds,
            blockedIds: blockedIds, myAnswers: myAnswers,
            savedIds: Set(todayAnswers.filter(\.isSaved).map(\.id)), reactions: reactions,
            remindersEnabled: remindersEnabled, reminderTime: reminderTime, isPrivateAccount: isPrivateAccount,
            defaultVisibility: defaultVisibility, notificationsSeenAt: notificationsSeenAt
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    private func restore() {
        isRestoring = true
        defer { isRestoring = false }
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let s = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        isSignedIn = s.isSignedIn
        onboarding = s.onboarding
        me = s.me
        followingIds = s.followingIds
        blockedIds = s.blockedIds
        myAnswers = s.myAnswers
        remindersEnabled = s.remindersEnabled
        reminderTime = s.reminderTime
        isPrivateAccount = s.isPrivateAccount
        defaultVisibility = s.defaultVisibility
        notificationsSeenAt = s.notificationsSeenAt
        for i in todayAnswers.indices {
            let id = todayAnswers[i].id
            todayAnswers[i].isSaved = s.savedIds.contains(id)
            let seeded = todayAnswers[i].myReaction
            let restored = s.reactions[id]
            if seeded != restored {
                if let old = seeded { todayAnswers[i].reactions[old] = max(0, todayAnswers[i].count(old) - 1) }
                if let new = restored { todayAnswers[i].reactions[new] = todayAnswers[i].count(new) + 1 }
                todayAnswers[i].myReaction = restored
            }
        }
    }
}
