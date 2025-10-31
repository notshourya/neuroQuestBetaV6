//
//  PatientProfileView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

struct PatientProfileView: View {
    @EnvironmentObject var auth: Authentication
    
    let careTeamSettings: [Setting] = [
        .init(iconName: "person.crop.circle.badge.plus", title: "Manage Caregivers", color: .green),
        .init(iconName: "list.clipboard.fill", title: "View Medical Reports", color: .blue)
    ]
    
    let accountSettings: [Setting] = [
        .init(iconName: "person.fill", title: "Manage Profile", color: .gray),
        .init(iconName: "bell.badge.fill", title: "Notification Settings", color: .orange),
        .init(iconName: "shield.lefthalf.filled", title: "Data & Privacy", color: .blue)
    ]
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [.blue.opacity(0.2), .clear]),
                center: .top, startRadius: 10, endRadius: 1000
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    
                    UserProfileHeroView(name: "Test User", initials: "TU", themeColor: .blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 0)
                    
                    
                    ConnectionCard(
                        title: "Health Data & Devices",
                        icon: "heart.text.clipboard.fill",
                        color: .blue
                    ) {
                        Button(action: {
                            print("Tapped Apple Health...")
                        }) {
                            StatusRow(
                                icon: "heart.fill",
                                title: "Apple Health",
                                color: .green,
                                statusText: "Not Connected",
                                statusColor: .secondary
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 60)
                        
                        Button(action: {
                            print("Tapped Apple Watch...")
                        }) {
                            StatusRow(
                                icon: "applewatch",
                                title: "Apple Watch",
                                color: .green,
                                statusText: "Connected",
                                statusColor: .green
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    SettingsCard(
                        title: "Caregivers",
                        icon: "person.3.fill",
                        color: .green,
                        settings: careTeamSettings
                    )
                    
                    SettingsCard(
                        title: "Account & App Settings",
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

// MARK: - Components
struct ConnectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Label(title, systemImage: icon)
                .font(.title2.bold())
                .foregroundColor(color)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                content
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .glassEffect(in: .rect(cornerRadius: 35))
        }
    }
}

struct StatusRow: View {
    let icon: String
    let title: String
    let color: Color
    
    let statusText: String
    let statusColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.headline.bold())
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
            }
            
            Spacer()
            
            Text(statusText)
                .font(.callout.weight(.medium))
                .foregroundStyle(statusColor)
                .padding(.trailing, 4)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding()
    }
}


// MARK: - Preview
#Preview {
    NavigationView {
        PatientProfileView()
            .environmentObject(Authentication())
    }
}
