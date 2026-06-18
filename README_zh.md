# 抗拖延實驗室｜Anti-delay Lab

> 一款結合 AI 與心理學的 iOS App，透過個人化任務拆解與 CBT 心情日記，幫助使用者戰勝拖延症。

[English](README.md)

---

## Demo

[▶ 觀看 Demo 影片](https://drive.google.com/drive/folders/1mB_a2rfpdAPlwQXGwFGSt1mypumTbJyE)

---

## 功能介紹

### AI 目標拆解
輸入目標後，Gemini AI 依照使用者的拖延類型、工作習慣與專注時長，自動拆解成可執行的每日任務，並透過對話方式持續調整計畫。

### 心情日記
以 CBT 認知行為治療為基礎的對話介面，AI 以「網友聊天」的語氣陪伴使用者，針對完美主義型或死線戰士型提供不同的回應策略。（我負責 UI + API 串接，Prompt 由隊友設計）

### 首頁 
今日任務總覽、進度環視覺化，以及根據拖延類型與當日完成率動態調整的激勵文案。

### 個人設定
入門問卷診斷拖延類型（完美主義型 / 死線戰士型），可設定工作風格、每日可用時數、專注時長與語言偏好（English / 繁體中文）。

### 👥 社群目標（隊友負責）
與朋友共同建立目標，支援合作或競爭模式，即時追蹤彼此進度。

### 📊 活動紀錄（隊友負責）
每週 / 每月任務完成率圖表，搭配心情趨勢分析。

---

## 🖼️ 畫面截圖

| 首頁 & 新增目標 | AI 拆解目標 & 心情日記 & 個人設定 |
|---|---|
| ![Home & Add Goal](screenshots/screen1.png) | ![Breakdown & Journal & Profile](screenshots/screen2.png) |

---

## 我負責範圍

這是三人小組專案，以下為我個人負責的部分：

| 項目 | 說明 |
|------|------|
| **前端 UI** | HomeView、BreakDownGoalView、JournalView、ProfileView、UIComponents 共用元件庫 |
| **Gemini API 串接** | `GeminiService.swift` — 串接 Firebase AI（Gemini 2.5 Flash Lite），處理 JSON 解析、code fence 清理、日期修正、每日任務上限邏輯 |
| **任務拆解 Prompt 設計** | 依拖延類型設計差異化 Prompt 策略（見下方 Prompt Engineering 章節）|
| **任務拆解功能** | 目標建立 → AI 拆解 → 子任務寫入資料庫 |
| **心情日記 API 串接** | 串接 Gemini API 至心情日記對話介面（Prompt 由隊友設計）|

---

## 技術架構

```
procrastination/
├── GeminiService.swift       # Gemini API 串接、Prompt 設計
├── HomeView.swift            # 首頁
├── BreakDownGoalView.swift   # AI 目標拆解對話介面
├── JournalView.swift         # 心情日記
├── ProfileView.swift         # 個人設定
├── UIComponents.swift        # 共用 UI 元件
├── Models.swift              # 全域資料模型、共用 extension
├── Store.swift               # AppStore 全域狀態管理
├── SupabaseRepository.swift  # 雲端資料庫操作
├── AuthService.swift         # 登入 / 註冊
└── ContentView.swift         # 根路由（Auth → Onboarding → Main）
```

### 使用技術

| 技術 | 用途 |
|------|------|
| **SwiftUI** | 全 UI 實作 |
| **Firebase AI (Gemini 2.5 Flash Lite)** | 任務拆解、心情日記 AI 回覆 |
| **Supabase** | 使用者認證、雲端資料同步 |
| **MarkdownUI** | AI 回覆的 Markdown 渲染 |

---

## 🤖 Prompt Engineering

核心挑戰是讓 AI 不只是「把目標切成幾個步驟」，而是真正根據使用者的心理狀態給出他們能執行的計畫。

### 個人化輸入層

每次呼叫 Gemini 時，Prompt 會帶入以下使用者資料：

```
- 拖延人格類型（完美主義型 / 死線戰士型）
- 每日可用時數（週一到週日分別設定）
- 慣用專注時長（< 15 min / 15–30 min / 30–60 min / > 1 hr）
- 心理特質量表（1–5 分）：完美主義傾向、起始焦慮、死線依賴
- 任務排程偏好、工作生活平衡習慣
- 截止日期與今日日期
```

### 依拖延類型的差異化策略

**完美主義型 (Perfectionist)**
- 第一個任務強制設計成低門檻的「醜草稿」，名稱刻意帶入「rough」、「草稿」、「不完美初版」等關鍵字，降低起始障礙
- 截止日期前 30–40% 的時間內就要產出第一份草稿，避免後期壓縮
- 最後幾天只保留輕量的潤飾 / 提交任務，不堆放重量工作

**死線戰士型 (Deadline Fighter)**
- 第一個任務設計成 5–15 分鐘的微步驟，專注在「打破靜摩擦」
- 在真實截止日前建立多個「人工迷你 deadline」，把衝刺分散到多天
- 任務標題強調行動感：「立刻開始」、「完成三行」、「第一階段死線」

### 輸出格式控制

Gemini 被要求回傳純 JSON，結構固定為：

```json
{
  "chatReply": "給使用者看的策略說明（約 150–250 字）",
  "tasks": [
    {
      "title": "任務名稱",
      "isCompleted": false,
      "dueDate": "YYYY-MM-DD",
      "estimatedDuration": "25 min"
    }
  ]
}
```

`chatReply` 有明確的結構要求：一段洞察說明計畫背後的「為什麼」、三個階段的 Roadmap（各有創意命名）、一句收尾鼓勵。

### 本地端後處理（防呆機制）

LLM 偶爾會產生超出截止日範圍的日期，或把太多任務堆在同一天，因此在 client 端加了後處理：

```swift
// 1. 日期修正：clamp 到 today ~ deadline 範圍內
// 2. 每日上限：超過 maxTasksPerDay 的任務自動合併成 Bundle
decoded.tasks = postProcessTasks(decoded.tasks, start: today, end: deadlineDate, maxPerDay: 3)
```
