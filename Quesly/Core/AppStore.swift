import SwiftUI
import UIKit
import Observation
import WidgetKit

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
    nonisolated static let defaultsKey = "quesly.snapshot.v3"

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
    /// Fresh installs treat older seed notifications as already seen, so "unread" stays meaningful.
    private(set) var notificationsSeenAt: Date = Date.now.addingTimeInterval(-50 * 60)

    // Feed loading / error state (the API seam: today everything is local and instant).
    private(set) var isLoadingFeed = false
    private(set) var feedError: String?
    /// The signed-in user's photo, stored on disk (Documents/avatar.jpg).
    private(set) var myPhoto: UIImage?

    var remindersEnabled = true { didSet { persist(); NotificationScheduler.reschedule(store: self) } }
    var reminderTime: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: .now) ?? .now {
        didSet { persist(); NotificationScheduler.reschedule(store: self) }
    }
    var isPrivateAccount = false { didSet { persist() } }
    /// Visibility pre-selected in the composer (remembers the last choice).
    var defaultVisibility: AnswerVisibility = .everyone { didSet { persist() } }

    /// When the feed should play its "unlocked" moment (set right after posting). Transient.
    var unlockCelebrationAt: Date?
    /// Days kept alive by a streak freeze (start of day).
    private(set) var frozenDays: Set<Date> = []
    /// Freezes in stock: one is earned every 7-day streak, at most `maxFreezes`.
    private(set) var streakFreezes = 1
    nonisolated static let maxFreezes = 2
    /// Set when a freeze was spent automatically; the feed shows a one-time note.
    var freezeJustUsed: Date?

    /// Friends whose answer was opened in the stories viewer today. Transient.
    private(set) var seenStoryAuthorIds: Set<String> = []

    @ObservationIgnored private var isRestoring = false

    init() {
        users = Dictionary(uniqueKeysWithValues: MockData.users.map { ($0.id, $0) })
        followingIds = MockData.followingIds
        refreshDay()
        restore()
        applyStreakFreezeIfNeeded()
        myPhoto = Self.loadPhoto()
        if let error = DemoConfig.forcedFeedError { feedError = error }
    }

    /// Simulates a network refresh. Replace the body with the real API call.
    func reloadFeed() async {
        isLoadingFeed = true
        feedError = nil
        try? await Task.sleep(for: .milliseconds(700))
        refreshDay()
        isLoadingFeed = false
    }

    // MARK: Profile photo

    private static var photoURL: URL {
        URL.documentsDirectory.appending(path: "avatar.jpg")
    }

    private static func loadPhoto() -> UIImage? {
        guard let data = try? Data(contentsOf: photoURL) else { return nil }
        return UIImage(data: data)
    }

    /// Downscales to 512 px, stores as JPEG and publishes the new photo.
    func setPhoto(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        let side: CGFloat = 512
        let scale = min(1, side / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        try? resized.jpegData(compressionQuality: 0.85)?.write(to: Self.photoURL, options: .atomic)
        myPhoto = resized
    }

    func removePhoto() {
        try? FileManager.default.removeItem(at: Self.photoURL)
        myPhoto = nil
    }

    // MARK: Answer draft (survives app restarts)

    private var draftKey: String { "quesly.draft." + todayQuestion.id }

    var draft: String {
        get { UserDefaults.standard.string(forKey: draftKey) ?? "" }
        set {
            if newValue.isEmpty { UserDefaults.standard.removeObject(forKey: draftKey) }
            else { UserDefaults.standard.set(newValue, forKey: draftKey) }
        }
    }

    // MARK: Day rotation

    /// Picks today's question and reloads the day's feed. Call when the app becomes active.
    func refreshDay(now: Date = .now) {
        let question = Self.question(for: now)
        guard question.id != todayQuestion.id || todayAnswers.isEmpty else { return }
        todayQuestion = question
        todayAnswers = MockData.answers(for: question, now: now)
        if notifications.isEmpty { notifications = MockData.notifications(now: now) }
        applyStreakFreezeIfNeeded(now: now)
        publishWidget()
    }

    nonisolated static func question(for date: Date) -> DailyQuestion {
        MockData.questions[QuestionBank.index(for: date)]
    }

    nonisolated static func nextQuestionDate(after date: Date = .now) -> Date {
        QuestionBank.nextQuestionDate(after: date)
    }

    /// "14h" / "35m" until the next question drops.
    nonisolated static func timeLeftString(now: Date = .now) -> String {
        QuestionBank.timeLeftString(now: now)
    }

    // MARK: Auth & onboarding

    func signUp(username: String, email: String) {
        me.username = username.trimmingCharacters(in: .whitespaces)
        me.email = email.trimmingCharacters(in: .whitespaces)
        seedHistoryIfNeeded()
        onboarding = .findFriends
        isSignedIn = true
        persist()
    }

    func signIn(email: String) {
        if !email.isEmpty { me.email = email }
        seedHistoryIfNeeded()
        onboarding = .done
        isSignedIn = true
        persist()
        NotificationScheduler.reschedule(store: self)
    }

    private func seedHistoryIfNeeded() {
        guard myAnswers.isEmpty else { return }
        myAnswers = MockData.myHistory()
        frozenDays = MockData.myFrozenDays()
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
        removePhoto()
        me = MockData.me
        myAnswers = []
        frozenDays = []
        streakFreezes = 1
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
        draft = ""
        myAnswers.insert(answer, at: 0)
        // Every full week of answers earns a freeze for a future missed day.
        if streak > 0, streak % 7 == 0, streakFreezes < Self.maxFreezes { streakFreezes += 1 }
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

    // MARK: Friends today (stories row)

    /// One answer per friend who answered today; unseen first.
    var friendStories: [Answer] {
        var authors = Set<String>()
        let unique = todayAnswers.filter {
            followingIds.contains($0.authorId) && !blockedIds.contains($0.authorId) && authors.insert($0.authorId).inserted
        }
        return unique.filter { !seenStoryAuthorIds.contains($0.authorId) }
            + unique.filter { seenStoryAuthorIds.contains($0.authorId) }
    }

    var friendsAnsweredToday: [AppUser] { friendStories.compactMap { users[$0.authorId] } }

    func markStorySeen(_ authorId: String) {
        seenStoryAuthorIds.insert(authorId)
    }

    /// Mock "people answered today" counter for social proof. Replace with the API value.
    var answeredTodayCount: Int {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return 9_000 + (day * 7_919) % 6_000 + todayAnswers.count + (hasAnsweredToday ? 1 : 0)
    }

    func answers(of userId: String) -> [Answer] {
        if userId == me.id { return myAnswers }
        return todayAnswers.filter { $0.authorId == userId }
    }

    func answer(_ id: String) -> Answer? {
        myAnswers.first { $0.id == id } ?? todayAnswers.first { $0.id == id }
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

    /// Answers the viewer reposted to their profile.
    var resharedAnswers: [Answer] {
        todayAnswers.filter { $0.isResharedByMe && !blockedIds.contains($0.authorId) }
    }

    /// Reposts someone's answer to your profile (or takes it back). The author is not told who.
    func toggleReshare(_ answerId: String) {
        mutateAnswer(answerId) { a in
            a.isResharedByMe.toggle()
            a.reshareCount = max(0, a.reshares + (a.isResharedByMe ? 1 : -1))
        }
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

    /// Who reacted to one of my answers. Mock: real reactors from notifications, padded with
    /// other users so the list matches the totals. Replace with an API call.
    struct Reactor: Identifiable {
        let user: AppUser
        let kind: ReactionKind
        var id: String { user.id }
    }

    func reactors(for answer: Answer) -> [Reactor] {
        var result: [Reactor] = []
        var used = Set<String>()
        for n in notifications where n.answerId == answer.id && n.kind == .reaction {
            if let id = n.actorId, let u = users[id], let r = n.reaction, !used.contains(id) {
                result.append(Reactor(user: u, kind: r)); used.insert(id)
            }
        }
        let pool = users.values.sorted { $0.username < $1.username }.filter { !used.contains($0.id) }
        var i = 0
        for kind in answer.topReactions {
            let have = result.filter { $0.kind == kind }.count
            let target = max(have, min(answer.count(kind), have + 6))
            for _ in have..<target where i < pool.count {
                result.append(Reactor(user: pool[i], kind: kind)); i += 1
            }
        }
        return result
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

    /// Consecutive answered days ending today (or yesterday). Frozen days keep the chain but don't count.
    var streak: Int {
        let cal = Calendar.current
        let days = answeredDays
        var day = cal.startOfDay(for: .now)
        if !days.contains(day) { day = cal.date(byAdding: .day, value: -1, to: day) ?? day }
        var count = 0
        while days.contains(day) || frozenDays.contains(day) {
            if days.contains(day) { count += 1 }
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return count
    }

    var answeredDays: Set<Date> {
        let cal = Calendar.current
        return Set(myAnswers.map { cal.startOfDay(for: $0.createdAt) })
    }

    /// If yesterday was missed but the day before kept the streak alive, spend a freeze on yesterday.
    func applyStreakFreezeIfNeeded(now: Date = .now) {
        let cal = Calendar.current
        guard isSignedIn, streakFreezes > 0,
              let yesterday = cal.date(byAdding: .day, value: -1, to: cal.startOfDay(for: now)),
              let dayBefore = cal.date(byAdding: .day, value: -1, to: yesterday) else { return }
        let days = answeredDays
        guard !days.contains(yesterday), !frozenDays.contains(yesterday),
              days.contains(dayBefore) || frozenDays.contains(dayBefore) else { return }
        frozenDays.insert(yesterday)
        streakFreezes -= 1
        freezeJustUsed = yesterday
        persist()
    }

    /// Answer for a calendar day, for Memories.
    func myAnswer(on day: Date) -> Answer? {
        myAnswers.first { Calendar.current.isDate($0.createdAt, inSameDayAs: day) }
    }

    // MARK: Widget

    /// Writes what the Home/Lock Screen widget shows; reloads it only when something changed.
    func publishWidget() {
        let friends = friendsAnsweredToday
        let snapshot = WidgetSnapshot(
            day: Calendar.current.startOfDay(for: .now), isSignedIn: isSignedIn,
            answeredToday: hasAnsweredToday, streak: streak,
            friendsAnswered: friends.count, friendNames: friends.prefix(2).map(\.username))
        if WidgetBridge.save(snapshot) {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetBridge.widgetKind)
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
                  icon: .starFill, color: Color(hex: 0x7ED321), progress: min(answered, 1), goal: 1),
            .init(id: "streak3", title: "Consistent Soul", subtitle: "You answered 3 days in a row",
                  icon: .fireFill, color: Color(hex: 0xF5A623), progress: min(streak, 3), goal: 3),
            .init(id: "vibe", title: "Vibe Connector", subtitle: "Invited 10 friends to join Quesly",
                  icon: .smileyFill, color: Color(hex: 0xE84FA5), progress: 7, goal: 10),
            .init(id: "streak14", title: "Steady Flow", subtitle: "You answered 14 days in a row",
                  icon: .sparkleFill, color: Color(hex: 0x6F8FC0), progress: min(streak, 14), goal: 14),
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
        /// Reposted answer ids (kept under the old "saved" name so older installs restore).
        var savedIds: Set<String>
        var reactions: [String: ReactionKind]
        var remindersEnabled: Bool
        var reminderTime: Date
        var isPrivateAccount: Bool
        var defaultVisibility: AnswerVisibility
        var notificationsSeenAt: Date
        var frozenDays: Set<Date>
        var streakFreezes: Int
    }

    private func persist() {
        guard !isRestoring else { return }
        var reactions: [String: ReactionKind] = [:]
        for a in todayAnswers { if let r = a.myReaction { reactions[a.id] = r } }
        let snapshot = Snapshot(
            isSignedIn: isSignedIn, onboarding: onboarding, me: me, followingIds: followingIds,
            blockedIds: blockedIds, myAnswers: myAnswers,
            savedIds: Set(todayAnswers.filter(\.isResharedByMe).map(\.id)), reactions: reactions,
            remindersEnabled: remindersEnabled, reminderTime: reminderTime, isPrivateAccount: isPrivateAccount,
            defaultVisibility: defaultVisibility, notificationsSeenAt: notificationsSeenAt,
            frozenDays: frozenDays, streakFreezes: streakFreezes
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
        publishWidget()
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
        frozenDays = s.frozenDays
        streakFreezes = s.streakFreezes
        for i in todayAnswers.indices {
            let id = todayAnswers[i].id
            todayAnswers[i].isResharedByMe = s.savedIds.contains(id)
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
