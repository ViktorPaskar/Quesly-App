import SwiftUI
import Observation

enum FeedScope: String, CaseIterable, Identifiable {
    case world = "World"
    case friends = "Friends"
    var id: String { rawValue }
}

/// Single source of truth for the app. Currently backed by `MockData` + local persistence;
/// swap the bodies of the mutating methods for API calls when the backend is ready.
@MainActor
@Observable
final class AppStore {
    static let maxAnswerLength = 200

    // MARK: State

    private(set) var isSignedIn = false
    var me: AppUser = MockData.me
    private(set) var users: [String: AppUser] = [:]
    private(set) var followingIds: Set<String> = []
    private(set) var todayAnswers: [Answer] = []
    private(set) var myAnswers: [Answer] = []
    private(set) var notifications: [AppNotification] = []
    private(set) var todayQuestion: DailyQuestion = MockData.questions[0]

    var remindersEnabled = true { didSet { persist(); NotificationScheduler.reschedule(store: self) } }
    var reminderTime: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: .now) ?? .now {
        didSet { persist(); NotificationScheduler.reschedule(store: self) }
    }
    var isPrivateAccount = false { didSet { persist() } }

    private var isRestoring = false
    private let defaultsKey = "quesly.snapshot.v1"

    init() {
        users = Dictionary(uniqueKeysWithValues: MockData.users.map { ($0.id, $0) })
        refreshDay()
        restore()
    }

    // MARK: Day rotation

    /// Picks today's question and reloads the day's feed. Call when the app becomes active.
    func refreshDay(now: Date = .now) {
        let question = Self.question(for: now)
        guard question.id != todayQuestion.id || todayAnswers.isEmpty else { return }
        todayQuestion = question
        let saved = Set(todayAnswers.filter(\.isSaved).map(\.id))
        todayAnswers = MockData.answers(for: question, now: now).map { answer in
            var a = answer
            if saved.contains(a.id) { a.isSaved = true }
            return a
        }
        if notifications.isEmpty { notifications = MockData.notifications(now: now) }
    }

    static func question(for date: Date) -> DailyQuestion {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return MockData.questions[day % MockData.questions.count]
    }

    static func nextQuestionDate(after date: Date = .now) -> Date {
        let cal = Calendar.current
        return cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: date)) ?? date
    }

    /// "14h" / "35m" until the next question drops.
    static func timeLeftString(now: Date = .now) -> String {
        let seconds = max(0, nextQuestionDate(after: now).timeIntervalSince(now))
        let hours = Int(seconds) / 3600
        if hours >= 1 { return "\(hours)h" }
        return "\(max(1, Int(seconds) / 60))m"
    }

    // MARK: Auth

    func signUp(username: String, email: String) {
        me.username = username.trimmingCharacters(in: .whitespaces)
        me.email = email.trimmingCharacters(in: .whitespaces)
        if myAnswers.isEmpty { myAnswers = MockData.myHistory() }
        isSignedIn = true
        persist()
        NotificationScheduler.requestAuthorization(store: self)
    }

    func signIn(email: String) {
        if !email.isEmpty { me.email = email }
        if myAnswers.isEmpty { myAnswers = MockData.myHistory() }
        isSignedIn = true
        persist()
        NotificationScheduler.requestAuthorization(store: self)
    }

    func signOut() {
        isSignedIn = false
        persist()
    }

    func deleteAccount() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        me = MockData.me
        myAnswers = []
        followingIds = MockData.followingIds
        isSignedIn = false
    }

    // MARK: Answers

    var todaysAnswer: Answer? {
        myAnswers.first { $0.questionId == todayQuestion.id && Calendar.current.isDateInToday($0.createdAt) }
    }

    var hasAnsweredToday: Bool { todaysAnswer != nil }

    func submitAnswer(_ text: String) {
        let trimmed = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxAnswerLength))
        guard !trimmed.isEmpty, !hasAnsweredToday else { return }
        let answer = Answer(
            id: UUID().uuidString,
            questionId: todayQuestion.id,
            questionText: todayQuestion.text,
            authorId: me.id,
            text: trimmed,
            createdAt: .now,
            isPinned: true
        )
        myAnswers.insert(answer, at: 0)
        notifications.insert(.init(id: UUID().uuidString, kind: .posted, actorId: nil,
                                   message: "Your new Answer was posted!", date: .now), at: 0)
        persist()
        NotificationScheduler.reschedule(store: self)
    }

    func feed(_ scope: FeedScope) -> [Answer] {
        var others = todayAnswers
        if scope == .friends { others = others.filter { followingIds.contains($0.authorId) } }
        if let mine = todaysAnswer { return [mine] + others }
        return others
    }

    func answers(of userId: String) -> [Answer] {
        if userId == me.id { return myAnswers }
        return todayAnswers.filter { $0.authorId == userId }
    }

    var savedAnswers: [Answer] { (todayAnswers + myAnswers).filter(\.isSaved) }

    func user(_ id: String) -> AppUser? { id == me.id ? me : users[id] }

    func toggleReaction(_ kind: ReactionKind, on answerId: String) {
        mutateAnswer(answerId) { a in
            if a.myReactions.contains(kind) {
                a.myReactions.remove(kind)
                a.reactions[kind] = max(0, a.count(kind) - 1)
            } else {
                a.myReactions.insert(kind)
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

    var followingUsers: [AppUser] { followingIds.compactMap { users[$0] }.sorted { $0.username < $1.username } }
    /// Mock: everyone who is not followed back is shown as a follower.
    var followerUsers: [AppUser] { users.values.sorted { $0.username < $1.username } }

    func updateProfile(_ updated: AppUser) {
        me = updated
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

    private var weekendsAnswered: Int {
        let cal = Calendar.current
        let weekends = myAnswers.filter { cal.isDateInWeekend($0.createdAt) }
            .map { cal.dateInterval(of: .weekOfYear, for: $0.createdAt)?.start ?? $0.createdAt }
        return Set(weekends).count
    }

    private var reactedCount: Int {
        todayAnswers.filter { !$0.myReactions.isEmpty }.count
    }

    var achievements: [Achievement] {
        let answered = myAnswers.count
        return [
            .init(id: "crown", title: "The Crowned One", subtitle: "Given by Quesly for exceptional impact",
                  symbol: "crown.fill", color: Color(hex: 0xE2A72E), progress: me.badge == .gold ? 1 : 0, goal: 1, isSpecial: true),
            .init(id: "first", title: "The First Step", subtitle: "You answered your first question",
                  symbol: "figure.walk", color: Color(hex: 0x7ED321), progress: min(answered, 1), goal: 1),
            .init(id: "streak3", title: "Consistent Soul", subtitle: "You answered 3 days in a row",
                  symbol: "3.circle.fill", color: Color(hex: 0xF5A623), progress: min(streak, 3), goal: 3),
            .init(id: "vibe", title: "Vibe Connector", subtitle: "Invited 10 friends to join Quesly",
                  symbol: "hand.wave.fill", color: Color(hex: 0xE84FA5), progress: 7, goal: 10),
            .init(id: "streak14", title: "Steady Flow", subtitle: "You answered 14 days in a row",
                  symbol: "14.circle.fill", color: Color(hex: 0x8CA6C9), progress: min(streak, 14), goal: 14),
            .init(id: "weekend", title: "Weekend Reflector", subtitle: "Answered on 5 different weekends",
                  symbol: "leaf.fill", color: Color(hex: 0xB0643A), progress: min(weekendsAnswered, 5), goal: 5),
            .init(id: "voice", title: "Thoughtful Voice", subtitle: "Answered 30 questions total",
                  symbol: "30.circle.fill", color: Color(hex: 0xB8B8B8), progress: min(answered, 30), goal: 30),
            .init(id: "support", title: "Community Supporter", subtitle: "Reacted to 100 different people's answers",
                  symbol: "heart.fill", color: Color(hex: 0xB8B8B8), progress: min(reactedCount, 100), goal: 100),
            .init(id: "story", title: "Storyteller", subtitle: "Shared 10 answers to your stories",
                  symbol: "square.and.arrow.up.fill", color: Color(hex: 0xB8B8B8), progress: 0, goal: 10),
            .init(id: "early", title: "Early Adopter", subtitle: "Joined Quesly in its first year",
                  symbol: "sparkles", color: Color(hex: 0xB8B8B8), progress: 1, goal: 1),
        ]
    }

    // MARK: Persistence

    private struct Snapshot: Codable {
        var isSignedIn: Bool
        var me: AppUser
        var followingIds: Set<String>
        var myAnswers: [Answer]
        var savedIds: Set<String>
        var reactions: [String: Set<ReactionKind>]
        var remindersEnabled: Bool
        var reminderTime: Date
        var isPrivateAccount: Bool
    }

    private func persist() {
        guard !isRestoring else { return }
        var reactions: [String: Set<ReactionKind>] = [:]
        for a in todayAnswers where !a.myReactions.isEmpty { reactions[a.id] = a.myReactions }
        let snapshot = Snapshot(
            isSignedIn: isSignedIn, me: me, followingIds: followingIds, myAnswers: myAnswers,
            savedIds: Set(todayAnswers.filter(\.isSaved).map(\.id)), reactions: reactions,
            remindersEnabled: remindersEnabled, reminderTime: reminderTime, isPrivateAccount: isPrivateAccount
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func restore() {
        isRestoring = true
        defer { isRestoring = false }
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let s = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            followingIds = MockData.followingIds
            return
        }
        isSignedIn = s.isSignedIn
        me = s.me
        followingIds = s.followingIds
        myAnswers = s.myAnswers
        remindersEnabled = s.remindersEnabled
        reminderTime = s.reminderTime
        isPrivateAccount = s.isPrivateAccount
        for i in todayAnswers.indices {
            let id = todayAnswers[i].id
            todayAnswers[i].isSaved = s.savedIds.contains(id)
            if let mine = s.reactions[id] {
                for kind in mine where !todayAnswers[i].myReactions.contains(kind) {
                    todayAnswers[i].reactions[kind] = todayAnswers[i].count(kind) + 1
                }
                todayAnswers[i].myReactions = mine
            }
        }
    }
}
