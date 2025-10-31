//
//  ScoreSummaryView.swift
//  neuroQuest
//  Redesigned Version
//

import SwiftUI

struct ScoreSummaryView: View {
    let score: Int
    let oldBestScore: Int
    let rating: Int
    let accentColor: Color
    let targetScore: Int
    let onContinue: () -> Void

    @State private var animatedScore: Int = 0
    @State private var starsToShow: Int = 0
    @State private var showElements = false
    @State private var showContinueButton = false
    @State private var confettiTrigger = false
    @State private var circleScale: CGFloat = 0
    
    private var isNewHighScore: Bool {
        score > oldBestScore
    }
    
    private var didMeetTarget: Bool {
        score >= targetScore
    }

    init(score: Int, oldBestScore: Int, rating: Int, accentColor: Color, targetScore: Int, onContinue: @escaping () -> Void) {
        self.score = score
        self.oldBestScore = oldBestScore
        self.rating = rating
        self.accentColor = accentColor
        self.targetScore = targetScore
        self.onContinue = onContinue
    }

    var body: some View {
        ZStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        accentColor.opacity(didMeetTarget ? 0.2 : 0.1),
                        .clear
                    ]),
                    center: .center,
                    startRadius: 10,
                    endRadius: 600
                )
                .ignoresSafeArea()
                .scaleEffect(showElements ? 1.0 : 0.8)
                
                if didMeetTarget && showElements {
                    ConfettiView(accentColor: accentColor, trigger: confettiTrigger)
                }
            }
            .transition(.opacity)
            
            VStack(spacing: 30) {
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text(didMeetTarget ? "Level Complete!" : "Try Again!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: accentColor.opacity(0.3), radius: 8)
                        .scaleEffect(showElements ? 1.0 : 0.8)
                        .opacity(showElements ? 1.0 : 0)
                }
                .padding(.bottom,30)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showElements)
                
                if isNewHighScore {
                    Label("New Highscore!", systemImage: "trophy.fill")
                        .font(.headline)
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.1))
                                .overlay(
                                    Capsule()
                                        .stroke(accentColor.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                        .shadow(color: accentColor.opacity(0.2), radius: 10)
                        .scaleEffect(showElements ? 1.0 : 0.8)
                        .opacity(showElements ? 1.0 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showElements)
                        .padding(.bottom, 10)
                }

                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: circleScale)
                        .stroke(
                            LinearGradient(
                                colors: [accentColor.opacity(0.7), accentColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: accentColor.opacity(0.4), radius: 8)
                    
                    VStack(spacing: 4) {
                        Text("\(animatedScore)")
                            .font(.system(size: 64, weight: .heavy, design: .rounded))
                            .foregroundColor(accentColor)
                            .contentTransition(.numericText())
                        
                        Text("SCORE")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(2)
                    }
                }
                .scaleEffect(showElements ? 1.0 : 0.8)
                .opacity(showElements ? 1.0 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: showElements)

                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        ZStack {
                            if index < starsToShow {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(accentColor.opacity(0.3))
                                    .blur(radius: 8)
                                    .scaleEffect(1.5)
                            }
                            
                            Image(systemName: index < starsToShow ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundStyle(
                                    index < starsToShow
                                    ? accentColor
                                    : Color.secondary.opacity(0.2)
                                )
                                .scaleEffect(index < starsToShow ? 1.0 : 0.8)
                                .rotationEffect(.degrees(index < starsToShow ? Double.random(in: -10...10) : 0))
                                .shadow(
                                    color: index < starsToShow ? accentColor.opacity(0.4) : .clear,
                                    radius: 6
                                )
                        }
                    }
                }
                .padding(.vertical, 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: starsToShow)
                
                if showElements {
                    HStack(spacing: 30) {
                        newStatItem(
                            title: "Target",
                            value: "\(targetScore)",
                            icon: "target",
                            accentColor: accentColor
                        )
                        
                        Divider()
                            .frame(height: 40)
                        
                        newStatItem(
                            title: "Best",
                            value: "\(max(score, oldBestScore))",
                            icon: "chart.line.uptrend.xyaxis",
                            accentColor: accentColor
                        )
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .glassEffect(in: .rect(cornerRadius: 30))
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()
                
                if showContinueButton {
                    Button(action: onContinue) {
                        HStack(spacing: 12) {
                            Text(didMeetTarget ? "Continue" : "Retry")
                                .font(.title3.bold())
                            Image(systemName: didMeetTarget ? "arrow.right.circle.fill" : "arrow.counterclockwise.circle.fill")
                                .font(.title3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .controlSize(.extraLarge)
                    .buttonStyle(.glassProminent)
                    .tint(accentColor)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
        }
        .onAppear(perform: startAnimations)
    }

    private func startAnimations() {
        showElements = true
        
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 1.2).delay(0.4)) {
            animatedScore = score
        }
        
        withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
            circleScale = CGFloat(score) / 100.0
        }

        Task {
            guard showElements else { return }
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            for i in 1...rating {
                if !showElements { break }
                let haptic = UIImpactFeedbackGenerator(style: i == 5 ? .heavy : .light)
                haptic.impactOccurred()
                starsToShow = i
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            
            if didMeetTarget {
                confettiTrigger.toggle()
            }
            
            try? await Task.sleep(nanoseconds: 400_000_000)
            
            if showElements {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showContinueButton = true
                }
            }
        }
    }
}

// MARK: - Supporting Views (Unchanged)

struct newStatItem: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accentColor.opacity(0.7))
            
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(accentColor)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)
        }
    }
}

struct ConfettiView: View {
    let accentColor: Color
    let trigger: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<30) { index in
                ConfettiPiece(
                    accentColor: accentColor,
                    geometry: geometry,
                    index: index,
                    trigger: trigger
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct ConfettiPiece: View {
    let accentColor: Color
    let geometry: GeometryProxy
    let index: Int
    let trigger: Bool
    
    @State private var yOffset: CGFloat = -100
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        Circle()
            .fill(
                [accentColor, accentColor.opacity(0.7), accentColor.opacity(0.5)].randomElement() ?? accentColor
            )
            .frame(width: CGFloat.random(in: 6...12))
            .offset(
                x: geometry.size.width / 2 + xOffset,
                y: yOffset
            )
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: Double.random(in: 1.5...2.5))
                    .delay(Double(index) * 0.02)
                ) {
                    yOffset = geometry.size.height + 100
                    xOffset = CGFloat.random(in: -150...150)
                    rotation = Double.random(in: 360...720)
                    opacity = 0
                }
            }
    }
}

#Preview {
    ScoreSummaryView(
        score: 92,
        oldBestScore: 85,
        rating: 4,
        accentColor: .orange,
        targetScore: 80
    ) {
        print("Continue Tapped")
    }
}
