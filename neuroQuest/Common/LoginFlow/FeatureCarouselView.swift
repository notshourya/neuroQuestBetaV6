//
//  FeatureCarouselView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI
import Charts

// MARK: - Feature Showcase Items
struct FeatureShowcaseItem<Visual: View>: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let accentColor: Color
    let visual: (Binding<Bool>) -> Visual
}

struct AnyFeatureShowcaseItem: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let iconName: String
    let accentColor: Color
    let visual: (Binding<Bool>) -> AnyView
    
    init<V: View>(
        id: UUID = UUID(),
        title: String,
        description: String,
        iconName: String,
        accentColor: Color,
        @ViewBuilder visual: @escaping (Binding<Bool>) -> V
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.accentColor = accentColor
        self.visual = { isAnimating in AnyView(visual(isAnimating)) }
    }
}


struct FeatureCarouselView: View {
    @EnvironmentObject var auth: Authentication
    @Environment(\.dismiss) var dismiss
    
    @State private var showAuthSheet = false
    @State private var currentPage = 0
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)


    let features: [AnyFeatureShowcaseItem] = [
        .init(title: "Engaging Exercises", description: "Play fun designed games that adapt to you.", iconName: "gamecontroller.fill", accentColor: .teal, visual: { isAnimating in AnimatedGameIconsView(animate: isAnimating) }),
      
        .init(title: "Intelligent Analysis", description: "Get personalized insights powered by advanced AI.", iconName: "sparkle.body.visionography", accentColor: .purple, visual: { isAnimating in AnimatedIntelligenceView(animate: isAnimating) }),
        .init(title: "Track Your Progress", description: "Visualize your scores and improvements with clear, interactive charts.", iconName: "chart.bar.xaxis", accentColor: .blue, visual: { isAnimating in AnimatedChartView(animate: isAnimating) }),
        .init(title: "Meet Your Companion", description: "Your personal guide to celebrate wins and keep you motivated.", iconName: "sparkles", accentColor: .indigo, visual: { isAnimating in CompanionIntroView(animate: isAnimating) }),
        .init(title: "Level Up & Achieve", description: "Unlock new challenges and earn badges as you get stronger.", iconName: "star.fill", accentColor: .orange, visual: { isAnimating in AnimatedLevelsView(animate: isAnimating) }),
        .init(title: "Stay Organized", description: "Manage appointments and reminders all in one place.", iconName: "calendar.day.timeline.left", accentColor: .pink, visual: { isAnimating in AnimatedPlanView(animate: isAnimating) })
    ]
    
    private var currentAccentColor: Color {
        features[currentPage % features.count].accentColor
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundGradient
            carouselContent
            floatingButton
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            backButtonOverlay
        }
        .fullScreenCover(isPresented: $showAuthSheet) {
            AuthSheetContainerView(initialState: .signUp)
                .environmentObject(auth)
                .presentationBackground(.clear)
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                showAuthSheet = false
                dismiss()
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        RadialGradient(
            gradient: Gradient(colors: [currentAccentColor.opacity(0.12), Color(.systemGroupedBackground)]),
            center: .top, startRadius: 10, endRadius: 1000
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.6), value: currentPage)
    }
    
    private var carouselContent: some View {
        VStack(spacing: 0) {
            headerView
            carouselView
            pageIndicator
            Spacer(minLength: 120)
        }
    }
    
    private var headerView: some View {
        VStack {
            Text("NeuroQuest")
                .font(.system(size: 32, weight: .bold, design: .rounded))
        }
        .padding(.top, 20)
        .padding(.bottom, 15)
    }
    
    private var carouselView: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<features.count * 100, id: \.self) { index in
                let featureIndex = index % features.count
                FeaturePageView(
                    feature: features[featureIndex],
                    isVisible: currentPage == index
                )
                    .tag(index)
                    .scaleEffect(currentPage == index ? 1.0 : 0.9)
                    .opacity(currentPage == index ? 1.0 : 0.5)
                    .animation(.interpolatingSpring(stiffness: 120, damping: 15), value: currentPage)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.default, value: currentPage)
        .onChange(of: currentPage) { _, _ in hapticFeedback.impactOccurred() }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(features.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage % features.count ? features[index].accentColor : Color.secondary.opacity(0.3))
                    .frame(width: index == currentPage % features.count ? 30 : 10, height: 10)
                    .scaleEffect(index == currentPage % features.count ? 1.1 : 1.0)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)
        .padding(.vertical, 20)
    }
    
    private var floatingButton: some View {
        FloatingCreateAccountButton(accentColor: currentAccentColor, action: {
            hapticFeedback.impactOccurred()
            showAuthSheet = true
        })
        .animation(.easeInOut, value: currentAccentColor)
    }
    
    private var backButtonOverlay: some View {
        Button(action: {
            hapticFeedback.impactOccurred()
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundStyle(currentAccentColor)
                .padding()
                .glassEffect(in: .circle)
        }
        .padding()
        .animation(.easeInOut, value: currentAccentColor)
    }
}

