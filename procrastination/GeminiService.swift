// GeminiService.swift
import Foundation
import FirebaseAI
import Observation

// MARK: - Errors

enum GeminiError: Error {
    case modelInitializationError
    case jsonParsingError(Error)
    case generationError(String)
}

// MARK: - Service

@Observable
@MainActor
class GeminiService {

    private var generativeModel: GenerativeModel

    // 每日任務上限（要 2 個就把 3 改成 2）
    private let maxTasksPerDay: Int = 3

    init() {
        let ai = FirebaseAI.firebaseAI()
        self.generativeModel = ai.generativeModel(modelName: "gemini-2.5-flash-lite")
    }

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

        // 1) 使用 DTO 組合偏好摘要
        let preferencesSummary = """
        - Task Arrangement Preference: \(preferences.arrangeStrategy)
        - Work/Life Balance: \(preferences.weekdayWeekend)
        - Typical Focus Span: \(preferences.focusSpan)
        - Preference for Long Tasks: \(preferences.longTask)
        - Available daily hours (Mon-Sun): \(workstyle.dailyHours)
        - User's Procrastination Archetype (zh-TW): \(type.rawValue)
        - Tends to wait for perfection before starting (1-5 scale): \(onboarding.perfectionismPrep)
        - Tends to feel anxious when starting important tasks (1-5 scale): \(onboarding.anxietyStart)
        - Tends to do things at the last minute (1-5 scale): \(onboarding.lastMinute)
        """

        // 2) 根據拖延類型產生「拆解 & 排程準則」
        let archetypePlanningRules = breakdownPlanningStyleFor(
            archetypeRaw: type.rawValue,
            onboarding: onboarding,
            preferences: preferences,
            workstyle: workstyle
        )

        // 日期格式（使用 Models.swift 統一的 DateFormatter.isoDate）
        let df = DateFormatter.isoDate

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

        ## 2. The User Profile (Data)
        - **Archetype:** "\(type.rawValue)"
        - **Focus Span:** \(preferences.focusSpan) minutes
        - **Daily Capacity:** \(workstyle.dailyHours) hours
        - **Psychological Traits:**
        \(preferencesSummary)

        ## 3. STRATEGY GUIDE (How to handle the Archetype)
        You MUST apply the following strategy based on the User's Archetype:

        \(archetypePlanningRules)

        ## 4. Execution Rules
        - **Granularity:** Tasks must be sized according to the user's Focus Span. No vague tasks.
        - **Scheduling:** Distribute tasks logically. Respect Daily Capacity & Max Tasks (\(maxTasksPerDay)).
        - **Output Format:** RAW JSON ONLY (No markdown fences, no explanatory text).
        - **Language:** \(language == "en" ? "Please output all content (chatReply and tasks) in English." : "請使用繁體中文 (Traditional Chinese) 回覆所有的內容 (chatReply 與 tasks)。")

