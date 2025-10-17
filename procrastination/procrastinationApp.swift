//
//  procrastinationApp.swift
//  procrastination
//
//  Created by Iris Tsou on 2025/10/10.
//

import SwiftUI

@main
struct procrastinationApp: App {
    @StateObject private var store = AppStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { NotificationManager.requestAuthorization() }
        }
    }
}
