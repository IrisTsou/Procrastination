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

                        case .achievements:
                            AchievementsSection()
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
    case achievements = "Achievements"
    var id: String { rawValue }
}

struct ProfileSegmented: View {
    @Binding var selection: ProfileTab

    var body: some View {
        HStack(spacing: 8) {
            segmentButton(.workstyle)
            segmentButton(.achievements)
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

private struct AchievementsSection: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Card {
            Text("Achievements").font(.headline)

            if store.achievements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("還沒有成就").font(.subheadline.bold())
                    Text("完成連續 7 天任務、加入挑戰賽、或維持一週 80% 完成率即可解鎖✨")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(store.achievements) { a in
                    HStack(spacing: 10) {
                        Image(systemName: "medal.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading) {
                            Text(a.title).bold()
                            Text(a.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
