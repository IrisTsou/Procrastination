//
//  ProfileView.swift
//  procrastination
//
//  Created by Iris Tsou on 2025/10/25.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var authVM: AuthViewModel
    @State private var tab: ProfileTab = .workstyle
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // 頭像卡片
                    Card {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(Text("🙂").font(.title2))

                            VStack(alignment: .leading) {
                                // ✅ 顯示使用者名稱（安全 unwrap）
                                Text(
                                    {
                                        if let user = authVM.currentUser {
                                            if let name = user.displayName,
                                               !name.isEmpty {
                                                return name
                                            } else {
                                                return user.email
                                            }
                                        } else {
                                            return "User"
                                        }
                                    }()
                                )
                                .bold()

                                Text("Your Profile")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            Spacer()
                        }
                    }
                    
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Language / 語言").font(.headline)
                            
                            HStack(spacing: 8) {
                                ForEach(AppLanguage.allCases) { lang in
                                    Button {
                                        store.language = lang
                                    } label: {
                                        Text(lang.displayName)
                                            .font(.headline)
                                            .foregroundStyle(store.language == lang ? .black : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                Capsule()
                                                    .fill(store.language == lang ? Color.themeBlue : Color.gray.opacity(0.12))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(6)
                            .background(Capsule().fill(Color.gray.opacity(0.12)))
                        }
                    }

                    // 分段控制
                    ProfileSegmented(selection: $tab)

                    // 主體內容
                    Group {
                        switch tab {
                        case .workstyle:
                            WorkstyleSection().environmentObject(store)
                        case .characteristics:
                            CharacteristicsSection().environmentObject(store)
                        }
                    }

                    // ✅ 登出按鈕
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        Text("Log Out")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 24)
                    .confirmationDialog(
                        "Are you sure you want to log out?",
                        isPresented: $showLogoutConfirm
                    ) {
                        Button("Log Out", role: .destructive) {
                            Task {
                                await authVM.logout()   // ✅ 在 Task 裡呼叫 async 函式
                                store.resetToEmptyState()
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Profile")
        }
    }


// MARK: - Segmented Control

enum ProfileTab: String, CaseIterable, Identifiable {
    case workstyle = "Workstyle"
    case characteristics = "Characteristics"
    var id: String { rawValue }
}

struct ProfileSegmented: View {
    @Binding var selection: ProfileTab

    var body: some View {
        HStack(spacing: 8) {
            segmentButton(.workstyle)
            segmentButton(.characteristics)
        }
        .padding(6)
        .background(
            Capsule().fill(Color.gray.opacity(0.12))   // 整條的淡灰底
        )
    }

    @ViewBuilder
    private func segmentButton(_ tab: ProfileTab) -> some View {
        let isSelected = (selection == tab)

        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                selection = tab
            }
        } label: {
            Text(LocalizedStringKey(tab.rawValue))
                .font(.headline)
                .foregroundStyle(isSelected ? .black : .secondary)        // ✅ 選取黑字
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                            ? Color.themeBlue                             // ✅ 選取 themeBlue 底
                            : Color.gray.opacity(0.12)                    // ✅ 未選取淡灰底
                        )
                )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Workstyle Section

private struct WorkstyleSection: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Card {
            Text(LocalizedStringKey("Workstyle")).font(.headline)

            VStack(spacing: 14) {
                ForEach(Weekday.allCases) { day in
                    DaySliderRow(
                        title: day.shortTitle,
                        value: Binding(
                            get: { store.workstyle.dailyHours[day.rawValue] },
                            set: { newVal in
                                store.workstyle.dailyHours[day.rawValue] = newVal
                                Task { try? await SupabaseRepository.shared.upsertUserProfile(from: store) }
                            }
                        )
                    )
                }
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 16) {
                Text(LocalizedStringKey("Task Arrange Preference")).font(.title3).bold()

                SingleChoiceQuestion(
                    title: "1. 你希望系統安排任務時，偏好：",
                    options: ArrangeStrategy.allCases,
                    selection: Binding(
                        get: { store.preferences.arrangeStrategy },
                        set: { newVal in
                            store.preferences.arrangeStrategy = newVal
                            Task { try? await SupabaseRepository.shared.upsertUserProfile(from: store) }
                        }
                    )
                )

                SingleChoiceQuestion(
                    title: "2. 你平日和週末的作息會不同嗎？",
                    options: WeekdayWeekend.allCases,
                    selection: Binding(
                        get: { store.preferences.weekdayWeekend },
                        set: { newVal in
                            store.preferences.weekdayWeekend = newVal
                            Task { try? await SupabaseRepository.shared.upsertUserProfile(from: store) }
                        }
                    )
                )

                SingleChoiceQuestion(
                    title: "3. 你通常一次可以專心做事多久？",
                    options: FocusSpan.allCases,
                    selection: Binding(
                        get: { store.preferences.focusSpan },
                        set: { newVal in
                            store.preferences.focusSpan = newVal
                            Task { try? await SupabaseRepository.shared.upsertUserProfile(from: store) }
                        }
                    )
                )

                SingleChoiceQuestion(
                    title: "4. 當任務超過 1 小時時，你比較喜歡：",
                    options: LongTaskPref.allCases,
                    selection: Binding(
                        get: { store.preferences.longTask },
                        set: { newVal in
                            store.preferences.longTask = newVal
                            Task { try? await SupabaseRepository.shared.upsertUserProfile(from: store) }
                        }
                    )
                )
            }
        }
    }
}

