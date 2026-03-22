// AppStore.swift — Cloud Snapshot Version (Supabase as single source of truth)
import Foundation
import Combine
import SwiftUI
import Supabase

// MARK: - Onboarding Model (存進 Snapshot 用)
struct Onboarding: Codable {
    var perfectionismPrep: Int = 3
    var pressureNeed: Int = 3
    var anxietyStart: Int = 3
    var noPressureIdle: Int = 3
    var researchLoop: Int = 3
    var lastMinute: Int = 3
    var selfBlame: Int = 3
    var needExternalPressure: Int = 3
}

// MARK: - AppStore

// 定義語言
enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case english = "en"
    case chinese = "zh-Hant"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "繁體中文"
        }
    }
}

@MainActor
final class AppStore: ObservableObject {

    // MARK: - App State（會被 Snapshot 包起來的東西）

    @Published var goals: [Goal] = []
    @Published var tasksToday: [TaskItem] = []          // 會自動從 goals 算出來
    @Published var moods: [MoodRecord] = []
    @Published var achievements: [Achievement] = []
    @Published var activity: ActivityStats = ActivityStats()
    @Published var workstyle: Workstyle = Workstyle()
    @Published var preferences: UserPreferences = UserPreferences()
    @Published var conversations: [ChatThread] = []

    @Published var onboarding: Onboarding = Onboarding()
    @Published var hasOnboarded: Bool = false
    @Published var procrastinationType: ProcrastinationType = .unknown
    @Published var language: AppLanguage = .chinese {
        didSet {
            // 1. 存本地
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
            // 2. 更新到 preferences 結構 (為了上傳雲端)
            preferences.language = language.rawValue
            // 3. 觸發上傳
            Task { await saveSnapshotToCloud() }
        }
    }

    /// 目前登入中的 Supabase user id（字串）
    @Published private(set) var activeUserId: String? = nil

    @Published var isSyncing: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    // 雲端 Snapshot 持久層
    private let persistence = Persistence()

    // MARK: - Init

    init() {
        setupDerived()
        // ❌ 不在 init 做任何雲端讀寫，全部交給 AuthViewModel / ContentView 決定何時切換使用者
    }

    // MARK: - 把現在的 state → Snapshot

    private func makeSnapshot() -> Persistence.Snapshot {
        Persistence.Snapshot(
            goals: goals,
            tasksToday: tasksToday,
            moods: moods,
            achievements: achievements,
            activity: activity,
            workstyle: workstyle,
            preferences: preferences,
            onboarding: onboarding,
            hasOnboarded: hasOnboarded,
            procrastinationType: procrastinationType,
            conversations: conversations
        )
    }

    // MARK: - 把 Snapshot 套回 state

    private func apply(snapshot: Persistence.Snapshot) {
        self.goals = snapshot.goals
        self.moods = snapshot.moods
        self.achievements = snapshot.achievements
        self.activity = snapshot.activity
        self.workstyle = snapshot.workstyle
        self.preferences = snapshot.preferences
        self.onboarding = snapshot.onboarding
        self.hasOnboarded = snapshot.hasOnboarded
        self.procrastinationType = snapshot.procrastinationType
        self.conversations = snapshot.conversations

        // ⚠️ tasksToday 不直接用 snapshot 這個欄位，
        // 每次都「用 goals + 今天日期」重新算一次，避免不同版本不一致
        refreshTasksTodayFromGoals()

        if let savedLang = AppLanguage(rawValue: snapshot.preferences.language) {
            self.language = savedLang
        }

        print("📥 apply snapshot: goals=\(goals.count), moods=\(moods.count)")
    }

    // MARK: - 依 goals 自動更新今天的 tasksToday

