import SwiftUI
import AVKit
import WebKit


struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        init(_ parent: WebView) { self.parent = parent }
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { parent.isLoading = true }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { parent.isLoading = false }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            print("Webview navigation failed: \(error.localizedDescription)")
        }
    }
}
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let description: String
    var dateAchieved: Date? = nil
     
    var achieved: Bool {
        dateAchieved != nil
    }
}

// MARK: - Game Detail View
struct GameDetailView: View {
    let game: GameCard
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var patientModel: PatientDataModel // <-- ADDED
   
    @Binding var tiers: [LevelTier]

    // MARK: - Updated Achievements List
    @State private var achievements: [Achievement] = [
        Achievement(title: "First Play", imageName: "play.fill", description: "Complete your very first game session.", dateAchieved: Date().addingTimeInterval(-86400 * 5)),
        Achievement(title: "Level 1", imageName: "star.fill", description: "Complete the first level of any tier.", dateAchieved: Date().addingTimeInterval(-86400 * 4)),
        Achievement(title: "Perfect Score", imageName: "target", description: "Get a perfect score of 100 on any level."),
        Achievement(title: "Explorer", imageName: "map.fill", description: "Unlock three different game tiers."),
        Achievement(title: "Specialist", imageName: "sparkles", description: "Complete an entire tier, from start to finish.", dateAchieved: Date().addingTimeInterval(-86400 * 2)),
        Achievement(title: "Consistent", imageName: "calendar.badge.clock", description: "Play the game on 3 different days.")
    ]
     
    @State private var hasAppeared = false
    @State private var isShowingTutorial = false

    // MARK: - State for Achievement Sheet
    @State private var selectedAchievement: Achievement?

    private let tierGridColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 100, maximum: 120))
    ]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [game.accentColor.opacity(0.15), .clear]),
                center: .top, startRadius: 10, endRadius: 1000
            ).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                         
                    GameHeaderView(game: game)
                        .padding(15)
                        .padding(.horizontal)
                        .animateOnAppear(hasAppeared: hasAppeared, delay: 0)
                         
                    GameProgressCard(tiers: tiers, accentColor: game.accentColor)
                        .animateOnAppear(hasAppeared: hasAppeared, delay: 0.2)
                         
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Difficulties")
                            .font(.title2.bold())
                            .padding(.horizontal)
                         
                        LazyVGrid(columns: tierGridColumns, spacing: 16) {
                            ForEach($tiers) { $tier in
                                
                                let isUnlocked = tier.levels.contains(where: { $0.status != .locked })
                                 
                                NavigationLink {
                                    LevelPathView(
                                        tier: $tier,
                                        game: game,
                                        onLastLevelComplete: {
                                            unlockNextTier(after: tier)
                                        }
                                    )
                                    .environmentObject(patientModel) // <-- ADDED
                                } label: {
                                     
                                    TierGridItemView(tier: tier, accentColor: game.accentColor, isUnlocked: isUnlocked)
                                }
                                .disabled(!isUnlocked)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .animateOnAppear(hasAppeared: hasAppeared, delay: 0.4)
                         
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Achievements")
                            .font(.title2.bold())
                            .padding(.horizontal)
                             
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(achievements) { achievement in
                                    // MARK: - Tappable Achievement Button
                                    Button {
                                        selectedAchievement = achievement
                                    } label: {
                                        AchievementBadgeView(achievement: achievement)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal,30)
                        }
                    }
                    .animateOnAppear(hasAppeared: hasAppeared, delay: 0.6)
                         
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss() } label: {
                            HStack {
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 17))}
                                    .foregroundColor(game.accentColor)
                                    }
                                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isShowingTutorial = true } label: {
                        Image(systemName: "info")
                            .font(.caption.bold())
                            .foregroundColor(game.accentColor)
                    }
                }
            }
        }
        // MARK: - Sheet Modifier
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement, accentColor: game.accentColor)
        }
        
        .sheet(isPresented: $isShowingTutorial) {
            TutorialViewSheet(game: game, isShowingTutorial: $isShowingTutorial)
        }
        
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }
     
    private func unlockNextTier(after completedTier: LevelTier) {
        guard let completedTierIndex = tiers.firstIndex(where: { $0.id == completedTier.id }) else {
            return
        }
        let nextTierIndex = completedTierIndex + 1
        if tiers.indices.contains(nextTierIndex) {
            guard let firstLevel = tiers[nextTierIndex].levels.first, firstLevel.status != .unlocked else {
                return
            }
            withAnimation(.spring()) {
                tiers[nextTierIndex].levels[0].status = .unlocked
            }
        }
    }
}

// ... All other subviews (TierGridItemView, GameProgressCard, etc.) remain unchanged ...
// MARK: - Subviews for GameDetailView
// ... (TierGridItemView, GameProgressCard, AchievementBadgeView, etc.) ...

struct TierGridItemView: View {
    let tier: LevelTier
    let accentColor: Color
    let isUnlocked: Bool

    @State private var isVisible = false

    private var levelsCompleted: Int {
        tier.levels.filter { $0.status == .completed }.count
    }

    private var progressFraction: Double {
        guard !tier.levels.isEmpty else { return 0.0 }
        return Double(levelsCompleted) / Double(tier.levels.count)
    }

    private var tierNumberString: String {
        let components = tier.title.split(separator: ":")
        if let firstPart = components.first {
            let numberPart = firstPart.replacingOccurrences(of: "Tier", with: "").trimmingCharacters(in: .whitespaces)
            if !numberPart.isEmpty {
                return numberPart
            }
        }
        return "?"
    }

