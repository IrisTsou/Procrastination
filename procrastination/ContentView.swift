import SwiftUI

struct ContentView: View {

    @EnvironmentObject var store: AppStore
    @State private var showBottomSheet = false
    @State private var selectedTab = 0
    @State private var lastSelectedTab = 0
    @State private var showAddGoal = false

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
