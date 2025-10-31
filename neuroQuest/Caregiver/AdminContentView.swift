//
//  AdminContentView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI

enum AdminTab {
    case dashboard
    case activity
    case assign
    case aiChat
}

struct AdminContentView: View {
    @EnvironmentObject var auth: Authentication
    @StateObject private var patientStore = PatientDataStore()
    
    @State private var selectedTab: AdminTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            
            Tab("Dashboard", systemImage: "person.crop.rectangle.stack", value: .dashboard) {
                AdminHomeView()
                    .environmentObject(auth)
            }
            
            Tab("Activity", systemImage: "chart.bar.doc.horizontal", value: .activity) {
                ActivityView()
                    .environmentObject(auth)
            }
            
            Tab("Schedule", systemImage: "calendar.badge.plus", value: .assign) {
                AdminHealthView()
                    .environmentObject(auth)
            }
            
            Tab("Ai Chat",
                systemImage: "apple.image.playground.fill",
                value: .aiChat,
                role: .search) {
                
                NavigationStack {
                    Text("AI Chat View Placeholder")
                }
            }
        }
        .environmentObject(patientStore)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewStyle(.sidebarAdaptable)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}

#Preview {
    AdminContentView()
        .environmentObject(Authentication())
}
