//
//  RootView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: Authentication

    var body: some View {
        Group {
            if auth.isSigningOut {
                SignOutLoadingView()
            }
            else if auth.isAuthenticating {
                PostAuthLoadingView()
            }
            else if auth.isAuthenticated {
                switch auth.userRole {
                case .patient: PatientContentView()
                case .admin: AdminContentView()
                case .none: WelcomeView() // Fallback
                }
            }
            else {
                WelcomeView()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: auth.isAuthenticated)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: auth.isAuthenticating)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: auth.isSigningOut)
    }
}

#Preview {
    RootView()
        .environmentObject(Authentication())
//        .environmentObject(GameDataStore())
//        .environmentObject(PatientDataModel())
}
