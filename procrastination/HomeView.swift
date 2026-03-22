//  HomeView.swift

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab: SegmentedTabs.Tab = .all
    @State private var selectedDate: Date = Date()
    
    // MARK: - Derived data (今天的任務 & 過濾)
    private var allTasksToday: [TaskItem] {
        let all = store.goals.flatMap { $0.subTasks }
        return all.filter { task in
            guard let d = task.dueDate else { return false }
            return Calendar.current.isDate(d, inSameDayAs: selectedDate)
        }
    }
    
    // 今天的「個人任務」（排除社群任務）
    private var personalTasksToday: [TaskItem] {
        allTasksToday.filter { task in
            guard let goal = parentGoal(of: task) else { return true } // 沒找到 goal 的就當作個人任務
            return (goal.isGroupGoal == false)
        }
    }

    // 用來顯示在今日任務區塊的清單（+ 分頁篩選）
    private var filteredTasksToday: [TaskItem] {
        switch selectedTab {
        case .all:
            return personalTasksToday
        case .todo:
            return personalTasksToday.filter { !$0.isCompleted }
        case .completed:
            return personalTasksToday.filter { $0.isCompleted }
        }
    }

    private var todayCompletedCount: Int { allTasksToday.filter { $0.isCompleted }.count }
    private var todayTotalCount: Int { allTasksToday.count }
    private var todayProgress: Double {
        guard todayTotalCount > 0 else { return 0 }
        return Double(todayCompletedCount) / Double(todayTotalCount)
    }

    // 今天的社群任務
    private var groupTasksToday: [TaskItem] {
        allTasksToday.filter { task in
            guard let goal = parentGoal(of: task) else { return false }
            return goal.isGroupGoal == true
        }
    }

    private func parentGoal(of task: TaskItem) -> Goal? {
        store.goals.first(where: { $0.subTasks.contains(where: { $0.id == task.id }) })
    }

    // MARK: - Banner 文案
    private var bannerTitle: LocalizedStringKey {
        let p = todayProgress
        let typeRaw = store.procrastinationType.rawValue

        if typeRaw.contains("完美") {
            switch p {
            case 0:
                return "不用一次做到完美，先動一小步就很棒了 ✨"
            case ..<0.25:
                return "有開始就是贏一半，先讓草稿長出來就好 🌱"
            case ..<0.50:
                return "慢慢推進就好，你已經踏出一大步 🙂"
            case ..<0.75:
                return "已經做了這麼多，再加把勁就會更接近完成 🤍"
            case ..<1.0:
                return "快收尾了，不用修改到完美才交，現在的你已經很努力 🥹"
            default:
                return "今天已經做到夠多了，可以允許自己下班休息 🏆"
            }

        } else if typeRaw.contains("死線") || typeRaw.contains("戰士") {
            switch p {
            case 0:
                return "不要等到最後一刻，先來個 5 分鐘暖身就好 🔥"
            case ..<0.25:
                return "已經比昨天更早開始了，之後衝刺會輕鬆很多 💪"
            case ..<0.50:
                return "進度過半了，再多一個小 checkpoint 就超棒 🚀"
            case ..<0.75:
                return "現在多做一點，deadline 當天就可以像在收尾不是救火 🙌"
            case ..<1.0:
                return "快完成了，最後這段當成小終點衝一把就好 🏁"
            default:
                return "今天有先動起來，已經打破只在死線前才動的老模式了 🏆"
            }

        } else {
            switch p {
            case 0:       return "Let's kick things off 💪"
            case ..<0.25: return "Warming up… 🔄"
            case ..<0.50: return "Nice momentum! 🚀"
            case ..<0.75: return "Over halfway there 🙌"
            case ..<1.0:  return "Almost done! 🔥"
            default:      return "All done — great job! 🏆"
            }
        }
    }

    private var bannerSubtitle: LocalizedStringKey {
        if todayTotalCount == 0 {
            return "No tasks scheduled today"
        } else {
            return "\(todayCompletedCount) of \(todayTotalCount) completed"
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView { contentStack.padding(16) }
        }
    }

    // MARK: - Main content
    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleRow
            headerArea
            SegmentedTabs(selection: $selectedTab)
            dateStrip
            progressBannerSection
            Spacer()

            SectionHeader(title: "Today's Tasks", actionTitle: "VIEW ALL") {
                selectedTab = .all
            }
            tasksSection

            SectionHeader(title: "Today's Group Tasks") { }
            groupTasksSection
        }
    }
    
    // MARK: - Banner
    private var progressBannerSection: some View {
        ProgressBanner(
            progress: todayProgress,
            title: bannerTitle,
            subtitle: bannerSubtitle
        )
        .padding(.horizontal, -20)
        .padding(.horizontal, 20)
    }
    
    // MARK: - 個人任務區塊
    private var tasksSection: some View {
        VStack(spacing: 12) {
            if filteredTasksToday.isEmpty {
                Text(LocalizedStringKey(emptyMessage))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                ForEach(filteredTasksToday) { task in
                    PersonalTaskRow(task: task)
                }
            }
        }
    }

    private var emptyMessage: String {
        switch selectedTab {
        case .all:
            return "No tasks scheduled for this day. ✨"
        case .todo:
            return "No to-do tasks for this day. 🎯"
        case .completed:
            return "No completed tasks yet. Keep going! 💫"
        }
    }

    // MARK: - 社群任務區塊
    private var groupTasksSection: some View {
        VStack(spacing: 12) {
            if groupTasksToday.isEmpty {
                Text("No group tasks for this day. 🧑‍🤝‍🧑")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                ForEach(groupTasksToday) { task in
                    GroupTaskRow(task: task)
                }
            }
        }
    }
    
    // MARK: - Title & Header
    private var titleRow: some View {
        HStack(alignment: .center) {
            Text("Home")
                .font(.largeTitle.bold())
                .foregroundColor(.themeBlue)
            Spacer()
            NavigationLink {
                BreakDownGoalView()
            } label: {
                Image(systemName: "text.bubble")
                    .font(.title3)
                    .foregroundStyle(Color.themeBlue)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    private var headerArea: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hi, \(authVM.currentUser?.displayName ?? "Guest") 👋")
                    .font(.title2).bold()
                Text("Let's beat procrastination together!")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                NavigationLink {
                    JournalView()
                        .environmentObject(store)
                } label: {
                    Text(todayMoodEmoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ProfileView()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(Color.themeBlue)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var todayMoodEmoji: String {
        let map = ["😡","😞","😢","😆","🥰"]  // 1..5
        if let today = store.moods.last(where: {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        }) {
            let i = max(1, min(5, today.moodScore)) - 1
            return map[i]
        }
        return "😆"
    }

    private var dateStrip: some View {
        let days: [Date] = (0..<9).compactMap {
            Calendar.current.date(byAdding: .day, value: $0 - 1, to: Date())
        }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days, id: \.self) { day in
                    let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                    DayChip(
                        dayNumber: DateFormatter.dayNumber.string(from: day),
                        weekday: getWeekdayString(from: day),
                        isSelected: isSelected
                    )
                    .onTapGesture { selectedDate = day }
                }
            }
            .padding(.vertical, 6)
        }
    }
    
    private func getWeekdayString(from date: Date) -> String {
        // 強制使用 AppStore 設定的語言（locale 依語言動態切換）
        DateFormatter.weekdayShort.locale = Locale(identifier: store.language.rawValue)
        return DateFormatter.weekdayShort.string(from: date)
    }
}

//
// MARK: - 個人任務 row
//
private struct PersonalTaskRow: View {
    @EnvironmentObject var store: AppStore
    let task: TaskItem
    
    private var parentGoal: Goal? {
        store.goals.first(where: { $0.subTasks.contains(where: { $0.id == task.id }) })
    }
    
    private var iconName: String {
        parentGoal?.icon ?? "checkmark.circle"
    }
    
    private var iconColor: Color {
        if let hex = parentGoal?.colorHex {
            return Color(hex: hex)
        }
        return .blue   // fallback 顏色
    }

    
    var body: some View {
        TaskRow(
            icon: iconName,
            iconColor: iconColor,
            title: task.title,
            detail: task.isCompleted
                ? String(localized: "Completed!")
                : String(localized: "To-do"),
            isOn: task.isCompleted,
            toggle: toggleTask,
            onFail: nil,
            onDone: nil
        )
    }
    
    private func toggleTask() {
        store.toggleTask(task.id)
    }
}

//
// MARK: - 社群任務 row
//
private struct GroupTaskRow: View {
    @EnvironmentObject var store: AppStore
    let task: TaskItem

    private var goal: Goal? {
        store.goals.first(where: { $0.subTasks.contains(where: { $0.id == task.id }) })
    }

    private var iconName: String {
        goal?.icon ?? "person.3.fill"
    }

    private var iconColor: Color {
        if let hex = goal?.colorHex {
            return Color(hex: hex)
        }
        return .blue
    }


    private var detailText: String {
        guard let goal else { return "Group task" }
        if let mode = SocialMode(raw: goal.socialModeRaw) {
            switch mode {
            case .cooperation: return "Group (Cooperation)"
            case .competition: return "Group (Competition)"
            }
        }
        return "Group task"
    }

    var body: some View {
        TaskRow(
            icon: iconName,
            iconColor: iconColor,
            title: task.title,
            detail: task.isCompleted ? "\(detailText) · Completed" : detailText,
            isOn: task.isCompleted,
            toggle: toggleTask,
            onFail: nil,
            onDone: nil
        )
    }

    private func toggleTask() {
        store.toggleTask(task.id)
    }
}