// MARK: - Page View
struct FeaturePageView: View {
    let feature: AnyFeatureShowcaseItem
    let isVisible: Bool
    @State private var animate = false
    var body: some View {
        VStack(spacing: 30) {
            
            feature.visual($animate)
                .frame(height: 320)
                .opacity(animate ? 1 : 0)
                .scaleEffect(animate ? 1.0 : 0.9)
                .offset(y: animate ? 0 : 30)
                .animation(.interpolatingSpring(stiffness: 80, damping: 12).delay(0.1), value: animate)
            
            VStack(spacing: 10) {
                Text(feature.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(feature.accentColor)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(.interpolatingSpring(stiffness: 80, damping: 12).delay(0.2), value: animate)
        }
        .padding(30)
        .onChange(of: isVisible) { _, newIsVisible in
            if newIsVisible {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animate = true
                }
            } else {
                animate = false
            }
        }
        .onAppear {
             if isVisible {
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                     animate = true
                 }
             }
         }
    }
}

struct FloatingCreateAccountButton: View {
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        VStack {
            Button(action: action) {
                Text("Create Account")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.glassProminent)
            .tint(accentColor.gradient)
            .shadow(color: accentColor.opacity(0.4), radius: 10, y: 5)
        }
        .padding(30)
    }
}

// MARK: - Animated Visuals

struct AnimatedGameIconsView: View {
    @Binding var animate: Bool
    
    let icons = ["hand.raised.fill", "figure.walk", "mic.fill", "hand.draw.fill", "brain.head.profile", "figure.stand"]
    let colors: [Color] = [.teal, .blue, .purple, .orange, .pink, .green]
    let animation = Animation.interpolatingSpring(stiffness: 45, damping: 6).speed(0.6)

    private struct IconProperties {
        let angle: Double
        let radiusFactor: CGFloat
    }
    
    private let iconProperties: [IconProperties]
    
    init(animate: Binding<Bool>) {
        self._animate = animate
        self.iconProperties = Self.generateProperties(count: icons.count)
    }
    
    private static func generateProperties(count: Int) -> [IconProperties] {
        var properties: [IconProperties] = []
        let angleStep = (2.0 * .pi) / Double(count)
        
        for i in 0..<count {
            let baseAngle = angleStep * Double(i)
            let angleJitter = angleStep * 0.3
            let randomAngle = baseAngle + Double.random(in: -angleJitter...angleJitter)
            let randomRadiusFactor = CGFloat.random(in: 0.7...1.0)
            
            properties.append(IconProperties(
                angle: randomAngle,
                radiusFactor: randomRadiusFactor
            ))
        }
        return properties
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<icons.count, id: \.self) { index in
                    Image(systemName: icons[index])
                        .font(.system(size: 50 + CGFloat(index * 2)))
                        .foregroundStyle(colors[index].gradient)
                        .padding(15)
                        .glassEffect(in: .circle)
                        .shadow(color: colors[index].opacity(0.4), radius: 8, y: 4)
                        .offset(
                            x: animate ? randomX(index, geo: geo) : 0,
                            y: animate ? randomY(index, geo: geo) : 0
                        )
                        .scaleEffect(animate ? 1 : 0.3)
                        .opacity(animate ? 1 : 0)
                        .animation(
                            animation.delay(Double(index) * 0.15),
                            value: animate
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    func randomX(_ index: Int, geo: GeometryProxy) -> CGFloat {
        let props = iconProperties[index]
        let baseRadius = min(geo.size.width, geo.size.height) * 0.5
        let finalRadius = baseRadius * props.radiusFactor
        return cos(props.angle) * finalRadius
    }
    
    func randomY(_ index: Int, geo: GeometryProxy) -> CGFloat {
        let props = iconProperties[index]
        let baseRadius = min(geo.size.width, geo.size.height) * 0.5
        let finalRadius = baseRadius * props.radiusFactor
        return sin(props.angle) * finalRadius
    }
}

// MARK: - NEW Animated Intelligence View
struct AnimatedIntelligenceView: View {
    @Binding var animate: Bool
    
    let aiBlue = Color(red: 0.3, green: 0.0, blue: 1.0)
    let aiViolet = Color(red: 0.6, green: 0.0, blue: 1.0)
    let aiPink = Color(red: 1.0, green: 0.2, blue: 0.5)
    let aiLightBlue = Color(red: 0.0, green: 0.9, blue: 1.0)
    let aiOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

    var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [aiBlue, aiViolet, aiViolet, aiPink, aiPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [aiLightBlue, aiViolet, aiLightBlue, aiPink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(primaryGradient)
                    .opacity(0.8)
                    .frame(width: geo.size.width * 0.6)
                    .blur(radius: 50)
                    
                    .offset(x: animate ? geo.size.width * 0.05 : -geo.size.width * 0.05)
                    .scaleEffect(animate ? 1.05 : 0.95)                    .animation(
                        .easeInOut(duration: 8)
                        .repeatForever(autoreverses: true),
                        value: animate
                    )
       
                Circle()
                    .fill(secondaryGradient)
                    .opacity(0.7)
                    .frame(width: geo.size.width * 0.4)
                    .blur(radius: 40)
                    .offset(y: animate ? geo.size.height * 0.12 : -geo.size.height * 0.12)
                    .scaleEffect(animate ? 0.95 : 0.85)
                    .animation(
                        .easeInOut(duration: 5)
                        .repeatForever(autoreverses: true)
                        .delay(1),
                        value: animate
                    )
                Circle()
                    .fill(aiOrange)
                    .opacity(0.65)
                    .frame(width: geo.size.width * 0.37)
                    .blur(radius: 30)
                    .offset(
                        x: animate ? -geo.size.width * 0.13 : geo.size.width * 0.13,
                        y: animate ? geo.size.height * 0.07 : -geo.size.height * 0.07
                    )
                    .animation(
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true)
                        .delay(0.5),
                        value: animate
                    )
                
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 80))
                    .foregroundStyle(primaryGradient)
                    .padding(30)
                    .glassEffect(in: .circle)
                    .shadow(color: aiBlue.opacity(0.4), radius: 12, y: 6)
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .opacity(animate ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: animate)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}




struct AnimatedChartView: View {
    @Binding var animate: Bool
    
