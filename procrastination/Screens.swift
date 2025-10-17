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
                    VStack(alignment: .leading, spacing: 16) {
                        titleRow
                        headerArea
                        SegmentedTabs(selection: $selectedTab)
                        dateStrip
                        ProgressBanner(
                            progress: 0.25,
                            title: "Your daily goals almost done! 🔥",
                            subtitle: "1 of 4 completed"
                        ).padding(.horizontal, -20)
                        .padding(.horizontal, 20)
                        Spacer()
                        SectionHeader(title: "Habits", actionTitle: "VIEW ALL") {}
                        VStack(spacing: 12) {
                            TaskRow(
                                icon: "drop.fill", 
                                title: "Drink the water", 
                                detail: "500/2000 ML", 
                                isOn: false,
                                toggle: {},
                                onFail: { print("Task failed") },
                                onDone: { print("Task completed") }
                            )
                            TaskRow(
                                icon: "figure.walk", 
                                title: "Walk", 
                                detail: "0/10000 STEPS", 
                                isOn: false,
                                toggle: {},
                                onFail: { print("Task failed") },
                                onDone: { print("Task completed") }
                            )
                            TaskRow(
                                icon: "brain.head.profile", 
                                title: "Meditate", 
                                detail: "30/30 MIN", 
                                isOn: true,
                                toggle: {},
                                onFail: { print("Task failed") },
                                onDone: { print("Task completed") }
                            )
                        }
                    }
                    .padding(16)
                }
                
                // Bottom sheet overlay
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
        let days = (0..<9).compactMap { Calendar.current.date(byAdding: .day, value: $0-1, to: Date()) }
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


