//
//  LevelPathView.swift
//  neuroQuest


import SwiftUI

// MARK: - Main View
struct LevelPathView: View {
    @Binding var tier: LevelTier
    let game: GameCard
    let onLastLevelComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var animateHeader = false

    private var lastUnlockedIndex: Int {
        tier.levels.lastIndex(where: { $0.status != .locked }) ?? 0
    }

    private var completionRatio: CGFloat {
        let completedCount = tier.levels.filter { level in
            if level.status != .completed { return false }
            return (level.score ?? 0) >= level.requiredScoreToUnlockNext
        }.count
        
        return CGFloat(completedCount) / CGFloat(max(tier.levels.count, 1))
    }

    var body: some View {
        ZStack {
            LevelPathBackgroundView(accentColor: game.accentColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ModernTierHeader(
                    title: tier.title,
                    progress: completionRatio,
                    totalLevels: tier.levels.count,
                    completedLevels: tier.levels.filter { $0.status == .completed }.count,
                    accentColor: game.accentColor,
                    animateHeader: animateHeader
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(tier.levels.indices, id: \.self) { index in
                                let level = tier.levels[index]
                                let levelBinding = $tier.levels[index]
                                let isLastInTier = (index == tier.levels.count - 1)

                                if index > 0 {
                                    EnhancedPathConnector(
                                        isUnlocked: level.status != .locked,
                                        isFromLeft: (index - 1) % 2 == 0,
                                        accentColor: game.accentColor,
                                        hasParticles: level.status == .unlocked
                                    )
                                }

                                HStack {
                                    if index % 2 == 1 { Spacer(minLength: 0) }

                                    EnhancedLevelNode(
                                        level: level,
                                        levelBinding: levelBinding,
                                        game: game,
                                        accentColor: game.accentColor,
                                        isLastInTier: isLastInTier,
                                        onComplete: { score in
                                            handleLevelCompletion(completedLevelId: level.id, score: score)
                                        }
                                    )
                                    .id(index)

                                    if index % 2 == 0 { Spacer(minLength: 0) }
                                }
                                .padding(.horizontal, 40)
                            }

                            Color.clear.frame(height: 120)
                        }
                        .padding(.top, 20)
                    }
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            animateHeader = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring()) {
                                proxy.scrollTo(lastUnlockedIndex, anchor: .center)
                            }
                        }
                    }
                }
            }
            .padding(.top, 60)
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleLevelCompletion(completedLevelId: Int, score: Int) {
        guard let index = tier.levels.firstIndex(where: { $0.id == completedLevelId }) else { return }
        guard score >= tier.levels[index].requiredScoreToUnlockNext else { return }

        if index + 1 == tier.levels.count {
            onLastLevelComplete()
        } else if tier.levels[index + 1].status == .locked {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    tier.levels[index + 1].status = .unlocked
                }
            }
        }
    }
}

// MARK: - Modern Tier Header (Linear Bar Removed)
struct ModernTierHeader: View {
    let title: String
    let progress: CGFloat
    let totalLevels: Int
    let completedLevels: Int
    let accentColor: Color
    let animateHeader: Bool

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "map.fill")
                    .font(.title3)
                    .foregroundStyle(accentColor)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("\(completedLevels) of \(totalLevels) levels")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.2), lineWidth: 4)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(progressPercentage)%")
                        .font(.caption.bold())
                        .foregroundStyle(accentColor)
                }
                .frame(width: 50, height: 50)
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 30))
        .scaleEffect(animateHeader ? 1.0 : 0.95)
        .opacity(animateHeader ? 1.0 : 0)
    }
}

// MARK: - Enhanced Level Node (5-Star Logic)
struct EnhancedLevelNode: View {
    let level: Level
    let levelBinding: Binding<Level>
    let game: GameCard
    let accentColor: Color
    let isLastInTier: Bool
    let onComplete: (Int) -> Void

