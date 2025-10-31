//
//  LoadingScreen.swift
//  neuroQuest
//  Redesigned Version
//

import SwiftUI
import Combine

struct LoadingScreenView: View {
    let game: GameCard
    let accentColor: Color
   
    @State private var animate = false
    @State private var pulse = false
    @State private var rotationAngle: Double = 0
    @State private var loadingProgress: CGFloat = 0
    @State private var currentTipIndex = 0
        @State private var timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
          
            Color(.systemBackground).ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(0.15), .clear]),
                center: .top, startRadius: 10, endRadius: 1000
            ).ignoresSafeArea()
        
            GeometryReader { geometry in
                ForEach(0..<8) { i in
                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: CGFloat.random(in: 20...40))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .offset(y: animate ? -20 : 20)
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                            value: animate
                        )
                }
            }
            .allowsHitTesting(false)
            
            VStack(spacing: 50) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Get Ready!")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(animate ? 1.0 : 0.8)
                    
                    Text(game.title)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .opacity(animate ? 1 : 0)
                }
              
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.2),
                                    accentColor.opacity(0.05)
                                ]),
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulse ? 1.1 : 1.0)
                    
                    Image(systemName: game.imageName)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: accentColor.opacity(0.3), radius: 10)
                }
                .frame(height: 180)
                VStack(spacing: 16) {
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray6))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.7), accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: loadingProgress, height: 6)
                            .shadow(color: accentColor.opacity(0.4), radius: 4)
                    }
                    .frame(maxWidth: 200)
                    
                    Text("Loading...")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            
                if !game.tips.isEmpty {
                    VStack(spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(accentColor)
                                .imageScale(.medium)
                            
                            Text("Pro Tip")
                                .font(.headline)
                                .foregroundStyle(accentColor)
                        }
                        
                        Text(game.tips[currentTipIndex])
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .frame(minHeight: 60)
                            .padding(.horizontal, 40)
                            .id("Tip-\(currentTipIndex)")
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    .padding(.horizontal, 30)
                }
                
                Spacer()
            }
            .opacity(animate ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animate = true
                }
                
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulse = true
                }
               
                withAnimation(.easeInOut(duration: 1.5)) {
                    loadingProgress = 200
                }
            }
            .onReceive(timer) { _ in
                guard !game.tips.isEmpty else { return }
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    currentTipIndex = (currentTipIndex + 1) % game.tips.count
                }
            }
            .onDisappear {
                self.timer.upstream.connect().cancel()
            }
        }
    }
}

#Preview {
    LoadingScreenView(game: GameCard.allGames[0], accentColor: .blue)
}
