//
//  ProfileSharedComponents.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

// MARK: - Reusable Models & Components
struct Setting: Identifiable, Hashable {
    let id = UUID()
    let iconName: String
    let title: String
    let color: Color
}

struct UserProfileHeroView: View {
    let name: String
    let initials: String
    var themeColor: Color = .blue
    
    var body: some View {
        VStack(spacing: 12) {
            ProfileAvatarView(initials: initials, color: themeColor)

            Text(name)
                .font(.largeTitle.bold())
        }
        .padding(.vertical)
    }
}

struct ProfileAvatarView: View {
    let initials: String
    let color: Color
    var size: CGFloat = 100
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.gradient.opacity(0.2))
            Circle()
                .stroke(color.gradient, lineWidth: 2)
            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}


struct SettingsCard: View {
    let title: String
    let icon: String
    let color: Color
    let settings: [Setting]
    
    var body: some View {
       
        VStack(alignment: .leading, spacing: 12) {
            
            Label(title, systemImage: icon)
                .font(.title2.bold())
                .foregroundColor(color)
                .padding(.horizontal)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(settings.enumerated()), id: \.element.id) { index, setting in
                    if index > 0 {
                        Divider().padding(.leading, 60)
                    }
                    NavigationLink(destination: Text("\(setting.title) Screen")) {
                        SettingsRow(iconName: setting.iconName, title: setting.title, tintColor: setting.color)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .glassEffect(in: .rect(cornerRadius: 35))
        }
    }
}

struct SettingsRow: View {
    let iconName: String
    let title: String
    let tintColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.headline.bold())
                .foregroundColor(tintColor)
                .frame(width: 30, height: 30)
                .background(tintColor.opacity(0.15))
                .clipShape(Circle())
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding() 
    }
}



