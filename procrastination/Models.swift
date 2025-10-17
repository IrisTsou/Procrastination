import Foundation

enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    
    var id: String { rawValue }
}

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var icon: String
    var colorHex: String
    var deadline: Date?
    var reminders: [Reminder] = []
    var subTasks: [TaskItem] = []
    var createdAt: Date = Date()
}

struct Habit: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var icon: String
    var colorHex: String
    var frequency: HabitFrequency = .daily
    var isArchived: Bool = false
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date?
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
    /// 每天可配置的工時（小時），索引依序 Mon..Sun
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
}

