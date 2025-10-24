//
//  BreakDownGoalView.swift
//  procrastination
//
//  Created by Iris Tsou on 2025/10/25.
//
import SwiftUI

// BreakDownGoalView and its helpers
struct BreakDownGoalView: View {
    // MARK: - Properties
    @Environment(GeminiService.self) private var geminiService
    @EnvironmentObject var store: AppStore
    
    // 可選：從 AddEntryView 帶入，用於自動觸發第一次請求
    var initialGoalID: UUID? = nil
    var initialUserMessage: String? = nil
    
    // 對話串管理
    // ----- 這是主要的修改 -----
    // 移除局域的 @State private var threads
    // 我們現在直接讀取 store.conversations
    // -------------------------
    @State private var activeThreadID: UUID? = nil
    @State private var showThreadPicker = false
    @State private var hasAutoTriggered = false
    
    // 輸入與狀態管理
    @State private var input = ""
    @State private var isGenerating = false // AI 是否正在回應
    
    private let suggestions: [Suggestion] = [
        .init(title: "Will the tasks too hard for you?",
              subtitle: "AI can help you customize your own plan"),
        .init(title: "Tell me the part you want to modify",
              subtitle: "Estimated time, details of the tasks")
    ]
    
    // MARK: - Computed Properties
         
    // --- 修改：從 store.conversations 讀取 ---
    private var activeIndex: Int {
        guard let id = activeThreadID,
              let idx = store.conversations.firstIndex(where: { $0.id == id }) else {
            // 如果沒有 ID，或找不到，預設為第一個
            if !store.conversations.isEmpty {
                return 0
            }
            return -1 // 代表 store 為空
        }
        return idx
    }
    
