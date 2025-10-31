//
//  AdminProfileView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

struct AdminProfileView: View {
    @EnvironmentObject var auth: Authentication
    let patientManagementSettings: [Setting] = [
        .init(iconName: "list.bullet.clipboard.fill", title: "My Patients", color: .blue),
        .init(iconName: "chart.bar.xaxis", title: "Patient Analytics", color: .purple),
        .init(iconName: "doc.text.magnifyingglass", title: "Pending Reports", color: .orange)
    ]
    let accountSettings: [Setting] = [
        .init(iconName: "person.fill", title: "Edit My Profile", color: .gray),
        .init(iconName: "bell.badge.fill", title: "Notification Settings", color: .orange),
        .init(iconName: "shield.lefthalf.filled", title: "Data & Privacy", color: .blue)
    ]
    
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [.pink.opacity(0.20), .clear]),
                center: .top, startRadius: 20, endRadius: 600
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    UserProfileHeroView(
                        name: "Caregiver",
                        initials: "CR",
                        themeColor: .pink
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 0)
                    SettingsCard(
                        title: "Patient Management",
                        icon: "person.2.fill",
                        color: .pink,
                        settings: patientManagementSettings
                    )
                    SettingsCard(
                        title: "My Account",
                        icon: "gear",
                        color: .gray,
                        settings: accountSettings
                    )
                    Button(action: {
                        auth.triggerSignOut()
                    }) {
                        Label("Sign Out", systemImage: "arrow.right.to.line.circle.fill")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                    .padding(.top, 10)
                    
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    NavigationView {
        AdminProfileView()
            .environmentObject(Authentication())
    }
}

