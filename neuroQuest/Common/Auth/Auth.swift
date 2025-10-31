//
//  Auth.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI
import Combine
enum UserRole {
    case patient
    case admin
    case none
}

class Authentication: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var isSigningOut: Bool = false
    @Published var userRole: UserRole = .none
    @Published var requestedAuthState: AuthState? = nil
    
    func triggerSignOut() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            self.isSigningOut = true
        }
    }

    func completeSignOut() {
        self.isAuthenticated = false
        self.userRole = .none
        self.isSigningOut = false
    }
}
