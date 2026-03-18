//  Models.swift

import Foundation

enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    
    var id: String { rawValue }
}

enum ProcrastinationType: String, Codable, Equatable {
    case unknown        = "尚未分析"
    case perfectionist  = "完美主義型"
    case deadlineFighter = "死線戰士型"
}



// 🆕 社群模式（全專案只在這裡宣告一次）
enum SocialMode: String, Codable, CaseIterable, Identifiable {
    case cooperation   // 合作
    case competition   // 競爭
    
    var id: String { rawValue }
    
    /// 給 UI 用的中文名稱
    var displayName: String {
        switch self {
        case .cooperation: return "合作模式"
        case .competition: return "競爭模式"
        }
    }
}

// 方便從 Goal.socialModeRaw (String?) 轉成 enum
extension SocialMode {
    init?(raw: String?) {
        guard let raw else { return nil }
        self.init(rawValue: raw)
    }
}

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var icon: String
    var colorHex: String
    var startDate: Date?
    var deadline: Date?
    var reminders: [Reminder] = []
    var subTasks: [TaskItem] = []
    var createdAt: Date = Date()
    
    // 🆕 社群任務相關
    var isGroupGoal: Bool = false                  // 是否為社群任務
    var groupId: UUID? = nil                       // 同一個 group 任務共用的 id
    var participantEmails: [String] = []           // 參與者 email（包含自己）
    var socialModeRaw: String? = nil               // "cooperation" / "competition"
}

struct GoalBreakdownResponse: Codable {
    var chatReply: String
    var tasks: [TaskItem]
}

struct ChatThread: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var title: String
    var messages: [ChatMessage]
    var relatedGoalID: UUID? = nil
    var lastUpdated: Date = Date()

    // 日記 thread 資訊
    var isJournal: Bool? = nil
    var journalDate: Date? = nil

    init(
        id: UUID = UUID(),
        title: String,
        messages: [ChatMessage],
        relatedGoalID: UUID? = nil,
        lastUpdated: Date = Date(),
        isJournal: Bool? = nil,
        journalDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.relatedGoalID = relatedGoalID
        self.lastUpdated = lastUpdated
        self.isJournal = isJournal
        self.journalDate = journalDate
    }
}

struct ChatMessage: Identifiable, Equatable, Codable {
    enum Role: String, Codable { case user, assistant }
    let id: UUID
    var role: Role
    var text: String
    var date: Date

    init(
        id: UUID = UUID(),
        role: Role,
        text: String,
        date: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.date = date
    }
}

struct Suggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var estimatedDuration: String?

    private enum CodingKeys: String, CodingKey {
        case title, isCompleted, dueDate
        case estimatedDuration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.estimatedDuration = try container.decodeIfPresent(String.self, forKey: .estimatedDuration)
        self.id = UUID()
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        estimatedDuration: String? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
    }
}

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var time: Date
    var repeatDaily: Bool
}

struct MoodRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date = Date()
    var moodScore: Int // 1..5
    var note: String
}

struct Achievement: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var createdAt: Date = Date()
}

struct ActivityStats: Codable, Equatable {
    var weekCompletedCount: Int = 0
    var monthCompletedCount: Int = 0
}

// MARK: - Journal helpers

extension ChatThread {
    var isJournalThread: Bool {
        isJournal ?? false
    }

    var effectiveJournalDate: Date {
        (journalDate ?? lastUpdated).startOfDayLocal
    }

    var firstUserMessage: ChatMessage? {
        messages.first(where: { $0.role == .user })
    }
}

extension ChatMessage {
    func journalTitleCandidate(maxLength: Int = 20) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "未命名日記" }

        let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed

        if firstLine.count <= maxLength { return firstLine }

        let idx = firstLine.index(firstLine.startIndex, offsetBy: maxLength)
        return String(firstLine[..<idx]) + "…"
    }
}

extension Array where Element == TaskItem {
    var completionRate: Double {
        guard isEmpty == false else { return 0 }
        let done = filter { $0.isCompleted }.count
        return Double(done) / Double(count)
    }
}

extension String {
    static func colorHex(default hex: String = "#4F46E5") -> String { hex }
}

extension DateFormatter {
    static let dayNumber: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d"
        return df
    }()
    static let weekdayShort: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "EEE"
        return df
    }()
}

enum Weekday: Int, CaseIterable, Identifiable, Codable {
    case mon = 0, tue, wed, thu, fri, sat, sun
    var id: Int { rawValue }
    var shortTitle: String {
        switch self {
        case .mon: return "Mon."
        case .tue: return "Tue."
        case .wed: return "Wed."
        case .thu: return "Thu."
        case .fri: return "Fri."
        case .sat: return "Sat."
        case .sun: return "Sun."
        }
    }
}

struct Workstyle: Codable, Equatable {
    var dailyHours: [Double] = Array(repeating: 3.5, count: 7)
}

enum ArrangeStrategy: String, CaseIterable, Codable, Identifiable {
    case focusBlock    = "集中在一天的某個時段完成"
    case evenlySpread  = "平均分散到每天不同時間"
    case aiSuggest     = "由我自己安排，AI 只提供建議"
    var id: String { rawValue }
}

enum WeekdayWeekend: String, CaseIterable, Identifiable, Codable {
    case same      = "相同，時間固定"
    case moreOnWE  = "週末時間比較多"
    case noTaskWE  = "週末通常不想安排任務"
    var id: String { rawValue }
}

enum FocusSpan: String, CaseIterable, Identifiable, Codable {
    case lt15  = "少於 15 分鐘"
    case m15_30 = "15–30 分鐘"
    case m30_60 = "30–60 分鐘"
    case gt60  = "超過 1 小時"
    var id: String { rawValue }
}

enum LongTaskPref: String, CaseIterable, Identifiable, Codable {
    case once    = "一次做完"
    case chunks  = "拆成幾個短段完成"
    case flexible = "視情況彈性安排"
    var id: String { rawValue }
}

struct UserPreferences: Codable, Equatable {
    var arrangeStrategy: ArrangeStrategy = .evenlySpread
    var weekdayWeekend: WeekdayWeekend = .same
    var focusSpan: FocusSpan = .m15_30
    var longTask: LongTaskPref = .chunks
    var language: String = "zh-Hant"
}
