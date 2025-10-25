//
//  ProfileView.swift
//  procrastination
//
//  Created by Iris Tsou on 2025/10/25.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: ProfileTab = .workstyle

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    Card {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 44, height: 44)
                                .overlay(Text("🙂").font(.title2))
                            VStack(alignment: .leading) {
                                Text("Mert").bold()
                                Text("Your Profile").foregroundStyle(.secondary).font(.caption)
                            }
                            Spacer()
                        }
                    }

                    ProfileSegmented(selection: $tab)

                    Group {
                        switch tab {
                        case .workstyle:
                            WorkstyleSection()
                                .environmentObject(store)

                        case .characteristics:
                            CharacteristicsSection()
                                .environmentObject(store)
                        }
                    }

                }
                .padding(16)
            }
            .navigationTitle("Profile")
        }
    }
}

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
            Capsule().fill(Color.gray.opacity(0.12))
        )
    }

    @ViewBuilder
    private func segmentButton(_ tab: ProfileTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                selection = tab
            }
        } label: {
            Text(tab.rawValue)
                .font(.headline)
                .foregroundStyle(selection == tab ? .blue : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(selection == tab ? Color.white : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct WorkstyleSection: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Card {
            Text("Workstyle").font(.headline)

            VStack(spacing: 14) {
                ForEach(Weekday.allCases) { day in
                    DaySliderRow(
                        title: day.shortTitle,
                        value: Binding(
                            get: { store.workstyle.dailyHours[day.rawValue] },
                            set: { newVal in
                                store.workstyle.dailyHours[day.rawValue] = newVal
                                store.save()
                            }
                        )
                    )
                }
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 16) {
                Text("Task Arrange Preference").font(.title3).bold()

                SingleChoiceQuestion(
                    title: "1. 你希望系統安排任務時，偏好：",
                    options: ArrangeStrategy.allCases,
                    selection: Binding(
                        get: { store.preferences.arrangeStrategy},
                        set: { store.preferences.arrangeStrategy = $0; store.save() }
                    )
                )

                SingleChoiceQuestion(
                    title: "2. 你平日和週末的作息會不同嗎？",
                    options: WeekdayWeekend.allCases,
                    selection: Binding(
                        get: { store.preferences.weekdayWeekend },
                        set: { store.preferences.weekdayWeekend = $0; store.save() }
                    )
                )
                    
                SingleChoiceQuestion(
                    title: "3. 你通常一次可以專心做事多久？",
                    options: FocusSpan.allCases,
                    selection: Binding(
                        get: { store.preferences.focusSpan },
                        set: { store.preferences.focusSpan = $0; store.save() }
                    )
                )
                
                SingleChoiceQuestion(
                    title: "4. 當任務超過 1 小時時，你比較喜歡：",
                    options: LongTaskPref.allCases,
                    selection: Binding(
                        get: { store.preferences.longTask },
                        set: { store.preferences.longTask = $0; store.save() }
                    )
                )
            }
        }
    }
}

private struct DaySliderRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.bold())
                .frame(width: 56, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.blue.opacity(0.12)))
                .foregroundStyle(Color.blue)

            VStack(spacing: 6) {
                HStack {
                    Text("0").font(.caption2).foregroundStyle(.secondary)
                    ZStack(alignment: .center) {
                        Slider(value: $value, in: 0...10, step: 0.5)
                            .tint(.blue)
                        Text(value.formatted(.number.precision(.fractionLength(1))))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    Text("10").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CharacteristicsSection: View {
    @EnvironmentObject var store: AppStore
    @State private var showTieBreaker = false

    var body: some View {
        Card {
            Text("Characteristics").font(.headline)

            // 8 題（與 Onboarding 相同）
            VStack(spacing: 16) {
                QuestionCard(
                    index: 1,
                    text: "我通常想等自己「準備得更好」再開始做事情",
                    value: $store.onboarding.perfectionismPrep
                )
                QuestionCard(
                    index: 2,
                    text: "我常覺得「要給我施加壓力，我才能進入狀態」",
                    value: $store.onboarding.pressureNeed
                )
                QuestionCard(
                    index: 3,
                    text: "當我想到要開始一件重要的事時，會感到焦慮或害怕",
                    value: $store.onboarding.anxietyStart
                )
                QuestionCard(
                    index: 4,
                    text: "若沒有時間壓力，我通常提不起勁行動",
                    value: $store.onboarding.noPressureIdle
                )
                QuestionCard(
                    index: 5,
                    text: "我會一直查資料、準備、修正，但很難真正開始",
                    value: $store.onboarding.researchLoop
                )
                QuestionCard(
                    index: 6,
                    text: "我常拖到最後一天才動手，但仍能在期限內完成",
                    value: $store.onboarding.lastMinute
                )
                QuestionCard(
                    index: 7,
                    text: "當我沒達到自己預期的標準時，會很沮喪或自責",
                    value: $store.onboarding.selfBlame
                )
                QuestionCard(
                    index: 8,
                    text: "若沒有外在壓力或他人督促，我就很難集中注意力",
                    value: $store.onboarding.needExternalPressure
                )
            }
            .padding(.top, 4)

            // 重新計算按鈕（等同 Submit）
            Button {
                recalculateTypeOrShowTieBreaker()
            } label: {
                Text("Recalculate")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 8)
        }
        // 平手才出現第 9 題
        .sheet(isPresented: $showTieBreaker) {
            // 若要重用 Questionnaire.swift 的 TieBreakerView，請把那個 struct 從 private 改成 internal
            TieBreakerView(
                onSelectPerfectionist: {
                    store.procrastinationType = .perfectionist
                    store.save()
                    showTieBreaker = false
                },
                onSelectDeadlineFighter: {
                    store.procrastinationType = .deadlineFighter
                    store.save()
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
            store.save()
        } else if scoreB > scoreA {
            store.procrastinationType = .deadlineFighter
            store.save()
        } else {
            showTieBreaker = true
        }
    }
}