        ## 5. JSON Structure
        {
          "chatReply": "String. A strategic coaching message.
              - CRITICAL CONSTRAINT: DO NOT list specific daily tasks or dates here. Keep those for the 'tasks' array.
              - LENGTH: Compact and punchy (approx. 150-250 characters).
              - STRUCTURE:
                1. Insight: 1-2 sentences explaining the 'Why' behind this plan based on their Archetype.
                2. The Roadmap: Break the plan into 3 phases (Short/Mid/Long-term).
                   - Give each phase a creative Specific Action Name.
                   - Briefly explain the Core Activity of each phase.
                3. Closing: A final encouraging nudge.
              - FORMATTING: Use bullet points and bold for phase names. Use \\n\\n to separate paragraphs.",

          "tasks": [
            {
              "title": "String. Actionable step.",
              "isCompleted": false,
              "dueDate": "YYYY-MM-DD",
              "estimatedDuration": "String (e.g., '25 min')"
            }
          ]
        }
        """

        // 4) 呼叫 Gemini 並解析 JSON
        do {
            let response = try await generativeModel.generateContent(prompt)
            print("已成功從 Gemini 收到回應。")

            guard var text = response.text else {
                throw GeminiError.generationError("Failed to get valid text from response.")
            }

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

        } catch let error as DecodingError {
            print("JSON Parsing Error: \(error)")
            throw GeminiError.jsonParsingError(error)
        } catch {
            print("Generation Error: \(error)")
            throw GeminiError.generationError(error.localizedDescription)
        }
    }

    // MARK: - Journal Response（個人化版：CBT + 網友語氣 + 兩類型差異）

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
        You reply in Traditional Chinese (zh-TW), like a supportive 網友, not like an AI assistant or formal therapist.

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
        - At most ONE short follow-up question at the end（可以不問問題）; other 句子以陪伴、回應為主。
        - Do NOT heavily repeat the user's original sentences. 回應要像自己真的在聽，而不是複誦。
        - Focus on ONE tiny next step or reframe，不要塞太多建議。

        ## CBT-style guidance (what you should DO in your reply)
        1) Briefly name and validate the emotion you infer（e.g. 壓力、愧疚、挫折、無力）.
        2) Gently challenge 可能的自動想法或認知偏誤（例如全有全無、災難化、自我貶低），用溫柔而實際的角度重構。
        3) 提出「今天可以嘗試的一個很小的行為實驗」（5–15 分鐘就好），說明只是試試看，不用完美。
        4) 結尾用一句給力量的話，讓對方覺得「可以再試一次」，不要批評或說教。

        ## Archetype-specific coaching notes
        \(styleAdvice)

        ---

        使用者剛剛在心情日記裡寫下這段話（可能是中文或英文）：
        "\(newMessage)"

        現在請你用繁體中文直接回覆對方一段話，
        遵守以上所有規則，只輸出訊息內容，不要多做說明。
        """

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

    // MARK: - Wrapper：給 View 呼叫

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

        var tempGoal = Goal(
            title: goalTitle,
            icon: "checklist",
            colorHex: "#4F46E5",
            deadline: deadline,
            reminders: [],
            subTasks: []
        )
        if !description.isEmpty {
            tempGoal.subTasks = [TaskItem(title: description, isCompleted: false, dueDate: nil)]
        }

        return try await generateInitialBreakdown(
            goal: tempGoal,
            preferences: preferences,
            onboarding: onboarding,
            workstyle: workstyle,
            type: type,
            language: language
        )
    }
}

// MARK: - Private: Archetype-specific Prompt Helpers

private extension GeminiService {

    /// Journal 回覆風格（依拖延類型）
    func journalStyleFor(archetypeRaw: String, onboarding: Onboarding) -> String {
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

    /// 任務拆解 Prompt 的規則段落（依拖延類型）
    func breakdownPlanningStyleFor(
        archetypeRaw: String,
        onboarding: Onboarding,
        preferences: PreferenceDTO,
        workstyle: Workstyle
    ) -> String {
        if archetypeRaw.contains("完美") {
            return """
            ### IF Archetype is 完美主義型 (perfectionist-type)
            - **Strategy:** Lower the bar. The first task MUST be non-intimidating (e.g., "Ugly Draft" or "Outline"). Use Time-Boxing.
            - **Tone:** Soothing, encouraging, empathetic.
            - **Task Naming Keywords:** "草稿 (Draft)", "快速瀏覽 (Quick scan)", "不完美初版 (Rough version)".
            - **Scheduling:** Force an early, imperfect first draft within the first 30–40% of the time window.
              Never put all heavy work on the last 1–2 days.
            """
        } else if archetypeRaw.contains("死線") || archetypeRaw.contains("戰士") {
            return """
            ### IF Archetype is 死線戰士型 (deadline-warrior / last-minute-type)
            - **Strategy:** Create Artificial Urgency. The first task MUST be a micro-step (<15m) to break friction.
            - **Tone:** Energetic, urgent, pushy.
            - **Task Naming Keywords:** "立刻開始 (Start Now)", "完成三行 (Write 3 lines)", "第一階段死線 (Stage 1 Deadline)".
            - **Scheduling:** Introduce explicit mini-deadlines several days BEFORE the real deadline.
              Do NOT place the majority of effort on the final day.
            """
        } else {
            return """
            ### GENERAL / MIXED-type
            - Use balanced granularity: tasks are 20–60 minutes each, each with a clear concrete action.
            - Ensure the user starts within the next 24 hours with a simple, low-friction task.
            - Avoid clustering all work on the last day.
            """
        }
    }
}

// MARK: - Private: Post-processing

private extension GeminiService {