    private func refreshTasksTodayFromGoals(for date: Date = Date()) {
        let all = goals.flatMap { $0.subTasks }
        let todays = all.filter { task in
            guard let d = task.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: date)
        }
        self.tasksToday = todays
    }

    // MARK: - 手動切換使用者（登入 / 自動登入 / 登出 都用這個）

    /// 切換目前 AppStore 綁定的使用者，並從 Supabase 載入 / 套用 Snapshot
    func switchUser(to userId: String?) async {
        if let userId {
            print("👤 [AppStore.switchUser] switched to uid=\(userId)")
        } else {
            print("👤 [AppStore.switchUser] switched to no user (empty state)")
        }

        self.activeUserId = userId

        if let uid = userId {
            // 從 Supabase 載入這個 user 的 snapshot
            let snapshot = await persistence.load(for: uid)
            self.apply(snapshot: snapshot)
        } else {
            // 沒有 user → 套用空狀態
            self.apply(snapshot: Persistence.empty)
        }
    }

    // 如果你在某些地方想「硬重置 app 狀態」，可以用這個
    func resetToEmptyState() {
        print("🧼 AppStore.resetToEmptyState")
        self.activeUserId = nil
        self.apply(snapshot: Persistence.empty)
    }

    // MARK: - 把目前 state 儲存回 Supabase snapshot

    func saveSnapshotToCloud() async {
        // ⛔️ 沒有 activeUserId 就不要存，避免用空 snapshot 覆蓋雲端
        guard let uid = activeUserId, !uid.isEmpty else {
            print("⛔️ saveSnapshotToCloud: no active user id, skip")
            return
        }

        let snapshot = makeSnapshot()
        print("☁️ saveSnapshotToCloud: saving snapshot for user_id=\(uid) (goals=\(goals.count), moods=\(moods.count))")
        await persistence.save(snapshot: snapshot, for: uid)
        print("✅ saveSnapshotToCloud: done for user_id=\(uid)")
    }

    // MARK: - Domain Logic（所有變動都順便更新 snapshot）

    func addMood(score: Int, note: String) {
        let m = MoodRecord(moodScore: score, note: note)
        moods.append(m)

        Task { [weak self] in
            await self?.saveSnapshotToCloud()
        }
    }

    func addGoal(_ goal: Goal) {
        goals.append(goal)
        refreshTasksTodayFromGoals()

        Task { [weak self] in
            await self?.saveSnapshotToCloud()
        }
    }

    /// 勾 / 取消勾 任務：本地狀態 + Snapshot + 單筆 Task 同步到 Supabase
    func toggleTask(_ id: UUID) {
        guard
            let gi = goals.firstIndex(where: { $0.subTasks.contains(where: { $0.id == id }) }),
            let ti = goals[gi].subTasks.firstIndex(where: { $0.id == id })
        else {
            print("⚠️ toggleTask 找不到對應的 goal / task，id=\(id)")
            return
        }

        // 1. 本地更新
        goals[gi].subTasks[ti].isCompleted.toggle()

        // 2. 用最新 goals 再算一次今天任務
        refreshTasksTodayFromGoals()

        // 3. 拿出剛改完的 task & goalId
        let updatedTask = goals[gi].subTasks[ti]
        let goalId = goals[gi].id
        let goal   = goals[gi]

        // 4. 同步到雲端：snapshot + 單筆 task
        // 4. 同步到雲端：snapshot + 單筆 task
        Task { [weak self] in
            guard let self else { return }

            await self.saveSnapshotToCloud()
            try? await SupabaseRepository.shared.upsertTask(updatedTask, goalId: goalId)

            // ⭐ 如果這是社群目標，計算完成比例，更新到 group_participants.progress
            if goal.isGroupGoal, let groupId = goal.groupId {
                let allTasks = goal.subTasks
                let total = allTasks.count
                let completed = allTasks.filter { $0.isCompleted }.count

                print("📊 [toggleTask] group goal: total=\(total), completed=\(completed)")

                guard total > 0 else {
                    print("⚠️ [toggleTask] total tasks == 0, skip score update")
                    return
                }

                // ✅ 這裡改成「完成比例」0.0 ~ 1.0
                let completionRatio = Double(completed) / Double(total)
                print("📊 [toggleTask] completionRatio=\(completionRatio)")

                do {
                    let session = try await SupabaseManager.shared.client.auth.session
                    guard let email = session.user.email, !email.isEmpty else {
                        print("⚠️ [toggleTask] no email in session user")
                        return
                    }

                    try await SupabaseRepository.shared.updateGroupParticipantProgress(
                        groupId: groupId,
                        email: email,
                        progress: completionRatio      // ✅ 寫入比例
                    )
                    print("✅ [toggleTask] updated progress=\(completionRatio) for \(email)")
                } catch {
                    print("❌ [toggleTask] failed to update progress:", error)
                }
            }
        }


            }

    func upsertThread(_ thread: ChatThread) {
        if let idx = conversations.firstIndex(where: { $0.id == thread.id }) {
            conversations[idx] = thread
        } else {
            conversations.insert(thread, at: 0)
        }

        Task { [weak self] in
            await self?.saveSnapshotToCloud()
        }
    }

    func deleteThreads(at offsets: IndexSet) {
        conversations.remove(atOffsets: offsets)

        Task { [weak self] in
            await self?.saveSnapshotToCloud()
        }
    }

    // ✅ 提供給 Profile / Onboarding 用的「存到雲端」方法（另外那張 user_profile 資料表）
    func saveProfileToCloud() {
        Task {
            do {
                try await SupabaseRepository.shared.upsertUserProfile(from: self)
                print("✅ saveProfileToCloud 成功")
            } catch {
                print("❌ saveProfileToCloud 失敗：\(error)")
            }
        }
    }

    // MARK: - Derived Logic（例如依 tasksToday 自動更新 activity）

    private func setupDerived() {
        $tasksToday
            .sink { [weak self] tasks in
                guard let self = self else { return }

                let completed = tasks.filter { $0.isCompleted }.count
                self.activity.weekCompletedCount = completed

                Task { [weak self] in
                    await self?.saveSnapshotToCloud()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - 如果你想在設定畫面做「手動同步」按鈕

    func pushAllToCloud() async {
        isSyncing = true
        defer { isSyncing = false }
        await saveSnapshotToCloud()
    }
}
// MARK: - Group Goals Sync (from Supabase)

extension AppStore {

    /// 把 "yyyy-MM-dd" 的字串轉成 Date
    fileprivate func parseYyyyMMdd(_ s: String?) -> Date? {
        guard let s, !s.isEmpty else { return nil }
        return DateFormatter.isoDate.date(from: s)
    }

    /// 從 Supabase 抓 group goals 並同步到本地 snapshot
    func syncGroupGoalsFromCloud(forEmail email: String) async {
        guard let uid = activeUserId, !uid.isEmpty else {
            print("⛔️ syncGroupGoalsFromCloud: no activeUserId, skip")
            return
        }

        print("☁️ syncGroupGoalsFromCloud 開始，email=\(email)")

        do {
            let rows = try await SupabaseRepository.shared.fetchGroupGoals(forEmail: email)

            let existingGroupIds = Set(
                goals.filter { $0.isGroupGoal }.compactMap { $0.groupId }
            )

            var added = 0

            for row in rows {
                if existingGroupIds.contains(row.id) {
                    continue
                }

                let startDate = parseYyyyMMdd(row.start_date)
                let deadline  = parseYyyyMMdd(row.deadline)

                let newGoal = Goal(
                    id: UUID(),
                    title: row.title,
                    icon: row.icon ?? "person.3.fill",
                    colorHex: row.color_hex ?? "#B8C0FF",
                    startDate: startDate,
                    deadline: deadline,
                    reminders: [],
                    subTasks: [],
                    createdAt: Date(),
                    isGroupGoal: true,
                    groupId: row.id,
                    participantEmails: [],              // 之後可補 fetchParticipants
                    socialModeRaw: row.social_mode
                )

                self.addGoal(newGoal)
                added += 1
            }

            print("✅ syncGroupGoalsFromCloud 完成：新增 \(added) 個 group goal")

        } catch {
            print("❌ syncGroupGoalsFromCloud failed:", error)
        }
    }
}