    let fullData: [Double] = [52, 70, 65, 90, 85, 110, 120, 100, 130, 115, 150]
    let zeroData: [Double]
    
    init(animate: Binding<Bool>) {
        self._animate = animate
        self.zeroData = Array(repeating: 0.0, count: fullData.count)
    }
    
    private var dataToPlot: AnimatableVector {
        AnimatableVector(values: animate ? fullData : zeroData)
    }
    
    private var chartData: [(offset: Int, value: Double)] {
        dataToPlot.values.enumerated().map { (offset: $0, value: $1) }
    }
    
    private var maxYValue: Double {
        (fullData.max() ?? 120) + 20
    }
    
    private var areaGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.0)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var chartView: some View {
        Chart(chartData, id: \.offset) { item in
            createLineMark(index: item.offset, value: item.value)
            createAreaMark(index: item.offset, value: item.value)
        }
        .chartXAxis { createXAxis() }
        .chartYAxis { createYAxis() }
        .chartYScale(domain: -10...maxYValue)
        .animation(.interpolatingSpring(stiffness: 60, damping: 10).delay(0.3), value: animate)
        .animation(.easeIn(duration: 0.5).delay(0.6), value: animate)
    }
    
    private func createLineMark(index: Int, value: Double) -> some ChartContent {
        LineMark(
            x: .value("Day", index),
            y: .value("Score", value)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(Color.blue.gradient)
        .lineStyle(StrokeStyle(lineWidth: 5, lineCap: .round))
        .shadow(color: .blue.opacity(0.5), radius: 10, y: 5)
    }
    
    private func createAreaMark(index: Int, value: Double) -> some ChartContent {
        AreaMark(
            x: .value("Day", index),
            y: .value("Score", value)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(areaGradient)
    }
    
    @AxisContentBuilder
    private func createXAxis() -> some AxisContent {
        AxisMarks(values: .automatic) { _ in
            if animate {
                AxisGridLine()
                AxisTick()
            }
        }
    }
    
    @AxisContentBuilder
    private func createYAxis() -> some AxisContent {
        AxisMarks(values: .automatic) { _ in
            if animate {
                AxisGridLine()
                AxisTick()
            }
        }
    }
    
    var body: some View {
        chartView
            .padding(20)
            .glassEffect(in: .rect(cornerRadius: 35))
    }
}

struct AnimatableVector: VectorArithmetic {
    var values: [Double]
    
    static var zero: AnimatableVector {
        .init(values: [])
    }
    
    var magnitudeSquared: Double {
        values.map { $0 * $0 }.reduce(0, +)
    }
    
    static func + (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let c = max(lhs.values.count, rhs.values.count)
        let l = lhs.values + Array(repeating: 0.0, count: max(0, c - lhs.values.count))
        let r = rhs.values + Array(repeating: 0.0, count: max(0, c - rhs.values.count))
        return .init(values: zip(l, r).map(+))
    }
    
    static func - (lhs: AnimatableVector, rhs: AnimatableVector) -> AnimatableVector {
        let c = max(lhs.values.count, rhs.values.count)
        let l = lhs.values + Array(repeating: 0.0, count: max(0, c - lhs.values.count))
        let r = rhs.values + Array(repeating: 0.0, count: max(0, c - rhs.values.count))
        return .init(values: zip(l, r).map(-))
    }
    
    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }
}

struct CompanionIntroView: View {
    @Binding var animate: Bool
    var body: some View {
        ZStack {
            Image(systemName: "figure.wave")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.indigo.gradient)
                .frame(width: 150, height: 150)
                .scaleEffect(animate ? 1.0 : 0.8)
                .rotationEffect(.degrees(animate ? 5 : -5))
                .offset(y: animate ? -10 : 10)
                .shadow(color: .indigo.opacity(0.4), radius: 15, y: 10)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.2), value: animate)
            
