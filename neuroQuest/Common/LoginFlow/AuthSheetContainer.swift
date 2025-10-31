//
//  AuthSheetContainer.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

struct AuthSheetContainerView: View {
    @EnvironmentObject var auth: Authentication
    @State private var currentAuthState: AuthState
    @Environment(\.dismiss) var dismiss
    
    @State private var loginRole: UserRole = .patient
    
    init(initialState: AuthState) {
        _currentAuthState = State(initialValue: initialState)
    }
    
    private var currentAccentColor: Color {
        switch currentAuthState {
        case .login:
            return loginRole == .patient ? .blue : .red
        case .signUp:
            return .blue
        case .onboardingHealth:
            return .red
        case .onboardingWatch:
            return .blue
        case .welcome:
            return .blue
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [currentAccentColor.opacity(0.2), .clear]),
                center: .top, startRadius: 20, endRadius: 600
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: currentAccentColor)
            Group {
                switch currentAuthState {
                case .login:
                    LoginView(authSheetState: $currentAuthState, selectedRole: $loginRole)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                case .signUp:
                    SignUpView(authSheetState: $currentAuthState)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                
                case .onboardingHealth:
                    OnboardingHealthView(authSheetState: $currentAuthState)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        
                case .onboardingWatch:
                    OnboardingWatchView(authSheetState: $currentAuthState)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                
                case .welcome:
                    EmptyView()
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentAuthState)
        }
        .onChange(of: auth.isAuthenticating) { _, isAuthenticating in
            if isAuthenticating {
                dismiss()
            }
        }
        .onChange(of: currentAuthState) { _, newState in
            if newState == .signUp {
                loginRole = .patient
            }
        }
    }
}
