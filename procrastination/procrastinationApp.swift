//
//  procrastinationApp.swift
//  procrastination
//
//  Created by Iris Tsou on 2025/10/10.
//

import SwiftUI
import FirebaseCore

@main
struct procrastinationApp: App {
    @StateObject private var store = AppStore()
    @State private var geminiService: GeminiService

    init() {
        // Ensure Firebase is configured before any service that depends on it is created.
        FirebaseApp.configure()
        // Now it's safe to create GeminiService (which uses FirebaseAI/FirebaseApp)
        _geminiService = State(initialValue: GeminiService())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(geminiService)
                .onAppear { NotificationManager.requestAuthorization() }
        }
    }
}
