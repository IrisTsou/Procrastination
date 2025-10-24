import Foundation
import Combine
import SwiftUI

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

final class AppStore: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var tasksToday: [TaskItem] = []
    @Published var moods: [MoodRecord] = []
    @Published var achievements: [Achievement] = []
    @Published var activity: ActivityStats = ActivityStats()
    @Published var workstyle: Workstyle = Workstyle()
    @Published var preferences = UserPreferences()
    @Published var conversations: [ChatThread] = []   // 新增：保存 Gemini 對話

    // Added for onboarding flow
    @Published var onboarding: Onboarding = Onboarding()
    @Published var hasOnboarded: Bool = false
    @Published var procrastinationType: ProcrastinationType = .unknown
    
    private let persistence = Persistence()
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        load()
        setupDerived()
    }
    
    func load() {
        let snapshot = persistence.load()
        goals = snapshot.goals
        tasksToday = snapshot.tasksToday
        moods = snapshot.moods
        achievements = snapshot.achievements
        activity = snapshot.activity
        workstyle = snapshot.workstyle
        preferences = snapshot.preferences
        onboarding = snapshot.onboarding
        hasOnboarded = snapshot.hasOnboarded
        procrastinationType = snapshot.procrastinationType
        conversations = snapshot.conversations // 新增
    }
    

    func save() {
        let snapshot = Persistence.Snapshot(
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
            conversations: conversations // 新增
        )
        persistence.save(snapshot: snapshot)
    }
    
    func addMood(score: Int, note: String) {
        moods.append(MoodRecord(moodScore: score, note: note))
        save()
    }
    
    func toggleTask(_ id: UUID) {
        guard let idx = tasksToday.firstIndex(where: { $0.id == id }) else { return }
        tasksToday[idx].isCompleted.toggle()
        save()
    }
    
    func addGoal(_ goal: Goal) {
        goals.append(goal)
        save()
    }
    
    // 會話相關便捷方法
    func upsertThread(_ thread: ChatThread) {
        if let idx = conversations.firstIndex(where: { $0.id == thread.id }) {
            conversations[idx] = thread
        } else {
            conversations.insert(thread, at: 0)
        }
        save()
    }
    
    func deleteThreads(at offsets: IndexSet) {
        conversations.remove(atOffsets: offsets)
        save()
    }
    
    private func setupDerived() {
        $tasksToday
            .sink { [weak self] tasks in
                guard let self else { return }
                let completed = tasks.filter { $0.isCompleted }.count
                self.activity.weekCompletedCount = completed
            }
            .store(in: &cancellables)
    }
}

final class Persistence {
    struct Snapshot: Codable {
        var goals: [Goal]
        var tasksToday: [TaskItem]
        var moods: [MoodRecord]
        var achievements: [Achievement]
        var activity: ActivityStats
        var workstyle: Workstyle
        var preferences: UserPreferences

        // Added fields
        var onboarding: Onboarding
        var hasOnboarded: Bool
        var procrastinationType: ProcrastinationType
        
        // 新增：對話
        var conversations: [ChatThread]
    }
    
    private let url: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("app-data.json")
    }()
    
    func load() -> Snapshot {
        
        print("--- App data file path ---")
        print(url.path)
        print("--------------------------")
        
        guard let data = try? Data(contentsOf: url),
              let s = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return Snapshot(
                goals: [],
                tasksToday: [],
                moods: [],
                achievements: [],
                activity: ActivityStats(),
                workstyle: Workstyle(),
                preferences: UserPreferences(),
                onboarding: Onboarding(),
                hasOnboarded: false,
                procrastinationType: .unknown,
                conversations: [] // 新增
            )
        }
        return s
    }
    
    func save(snapshot: Snapshot) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: url)
    }
}