struct AddEntryView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var goalTitle: String = ""
    @State private var goalDescription: String = ""
    @State private var showIconPicker = false
    @State private var showColorPicker = false
    @State private var showDatePicker = false
    @State private var selectedIcon: String = "figure.walk"
    @State private var selectedColorHex: String = "#F59E0B"
    @State private var deadline: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var addReminder: Bool = true
    @State private var reminderTime: Date = Date()
    // 新增：導航狀態
    @State private var navigateToBreakdown: Bool = false
    
    let icons = ["figure.walk", "drop.fill", "brain.head.profile", "heart.fill", "book.fill"]
    let colors = ["Orange", "Blue", "Green", "Purple", "Red"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 隱形 NavigationLink 由狀態觸發
                NavigationLink(isActive: $navigateToBreakdown) {
                    BreakDownGoalView()
                } label: {
                    EmptyView()
                }
                .hidden()
                
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Text("Set a New Goal")
                        .font(.headline).bold()
                    Spacer()
                    // Balance the back button
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // GOAL Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("GOAL")
                                .font(.caption).bold()
                                .foregroundStyle(.secondary)
                            
                            TextField("Please enter your goal.", text: $goalTitle)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                            
                            TextField("Describe your goal.", text: $goalDescription)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                        }
                        
                        // ICON AND COLOR Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ICON AND COLOR")
                                .font(.caption).bold()
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 16) {
                                // Icon Card
                                Button(action: { showIconPicker = true }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle().fill(Color.gray.opacity(0.1))
                                            Image(systemName: selectedIcon)
                                                .foregroundStyle(.purple)
                                        }
                                        .frame(width: 40, height: 40)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Walking").bold()
                                            Text("Icon").font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                                }
                                .buttonStyle(.plain)
                                .sheet(isPresented: $showIconPicker) {
                                    IconPickerView(selected: $selectedIcon)
                                        .presentationDetents([.large])
                                }

                                // ---- Color Card ----
                                Button(action: { showColorPicker = true }) {
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: selectedColorHex))
                                            .frame(width: 24, height: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(colorName(for: selectedColorHex)).bold()
                                            Text("Color").font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(16)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                                }
                                .buttonStyle(.plain)
                                .sheet(isPresented: $showColorPicker) {
                                    ThemeColorPickerView(selectedHex: $selectedColorHex)
                                        .presentationDetents([.medium, .large])
                                }
                            }
                        }
                        
                        // DEADLINE Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DEADLINE")
                                .font(.caption).bold()
                                .foregroundStyle(.secondary)

                            Button(action: { showDatePicker = true }) {
                                HStack {
                                    Spacer()
                                    Text(deadline.formatted(.dateTime.year().month().day())) // 顯示 yyyy/MM/dd
                                        .foregroundStyle(.blue)
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // REMINDERS Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("REMINDERS")
                                .font(.caption).bold()
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                Text("Want to receive a notification?")
                                Spacer()
                                Toggle("", isOn: $addReminder)
                                    .toggleStyle(SwitchToggleStyle(tint: .green))
                            }
                            
                            if addReminder {
                                HStack(spacing: 12) {
                                    Image(systemName: "moon.fill")
                                        .foregroundStyle(.blue)
                                    Text("30 minutes before the deadline")
                                    Spacer()
                                    Image(systemName: "bell.fill")
                                        .foregroundStyle(.blue)
                                    Text("Every day")
                                }
                                .padding(16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                            }
                            
                            Button("Add Reminder") {
                                // Add reminder logic
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Bottom Button
                VStack {
                    Button("Start breaking down the goal!") {
                        createGoal()
                        // 不先 dismiss，直接導向 BreakDownGoalView
                        navigateToBreakdown = true
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(date: $deadline)
                .presentationDetents([.medium])       // 你也可以用 [.medium, .large]
                .presentationDragIndicator(.visible)
        }
        
        .background(Color(uiColor: .systemBackground))
    }
    
    private func createGoal() {
        var reminders: [Reminder] = []
        if addReminder {
            reminders.append(Reminder(time: reminderTime, repeatDaily: true))
        }
        let hex = "#F59E0B"
        let newGoal = Goal(title: goalTitle.isEmpty ? "未命名目標" : goalTitle, icon: selectedIcon, colorHex: hex, deadline: deadline, reminders: reminders, subTasks: [])
        store.addGoal(newGoal)
        if addReminder {
            NotificationManager.scheduleDailyReminder(id: newGoal.id.uuidString, title: newGoal.title, at: reminderTime)
        }
    }
    
    private struct DatePickerSheet: View {
        @Environment(\.dismiss) private var dismiss
        @Binding var date: Date

        var body: some View {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    DatePicker(
                        "Select a deadline",
                        selection: $date,
                        in: Date()...,                   // 不可選今天以前
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Spacer()
                }
                .navigationTitle("Choose Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

}

private func colorName(for hex: String) -> String {
    switch hex {
    case "#BDCFFF": return "Skyblue"
    case "#B8C0FF": return "Blue"
    case "#C8B6FE": return "Purple"
    case "#E7C5FF": return "Pink Purple"
    case "#FED5FF": return "Pink"
    default: return "Custom"
    }
}

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: String

    // 你可以自由增減這份清單
    private let icons = [
        "figure.walk", "drop.fill", "brain.head.profile", "heart.fill", "book.fill",
        "bolt.fill", "flame.fill", "leaf.fill", "sun.max.fill", "moon.fill",
        "timer", "alarm.fill", "pencil", "checkmark.seal.fill", "cart.fill",
        "dumbbell.fill", "bicycle", "medal.fill", "music.note", "paintbrush.fill"
    ]

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(icons, id: \.self) { name in
                        Button {
                            selected = name
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(name == selected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                                Image(systemName: name)
                                    .font(.title2)
                                    .foregroundStyle(name == selected ? Color.accentColor : .primary)
                            }
                            .frame(width: 56, height: 56)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose an Icon")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
    
struct ThemeColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedHex: String

    // 你的品牌色盤
    private let palette: [(name: String, hex: String)] = [
        ("Skyblue", "#BDCFFF"),
        ("Blue",   "#B8C0FF"),
        ("Purple",  "#C8B6FE"),
        ("Pink Purple", "#E7C5FF"),
        ("Pink",    "#FED5FF"),
    ]

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 14)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(palette, id: \.hex) { c in
                            Button {
                                selectedHex = c.hex
                                dismiss()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: c.hex))
                                        .frame(width: 48, height: 48)
                                    if selectedHex == c.hex {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white)
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }

                // 可選：提供系統色票（會回存為 hex）
                Divider().padding(.horizontal)
                SystemColorPickerRow(selectedHex: $selectedHex)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .navigationTitle("Choose a Color")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 系統 ColorPicker, 轉成 hex 回存
private struct SystemColorPickerRow: View {
    @Binding var selectedHex: String
    @State private var tempColor: Color = .orange

    var body: some View {
        HStack(spacing: 12) {
            ColorPicker("Custom color", selection: $tempColor, supportsOpacity: false)
            Spacer()
            Button("Use") {
                selectedHex = tempColor.toHex() ?? selectedHex
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

extension Color {
    init(hex: String) {
        self = Color(UIColor(hex: hex))
    }

    func toHex() -> String? {
        UIColor(self).toHex()
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    func toHex() -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
}

// -----------------------------------------------------------------------------


struct BreakDownGoalView: View {
    // 多個聊天室（對話）
    @State private var threads: [ChatThread] = [
        .init(title: "My new goal", messages: [
            .init(role: .assistant, text: "Hi! Tell me your goal and I’ll break it down ✨")
        ]),
        .init(title: "Workout plan", messages: [
            .init(role: .assistant, text: "Ready to plan your weekly workouts?")
        ])
    ]
    @State private var activeThreadID: UUID? = nil
    @State private var showThreadPicker = false

    @State private var input = ""
    
    private let suggestions: [Suggestion] = [
        .init(title: "Will the tasks too hard for you?",
              subtitle: "AI can help you customize your own plan"),
        .init(title: "Tell me the part you want to modify",
              subtitle: "Estimated time, details of the tasks")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 訊息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(active.messages) { msg in
                                MessageRow(msg: msg)
                                    .id(msg.id)
                            }
                            Spacer(minLength: 6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .onChange(of: active.messages.count) { _ in
                        withAnimation {
                            if let lastID = active.messages.last?.id {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // 建議卡 + 輸入列
                bottomComposer
            }
            .navigationTitle("Break Down the Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showThreadPicker = true
                    } label: {
                        Image(systemName: "ellipsis.bubble")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(.secondarySystemBackground)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Switch conversation")
                }
            }
            .sheet(isPresented: $showThreadPicker) {
                ConversationPickerSheet(
                    threads: $threads,
                    activeThreadID: $activeThreadID
                )
                .presentationDetents([.medium, .large])
            }
            .onAppear {
                if activeThreadID == nil {
                    activeThreadID = threads.first?.id
                }
            }
        }
    }
    
    // 目前作用中的聊天室
    private var activeIndex: Int {
        guard let id = activeThreadID,
              let idx = threads.firstIndex(where: { $0.id == id }) else {
            return 0
        }
        return idx
    }
    private var active: ChatThread {
        get { threads[activeIndex] }
        set { threads[activeIndex] = newValue }
    }
    
    // MARK: - Bottom composer
    private var bottomComposer: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let cardW = geo.size.width * 0.82
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(suggestions) { s in
                            SuggestionCard(s, width: cardW) {
                                input = s.title
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
            .frame(height: 128)
            
            HStack(spacing: 10) {
                TextField("Ask me anything...", text: $input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                
                Button(action: send) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.accentColor))
                }
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
    }
    
    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        var t = active
        t.messages.append(.init(role: .user, text: text))
        // 這裡之後串 GPT：把 `text` 丟到你的 GPTService，收到回覆再 append 一則 assistant
        // 先放一個假回覆：
        t.messages.append(.init(role: .assistant, text: "Got it! I’ll break it down into clear subtasks for you."))
        threads[activeIndex] = t
        input = ""
    }
}

private struct ConversationPickerSheet: View {
    @Binding var threads: [ChatThread]
    @Binding var activeThreadID: UUID?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(threads) { t in
                    Button {
                        activeThreadID = t.id
                        dismiss()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(t.title).bold()
                                Text(t.messages.last?.text ?? "No messages yet")
                                    .lineLimit(2)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            Spacer()
                            if activeThreadID == t.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
                .onDelete { idx in
                    threads.remove(atOffsets: idx)
                    if threads.isEmpty { activeThreadID = nil }
                    else if activeThreadID == nil || threads.contains(where: { $0.id == activeThreadID }) == false {
                        activeThreadID = threads.first?.id
                    }
                }
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let new = ChatThread(title: "New chat", messages: [
                            .init(role: .assistant, text: "Tell me your goal ✨")
                        ])
                        threads.insert(new, at: 0)
                        activeThreadID = new.id
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
}

// MARK: - Models
struct ChatThread: Identifiable, Equatable {
    let id: UUID = UUID()
    var title: String
    var messages: [ChatMessage]
}

struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant }
    let id: UUID = UUID()
    var role: Role
    var text: String
    var date: Date = Date()
}

struct Suggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

// MARK: - UI bits
private struct MessageRow: View {
    let msg: ChatMessage
    var body: some View {
        HStack {
            if msg.role == .assistant {
                HStack(alignment: .top) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text(msg.text)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                Text(msg.text)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentColor.opacity(0.15)))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

private struct SuggestionCard: View {
    let s: Suggestion
    let width: CGFloat
    var tap: () -> Void
    
    init(_ s: Suggestion, width: CGFloat, tap: @escaping () -> Void) {
        self.s = s; self.width = width; self.tap = tap
    }
    
    var body: some View {
        Button(action: tap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(s.title)
                    .font(.subheadline.bold())
                Text(s.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(width: width, height: 110, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }
}

    
    
// -----------------------------------------------------------------------------

struct ActivityView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedPeriod: ActivityPeriod = .weekly
    
    enum ActivityPeriod: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Activity")
                    .font(.largeTitle).bold()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Period selector
                    HStack {
                        ForEach(ActivityPeriod.allCases) { period in
                            Button(action: { selectedPeriod = period }) {
                                Text(period.rawValue)
                                    .font(.subheadline).bold()
                                    .foregroundStyle(selectedPeriod == period ? .blue : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(selectedPeriod == period ? Color.white : Color.gray.opacity(0.1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Date range
                    HStack {
                        VStack(alignment: .leading) {
                            Text("This week").bold()
                            Text("May 28 - Jun 3").foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            Button(action: {}) {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.gray.opacity(0.1)))
                            }
                            Button(action: {}) {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.gray.opacity(0.1)))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Task Achievement Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 48, height: 48)
                                .overlay(Image(systemName: "eye").foregroundStyle(.secondary))
                            
                            VStack(alignment: .leading) {
                                Text("Task Achievement").bold()
                                Text("Summary").foregroundStyle(.secondary).font(.caption)
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.gray.opacity(0.1)))
                            }
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            StatItem(title: "SUCCESS RATE", value: "98%", color: .green)
                            StatItem(title: "COMPLETED", value: "244", color: .primary)
                            StatItem(title: "BEST STREAK DAY", value: "22", color: .primary)
                            StatItem(title: "FAILED", value: "2", color: .red)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                    
                    // Tasks Completed Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 48, height: 48)
                                .overlay(Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(.red))
                            
                            VStack(alignment: .leading) {
                                Text("Tasks Completed").bold()
                                Text("Comparison by week").foregroundStyle(.secondary).font(.caption)
                            }
                            
                            Spacer()
                            
                            Pill(text: "🔥 Highest 4 tasks")
                        }
                        
                        // Bar chart
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(4...10, id: \.self) { week in
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: 20, height: week == 7 || week == 10 ? 80 : CGFloat.random(in: 30...60))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text("\(week)").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(height: 100)
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                    
                    // Happy Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 48, height: 48)
                                .overlay(Text("😊").font(.title2))
                            
                            VStack(alignment: .leading) {
                                Text("Happy").bold()
                                Text("Weekly Mood").foregroundStyle(.secondary).font(.caption)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(["😊", "🥰", "😞", "😊", "😊", "🥰", "😊"], id: \.self) { emoji in
                                Text(emoji)
                                    .font(.title2)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(Color.gray.opacity(0.05))
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.title2).bold().foregroundStyle(color)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: ProfileTab = .workstyle

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // 個人頭像/名稱…（可保留你原本的 Header）
                    Card {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(Text("🙂").font(.title2))
                            VStack(alignment: .leading) {
                                Text("Mert").bold()
                                Text("Your Profile").foregroundStyle(.secondary).font(.caption)
                            }
                            Spacer()
                        }
                    }

                    ProfileSegmented(selection: $tab)

                    Group {
                        switch tab {
                        case .workstyle:
                            WorkstyleSection()
                                .environmentObject(store)

                        case .achievements:
                            AchievementsSection()
                                .environmentObject(store)
                        }
                    }

                }
                .padding(16)
            }
            .navigationTitle("Profile")
        }
    }
}

enum ProfileTab: String, CaseIterable, Identifiable {
    case workstyle = "Workstyle"
    case achievements = "Achievements"
    var id: String { rawValue }
}


struct ProfileSegmented: View {
    @Binding var selection: ProfileTab

    var body: some View {
        HStack(spacing: 8) {
            segmentButton(.workstyle)
            segmentButton(.achievements)
        }
        .padding(6)
        .background(
            Capsule().fill(Color.gray.opacity(0.12))
        )
    }

    @ViewBuilder
    private func segmentButton(_ tab: ProfileTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                selection = tab
            }
        } label: {
            Text(tab.rawValue)
                .font(.headline)                // 讓字重接近設計
                .foregroundStyle(selection == tab ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(selection == tab ? Color.white : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}




private struct WorkstyleSection: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Card {
            Text("Workstyle").font(.headline)

            // 每日可配置時間
            VStack(spacing: 14) {
                ForEach(Weekday.allCases) { day in
                    DaySliderRow(
                        title: day.shortTitle,
                        value: Binding(
                            get: { store.workstyle.dailyHours[day.rawValue] },
                            set: { newVal in
                                store.workstyle.dailyHours[day.rawValue] = newVal
                                store.save()
                            }
                        )
                    )
                }
            }
            .padding(.top, 4)

            // 任務安排偏好
            VStack(alignment: .leading, spacing: 16) {
                Text("Task Arrange Preference").font(.title3).bold()

                SingleChoiceQuestion(
                    title: "1. 你希望系統安排任務時，偏好：",
                    options: ArrangeStrategy.allCases,
                    selection: Binding(
                        get: { store.preferences.arrangeStrategy},
                        set: { store.preferences.arrangeStrategy = $0; store.save() }
                    )
                )

                SingleChoiceQuestion(
                    title: "2. 你平日和週末的作息會不同嗎？",
                    options: WeekdayWeekend.allCases,
                    selection: Binding(
                        get: { store.preferences.weekdayWeekend },
                        set: { store.preferences.weekdayWeekend = $0; store.save() }
                    )
                )
                    
                SingleChoiceQuestion(
                    title: "3. 你通常一次可以專心做事多久？",
                    options: FocusSpan.allCases,
                    selection: Binding(
                        get: { store.preferences.focusSpan },
                        set: { store.preferences.focusSpan = $0; store.save() }
                    )
                )
                
                SingleChoiceQuestion(
                    title: "4. 當任務超過 1 小時時，你比較喜歡：",
                    options: LongTaskPref.allCases,
                    selection: Binding(
                        get: { store.preferences.longTask },
                        set: { store.preferences.longTask = $0; store.save() }
                    )
                )
            }
        }
    }
}

/// 每日滑桿 Row
private struct DaySliderRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
                .frame(width: 56, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.blue.opacity(0.12)))
                .foregroundStyle(Color.blue)

            VStack(spacing: 6) {
                // Slider + 0/10 刻度
                HStack {
                    Text("0").font(.caption2).foregroundStyle(.secondary)
                    ZStack(alignment: .center) {
                        Slider(value: $value, in: 0...10, step: 0.5)
                            .tint(.blue)
                        // 中央顯示目前數值（與參考圖一致）
                        Text(value.formatted(.number.precision(.fractionLength(1))))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    Text("10").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct AchievementsSection: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Card {
            Text("Achievements").font(.headline)

            if store.achievements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("還沒有成就").font(.subheadline.bold())
                    Text("完成連續 7 天任務、加入挑戰賽、或維持一週 80% 完成率即可解鎖✨")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(store.achievements) { a in
                    HStack(spacing: 10) {
                        Image(systemName: "medal.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading) {
                            Text(a.title).bold()
                            Text(a.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}



struct JournalView: View {
    @EnvironmentObject var store: AppStore

    @State private var input = ""
    @State private var messages: [String] = []   // ← 補上
    private let suggestions: [JournalSuggestion] = [
        .init(title: "Tell me how you feel when completing tasks?",
              subtitle: "Sense of achievement, exhausted…"),
        .init(title: "Do you face any bottlenecks?",
              subtitle: "Lack of motivation, outcome wasn’t as good as expected…"),
        .init(title: "What small win did you have today?",
              subtitle: "Finished a subtask, stayed focused…")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // 內容區（訊息列表）
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                if messages.isEmpty {
                                    Spacer().frame(height: 120)
                                } else {
                                    ForEach(messages.indices, id: \.self) { i in
                                        Bubble(text: messages[i]).id(i)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .onChange(of: messages.count) { _ in
                            withAnimation { proxy.scrollTo(max(0, messages.count - 1), anchor: .bottom) }
                        }
                    }

                    // 建議卡片 + 輸入列
                    bottomComposer
                }
            }
            .navigationTitle("Mood Journal")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Bottom composer
    private var bottomComposer: some View {
        VStack(spacing: 12) {
            // 可左右滑動、分頁吸附的卡片
            GeometryReader { geo in
                let cardW = geo.size.width * 0.82
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(suggestions) { s in
                            JournalSuggestionCard(s, width: cardW) {
                                input = s.title   // 點卡片 → 將標題填入輸入框（或直接 send()）
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
            .frame(height: 140)

            HStack(spacing: 10) {
                TextField("Ask me anything…", text: $input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                Button(action: send) {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.accentColor))
                }
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
//        .background(.ultraThinMaterial)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        messages.append(text)
        input = ""
        // 若要同步存到本地紀錄：
        // store.addMood(score: 3, note: text)
    }
}

struct JournalSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct JournalSuggestionCard: View {
    let s: JournalSuggestion
    let width: CGFloat
    var tap: () -> Void

    init(_ s: JournalSuggestion, width: CGFloat, tap: @escaping () -> Void) {
        self.s = s; self.width = width; self.tap = tap
    }

    var body: some View {
        Button(action: tap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(s.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(s.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(width: width, height: 120, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.gray.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }
}

private struct Bubble: View {
    var text: String
    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentColor.opacity(0.15)))
        }
    }
}

