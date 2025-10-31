//
//  neuroQuestApp.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

@main
struct NeuroQuestApp: App {
    @StateObject private var auth = Authentication()
    @StateObject private var gameDataStore = GameDataStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(gameDataStore)
        }
    }
}