    @State private var isPressed = false
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    
    private var didMeetTarget: Bool {
        (level.score ?? 0) >= level.requiredScoreToUnlockNext
    }
    
    private func calculateRating() -> Int {
        guard level.status == .completed, let score = level.score else { return 0 }
        
        switch score {
        case ...75: return 1
        case ...80: return 2
        case ...90: return 3
        case ...99: return 4
        default: return 5
        }
    }

    var body: some View {
        NavigationLink {
            EnhancedLevelDetailView(
                level: levelBinding,
                game: game,
                accentColor: accentColor,
                onComplete: onComplete
            )
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if level.status == .unlocked {
                        ForEach([1.0, 1.15, 1.3], id: \.self) { scale in
                            Circle()
                                .stroke(accentColor.opacity(0.15), lineWidth: 2)
                                .frame(width: 100 * scale, height: 100 * scale)
                                .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                                .opacity(pulseAnimation ? 0 : 0.5)
                        }
                    }
                    
                    if isLastInTier && level.status != .locked {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        accentColor,
                                        accentColor.opacity(0.3),
                                        accentColor
                                    ],
                                    center: .center
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 110, height: 110)
                            .rotationEffect(.degrees(rotationAngle))
                    }

                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 102, height: 102)
                            .blur(radius: 8)
                            .offset(y: 4)
                        
                        Circle()
                            .fill(
                                level.status == .locked
                                ? LinearGradient(
                                    colors: [Color(.systemGray5), Color(.systemGray4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [accentColor.opacity(0.3), accentColor.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Circle()
                            .stroke(
                                level.status == .locked
                                ? Color(.systemGray3)
                                : accentColor,
                                lineWidth: level.status == .unlocked ? 4 : 6
                            )
                        
                        Group {
                            switch level.status {
                            case .locked:
                                Image(systemName: "lock.fill")
                                    .font(.title)
                                    .foregroundStyle(Color(.systemGray))
                                
                            case .unlocked:
                                if isLastInTier {
                                    VStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [accentColor, accentColor.opacity(0.7)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .shadow(color: accentColor.opacity(0.3), radius: 4)
                                        
                                        Text("BOSS")
                                            .font(.caption2.bold())
                                            .foregroundStyle(accentColor.opacity(0.8))
                                            .tracking(1)
                                    }
                                } else {
                                    Text("\(level.id)")
                                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [accentColor, accentColor.opacity(0.7)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .shadow(color: accentColor.opacity(0.2), radius: 2)
                                }
                                
                            case .completed:
                                ZStack {
                                    Circle()
                                        .fill(
                                            didMeetTarget
                                            ? accentColor
                                            : accentColor.opacity(0.5)
                                        )
                                    
                                    VStack(spacing: 6) {
                                        Image(systemName: didMeetTarget ? "checkmark.circle.fill" : "arrow.trianglehead.counterclockwise")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundStyle(.white)
                                        
                                        Text("\(level.score ?? 0)")
                                            .font(.headline.bold())
                                            .foregroundStyle(.white.opacity(0.95))
                                    }
                                }
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                            }
                        }
                    }
                    .frame(width: 100, height: 100)
                }
                
                StarCapsuleView(
                    rating: calculateRating(),
                    status: level.status,
                    accentColor: accentColor
                )
                .transition(.opacity.combined(with: .scale))
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onAppear {
                if level.status == .unlocked {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                }
                
                if isLastInTier && level.status != .locked {
                    withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
            }
            .onChange(of: level.status) { _, newStatus in
                if newStatus == .unlocked {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        pulseAnimation = true
                    }
                } else {
                    pulseAnimation = false
                }
            }
        }
        .disabled(level.status == .locked)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Star Capsule View (5-Star, Accent Color)
struct StarCapsuleView: View {
    let rating: Int
    let status: LevelStatus
    let accentColor: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(
                        status == .completed && index < rating
                        ? accentColor
                        : Color.secondary.opacity(0.2)
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.1))
                .glassEffect(in: .capsule)
        )
        .opacity(status == .locked ? 0.6 : 1.0)
    }
}


