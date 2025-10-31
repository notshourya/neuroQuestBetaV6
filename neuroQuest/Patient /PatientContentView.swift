//
//  PatientContentView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI
enum MainTab {
    case summary
    case games
    case myPlan
    case aiChat
}

struct PatientContentView: View {
    @EnvironmentObject var auth: Authentication
    
    @State private var selectedTab: MainTab = .summary
    
    @StateObject private var gameDataStore = GameDataStore()
    @StateObject private var patientModel = PatientDataModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            
            Tab("Summary", systemImage: "rectangle.3.offgrid.fill", value: .summary) {
                HomeView()
                    .environmentObject(auth)
                    .environmentObject(gameDataStore)
                    .environmentObject(patientModel)
            }
            
            Tab("Games", systemImage: "arcade.stick.console", value: .games) {
                ExerciseView()
                    .environmentObject(auth)
                    .environmentObject(gameDataStore)
                    .environmentObject(patientModel)
            }
            
            Tab("My Plan", systemImage: "calendar.badge.clock", value: .myPlan) {
                
                NavigationStack {
                    PatientHealthView()
                        .environmentObject(auth)
                        .environmentObject(gameDataStore)
                        .environmentObject(patientModel)
                }
            }
            
            
            Tab("Ai Chat",
                systemImage: "apple.image.playground.fill",
                value: .aiChat,
                role: .search) {
                
                NavigationStack {
                    Text("Companion Chat")
                }
                .environmentObject(auth)
            }
            
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewStyle(.sidebarAdaptable)
    }
}
#Preview {
    PatientContentView()
        .environmentObject(Authentication())
}
