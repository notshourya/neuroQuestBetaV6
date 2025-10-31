//
//  GamesDataStore.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import Foundation
import SwiftUI
import Combine

struct Game: Identifiable {
    let id: UUID = UUID()
    var card: GameCard
    var tiers: [LevelTier]

    var overallProgress: Double {
        let allLevels = tiers.flatMap { $0.levels }
        guard !allLevels.isEmpty else { return 0.0 }
        
        let completedLevels = allLevels.filter { $0.status == .completed }.count
        return Double(completedLevels) / Double(allLevels.count)
    }

    var lastPlayedDate: Date? {
        let allHistory = tiers.flatMap { $0.levels }.flatMap { $0.history }
        let latestEntry = allHistory.max(by: { $0.date < $1.date })
        return latestEntry?.date
    }
}

class GameDataStore: ObservableObject {
    
    @Published var games: [Game] = []
    
    init() {
        self.games = loadMockGameData()
    }
    
    private func loadMockGameData() -> [Game] {
        return GameCard.allGames.map { gameCard in
            let tiers = LevelTier.generateMockTiers()
            return Game(card: gameCard, tiers: tiers)
        }
    }
}
