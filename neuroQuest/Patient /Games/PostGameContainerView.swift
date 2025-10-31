//
//  PostGameContainerView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/31/25.
//

import SwiftUI
struct PostGameContainerView: View {
    
    let newSession: GameScore
    let game: GameCard
    let accentColor: Color
    let targetScore: Int
    let oldBestScore: Int
    
    let onDismiss: () -> Void
    
    private enum FlowStep {
        case loading
        case summary
        case detail
    }
    
    @State private var currentStep: FlowStep = .loading
    
    private var score: Int { newSession.score }
    private var rating: Int {
        switch score {
        case ...75: return 1
        case ...80: return 2
        case ...90: return 3
        case ...99: return 4
        default: return 5
        }
    }
    public init(
        newSession: GameScore,
        game: GameCard,
        accentColor: Color,
        targetScore: Int,
        oldBestScore: Int,
        onDismiss: @escaping () -> Void
    ) {
        self.newSession = newSession
        self.game = game
        self.accentColor = accentColor
        self.targetScore = targetScore
        self.oldBestScore = oldBestScore
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            if currentStep == .loading {
                LoadingScreenView(game: game, accentColor: accentColor)
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            withAnimation {
                                currentStep = .summary
                            }
                        }
                    }
            }
            
            if currentStep == .summary {
                ScoreSummaryView(
                    score: score,
                    oldBestScore: oldBestScore,
                    rating: rating,
                    accentColor: accentColor,
                    targetScore: targetScore,
                    onContinue: {
                        withAnimation {
                            currentStep = .detail
                        }
                    }
                )
            }
            
            if currentStep == .detail {
                PostGameView(
                    session: newSession,
                    game: game,
                    oldBestScore: oldBestScore, 
                    onDismiss: onDismiss
                )
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
    }
}
