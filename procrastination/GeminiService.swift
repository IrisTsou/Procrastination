// file name: GeminiService.swift

import Foundation
import FirebaseAI
import Observation

enum GeminiError: Error {
    case modelInitializationError
    case jsonParsingError(Error)
    case generationError(String)
}

@Observable
@MainActor
class GeminiService {
    
    private var generativeModel: GenerativeModel
    
    init() {
        let ai = FirebaseAI.firebaseAI()
        self.generativeModel = ai.generativeModel(modelName: "gemini-2.5-flash-lite")
    }
    
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
        - Tends to wait for perfection before starting (1-5 scale): \(onboarding.perfectionismPrep)
        - Tends to feel anxious when starting important tasks (1-5 scale): \(onboarding.anxietyStart)
        - Tends to do things at the last minute (1-5 scale): \(onboarding.lastMinute)
        """

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
        do {
            let response = try await generativeModel.generateContent(prompt)
            print("已成功從 Gemini 收到回應。")
            
            guard var text = response.text else {
                throw GeminiError.generationError("Failed to get valid text from response.")
            }

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
            
        } catch let error as DecodingError {
            print("JSON Parsing Error: \(error)")
            throw GeminiError.jsonParsingError(error)
        } catch {
            print("Generation Error: \(error)")
            print("Gemini 請求失敗，錯誤: \(error.localizedDescription)")
            throw GeminiError.generationError(error.localizedDescription)
        }
    }
    
    // MARK: - Journal Response Function
    
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
        
        // 呼叫 *主要* 函式，並傳入 *所有* 參數
        let response = try await generateInitialBreakdown(
            goal: tempGoal,
            preferences: preferences,
            onboarding: onboarding,
            workstyle: workstyle,
            type: type
        )
        
        return response // <-- **重要修改**：回傳完整的 Response
    }
}
