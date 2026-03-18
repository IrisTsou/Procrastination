<<<<<<< HEAD
import SwiftUI
=======
//
//  ContentView.swift
//

import SwiftUI
import Supabase
>>>>>>> teamrepo/main

struct ContentView: View {

    @EnvironmentObject var store: AppStore
<<<<<<< HEAD
=======
    @EnvironmentObject var authVM: AuthViewModel

>>>>>>> teamrepo/main
    @State private var showBottomSheet = false
    @State private var selectedTab = 0
    @State private var lastSelectedTab = 0
    @State private var showAddGoal = false
<<<<<<< HEAD

    var body: some View {
        Group {
            if store.hasOnboarded == false {
                // Onboarding 階段：僅顯示問卷頁，不顯示 TabView
                OnboardingQuestionsView()
                    .environmentObject(store)
            } else {
                // 已完成 Onboarding：顯示主分頁
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem { Label("Home", systemImage: "house.fill") }
                        .tag(0)

                    JournalView()
                        .tabItem { Label("Mood", systemImage: "heart.fill") }
                        .tag(1)

                    Text("").hidden() // 佔位用的 Add 分頁
                        .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                        .tag(2)

                    ActivityView()
                        .tabItem { Label("Activity", systemImage: "chart.bar.fill") }
                        .tag(3)

                    ProfileView()
                        .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                        .tag(4)
                }
                .onChange(of: selectedTab) { oldValue, newValue in
                    if newValue == 2 {
                        showBottomSheet = true
                        selectedTab = oldValue
                    } else {
                        lastSelectedTab = newValue
                    }
                }
                .sheet(isPresented: $showBottomSheet) {
                    BottomSheet(
                        isPresented: $showBottomSheet,
                        onSetNewGoal: {
                            showBottomSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                showAddGoal = true
                            }
                        },
                        onSelectMood: { score in
                            if let idx = store.moods.firstIndex(where: {
                                Calendar.current.isDate($0.date, inSameDayAs: Date())
                            }) {
                                store.moods[idx].moodScore = score
                                store.save()
                            } else {
                                store.addMood(score: score, note: "")
                            }
                        }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
                .fullScreenCover(isPresented: $showAddGoal) {
                    AddEntryView()
                        .environmentObject(store)
                }
            }
        }
    }
}

struct TabButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isSelected ? .blue : .secondary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    // Provide both AppStore and GeminiService for previews to avoid environment crashes.
    let store = AppStore()
    let gemini = GeminiService()
    return ContentView()
        .environmentObject(store)
        .environment(gemini)
}
=======
    @State private var showAddGroupGoal = false
    @State private var supabaseStatus = "Checking Supabase…"

    var body: some View {
        Group {
            if authVM.currentUser == nil {
                unauthenticatedView
            } else if authVM.didJustRegister && store.hasOnboarded == false {
                onboardingView
            } else {
                mainTabView
                    .task(id: authVM.currentUser?.id) {
                        // ✅ 每次換使用者時，跑一次 smoke 測試
                        await SupabaseRepository.shared.smokeInsertUserProfilesMinimal()
                    }
            }
        }.id(store.language)
        // ⛔️ 這裡原本的 .onAppear + switchUser 已經移除
    }

    // MARK: - 子 View 抽出，減少 body 複雜度

    private var unauthenticatedView: some View {
        AuthView()
            .environmentObject(authVM)
    }

    private var onboardingView: some View {
        OnboardingQuestionsView()
            .environmentObject(store)
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            JournalView()
                .tabItem { Label("Mood", systemImage: "heart.fill") }
                .tag(1)

            // 中間的「+」Tab：點擊時不真的切 tab，而是打開 BottomSheet
            Text("").hidden()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(2)

            ActivityView()
                .tabItem { Label("Activity", systemImage: "chart.bar.fill") }
                .tag(3)

            GroupListView()
                .tabItem { Label("Social", systemImage: "person.3.fill") }
                .tag(4)
        }
        // ⭐ 這兩行讓 TabBar 背景變 themeYellow
        .toolbarBackground(Color.themeYellow, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)

        // ⭐ 這行讓「選到的」icon + 文字變 themeBrown
        .tint(Color.themeBlue)
        
        .onChange(of: selectedTab) { newValue in
            if newValue == 2 {
                // 點到中間 + → 打開 bottom sheet，tab 保持在舊的
                showBottomSheet = true
                selectedTab = lastSelectedTab
            } else {
                lastSelectedTab = newValue
            }
        }
        // Bottom Sheet：新增目標 / 心情 / 群組目標
        .sheet(isPresented: $showBottomSheet) {
            BottomSheet(
                isPresented: $showBottomSheet,
                onSetNewGoal: {
                    print("👉 onSetNewGoal from ContentView")
                    showBottomSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showAddGoal = true
                    }
                },
                onSelectMood: { score in
                    print("👉 onSelectMood from ContentView: \(score)")
                    handleSelectMood(score: score)
                },
                onCreateGroupGoal: {
                    print("🔥 onCreateGroupGoal from ContentView")
                    showBottomSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showAddGroupGoal = true
                    }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        // 個人目標建立畫面
        .fullScreenCover(isPresented: $showAddGoal) {
            AddEntryView()
                .environmentObject(store)
        }
        // 群組目標建立畫面
        .fullScreenCover(isPresented: $showAddGroupGoal) {
            NavigationStack {
                AddGroupEntryView()
                    .environmentObject(store)
                    .environmentObject(authVM)
            }
        }
        .task {
            await probeSupabase()
        }
    }

    // MARK: - 處理心情選擇（雲端版）

    private func handleSelectMood(score: Int) {
        // 找當天是否已有心情記錄
        if let idx = store.moods.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        }) {
            var mood = store.moods[idx]
            mood.moodScore = score
            store.moods[idx] = mood

            // 這裡目前只有 upsert Mood 表
            Task {
                try? await SupabaseRepository.shared.upsertMood(mood)
                // 如果之後要讓 snapshot 也跟著更新，可以再加：
                await store.saveSnapshotToCloud()
            }
        } else {
            // 沒有的話就新增（這個會自動呼叫 saveSnapshotToCloud）
            store.addMood(score: score, note: "")
        }
    }

    // MARK: - Supabase 連線測試

    private func probeSupabase() async {
        do {
            let client = SupabaseManager.shared.client
            _ = try await client
                .from("goals")
                .select()
                .limit(1)
                .execute()
            await MainActor.run { supabaseStatus = "Supabase connected ✅" }
        } catch {
            print("❌ Supabase connection error:", error)
            await MainActor.run { supabaseStatus = "Supabase error: \(error.localizedDescription)" }
        }
    }
}
>>>>>>> teamrepo/main
