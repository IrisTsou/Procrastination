//
//  JournalView.swift
//  procrastination
//
//  Created by Iris Tsou on 2025/10/25.
//
import SwiftUI

struct JournalView: View {
    @Environment(GeminiService.self) private var geminiService
    @EnvironmentObject var store: AppStore

    // --- 1. 定義一個固定的 ID 給日誌聊天室 ---
    // 這樣我們才能在 store.conversations 中準確地找到它
    // 使用一個獨特且固定的 UUID 字串
    private let journalThreadID: UUID = UUID(uuidString: "A1B2C3D4-E5F6-7890-1234-567890ABCDEF")! // 你可以用任何固定的 UUID

    @State private var input = ""
    // --- 2. 移除 @State private var messages ---
    // 我們將改為直接讀取 store

    @State private var isGenerating = false

    private let suggestions: [JournalSuggestion] = [
        .init(title: "Tell me how you feel when completing tasks?",
              subtitle: "Sense of achievement, exhausted…"),
        .init(title: "Do you face any bottlenecks?",
              subtitle: "Lack of motivation, outcome wasn’t as good as expected…"),
        .init(title: "What small win did you have today?",
              subtitle: "Finished a subtask, stayed focused…")
    ]

    // --- 3. 建立 Computed Property 來讀取 store ---

    /// 從 store 中取得 Journal 聊天室 (只讀)
    private var activeThread: ChatThread {
        // 嘗試在 store 中尋找
        if let thread = store.conversations.first(where: { $0.id == journalThreadID }) {
            return thread
        } else {
            // 如果在 store 找不到 (例如 App 第一次啟動)
            // 就建立一個新的、預設的
            let defaultThread = ChatThread(
                id: journalThreadID, // 使用我們的固定 ID
                title: "Mood Journal",
                messages: [
                    .init(role: .assistant, text: "How are you feeling today? You can tell me anything.")
                ],
                lastUpdated: Date() // 設定初始時間
            )
            // **重要**：立刻把它存回 store
            // 這需要在主執行緒執行，因為會修改 @Published 屬性
            DispatchQueue.main.async {
                store.upsertThread(defaultThread)
            }
            return defaultThread
        }
    }

    /// 取得要顯示的訊息列表
    private var messages: [ChatMessage] {
        // 從 activeThread 取得最新的訊息列表
        return activeThread.messages
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { msg in // <-- 現在會讀取 store
                                MessageRow(msg: msg).id(msg.id)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .onChange(of: messages.count) { // 監聽 computed property
                        // 確保 proxy 操作也在主執行緒
                        DispatchQueue.main.async {
                             withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                        }
                    }
                }
                bottomComposer
            }
            .navigationTitle("Mood Journal")
            .navigationBarTitleDisplayMode(.inline)
             // --- (可選) 加入清除歷史紀錄按鈕 ---
             .toolbar {
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button("Clear History", role: .destructive) {
                         clearJournalHistory() // 呼叫清除函式
                     }
                 }
             }
        }
    }

    private var bottomComposer: some View {
        // (這個 View 保持不變)
        VStack(spacing: 12) {
            GeometryReader { geo in
                let cardW = geo.size.width * 0.82
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(suggestions) { s in
                            JournalSuggestionCard(s, width: cardW) {
                                input = s.title
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .contentMargins(.horizontal, 16)
            }
            .frame(height: 140)

            HStack(spacing: 10) {
                TextField("Ask me anything…", text: $input, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                if isGenerating {
                    ProgressView()
                        .frame(width: 40, height: 40)
                } else {
                    Button(action: send) {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.accentColor))
                    }
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
    }

    private func send() {
        guard !isGenerating else { return }

        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // --- 4. 修改儲存邏輯 ---

        // 取得目前的聊天室 (確保取得的是最新的)
        var thread = activeThread

        // 建立新訊息並加入
        let userMessage = ChatMessage(role: .user, text: text)
        thread.messages.append(userMessage)
        thread.lastUpdated = Date() // 更新時間戳

        // 立即儲存使用者訊息 (讓 UI 馬上更新)
        store.upsertThread(thread)

        let currentHistory = thread.messages // 把最新的 history 傳給 AI
        let newMessageText = input
        input = "" // 清空輸入框
        isGenerating = true

        Task {
            defer { isGenerating = false }

            do {
                let responseText = try await geminiService.getJournalResponse(history: currentHistory, newMessage: newMessageText)

                // 建立 AI 回覆訊息並加入 (再次取得 thread 確保是最新的)
                var updatedThread = activeThread
                let aiMessage = ChatMessage(role: .assistant, text: responseText)
                updatedThread.messages.append(aiMessage)
                updatedThread.lastUpdated = Date() // 更新時間戳

                // 儲存 AI 回覆
                store.upsertThread(updatedThread)

            } catch {
                // 發生錯誤時，也儲存一則錯誤訊息 (再次取得 thread 確保是最新的)
                 var errorThread = activeThread
                let errorMessage = ChatMessage(role: .assistant, text: "Sorry, I encountered an error. Please try again.")
                errorThread.messages.append(errorMessage)
                errorThread.lastUpdated = Date()
                store.upsertThread(errorThread)
            }
        }
    }

     // --- (可選) 清除歷史紀錄的函式 ---
     private func clearJournalHistory() {
         // 取得目前的聊天室
         var thread = activeThread
         // 保留第一則訊息或建立預設訊息
         if let firstMessage = thread.messages.first {
             thread.messages = [firstMessage]
         } else {
             thread.messages = [ChatMessage(role: .assistant, text: "How are you feeling today? You can tell me anything.")]
         }
         thread.lastUpdated = Date()
         // 存回 store
         store.upsertThread(thread)
     }
}

// (底下的 JournalSuggestion 和 JournalSuggestionCard 保持不變)
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


// Bubble View (如果你有用到它的話，也需確認存在)
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
