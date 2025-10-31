//
//  SignOutLoadingView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI
import SpriteKit

struct SignOutLoadingView: View {
    @EnvironmentObject var auth: Authentication
    
    private let appIconGradient = Gradient(colors: [.red, .pink, .gray])
    private let particleColors: [Color] = [.red, .pink, .gray]
    @State private var animate = false
    @State private var iconScale: CGFloat = 1.0
    @State private var showParticles = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.black)
                .ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.3), .clear]),
                center: .top, startRadius: 10, endRadius: 1000
            )
            .ignoresSafeArea()
            if showParticles {
                SpriteView(
                    scene: ParticleScene(colors: particleColors),
                    options: [.allowsTransparency]
                )
                .ignoresSafeArea()
                .opacity(animate ? 1.0 : 0.0)
                .transition(.opacity)
            }

            VStack(spacing: 25) {
                AppIconView(
                    iconName: "door.left.hand.open",
                    size: 140,
                    gradient: appIconGradient
                )
                .scaleEffect(iconScale)
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animate)
                
                VStack(spacing: 10) {
                    Text("Signing Out...")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("See you next time.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(animate ? 1.0 : 0)
                .offset(y: animate ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: animate)
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(.top, 10)
                    .opacity(animate ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animate)
            }
            .padding()
        }
        .onAppear {
            startAnimations()
            Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                await MainActor.run {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        auth.completeSignOut()
                    }
                }
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            animate = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                showParticles = true
            }
        }

        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
            .delay(0.5)
        ) {
            iconScale = 1.08
        }
    }
}

#Preview {
    SignOutLoadingView()
        .environmentObject(Authentication())
}
