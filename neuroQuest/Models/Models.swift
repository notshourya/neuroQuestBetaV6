//
//  Models.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI
import Charts

// MARK: - Game & Level Models

struct GameCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let imageName: String
    let accentColor: Color
    var tutorialVideo: URL?
    var tips: [String]

    static var allGames: [GameCard] = [
        GameCard(
            title: "Tremor Control",
            subtitle: "Steady your hands",
            imageName: "hand.raised.fill",
            accentColor: .teal,
            tips: [
                "Rest your arm on a table for better stability.",
                "Take a deep breath before you start the level.",
                "Try to trace the path in one smooth, continuous motion."
            ]
        ),
        GameCard(
            title: "Balance Practice",
            subtitle: "Improve stability",
            imageName: "figure.walk",
            accentColor: .blue,
            tips: [
                "Focus your eyes on a single, unmoving spot in front of you.",
                "Keep your core engaged to maintain your center of gravity.",
                "Stand near a wall or chair for support if you feel unsteady."
            ]
        ),
        GameCard(
            title: "Voice Strength",
            subtitle: "Enhance speech clarity",
            imageName: "mic.fill",
            accentColor: .purple,
            tips: [
                "Sit up straight to give your lungs plenty of room to expand.",
                "Project your voice as if you're speaking to someone across the room.",
                "Take a full breath before starting the exercise."
            ]
        ),
        GameCard(
            title: "Fine Motor Skills",
            subtitle: "Finger dexterity",
            imageName: "hand.draw.fill",
            accentColor: .orange,
            tips: [
                "Warm up your hands by gently stretching your fingers.",
                "Focus on accuracy over speed. Speed will come with practice.",
                "Don't grip your device too tightly. A relaxed hand is a steadier hand."
            ]
        ),
        GameCard(
            title: "Cognitive Focus",
            subtitle: "Memory and attention",
            imageName: "brain.head.profile",
            accentColor: .pink,
            tips: [
                "Try to create a story or association for the items you need to remember.",
                "Eliminate distractions. Find a quiet place to play.",
                "Say the sequence or items out loud to engage your auditory memory."
            ]
        ),
         GameCard(
            title: "Walking Rhythm",
            subtitle: "Improve gait",
            imageName: "figure.stand",
            accentColor: .mint,
            tips: [
                "Listen closely to the beat and try to match your steps to the rhythm.",
                "Focus on lifting your feet with each step, not shuffling.",
                "Start slow and find the tempo before trying to match it perfectly."
            ]
        )
    ]
}

enum LevelStatus {
    case locked, unlocked, completed
}

struct GameScore: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
    
    var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct Level: Identifiable {
    let id: Int
    var status: LevelStatus
    var score: Int?
    var history: [GameScore] = []
    let requiredScoreToUnlockNext: Int = 80
}

struct LevelTier: Identifiable {
    let id = UUID()
    let title: String
    var levels: [Level]
}

// MARK: - Activity & Stats Models


struct GamePlaySession: Identifiable {
    let id = UUID()
    let patientId: String
    let gameTitle: String
    let date: Date
    let score: Int
    let durationInSeconds: Int

    var steadiness: Double?
    var averageReactionTimeMS: Int?
    var pitchStability: Double?
    var decibelLevel: Double?

  
    static func generateMockData(for games: [GameCard], count: Int) -> [GamePlaySession] {
        var sessions: [GamePlaySession] = []
        guard !games.isEmpty else { return [] }

        let mockPatientIDs = ["Patient-A", "Patient-B", "Patient-C", "Patient-D", "Patient-E"]

        for _ in 0..<count {
            guard let randomGame = games.randomElement() else { continue }

            let randomDate = Date().addingTimeInterval(-Double.random(in: 0...(3600 * 24 * 30)))
            let randomScore = Int.random(in: 65...100)
            let randomDuration = Int.random(in: 90...300)

           
            var session = GamePlaySession(
                patientId: mockPatientIDs.randomElement()!,
                gameTitle: randomGame.title,
                date: randomDate,
                score: randomScore,
                durationInSeconds: randomDuration
            )

            switch randomGame.title {
            case "Tremor Control":
                session.steadiness = Double.random(in: 80...98)
            case "Cognitive Focus":
                session.averageReactionTimeMS = Int.random(in: 300...800)
            case "Voice Strength":
                session.pitchStability = Double.random(in: 85...99)
                session.decibelLevel = Double.random(in: 50...85)
            default:
                break
            }
            sessions.append(session)
        }
        return sessions
    }
}

enum TimeFilter: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    var id: Self { self }
}


struct ExerciseSession: Identifiable {
    let id = UUID()
    let day: String
    let date: Date
    let balanceScore: Int
    let coordinationScore: Int
    let steps: Int
}

enum MetricType: String, CaseIterable {
    case balance = "Balance"
    case coordination = "Coordination"
    case steps = "Steps"
    
    var color: Color {
        switch self {
        case .balance: return .cyan
        case .coordination: return .green
        case .steps: return .orange
        }
    }
    
    func value(from session: ExerciseSession) -> Int {
        switch self {
        case .balance: return session.balanceScore
        case .coordination: return session.coordinationScore
        case .steps: return session.steps
        }
    }
    
    func yAxisMax(for data: [ExerciseSession]) -> Int {
        switch self {
        case .balance, .coordination: return 100
        case .steps:
            let maxSteps = data.map { $0.steps }.max() ?? 10000
            return (maxSteps / 1000 + 1) * 1000
        }
    }
}

extension LevelTier {
    static func generateMockTiers() -> [LevelTier] {
       
        var tier1Levels: [Level] = []
        for i in 1...20 {
            tier1Levels.append(Level(id: i, status: (i == 1) ? .unlocked : .locked))
        }
        var tier2Levels: [Level] = []
        for i in 21...40 {
            tier2Levels.append(Level(id: i, status: .locked))
        }
      
        var tier3Levels: [Level] = []
        for i in 41...60 {
            tier3Levels.append(Level(id: i, status: .locked))
        }

        let tier1 = LevelTier(title: "Tier 1: Foundations", levels: tier1Levels)
        let tier2 = LevelTier(title: "Tier 2: Intermediate", levels: tier2Levels)
        let tier3 = LevelTier(title: "Tier 3: Advanced", levels: tier3Levels)
        
        return [tier1, tier2, tier3]
    }
}