            ZStack {
                Text("Hi there! I'm here to help\nyou on your quest.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .glassEffect(in: ChatBubble())
                    .shadow(radius: 5)
            }
            .scaleEffect(animate ? 1.0 : 0.5)
            .opacity(animate ? 1.0 : 0)
            .animation(.interpolatingSpring(stiffness: 100, damping: 10).delay(0.8), value: animate)
            .offset(
                x: 63,
                y: -120 + (animate ? -10 : 10)
            )
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.2), value: animate)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ChatBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight, .bottomRight],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        
        let tailWidth: CGFloat = 15
        let tailHeight: CGFloat = 10
        let tailPosition: CGFloat = 20
        
        path.move(to: CGPoint(x: rect.minX + tailPosition, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + tailPosition - tailWidth / 2, y: rect.maxY + tailHeight))
        path.addLine(to: CGPoint(x: rect.minX + tailPosition - tailWidth, y: rect.maxY))
        path.close()
        
        return Path(path.cgPath)
    }
}

struct AnimatedLevelsView: View {
    @Binding var animate: Bool
    @State private var unlockedLevels = 0
    let totalLevels = 5
    let animationDelay = 0.2
    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(0..<totalLevels, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 35))
                    .glassEffect(.clear, in: .circle)
                    .foregroundStyle(index < unlockedLevels ? Color.orange : Color.secondary.opacity(0.2))
                    .scaleEffect(index < unlockedLevels ? 1.0 : 0.8)
                    .rotationEffect(.degrees(index < unlockedLevels ? Double.random(in: -5...5) : 0))
            }
        }
        .padding(20)
        .glassEffect(in: .capsule)
        .animation(.interpolatingSpring(stiffness: 100, damping: 10).delay(0.2), value: unlockedLevels)
        .onChange(of: animate) { _, newValue in
            if newValue {
                Task {
                    guard newValue else { return }
                    for i in 1...3 {
                        if !animate { break }
                        unlockedLevels = i
                        try? await Task.sleep(nanoseconds: UInt64(animationDelay * 1_000_000_000))
                    }
                }
            } else {
                unlockedLevels = 0
            }
        }
    }
}

struct AnimatedPlanView: View {
    @Binding var animate: Bool
    
    @State private var item1Done = false
    @State private var item2Done = false
    @State private var item3Done = false
    
    var body: some View {
        VStack(spacing: 15) {
            PlanItemView(
                text: "Appointment: Dr. Smith",
                time: "10:00 AM",
                isDone: $item1Done,
                delay: 0.5,
                color: .indigo,
                animate: $animate
            )
            PlanItemView(
                text: "Take Medication",
                time: "12:00 PM",
                isDone: $item2Done,
                delay: 0.7,
                color: .orange,
                animate: $animate
            )
            PlanItemView(
                text: "Evening Exercise",
                time: "6:00 PM",
                isDone: $item3Done,
                delay: 1.0,
                color: .blue,
                animate: $animate
            )
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 30))
    }
}

struct PlanItemView: View {
    let text: String
    let time: String
    @Binding var isDone: Bool
    let delay: Double
    let color: Color
    @Binding var animate: Bool
    
    @State private var hasAppeared = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(text)
                    .font(.headline)
                    .strikethrough(isDone, color: .secondary)
                Text(time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .symbolEffect(.bounce, value: isDone)
                .foregroundStyle(isDone ? color : .secondary.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .glassEffect(in: .capsule)
        .opacity(isDone ? 0.7 : 1.0)
        .scaleEffect(isDone ? 0.98 : 1.0)
        .offset(x: isDone ? 5 : 0)
        .animation(.interpolatingSpring(stiffness: 100, damping: 12), value: isDone)
        .onChange(of: animate) { _, newValue in
            if newValue {
                if !hasAppeared {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if animate {
                            isDone = true
                            hasAppeared = true
                        }
                    }
                }
            } else {
                isDone = false
                hasAppeared = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        FeatureCarouselView()
            .environmentObject(Authentication())
    }
}

