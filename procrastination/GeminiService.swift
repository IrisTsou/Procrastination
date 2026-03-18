<<<<<<< HEAD
// file name: GeminiService.swift

import Foundation
import FirebaseAI
import Observation
=======
// GeminiService.swift
import Foundation
import FirebaseAI
import Observation
import SwiftUI

// MARK: - Errors
>>>>>>> teamrepo/main

enum GeminiError: Error {
    case modelInitializationError
    case jsonParsingError(Error)
    case generationError(String)
}

<<<<<<< HEAD
=======
// MARK: - Service

>>>>>>> teamrepo/main
@Observable
@MainActor
class GeminiService {
    
    private var generativeModel: GenerativeModel
    
<<<<<<< HEAD
=======
    // ✅ 每日任務上限（要 2 個就把 3 改成 2）
    private let maxTasksPerDay: Int = 3
    
>>>>>>> teamrepo/main
    init() {
        let ai = FirebaseAI.firebaseAI()
        self.generativeModel = ai.generativeModel(modelName: "gemini-2.5-flash-lite")
    }
    
<<<<<<< HEAD
    // MARK: - Main Breakdown Function
    
    /// 這是主要的函式，它接收所有個人化資訊並呼叫 Gemini
    func generateInitialBreakdown(
        goal: Goal,
        preferences: UserPreferences,
        onboarding: Onboarding,
        workstyle: Workstyle,
        type: ProcrastinationType
    ) async throws -> GoalBreakdownResponse {
        
        print("正在向 Gemini 發送請求...")
        
        // 1. 建立一個包含 *所有* 資訊的 preferencesSummary
        let preferencesSummary = """
        - Task Arrangement Preference: \(preferences.arrangeStrategy.rawValue)
        - Work/Life Balance: \(preferences.weekdayWeekend.rawValue)
        - Typical Focus Span: \(preferences.focusSpan.rawValue)
        - Preference for Long Tasks: \(preferences.longTask.rawValue)
        - Available daily hours (Mon-Sun): \(workstyle.dailyHours)
        - User's Procrastination Archetype: \(type.rawValue)
=======
    // MARK: - Main Breakdown Function（拆解任務）

    /// 主要生成函式：接收已「字串化」的偏好（PreferenceDTO）
    func generateInitialBreakdown(
        goal: Goal,
        preferences: PreferenceDTO,
        onboarding: Onboarding,
        workstyle: Workstyle,
        type: ProcrastinationType,
        language: String
    ) async throws -> GoalBreakdownResponse {
        
        print("正在向 Gemini 發送請求...")
        let langInstruction = (language == "en")
                ? "Please output all content (chatReply and tasks) in English."
                : "請使用繁體中文 (Traditional Chinese) 回覆所有的內容 (chatReply 與 tasks)。"
        
        // 1) 使用 DTO 組合偏好摘要
        let preferencesSummary = """
        - Task Arrangement Preference: \(preferences.arrangeStrategy)
        - Work/Life Balance: \(preferences.weekdayWeekend)
        - Typical Focus Span: \(preferences.focusSpan)
        - Preference for Long Tasks: \(preferences.longTask)
        - Available daily hours (Mon-Sun): \(workstyle.dailyHours)
        - User's Procrastination Archetype (zh-TW): \(type.rawValue)
>>>>>>> teamrepo/main
        - Tends to wait for perfection before starting (1-5 scale): \(onboarding.perfectionismPrep)
        - Tends to feel anxious when starting important tasks (1-5 scale): \(onboarding.anxietyStart)
        - Tends to do things at the last minute (1-5 scale): \(onboarding.lastMinute)
        """
<<<<<<< HEAD

        let todayFormatted = Date().formatted(.dateTime.year().month().day())
        let deadlineFormatted = goal.deadline?.formatted(.dateTime.year().month().day()) ?? "Not set"
        
        // 2. 建立 Prompt (使用上面的 preferencesSummary)
        // --- PROMPT 已根據你的新需求修改 ---
        let prompt = """
        You are a supportive and expert productivity coach. Your task is to help a user break down a new goal into actionable steps, personalizing the plan based on their unique habits and preferences.

        **The User's Goal:**
        - Title: "\(goal.title)"
        - Description: "\(goal.subTasks.first?.title ?? "No description provided.")"
        - Deadline: \(deadlineFormatted)
        - Today's Date: \(todayFormatted)

        **The User's Profile (Habits and Preferences):**
        \(preferencesSummary)

        **Your Task:**
        Generate a response as a single JSON object. This object must have two keys: "chatReply" and "tasks".
        **1. "tasks" (The JSON Array):**
        - This must be a JSON array of sub-task objects, representing the FULL plan.
        - Each task object must have **FOUR** keys:
          1. "title": (String) The name of the actionable task.
          2. "isCompleted": (Boolean) Always `false` initially.
          3. "dueDate": (String) The scheduled date in "YYYY-MM-DD" format.
            **IMPORTANT:** Dates MUST be strictly between **today (\(todayFormatted))** and the **deadline (\(deadlineFormatted))**.
            **Do NOT generate dates outside this range.** The year MUST be correct (e.g., 2025).
          4. "estimatedDuration": (String) A human-readable estimate of how long the task will take, considering the user's focus span (e.g., "30 minutes", "1 hour", "20-25 minutes").

        **2. "chatReply" (The User-Facing Message):**
        - This must be a friendly, encouraging, and personalized welcome message.
        - It **MUST** present the new tasks as a **bulleted list**.
        - Each bullet point should clearly state the task's `title`, its `dueDate` (e.g., "(Oct 25)"), and its `estimatedDuration` (e.g., "(Est: 30 min)").
        - **IMPORTANT:** If the full plan contains more than 5 tasks, only list the *first 3-5 tasks* in the `chatReply` and add a friendly note like "Here are your first few steps! You can see the full plan on your home screen."
        - The entire `chatReply` must be a single string, using "\\n" for new lines and bullet points.

        **Example of desired JSON output:**
        {
          "chatReply": "Awesome goal! Based on your preference for splitting up work, I've broken it down for you. Here are your first few steps:\\n\\n- (Oct 25) First personalized task (Est: 30 minutes)\\n- (Oct 26) Second personalized task (Est: 45 minutes)\\n- (Oct 27) Third task (Est: 30 minutes)\\n\\nYou can see the full plan on your home screen!",
          "tasks": [
            { "title": "First personalized task", "isCompleted": false, "dueDate": "2025-10-25", "estimatedDuration": "30 minutes" },
            { "title": "Second personalized task", "isCompleted": false, "dueDate": "2025-10-26", "estimatedDuration": "45 minutes" },
          ]
        }

        Now, generate the JSON for the user's goal based on all the provided information. Only output the raw JSON object, without any other text or markdown formatting.
        """
        
        // 4. 呼叫 API 並解碼
=======
        
        // 2) 根據拖延類型產生「拆解 & 排程準則」
        let archetypePlanningRules = breakdownPlanningStyleFor(
            archetypeRaw: type.rawValue,
            onboarding: onboarding,
            preferences: preferences,
            workstyle: workstyle
        )
        
        // 日期格式
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = .current
        df.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let todayFormatted = df.string(from: today)
        let deadlineDate = goal.deadline ?? Calendar.current.date(byAdding: .day, value: 7, to: today)!
        let deadlineFormatted = df.string(from: deadlineDate)
        
        // 3) Prompt：加入「依拖延類型拆解」的明確規則
        let prompt = """
        You are an expert Behavioral Productivity Coach.
        Your goal is to create a realistic, actionable plan that overcomes the user's specific procrastination triggers.

        ## 1. The Context
        - **Goal:** "\(goal.title)"
        - **Details:** "\(goal.subTasks.first?.title ?? "No description provided.")"
        - **Deadline:** \(deadlineFormatted) (Inclusive)
        - **Today:** \(todayFormatted)
        - **Target Language:** Traditional Chinese (zh-TW).

        ## 2. The User Profile (Data)
        - **Archetype:** "\(type.rawValue)"
        - **Focus Span:** \(preferences.focusSpan) minutes
        - **Daily Capacity:** \(workstyle.dailyHours) hours
        - **Psychological Traits:**
        \(preferencesSummary)

        ## 3. STRATEGY GUIDE (How to handle the Archetype)
        You MUST apply the following strategy based on the User's Archetype:

        ### IF Archetype is "完美主義者 (Perfectionist)"
        - **Strategy:** Lower the bar. The first task MUST be non-intimidating (e.g., "Ugly Draft" or "Outline"). Use Time-Boxing.
        - **Tone:** Soothing, encouraging, empathetic.
        - **Task Naming Keywords:** "草稿 (Draft)", "快速瀏覽 (Quick scan)", "不完美初版 (Rough version)".

        ### IF Archetype is "死線戰士 (Deadline Fighter)"
        - **Strategy:** Create Artificial Urgency. The first task MUST be a micro-step (<15m) to break friction. Front-load actionable tasks to TODAY.
        - **Tone:** Energetic, urgent, pushy.
        - **Task Naming Keywords:** "立刻開始 (Start Now)", "完成三行 (Write 3 lines)", "第一階段死線 (Stage 1 Deadline)".

        ## 4. Execution Rules
        - **Granularity:** Tasks must be sized according to the user's Focus Span. No vague tasks.
        - **Scheduling:** Distribute tasks logically. Respect Daily Capacity & Max Tasks (\(maxTasksPerDay)).
        - **Output Format:** RAW JSON ONLY (No markdown fences, no explanatory text).

        ## 5. JSON Structure
        {
          "chatReply": "String. A strategic coaching message in Traditional Chinese (zh-TW).
              - **CRITICAL CONSTRAINT**: DO NOT list specific daily tasks or dates here (Keep those for the 'tasks' array). Avoid Avoid excessive intimacy.
              - **LENGTH**: Compact and punchy (approx. 150-250 Chinese characters).
              - **STRUCTURE**:
                1. **Insight**: 1-2 sentences explaining the 'Why' behind this plan based on their Archetype.
                2. **The Roadmap**: Break the plan into 3 phases (Short/Mid/Long-term).
                   - Give each phase a creative **Specific Action Name** (e.g., 'Phase 1: Dirty Draft Mode').
                   - Briefly explain the **Core Activity** of each phase.
                3. **Closing**: A final encouraging nudge.
              - **FORMATTING**: Use bullet points and **Bold** for phase names to ensure scannability. Use \\n\\n to separate paragraphs.
              - **ARCHETYPE LOGIC**:
                - **Perfectionist**: Phase names should sound safe and low-pressure (e.g., 'Exploration Phase', 'Rough Outline'). Emphasize that quality comes later.
                - **Deadline Fighter**: Phase names should sound active and milestone-based (e.g., 'Quick Start', 'Sprint 1'). Emphasize speed and momentum.",
              
          "tasks": [
            {
              "title": "String. Actionable step in Traditional Chinese (zh-TW).",
              "isCompleted": false,
              "dueDate": "YYYY-MM-DD",
              "estimatedDuration": "String (e.g., '25 min')"
            }
          ]
        }
        """
        
        // 4) 呼叫 Gemini 並解析 JSON
>>>>>>> teamrepo/main
        do {
            let response = try await generativeModel.generateContent(prompt)
            print("已成功從 Gemini 收到回應。")
            
            guard var text = response.text else {
                throw GeminiError.generationError("Failed to get valid text from response.")
            }

<<<<<<< HEAD
            // 清理 JSON 字串
            if text.hasPrefix("```json\n") {
                text = String(text.dropFirst(7))
            }
            if text.hasSuffix("\n```") {
                text = String(text.dropLast(4))
            }
            text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) // Add CharacterSet.

            guard let jsonData = text.data(using: String.Encoding.utf8) else {
                throw GeminiError.generationError("Failed to convert cleaned text to data.")
            }
            
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            let decodedResponse = try decoder.decode(GoalBreakdownResponse.self, from: jsonData)
            return decodedResponse
=======
            // 清理可能的 code fence
            if text.hasPrefix("```json\n") { text = String(text.dropFirst(7)) }
            if text.hasPrefix("```") { text = String(text.dropFirst(3)) }
            if text.hasSuffix("\n```") { text = String(text.dropLast(4)) }
            if text.hasSuffix("```") { text = String(text.dropLast(3)) }
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = text.data(using: .utf8) else {
                throw GeminiError.generationError("Failed to convert cleaned text to data.")
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(df)
            var decoded = try decoder.decode(GoalBreakdownResponse.self, from: jsonData)
            
            // 5) 本地端保險機制：日期修正 + 每日上限合併
            decoded.tasks = postProcessTasks(
                decoded.tasks,
                start: today,
                end: deadlineDate,
                maxPerDay: maxTasksPerDay
            )
            
            return decoded
>>>>>>> teamrepo/main
            
        } catch let error as DecodingError {
            print("JSON Parsing Error: \(error)")
            throw GeminiError.jsonParsingError(error)
        } catch {
            print("Generation Error: \(error)")
<<<<<<< HEAD
            print("Gemini 請求失敗，錯誤: \(error.localizedDescription)")
=======
>>>>>>> teamrepo/main
            throw GeminiError.generationError(error.localizedDescription)
        }
    }
    
<<<<<<< HEAD
    // MARK: - Journal Response Function
    
=======
    // MARK: - Journal Response（簡單版：保留，必要時可以 fallback）

>>>>>>> teamrepo/main
    func getJournalResponse(history: [ChatMessage], newMessage: String) async throws -> String {
        let firebaseHistory = history.map { message -> ModelContent in
            let role = message.role == .user ? "user" : "model"
            return ModelContent(role: role, parts: [TextPart(message.text)])
        }
        let chat = generativeModel.startChat(history: firebaseHistory)
        do {
            let response = try await chat.sendMessage(newMessage)
            return response.text ?? "I'm sorry, I couldn't process that. Could you try again?"
        } catch {
<<<<<<< HEAD
             throw GeminiError.generationError(error.localizedDescription)
        }
    }
    
    // MARK: - Convenience Wrapper (Wrapper Function)
    
    /// 這是給 View 呼叫的「包裝」函式，它會收集所有需要的參數，然後呼叫上面的主要函式
    func breakDownGoal(
        goalTitle: String,
        description: String,
        preferences: UserPreferences,
        onboarding: Onboarding,
        workstyle: Workstyle,
        type: ProcrastinationType,
        deadline: Date? = nil
    ) async throws -> GoalBreakdownResponse { // <-- **重要修改**：回傳完整的 Response
=======
            throw GeminiError.generationError(error.localizedDescription)
        }
    }
    
    // MARK: - Journal Response（✅ 新版：CBT + 網友語氣 + 兩類型差異）

    func getJournalResponsePersonalized(
        history: [ChatMessage],
        newMessage: String,
        preferences: PreferenceDTO,
        onboarding: Onboarding,
        workstyle: Workstyle,
        type: ProcrastinationType
    ) async throws -> String {
        
        let styleAdvice = journalStyleFor(
            archetypeRaw: type.rawValue,
            onboarding: onboarding
        )
        
        let systemLikePrompt = """
        You are a warm, down-to-earth online friend chatting in a private DM with the user.
        You reply in Traditional Chinese (zh-TW), like a supportive網友, not like an AI assistant or formal therapist.

        ## User Profile (for CBT-style guidance, do NOT repeat as a list)
        - Archetype (zh-TW label): \(type.rawValue)
        - Perfectionism (1-5): \(onboarding.perfectionismPrep)
        - Anxiety at start (1-5): \(onboarding.anxietyStart)
        - Last-minute tendency (1-5): \(onboarding.lastMinute)

        ## General style rules (VERY IMPORTANT)
        - Tone: 像一個懂事又不嘴砲的好友在聊天室聊天，口氣自然，不要太制式。
        - Use short sentences, casual wording, and at most 1–2 emojis（例如 🙂、🤍、🥹）.
        - Total length: 3–5 short sentences. Avoid long paragraphs or walls of text.
        - NO bullet points, NO numbered lists, NO markdown formatting, NO section titles.
        - At most ONE short follow-up question at the end（可以不問問題）; other句子以陪伴、回應為主。
        - Do NOT heavily repeat the user's original sentences. 回應要像自己真的在聽，而不是複誦。
        - Focus on ONE tiny next step or reframe,不要塞太多建議。

        ## CBT-style guidance (what you should DO in your reply)
        1) Briefly name and validate the emotion you infer（e.g. 壓力、愧疚、挫折、無力）.
        2) Gently challenge可能的自動想法或認知偏誤（例如全有全無、災難化、自我貶低），用溫柔而實際的角度重構。
        3) 提出「今天可以嘗試的一個很小的行為實驗」（5–15 分鐘就好），說明只是試試看，不用完美。
        4) 結尾用一句給力量的話，讓對方覺得「可以再試一次」，不要批評或說教。

        ## Archetype-specific coaching notes
        Use the following notes to adapt your CBT reframe and the small experiment:

        \(styleAdvice)

        ---

        使用者剛剛在心情日記裡寫下這段話（可能是中文或英文）：
        "\(newMessage)"

        現在請你用繁體中文直接回覆對方一段話，
        遵守以上所有規則，只輸出訊息內容，不要多做說明。
        """
        
        // 這裡可以選擇帶歷史，也可以只帶當前訊息
        let firebaseHistory = history.map { message -> ModelContent in
            let role = message.role == .user ? "user" : "model"
            return ModelContent(role: role, parts: [TextPart(message.text)])
        }
        
        let chat = generativeModel.startChat(history: firebaseHistory)
        
        do {
            let response = try await chat.sendMessage(systemLikePrompt)
            return response.text ?? "我在這裡陪你，有什麼感受都可以慢慢跟我說。"
        } catch {
            throw GeminiError.generationError(error.localizedDescription)
        }
    }
    
    // MARK: - 依拖延類型決定「回應風格 & CBT 重點」（Journal 用）

    private func journalStyleFor(archetypeRaw: String, onboarding: Onboarding) -> String {
        // 目前類型： "完美主義型"、"死線戰士型"
        if archetypeRaw.contains("完美") {
            return """
            ### 完美主義型使用者（perfectionist-type）
            - 典型模式：很怕「不夠好」、很容易全有全無（覺得沒辦法做到完美就乾脆不做），做事前會先要求自己想清楚、準備好。
            - 在回覆裡：
              - 多幫他看到「已經做到了哪些小地方」，淡化「一次就要做到最好」的壓力。
              - 用口語方式提醒：「先做一個很醜/很亂的版本也沒關係」、「今天只要完成 30% 就很不錯」。
              - 在認知重建時，可以指出：把事情當成 0 分 / 100 分 是一種想法，不是事實，可以試著接受「60 分也有價值」。
              - 安排的行為實驗要小且不完美，例如：「先隨便寫 3 句，亂也沒關係」、「今天只要打開檔案 + 寫一段就收工」。
            """

        } else if archetypeRaw.contains("死線") || archetypeRaw.contains("戰士") {
            return """
            ### 死線戰士型使用者（deadline-warrior / last-minute-type）
            - 典型模式：覺得自己「壓力來才做得出來」，平常會拖到最後一刻才衝刺，事後又很累、很後悔。
            - 在回覆裡：
              - 先理解他喜歡「最後衝刺的爽感」，但溫柔點出：那種方式很耗體力、也很消磨自信。
              - 認知重建時，可以質疑「一定要到最後一刻才做得出好東西嗎？」並舉例：先動一點點，反而可以讓最後的衝刺比較輕鬆。
              - 行為實驗要強調「超小的暖身」，例如：「現在先花 5–10 分鐘，把明天要做的三件事列出來就好」、「今天只先寫開頭一段」。
              - 語氣可以稍微有一點動力感，像在說：「先動一點點，之後的你會很感謝現在的自己」。
            """

        } else {
            return """
            ### 一般或混合型使用者
            - 以溫和、中性的方式陪伴，混合一點穩定跟鼓勵。
            - 認知重建時，不要太激烈，點到為止：幫他看到事情不是只有一種解讀。
            - 行為實驗仍然保持小且可行，例如：「今天先做 10 分鐘試試看」。
            """
        }
    }
    
    // MARK: - 依拖延類型產生「拆解 & 排程」準則（Breakdown 用）

    private func breakdownPlanningStyleFor(
        archetypeRaw: String,
        onboarding: Onboarding,
        preferences: PreferenceDTO,
        workstyle: Workstyle
    ) -> String {
        // 目前 app 的類型： "完美主義型"、"死線戰士型"
        if archetypeRaw.contains("完美") {
            // ✅ 完美主義型
            return """
            ### Planning rules for 完美主義型 (perfectionist-type) procrastination
            - Main risk: They delay starting until they can do it "perfectly", over-plan, and over-edit.
            - Task granularity:
              - Always start with a very small, imperfect, "rough" action (e.g. brain-dump, ugly outline, quick sketch).
              - Avoid more than ONE separate "research" or "planning" task before a first draft. If you add research, time-box it strictly (e.g. 20–30 minutes).
              - Prefer task titles that explicitly include words like "rough", "messy", "first pass", "B-minus version".
            - Scheduling:
              - Force an early, imperfect first draft well BEFORE the deadline (e.g. within the first 30–40% of the time window).
              - Schedule 1–2 short review / refinement passes later, close to the deadline, but keep each review task short.
              - Never put all heavy work on the last 1–2 days; those days should only contain light polishing / formatting / submission tasks.
            - Emotional protection:
              - Avoid wording that sounds like "final", "perfect", or "comprehensive" too early.
              - Use wording that reduces fear of judgment, e.g. "draft a messy version just for yourself" instead of "write the final report".
            """

        } else if archetypeRaw.contains("死線") || archetypeRaw.contains("戰士") {
            // ✅ 死線戰士型
            return """
            ### Planning rules for 死線戰士型 (deadline-warrior / last-minute-type) procrastination
            - Main risk: They ignore the task until the deadline is very close, then rush in a big panic sprint.
            - Task granularity:
              - Create EASY, LOW-FRICTION warm-up tasks at the very beginning (5–20 minutes), such as "open the document and write 3 bullet points".
              - Break large work into several checkpoints (outline, half draft, full draft, revision) so that progress is visible before the last day.
            - Scheduling:
              - Introduce explicit "mini-deadlines" several days BEFORE the real deadline, e.g. "finish rough outline by X", "complete 50% draft by Y".
              - Do NOT place the majority of effort on the final day; the last day should mainly be review, small fixes, and submission.
              - Even if the total window is short, ensure at least 2 different days contain meaningful progress tasks (not all on one day).
            - Motivation hacks:
              - Prefer task titles that emphasize quick wins and action, e.g. "10-minute starter pass", "write only the introduction today".
              - Make it clear what "good enough for today" means, to reduce the feeling of "I'll just do it all later".
            """

        } else {
            // ✅ 預設平衡型（防呆）
            return """
            ### Planning rules for GENERAL / MIXED-type procrastination
            - Use balanced granularity: tasks are 20–60 minutes each, each with a clear concrete action.
            - Ensure the user starts within the next 24 hours with a simple, low-friction task.
            - Avoid clustering all work on the last day; spread tasks across the available window.
            - Combine at most one short research/planning task with clear output (e.g. "collect 3 sources and write 3 bullets about each").
            """
        }
    }
    
    // MARK: - Wrapper：給 View 呼叫（注意：收 `PreferenceDTO`）
    
    func breakDownGoal(
        goalTitle: String,
        description: String,
        preferences: PreferenceDTO,
        onboarding: Onboarding,
        workstyle: Workstyle,
        type: ProcrastinationType,
        deadline: Date?,
        language: String
    ) async throws -> GoalBreakdownResponse {
>>>>>>> teamrepo/main
        
        var tempGoal = Goal(
            title: goalTitle,
            icon: "checklist",
            colorHex: "#4F46E5",
            deadline: deadline,
            reminders: [],
            subTasks: []
        )
        if description.isEmpty == false {
            tempGoal.subTasks = [TaskItem(title: description, isCompleted: false, dueDate: nil)]
        }
        
<<<<<<< HEAD
        // 呼叫 *主要* 函式，並傳入 *所有* 參數
=======
>>>>>>> teamrepo/main
        let response = try await generateInitialBreakdown(
            goal: tempGoal,
            preferences: preferences,
            onboarding: onboarding,
            workstyle: workstyle,
<<<<<<< HEAD
            type: type
        )
        
        return response // <-- **重要修改**：回傳完整的 Response
    }
}
=======
            type: type,
            language: language
        )
        return response
    }
}

// MARK: - Post-processing: 日期與每日上限收斂（dueDate 為 Date 版）

extension GeminiService {
    
    private func postProcessTasks(
        _ tasks: [TaskItem],
        start: Date,
        end: Date,
        maxPerDay: Int
    ) -> [TaskItem] {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)
        
        // 1) 修正日期
        var fixed = tasks.map { t -> TaskItem in
            var t = t
            if let d = t.dueDate {
                let day = cal.startOfDay(for: d)
                let clamped = min(max(day, startDay), endDay)
                t.dueDate = clamped
            } else {
                t.dueDate = endDay
            }
            t.isCompleted = false
            return t
        }
        
        // 2) 每日上限，超出的合併成 bundle
        var grouped: [Date: [TaskItem]] = [:]
        for t in fixed {
            let key = cal.startOfDay(for: t.dueDate ?? endDay)
            grouped[key, default: []].append(t)
        }
        
        var result: [TaskItem] = []
        let allDatesSorted = grouped.keys.sorted()
        
        for dateKey in allDatesSorted {
            let dayTasks = grouped[dateKey] ?? []
            if dayTasks.count <= maxPerDay {
                result.append(contentsOf: dayTasks)
            } else {
                let keepCount = max(1, maxPerDay - 1)
                let keep = Array(dayTasks.prefix(keepCount))
                let toMerge = Array(dayTasks.dropFirst(keepCount))
                
                let mergedTitle = "Bundle: " + toMerge.map { $0.title }.joined(separator: "; ")
                let mergedMinutes = toMerge
                    .compactMap { parseEstimatedDurationMinutes($0.estimatedDuration) }
                    .reduce(0, +)
                let defaultPerTask = 30
                let missingCount = toMerge.filter { parseEstimatedDurationMinutes($0.estimatedDuration) == nil }.count
                let mergedTotalMin = mergedMinutes + missingCount * defaultPerTask
                let mergedEst = formatMinutesToHuman(mergedTotalMin)
                
                let merged = TaskItem(
                    title: mergedTitle,
                    isCompleted: false,
                    dueDate: dateKey,
                    estimatedDuration: mergedEst
                )
                result.append(contentsOf: keep)
                result.append(merged)
            }
        }
        
        result.sort { (a, b) -> Bool in
            let da = a.dueDate ?? Date.distantFuture
            let db = b.dueDate ?? Date.distantFuture
            if da != db { return da < db }
            return a.title < b.title
        }
        
        return result
    }
    
    // 解析 estimatedDuration
    private func parseEstimatedDurationMinutes(_ s: String?) -> Int? {
        guard let s = s?.lowercased() else { return nil }
        if let rangeMatch = s.range(of: #"(\d+)\s*[-–]\s*(\d+)\s*min"#, options: .regularExpression) {
            let sub = String(s[rangeMatch])
            let nums = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
            if nums.count >= 2 { return nums[1] }
        }
        if let hourMatch = s.range(of: #"(\d+(\.\d+)?)\s*hour"#, options: .regularExpression) {
            let sub = String(s[hourMatch])
            let numStr = sub.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
            if let hours = Double(numStr) { return Int(round(hours * 60.0)) }
        }
        if let minMatch = s.range(of: #"(\d+)\s*min"#, options: .regularExpression) {
            let sub = String(s[minMatch])
            let nums = sub.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
            if let m = nums.first { return m }
        }
        return nil
    }
    
    private func formatMinutesToHuman(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) minutes" }
        let h = minutes / 60
        let m = minutes % 60
        if m == 0 { return "\(h) hour" + (h > 1 ? "s" : "") }
        return "\(h) hour" + (h > 1 ? "s" : "") + " \(m) minutes"
    }
}

// MARK: - Helpers

extension Date {
    var startOfDayLocal: Date { Calendar.current.startOfDay(for: self) }
}
>>>>>>> teamrepo/main