// MARK: - Day Slider

private struct DaySliderRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 12) {
            // 左邊：星期幾
            Text(LocalizedStringKey(title))
                .font(.subheadline.bold())
                .frame(width: 56, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.themeBlue))
                .foregroundStyle(Color.black)

            // 右邊：滑桿區
            VStack(spacing: 6) {
                HStack {
                    Text("0").font(.caption2).foregroundStyle(.secondary)
                    ZStack(alignment: .center) {
                        Slider(value: $value, in: 0...10, step: 0.5)
                            .tint(Color.themeBlue)
                        Text(value.formatted(.number.precision(.fractionLength(1))))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            // 讓數字不被滑桿遮住，可以加 .allowsHitTesting(false) 如果需要
                    }
                    Text("10").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


// MARK: - Characteristics Section

private struct CharacteristicsSection: View {
    @EnvironmentObject var store: AppStore
    @State private var showTieBreaker = false

    var body: some View {
        Card {
            Text(LocalizedStringKey("Characteristics")).font(.headline)

            VStack(spacing: 16) {
                QuestionCard(index: 1, text: LocalizedStringKey("我通常想等自己「準備得更好」再開始做事情"), value: $store.onboarding.perfectionismPrep)
                QuestionCard(index: 2, text: LocalizedStringKey("我常覺得「要給我施加壓力，我才能進入狀態」"), value: $store.onboarding.pressureNeed)
                QuestionCard(index: 3, text: LocalizedStringKey("當我想到要開始一件重要的事時，會感到焦慮或害怕"), value: $store.onboarding.anxietyStart)
                QuestionCard(index: 4, text: LocalizedStringKey("若沒有時間壓力，我通常提不起勁行動"), value: $store.onboarding.noPressureIdle)
                QuestionCard(index: 5, text: LocalizedStringKey("我會一直查資料、準備、修正，但很難真正開始"), value: $store.onboarding.researchLoop)
                QuestionCard(index: 6, text: LocalizedStringKey("我常拖到最後一天才動手，但仍能在期限內完成"), value: $store.onboarding.lastMinute)
                QuestionCard(index: 7, text: LocalizedStringKey("當我沒達到自己預期的標準時，會很沮喪或自責"), value: $store.onboarding.selfBlame)
                QuestionCard(index: 8, text: LocalizedStringKey("若沒有外在壓力或他人督促，我就很難集中注意力"), value: $store.onboarding.needExternalPressure)
            }
            .padding(.top, 4)

            Button {
                recalculateTypeOrShowTieBreaker()
            } label: {
                Text("Recalculate")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.themeDarkYellow)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)
        }
        .sheet(isPresented: $showTieBreaker) {
            TieBreakerView(
                onSelectPerfectionist: {
                    store.procrastinationType = .perfectionist
                    Task { try? await SupabaseRepository.shared.upsertUserProfile(from: store) }
                    showTieBreaker = false
                },
                onSelectDeadlineFighter: {
                    store.procrastinationType = .deadlineFighter
                    Task { try? await SupabaseRepository.shared.upsertUserProfile(from: store) }
                    showTieBreaker = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func recalculateTypeOrShowTieBreaker() {
        let ob = store.onboarding
        let scoreA = ob.perfectionismPrep + ob.anxietyStart + ob.researchLoop + ob.selfBlame
        let scoreB = ob.pressureNeed + ob.lastMinute + ob.needExternalPressure + ob.noPressureIdle

        if scoreA > scoreB {
            store.procrastinationType = .perfectionist
            Task { try? await SupabaseRepository.shared.upsertUserProfile(from: store) }
        } else if scoreB > scoreA {
            store.procrastinationType = .deadlineFighter
            Task { try? await SupabaseRepository.shared.upsertUserProfile(from: store) }
        } else {
            showTieBreaker = true
        }
    }
}
