//
//  PostGameView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//


import SwiftUI
import Charts
struct PostGameView: View {
    
    let session: GameScore
    let game: GameCard
    
    let oldBestScore: Int
    let onDismiss: () -> Void
    
    private var accentColor: Color { game.accentColor }
    
    private var mockTimeTaken: String = "2:34 min"
    private var mockAccuracy: String = "92.1%"
    
    private var isNewHighScore: Bool {
        session.score > oldBestScore
    }
    
    private var scoreOverTime: [GameScore] {
        [
            .init(date: Date().addingTimeInterval(-300), score: 75),
            .init(date: Date().addingTimeInterval(-240), score: 80),
            .init(date: Date().addingTimeInterval(-180), score: 82),
            .init(date: Date().addingTimeInterval(-120), score: 90),
            .init(date: Date().addingTimeInterval(-60), score: 88),
            .init(date: Date(), score: session.score)
        ]
    }
    
    private var rating: Int {
        switch session.score {
        case ...75: return 1
        case ...80: return 2
        case ...90: return 3
        case ...99: return 4
        default: return 5
        }
    }

    public init(
        session: GameScore,
        game: GameCard,
        oldBestScore: Int,
        onDismiss: @escaping () -> Void
    ) {
        self.session = session
        self.game = game
        self.oldBestScore = oldBestScore
        self.onDismiss = onDismiss
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                RadialGradient(
                    gradient: Gradient(colors: [accentColor.opacity(0.15), .clear]),
                    center: .top, startRadius: 10, endRadius: 1000
                ).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 30) {
                        
                            Text("Session Summary")
                                .font(.largeTitle.bold())
                                .foregroundColor(accentColor)
                                .padding(.top, 20)
                    
                            if isNewHighScore {
                                Label("New Highscore!", systemImage: "trophy.fill")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(accentColor)
                                    .padding(10)
                                    .glassEffect(in: .capsule)
                            }
                           
                            ScoreProgressView(score: session.score, accentColor: accentColor)
                                .frame(width: 200, height: 200)
                          
                            HStack(spacing: 15) {
                                ForEach(0..<5, id: \.self) { index in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 35))
                                        .padding(12)
                                        .padding(.horizontal, -4)
                                        .foregroundStyle(index < rating ? accentColor : Color.secondary.opacity(0.2))
                                        .shadow(color: index < rating ? accentColor.opacity(0.3) : .clear, radius: 5)
                                }
                            }
                           
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Details")
                                    .font(.title2.bold())
                                    .foregroundColor(accentColor)
                                    .padding(.horizontal, 20)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 12) {
                                    StatCard(
                                        title: "Rating",
                                        value: "\(rating) / 5",
                                        icon: "star.fill",
                                        color: .yellow
                                    )
                                    StatCard(
                                        title: "Time",
                                        value: mockTimeTaken,
                                        icon: "hourglass",
                                        color: .blue
                                    )
                                    StatCard(
                                        title: "Accuracy",
                                        value: mockAccuracy,
                                        icon: "scope",
                                        color: .purple
                                    )
                                    StatCard(
                                        title: "Date",
                                        value: session.date.formatted(date: .abbreviated, time: .omitted),
                                        icon: "calendar",
                                        color: .green
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                           
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Session Progress")
                                    .font(.title2.bold())
                                    .foregroundColor(accentColor)
                                    .padding(.horizontal, 20)
                                
                                Chart(scoreOverTime) { dataPoint in
                                  
                                    LineMark(
                                        x: .value("Time", dataPoint.date),
                                        y: .value("Score", dataPoint.score)
                                    )
                                    .foregroundStyle(accentColor)
                                    .interpolationMethod(.catmullRom)
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                
                                    PointMark(
                                        x: .value("Time", dataPoint.date),
                                        y: .value("Score", dataPoint.score)
                                    )
                                    .foregroundStyle(accentColor)
                                }
                                .chartYScale(domain: 50...100) 
                                .chartXAxis(.hidden)
                                .chartYAxis {
                                    AxisMarks(position: .leading, values: [50, 75, 100])
                                }
                                .frame(height: 150)
                                .padding(20)
                                .glassEffect(in: .rect(cornerRadius: 30))
                                .padding(.horizontal, 20)
                            }
                            .padding(.bottom, 10)
                            
                        }
                    }
//                
//                    Button(action: onDismiss) {
//                        Label("Done", systemImage: "checkmark.circle.fill")
//                            .font(.title2.bold())
//                            .imageScale(.large)
//                            .frame(maxWidth: .infinity)
//                    }
//                    .buttonStyle(.glassProminent)
//                    .controlSize(.large)
//                    .tint(accentColor)
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 10)
//                    .padding(.top, 5)
//                    .background(
//                        Color.clear
//                            .ignoresSafeArea(edges: .bottom)
//                    )
//                    .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
                }
            }
           // .navigationBarHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: onDismiss) {
                        Label("Done", systemImage: "checkmark").labelStyle(.titleAndIcon)
                    }
                    .tint(accentColor)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .padding(10)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .glassEffect(in: .rect(cornerRadius: 30))
    }
}


#Preview {
    PostGameView(
        session: GameScore(date: Date(), score: 92),
        game: GameCard.allGames[0],
        oldBestScore: 85,
        onDismiss: { print("Done button tapped") }
    )
}
