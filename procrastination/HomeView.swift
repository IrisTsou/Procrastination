//
//  HomeView.swift
//  procrastination
//
//  Created by Iris Tsou on 2025/10/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedTab: SegmentedTabs.Tab = .all
    @State private var selectedDate: Date = Date()
    @State private var showBottomSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    contentStack
                        .padding(16)
                }
                
                if showBottomSheet {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture { showBottomSheet = false }
                    
                    VStack {
                        Spacer()
                        BottomSheet(isPresented: $showBottomSheet)
                            .transition(.move(edge: .bottom))
                    }
                }
            }
        }
    }
    
    // MARK: - Split main content to reduce type-checker load
    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleRow
            headerArea
            SegmentedTabs(selection: $selectedTab)
            dateStrip
            progressBannerSection
            Spacer()
            SectionHeader(title: "Today's Tasks", actionTitle: "VIEW ALL") {}
            tasksSection
        }
    }
    
    private var progressBannerSection: some View {
        ProgressBanner(
            progress: 0.25,
            title: "Your daily goals almost done! 🔥",
            subtitle: "1 of 4 completed"
        )
        .padding(.horizontal, -20)
        .padding(.horizontal, 20)
    }
    
    private var tasksSection: some View {
        // 取得所有任務
        let allTasks: [TaskItem] = store.goals.flatMap { $0.subTasks }
        
        // << 修改：根據 selectedDate 過濾出今天的任務 >>
        let todaysTasks = allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: selectedDate)
        }
            
        return VStack(spacing: 12) {
            if todaysTasks.isEmpty { // << 修改：檢查過濾後的列表 >>
                Text("No tasks scheduled for this day. ✨")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                ForEach(todaysTasks) { task in // << 修改：遍歷過濾後的列表 >>
                    TaskRowWrapper(task: task)
                }
            }
        }
    }
    
    private var titleRow: some View {
        HStack(alignment: .center) {
            Text("Home")
                .font(.largeTitle.bold())
            Spacer()
            NavigationLink {
                BreakDownGoalView()
            } label: {
                Image(systemName: "text.bubble")
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var headerArea: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hi, Mert 👋")
                    .font(.title2).bold()
                Text("Let's beat procrastination together!")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                // TODO: 導到 Mood / Journal
            } label: {
                Text(todayMoodEmoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
            .buttonStyle(.plain)
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
        return "😆" // 沒資料時預設
    }

    private var dateStrip: some View {
        let days: [Date] = (0..<9).compactMap { Calendar.current.date(byAdding: .day, value: $0-1, to: Date()) }
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days, id: \.self) { day in
                    let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                    DayChip(
                        dayNumber: DateFormatter.dayNumber.string(from: day),
                        weekday: DateFormatter.weekdayShort.string(from: day),
                        isSelected: isSelected
                    )
                    .onTapGesture { selectedDate = day }
                }
            }
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Small wrapper to reduce generic depth in HomeView
private struct TaskRowWrapper: View {
    @EnvironmentObject var store: AppStore
    let task: TaskItem
    
    private var iconName: String {
        // Find the goal that owns this task
        if let goal = store.goals.first(where: { $0.subTasks.contains(where: { $0.id == task.id }) }) {
            return goal.icon
        }
        return "checklist"
    }
    
    var body: some View {
        TaskRow(
            icon: iconName,
            title: task.title,
            detail: task.isCompleted ? "Completed!" : "To-do",
            isOn: task.isCompleted,
            toggle: toggleTask,
            onFail: nil,
            onDone: nil
        )
    }
    
    private func toggleTask() {
        // Locate the goal and toggle within it if you have such a method; otherwise update tasksToday if needed
        if let goalIndex = store.goals.firstIndex(where: { $0.subTasks.contains(where: { $0.id == task.id }) }) {
            if let taskIndex = store.goals[goalIndex].subTasks.firstIndex(where: { $0.id == task.id }) {
                store.goals[goalIndex].subTasks[taskIndex].isCompleted.toggle()
                store.save()
            }
        }
    }
}