    private var tierSubtitle: String {
        let components = tier.title.split(separator: ":")
        if components.count > 1 {
            return components[1].trimmingCharacters(in: .whitespaces)
        }
        return tier.title
    }

    let cardShape = RoundedRectangle(cornerRadius: 35, style: .continuous)

    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                Spacer()
                if isUnlocked {
                    Text(tierNumberString)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(accentColor)
                        .lineLimit(1)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                Spacer()
                Text(tierSubtitle)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .padding(15)
            if isUnlocked {
                 
                cardShape
                    .stroke(accentColor.opacity(0.2), lineWidth: 4)

                 
                cardShape
                    .trim(from: 0, to: progressFraction)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progressFraction)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
         
        .glassEffect(in: .rect(cornerRadius: 35))
        .clipShape(cardShape)
        .saturation(isUnlocked ? 1 : 0)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

struct GameProgressCard: View {
    let tiers: [LevelTier]
    let accentColor: Color
    private var allLevels: [Level] { tiers.flatMap { $0.levels } }
    private var levelsCompleted: Int { allLevels.filter { $0.status == .completed }.count }

    private var averageScoreDisplay: String {
        let allScores = allLevels.flatMap { $0.history }.map { $0.score }
        guard !allScores.isEmpty else { return "N/A" }
         
        let totalScore = allScores.reduce(0, +)
        let average = Double(totalScore) / Double(allScores.count)
         
        return String(format: "%.1f", average)
    }
     
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Label("Overall Progress", systemImage: "chart.pie.fill")
                .font(.title2.bold())
                .foregroundColor(accentColor)
            HStack(spacing: 10) {
                StatCardView(title: "Completed", value: "\(levelsCompleted) / \(allLevels.count)", systemImage: "star.fill", color: .yellow)
                    .glassEffect(in: .capsule)
                 
                StatCardView(title: "Average Score", value: averageScoreDisplay, systemImage: "arrow.backward.circle", color: .cyan)
                    .glassEffect(in: .capsule)
            }
        }
        .padding(15)
        .glassEffect(in: .rect(cornerRadius: 45))
        .padding(.horizontal)
    }
}

struct AchievementBadgeView: View {
    let achievement: Achievement
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: achievement.imageName)
                .font(.title)
                .foregroundColor(achievement.achieved ? .primary : .secondary)
            Text(achievement.title)
                .font(.caption)
                .lineLimit(2)
        }
        //.padding(12)
        .frame(width: 90, height: 90)
        .padding()
        .glassEffect(in: .rect(cornerRadius: 35))
        .saturation(achievement.achieved ? 1 : 0)
        .opacity(achievement.achieved ? 1 : 0.6)
    }
}


struct GameHeaderView: View {
    let game: GameCard
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(game.accentColor.opacity(0.1)).frame(width: 150, height: 150).blur(radius: 5)
                Image(systemName: game.imageName).resizable().scaledToFit().frame(width: 90, height: 90).foregroundColor(game.accentColor)
            }
            VStack(spacing: 8) {
                Text(game.title).font(.largeTitle.bold()).foregroundColor(.primary)
                if let subtitle = game.subtitle {
                    Text(subtitle).font(.title3).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                }
            }
        }
    }
}

struct TutorialView: View {
    let game: GameCard
    private var youtubeURL: URL? { URL(string: "https://www.youtube.com/watch?v=dGcqqA3Sl-o") }
    @State private var isLoadingWebView: Bool = true
     
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            if let url = youtubeURL {
                WebView(url: url, isLoading: $isLoadingWebView)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Rectangle().fill(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .glassEffect(in: .rect(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical)
    }
}

struct TutorialViewSheet: View {
    let game: GameCard
    @Binding var isShowingTutorial: Bool
     
    var body: some View {
        NavigationView {
            TutorialView(game: game)
                .navigationTitle("How to Play")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { isShowingTutorial = false }
                            .tint(game.accentColor)
                    }
                }
        }
        .presentationDetents([.large, .medium])
        .presentationDragIndicator(.visible)
    }
}

struct AnimateOnAppear: ViewModifier {
    let hasAppeared: Bool
    let delay: Double
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(delay), value: hasAppeared)
    }
}

extension View {
    func animateOnAppear(hasAppeared: Bool, delay: Double) -> some View {
        self.modifier(AnimateOnAppear(hasAppeared: hasAppeared, delay: delay))
    }
}

// MARK: -Achievement Detail Sheet
struct AchievementDetailSheet: View {
    let achievement: Achievement
    let accentColor: Color
     
    private var achievedDate: String {
        if let date = achievement.dateAchieved {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return ""
    }
     
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: achievement.imageName)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(achievement.achieved ? accentColor : .secondary)
                    .symbolRenderingMode(.hierarchical)
                    .padding(.bottom, 5)
                 
                Text(achievement.title)
                    .font(.title2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal)
                 
                Text(achievement.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                 
                if achievement.achieved {
                    Text("Achieved on: \(achievedDate)")
                        .font(.caption.bold())
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.2))
                        )
                } else {
                    Text("Not achieved yet")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                 
                Spacer()
            }
            .padding(.top, 25)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }
}


#Preview{
    NavigationView {
        GameDetailView(
            game: GameCard.allGames.first!,
            tiers: .constant(LevelTier.generateMockTiers())
        )
        .environmentObject(GameDataStore())
        .environmentObject(PatientDataModel()) // <-- ADDED
    }
}