// MARK: - Enhanced Path Connector
struct EnhancedPathConnector: View {
    let isUnlocked: Bool
    let isFromLeft: Bool
    let accentColor: Color
    let hasParticles: Bool
    
    @State private var animateParticles = false

    var body: some View {
        let path = CurveConnector(isFromLeft: isFromLeft)

        ZStack {
            path.stroke(
                Color(.systemGray5),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 8])
            )

            path.trim(from: 0, to: isUnlocked ? 1 : 0)
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.6),
                            accentColor,
                            accentColor.opacity(0.6)
                        ],
                        startPoint: isFromLeft ? .leading : .trailing,
                        endPoint: isFromLeft ? .trailing : .leading
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 8])
                )
                .shadow(color: accentColor.opacity(0.3), radius: 4)
            
            if hasParticles && isUnlocked {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(accentColor)
                        .frame(width: 6, height: 6)
                        .modifier(
                            PathAnimationModifier(
                                path: path,
                                isFromLeft: isFromLeft,
                                delay: Double(index) * 0.8,
                                animate: animateParticles
                            )
                        )
                }
            }
        }
        .frame(height: 100)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: isUnlocked)
        .onAppear {
            if hasParticles && isUnlocked {
                animateParticles = true
            }
        }
    }
}

// MARK: - Path Animation Helpers
struct PathAnimationModifier: ViewModifier {
    let path: CurveConnector
    let isFromLeft: Bool
    let delay: Double
    let animate: Bool
    
    @State private var progress: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: calculatePosition().x, y: calculatePosition().y)
            .opacity(animate ? 0.8 : 0)
            .onAppear {
                withAnimation(
                    .linear(duration: 2.5)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    progress = 1.0
                }
            }
    }
    
    private func calculatePosition() -> CGPoint {
        let rect = CGRect(x: 0, y: 0, width: 300, height: 100)
        let currentProgress = (progress + delay / 2.5).truncatingRemainder(dividingBy: 1)
        
        let startX = isFromLeft ? rect.minX : rect.maxX
        let endX = isFromLeft ? rect.maxX : rect.minX
        
        let x = startX + (endX - startX) * currentProgress
        let y = rect.midY - 50 * sin(currentProgress * .pi)
        
        return CGPoint(x: x, y: y)
    }
}


struct CurveConnector: Shape {
    let isFromLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startPoint: CGPoint
        let endPoint: CGPoint
        let controlPoint1: CGPoint
        let controlPoint2: CGPoint

        if isFromLeft {
            startPoint = CGPoint(x: rect.minX, y: rect.minY)
            endPoint = CGPoint(x: rect.maxX, y: rect.maxY)
            controlPoint1 = CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY)
            controlPoint2 = CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.maxY)
        } else {
            startPoint = CGPoint(x: rect.maxX, y: rect.minY)
            endPoint = CGPoint(x: rect.minX, y: rect.maxY)
            controlPoint1 = CGPoint(x: rect.maxX - rect.width * 0.3, y: rect.minY)
            controlPoint2 = CGPoint(x: rect.minX + rect.width * 0.3, y: rect.maxY)
        }

        path.move(to: startPoint)
        path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
        return path
    }
}


// MARK: - Enhanced Background (Updated)
struct LevelPathBackgroundView: View {
    let accentColor: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(0.15), .clear]),
                center: .top,
                startRadius: 10,
                endRadius: 1000
            ).ignoresSafeArea()
            
            GeometryReader { geometry in
                ForEach(0..<10) { _ in
                    Circle()
                        .fill(accentColor.opacity(0.12))
                        .blur(radius: 3)
                        .frame(width: CGFloat.random(in: 5...25))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .offset(y: animate ? 30 : -30)
                        .animation(
                            .easeInOut(duration: Double.random(in: 6...12))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...1)),
                            value: animate
                        )
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .onAppear {
            animate = true
        }
    }
}