    // --- 修改：從 store.conversations 讀取 (設為 Optional) ---
    private var active: ChatThread? {
        get {
            guard activeIndex != -1, store.conversations.indices.contains(activeIndex) else {
                return nil
            }
            return store.conversations[activeIndex]
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 訊息列表
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            // --- 修改：安全地 unwrap 'active' ---
                            if let messages = active?.messages {
                                ForEach(messages) { msg in
                                    MessageRow(msg: msg)
                                        .id(msg.id)
                                }
                            } else {
                                Text("Select or start a conversation.")
                                    .padding()
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    // --- 修改：監聽 'active?.messages.count' ---
                    .onChange(of: active?.messages.count) {
                        withAnimation {
                            if let lastID = active?.messages.last?.id {
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
                    // --- 修改：傳入 store.conversations 的 Binding ---
                    threads: $store.conversations,
                    activeThreadID: $activeThreadID
                )
                .environmentObject(store) // <-- 傳入 store
                .presentationDetents([.medium, .large])
            }
            .onAppear {
                // --- 修改：檢查 store.conversations ---
                if activeThreadID == nil {
                    // 1. 優先設定 store 中的第一個 thread 為 active
                    activeThreadID = store.conversations.first?.id
                }

                // 2. 如果 store 完全是空的，才建立並儲存預設的 thread
                if store.conversations.isEmpty {
                    let defaultThread = ChatThread(title: "My new goal", messages: [
                        .init(role: .assistant, text: "Hi! Tell me more about your goal and I’ll break it down into actionable steps for you. ✨")
                    ])
                    store.upsertThread(defaultThread) // 存到 store
                    activeThreadID = defaultThread.id // 設為 active
                }
                
                // (既有的自動送出邏輯，不變)
                if hasAutoTriggered == false,
                   let goalID = initialGoalID,
                   let message = initialUserMessage {
                    hasAutoTriggered = true
                    autoSendInitial(goalID: goalID, message: message)
                }
            }
        }
    }
    
    // MARK: - Bottom Composer View
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
                
                if isGenerating {
                    ProgressView()
                        .frame(width: 42, height: 42)
                } else {
                    Button(action: send) {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color.accentColor))
                    }
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Auto first message
    private func autoSendInitial(goalID: UUID, message: String) {
        // 1) 加入使用者初始訊息
        appendMessage(role: .user, text: message)
        isGenerating = true
        
        Task {
            defer { isGenerating = false }
            
            guard let goal = store.goals.first(where: { $0.id == goalID }) else {
                appendMessage(role: .assistant, text: "Error: Could not find the goal to work on.")
                return
            }
            do {
                // 2) 呼叫 Gemini 產生任務 (使用我們最新的修改)
                let response = try await geminiService.breakDownGoal(
                    goalTitle: goal.title,
                    description: message,
                    preferences: store.preferences,
                    onboarding: store.onboarding,
                    workstyle: store.workstyle,
                    type: store.procrastinationType,
                    deadline: goal.deadline
                )
                
                let subTasks = response.tasks
                let chatReply = response.chatReply // AI 的個人化回覆

                // 3) 寫回該目標的子任務
                if let goalIndex = store.goals.firstIndex(where: { $0.id == goal.id }) {
                    store.goals[goalIndex].subTasks = subTasks
                    store.save()
                    
                    // 4) 顯示 AI 的個人化回覆
                    appendMessage(role: .assistant, text: chatReply)
                }
            } catch {
                appendMessage(role: .assistant, text: "I'm sorry, I had trouble breaking down your goal. Please check your network and try again. Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Manual send (still available)
    private func send() {
        guard !isGenerating else { return }
        
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        appendMessage(role: .user, text: text)
        let userInput = input
        input = ""
        isGenerating = true

        Task {
            defer { isGenerating = false }

            guard let goal = store.goals.last else {
                appendMessage(role: .assistant, text: "Error: Could not find the goal to work on.")
                return
            }
            
            do {
                // (使用我們最新的修改)
                let response = try await geminiService.breakDownGoal(
                    goalTitle: goal.title,
                    description: userInput,
                    preferences: store.preferences,
                    onboarding: store.onboarding,
                    workstyle: store.workstyle,
                    type: store.procrastinationType,
                    deadline: goal.deadline
                )
                
                let subTasks = response.tasks
                let chatReply = response.chatReply

                if let goalIndex = store.goals.firstIndex(where: { $0.id == goal.id }) {
                    store.goals[goalIndex].subTasks = subTasks
                    store.save()
                    
                    // 顯示 AI 的個人化回覆
                    appendMessage(role: .assistant, text: chatReply)
                }
                
            } catch {
                appendMessage(role: .assistant, text: "I'm sorry, I had trouble breaking down your goal. Please check your network and try again. Error: \(error.localizedDescription)")
            }
        }
    }
    
    // --- 修改：儲存到 store ---
    private func appendMessage(role: ChatMessage.Role, text: String) {
        guard var t = active else { return } // 安全地 unwrap
        t.messages.append(.init(role: role, text: text))
        t.lastUpdated = Date() // 更新時間
        store.upsertThread(t) // 儲存回 AppStore
    }
}

// MARK: - Helper Views & Models for BreakDownGoalView

private struct ConversationPickerSheet: View {
    @EnvironmentObject var store: AppStore // <-- 1. 加入 store
    @Binding var threads: [ChatThread]
    @Binding var activeThreadID: UUID?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // 排序：讓最新的在最上面
                ForEach(threads.sorted(by: { $0.lastUpdated > $1.lastUpdated })) { t in
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
                    // --- 修改：使用 store.deleteThreads ---
                    // 找出實際在 sorted list 中的 item
                    let sortedThreads = threads.sorted(by: { $0.lastUpdated > $1.lastUpdated })
                    let threadsToDelete = idx.map { sortedThreads[$0] }
                    
                    // 找出它們在 *store* 中的原始 index
                    var storeOffsets = IndexSet()
                    for thread in threadsToDelete {
                        if let storeIndex = store.conversations.firstIndex(where: { $0.id == thread.id }) {
                            storeOffsets.insert(storeIndex)
                        }
                    }
                    
                    store.deleteThreads(at: storeOffsets)
                    
                    // 重新驗證 activeID
                    if store.conversations.isEmpty { activeThreadID = nil }
                    else if activeThreadID == nil || store.conversations.contains(where: { $0.id == activeThreadID }) == false {
                        activeThreadID = store.conversations.first?.id
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
                        // --- 修改：使用 store.upsertThread ---
                        store.upsertThread(new)
                        activeThreadID = new.id
                        dismiss() // 建立後直接切換並關閉
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
    }
}

// MARK: - UI bits

struct MessageRow: View {
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
                .contextMenu {
                    Button("Copy", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = msg.text
                    }
                }
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                Text(msg.text)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.accentColor.opacity(0.15)))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .contextMenu {
                        Button("Copy", systemImage: "doc.on.doc") {
                            UIPasteboard.general.string = msg.text
                        }
                    }
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