    /// 日期修正 + 每日任務上限合併
    func postProcessTasks(
        _ tasks: [TaskItem],
        start: Date,
        end: Date,
        maxPerDay: Int
    ) -> [TaskItem] {
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let endDay = cal.startOfDay(for: end)

        // 1) 修正超出範圍的日期
        let fixed = tasks.map { t -> TaskItem in
            var t = t
            if let d = t.dueDate {
                let day = cal.startOfDay(for: d)
                t.dueDate = min(max(day, startDay), endDay)
            } else {
                t.dueDate = endDay
            }
            t.isCompleted = false
            return t
        }

        // 2) 按日分組，超出上限的合併成 bundle
        var grouped: [Date: [TaskItem]] = [:]
        for t in fixed {
            let key = cal.startOfDay(for: t.dueDate ?? endDay)
            grouped[key, default: []].append(t)
        }

        var result: [TaskItem] = []
        for dateKey in grouped.keys.sorted() {
            let dayTasks = grouped[dateKey] ?? []
            guard dayTasks.count > maxPerDay else {
                result.append(contentsOf: dayTasks)
                continue
            }

            let keepCount = max(1, maxPerDay - 1)
            let keep = Array(dayTasks.prefix(keepCount))
            let toMerge = Array(dayTasks.dropFirst(keepCount))

            let mergedTitle = "Bundle: " + toMerge.map { $0.title }.joined(separator: "; ")
            let mergedMinutes = toMerge
                .compactMap { parseEstimatedDurationMinutes($0.estimatedDuration) }
                .reduce(0, +)
            let missingCount = toMerge.filter { parseEstimatedDurationMinutes($0.estimatedDuration) == nil }.count
            let mergedEst = formatMinutesToHuman(mergedMinutes + missingCount * 30)

            result.append(contentsOf: keep)
            result.append(TaskItem(
                title: mergedTitle,
                isCompleted: false,
                dueDate: dateKey,
                estimatedDuration: mergedEst
            ))
        }

        return result.sorted {
            ($0.dueDate ?? .distantFuture) == ($1.dueDate ?? .distantFuture)
                ? $0.title < $1.title
                : ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
        }
    }

    func parseEstimatedDurationMinutes(_ s: String?) -> Int? {
        guard let s = s?.lowercased() else { return nil }
        if let m = s.range(of: #"(\d+)\s*[-–]\s*(\d+)\s*min"#, options: .regularExpression) {
            let nums = String(s[m]).components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
            if nums.count >= 2 { return nums[1] }
        }
        if let m = s.range(of: #"(\d+(\.\d+)?)\s*hour"#, options: .regularExpression) {
            let numStr = String(s[m]).components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
            if let hours = Double(numStr) { return Int(round(hours * 60)) }
        }
        if let m = s.range(of: #"(\d+)\s*min"#, options: .regularExpression) {
            let nums = String(s[m]).components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
            if let min = nums.first { return min }
        }
        return nil
    }

    func formatMinutesToHuman(_ minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes) minutes" }
        let h = minutes / 60
        let m = minutes % 60
        let base = "\(h) hour" + (h > 1 ? "s" : "")
        return m == 0 ? base : "\(base) \(m) minutes"
    }
}

