//
//  ContentView.swift
//

import SwiftUI
import Supabase

struct ContentView: View {

    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authVM: AuthViewModel

    @State private var showBottomSheet = false
    @State private var selectedTab = 0
    @State private var lastSelectedTab = 0
    @State private var showAddGoal = false
    @State private var showAddGroupGoal = false

    var body: some View {
        Group {
            if authVM.currentUser == nil {
                unauthenticatedView
            } else if authVM.didJustRegister && store.hasOnboarded == false {
                onboardingView
            } else {
                mainTabView
            }
        }
        .id(store.language)
    }

    // MARK: - Sub-views

    private var unauthenticatedView: some View {
        AuthView()
            .environmentObject(authVM)
            .environmentObject(store)
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
        .toolbarBackground(Color.themeYellow, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .tint(Color.themeBlue)
        .onChange(of: selectedTab) { newValue in
            if newValue == 2 {
                showBottomSheet = true
                selectedTab = lastSelectedTab
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
                    handleSelectMood(score: score)
                },
                onCreateGroupGoal: {
                    showBottomSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showAddGroupGoal = true
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

    // MARK: - Mood

    private func handleSelectMood(score: Int) {
        if let idx = store.moods.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        }) {
            var mood = store.moods[idx]
            mood.moodScore = score
            store.moods[idx] = mood
            Task {
                try? await SupabaseRepository.shared.upsertMood(mood)
                await store.saveSnapshotToCloud()
            }
        } else {
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
            print("✅ Supabase connected")
        } catch {
            print("❌ Supabase connection error:", error)
        }
    }
}
