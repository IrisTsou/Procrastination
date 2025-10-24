//
//  ActivityView.swift
//  procrastination
//
//  Created by Iris Tsou on 2025/10/25.
//

import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var store: AppStore
    @State private var selectedPeriod: ActivityPeriod = .weekly
    
    enum ActivityPeriod: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Activity")
                    .font(.largeTitle).bold()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Period selector
                    HStack {
                        ForEach(ActivityPeriod.allCases) { period in
                            Button(action: { selectedPeriod = period }) {
                                Text(period.rawValue)
                                    .font(.subheadline).bold()
                                    .foregroundStyle(selectedPeriod == period ? .blue : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(selectedPeriod == period ? Color.white : Color.gray.opacity(0.1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Date range
                    HStack {
                        VStack(alignment: .leading) {
                            Text("This week").bold()
                            Text("May 28 - Jun 3").foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            Button(action: {}) {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.gray.opacity(0.1)))
                            }
                            Button(action: {}) {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.gray.opacity(0.1)))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Task Achievement Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 48, height: 48)
                                .overlay(Image(systemName: "eye").foregroundStyle(.secondary))
                            
                            VStack(alignment: .leading) {
                                Text("Task Achievement").bold()
                                Text("Summary").foregroundStyle(.secondary).font(.caption)
                            }
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "chevron.down")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(Color.gray.opacity(0.1)))
                            }
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            StatItem(title: "SUCCESS RATE", value: "98%", color: .green)
                            StatItem(title: "COMPLETED", value: "244", color: .primary)
                            StatItem(title: "BEST STREAK DAY", value: "22", color: .primary)
                            StatItem(title: "FAILED", value: "2", color: .red)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                    
                    // Tasks Completed Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 48, height: 48)
                                .overlay(Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(.red))
                            
                            VStack(alignment: .leading) {
                                Text("Tasks Completed").bold()
                                Text("Comparison by week").foregroundStyle(.secondary).font(.caption)
                            }
                            
                            Spacer()
                            
                            Pill(text: "🔥 Highest 4 tasks")
                        }
                        
                        // Bar chart
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(4...10, id: \.self) { week in
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: 20, height: week == 7 || week == 10 ? 80 : CGFloat.random(in: 30...60))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text("\(week)").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(height: 100)
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                    
                    // Happy Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 48, height: 48)
                                .overlay(Text("😊").font(.title2))
                            
                            VStack(alignment: .leading) {
                                Text("Happy").bold()
                                Text("Weekly Mood").foregroundStyle(.secondary).font(.caption)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(["😊", "🥰", "😞", "😊", "😊", "🥰", "😊"], id: \.self) { emoji in
                                Text(emoji)
                                    .font(.title2)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(Color.gray.opacity(0.05))
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.title2).bold().foregroundStyle(color)
        }
    }
}
