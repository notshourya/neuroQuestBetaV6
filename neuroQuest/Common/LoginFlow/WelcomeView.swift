//
//  WelcomeView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//


import SwiftUI
import SpriteKit

struct WelcomeView: View {
    @EnvironmentObject var auth: Authentication
    @State private var showAuthSheet = false
    @State private var initialAuthState: AuthState = .login
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 30
    @State private var buttonsOpacity: Double = 0

    @State private var showParticles = false
    
    let appIconGradient = Gradient(colors: [.blue, .purple, .pink])
    let particleColors: [Color] = [.blue, .purple, .pink]

    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.15), Color(.systemGroupedBackground)]),
                    center: .top,
                    startRadius: 10,
                    endRadius: 1000
                )
                .ignoresSafeArea()
                if showParticles {
                    SpriteView(
                        scene: ParticleScene(colors: particleColors),
                        options: [.allowsTransparency]
                    )
                    .ignoresSafeArea()
                    .opacity(iconOpacity)
                    .transition(.opacity)
                }

                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 24) {
                        AppIconView(
                            iconName: "waveform.mid",
                            size: 200,
                            gradient: appIconGradient
                        )
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                        
                        VStack(spacing: 12) {
                            Text("Welcome to NeuroQuest")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            
                            Text("Your personal, game based path to wellness.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 300)
                        }
                        .offset(y: titleOffset)
                        .opacity(titleOpacity)
                    }

                    Spacer()
                    Spacer()

                    VStack(spacing: 16) {
                        NavigationLink(
                            destination: FeatureCarouselView()
                        ) {
                            Text("Get Started")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .controlSize(.large)
                        .buttonStyle(.glassProminent)
                        .tint(Color.blue.gradient)
                        .shadow(color: .blue.opacity(0.3), radius: 12, y: 6)

                        Button(action: {
                            initialAuthState = .login
                            showAuthSheet = true
                        }) {
                            Text("Already have an account? **Log In**")
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                    .offset(y: buttonsOffset)
                    .opacity(buttonsOpacity)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showAuthSheet, onDismiss: {
                auth.requestedAuthState = nil
            }) {
                AuthSheetContainerView(initialState: initialAuthState)
                    .environmentObject(auth)
                  
                    .presentationBackground(.clear)
                   
            }
            .task {
                await animateEntrance()
            }
            .onChange(of: auth.requestedAuthState) { newState in
                if newState == .login {
                    self.initialAuthState = .login
                    self.showAuthSheet = true
                }
            }
        }
    }
    
    // MARK: - Animation Sequence
    
    @MainActor
    private func animateEntrance() async {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                showParticles = true
            }
        }
        
       
        try? await Task.sleep(nanoseconds: 150_000_000)
        
       
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            titleOffset = 0
            titleOpacity = 1.0
        }
        
      
        try? await Task.sleep(nanoseconds: 200_000_000)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            buttonsOffset = 0
            buttonsOpacity = 1.0
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(Authentication())
}
