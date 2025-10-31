//
//  HealthOnboardingView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//


import SwiftUI
import SpriteKit

// MARK: - Particle Scene
class HeartParticleScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        size = view.bounds.size
        scaleMode = .resizeFill
        
        createFloatingParticles()
    }
    
    private func createFloatingParticles() {
        for _ in 0..<20 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            particle.fillColor = SKColor(
                red: CGFloat.random(in: 0.8...1.0),
                green: CGFloat.random(in: 0.2...0.4),
                blue: CGFloat.random(in: 0.3...0.5),
                alpha: 0.4
            )
            particle.strokeColor = .clear
            particle.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            particle.zPosition = 0
            
            particle.glowWidth = 1.5
            
            addChild(particle)
            animateFloatingParticle(particle)
        }
    }
    
    private func animateFloatingParticle(_ particle: SKShapeNode) {
        let randomDuration = TimeInterval.random(in: 4...7)
        let randomX = CGFloat.random(in: -80...80)
        let randomY = CGFloat.random(in: -80...80)
        
        let move = SKAction.moveBy(x: randomX, y: randomY, duration: randomDuration)
        let fade = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: randomDuration / 2),
            SKAction.fadeAlpha(to: 0.6, duration: randomDuration / 2)
        ])
        
        let group = SKAction.group([move, fade])
        let repeatAction = SKAction.repeatForever(SKAction.sequence([
            group,
            group.reversed()
        ]))
        
        particle.run(repeatAction)
    }
}

// MARK: - Main View
struct OnboardingHealthView: View {
    @Binding var authSheetState: AuthState
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var heartScale: CGFloat = 1.0
    @State private var showParticles = false
    
    let healthRed = Color(red: 1.0, green: 0.3, blue: 0.3)
    let healthPink = Color(red: 1.0, green: 0.4, blue: 0.5)
    
    var body: some View {
        NavigationStack {
            ZStack {
                if showParticles {
                    SpriteView(
                        scene: HeartParticleScene(),
                        options: [.allowsTransparency]
                    )
                    .ignoresSafeArea()
                    .opacity(animate ? 1.0 : 0.0)
                    .transition(.opacity)
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(healthRed.opacity(0.15))
                            .frame(width: 200)
                            .blur(radius: 40)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 90))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [healthPink, healthRed],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: healthRed.opacity(0.5), radius: 20)
                            .scaleEffect(heartScale)
                    }
                    .frame(height: 300)
                        
                    Spacer().frame(height: 40)
                    Text("Connect Apple Health")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .opacity(animate ? 1.0 : 0.0)
                        .offset(y: animate ? 0 : 20)
                        
                    Spacer().frame(height: 20)
        
                    Text("NeuroQuest uses your motion and health data to track tremors, balance, and activity.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(animate ? 1.0 : 0.0)
                        .offset(y: animate ? 0 : 20)
                        
                    Spacer().frame(height: 10)
   
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption)
                        Text("Your data is kept private and secure")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .opacity(animate ? 1.0 : 0.0)
                    .offset(y: animate ? 0 : 20)
                        
                    Spacer()
                 
                    VStack(spacing: 14) {
                        Button(action: {
                            print("TODO: Request real HealthKit access here")
                            impactFeedback()
                            goToNextStep()
                        }) {
                            
                            HStack(spacing: 12) {
                                Image(systemName: "suit.heart.fil")
                                    .font(.title3)
                                Text("Connect")
                                    .font(.headline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                        }
                        .buttonStyle(.plain)
                        .background(
                            Capsule()
                                .fill(healthRed)
                                .shadow(color: healthRed.opacity(0.4), radius: 15, y: 8)
                        )
                        .foregroundStyle(.white)
                        .opacity(animate ? 1.0 : 0.0)
                        .scaleEffect(animate ? 1.0 : 0.9)
                        
                        Button(action: {
                            impactFeedback()
                            goToNextStep()
                        }) {
                            Text("Skip for Now")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.blue)
                                .frame(height: 44)
                        }
                        .opacity(animate ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button(action: { dismiss() }) {
//                        Label("Close", systemImage: "xmrk")
//                            .font(.callout)
//                            .foregroundStyle(healthRed)
//                            .padding(8)
//                            .background(Color.secondary.opacity(0.1))                             .clipShape(Circle())
//                    }
//                }
//            }
        }
        .onAppear {
            startAnimations()
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
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            heartScale = 1.08
        }
    }
    
    private func goToNextStep() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            authSheetState = .onboardingWatch
        }
    }
    
    private func impactFeedback() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

#Preview {
    OnboardingHealthView(authSheetState: .constant(.onboardingHealth))
}
