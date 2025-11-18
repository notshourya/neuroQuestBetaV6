//
//  LevelDetailedView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI

struct EnhancedLevelDetailView: View {
    @Binding var level: Level
    let game: GameCard
    let accentColor: Color
    let onComplete: (_ score: Int) -> Void
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var patientModel: PatientDataModel // <-- 1. Add EnvironmentObject

    @State private var showPostGameFlow = false
    @State private var sessionForModal: GameScore? = nil
    @State private var oldScoreForModal: Int = 0
    
    @State private var scoreToView: GameScore? = nil

    private var levelDescription: String {
        "A test of your stability and control. Focus on smooth movements to maximize your score and beat the target."
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
                
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(0.15), .clear]),
                center: .top, startRadius: 10, endRadius: 1000
            ).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                        
                    heroCardView
                        .animateOnAppear(delay: 0.1)
                        
                    Button(action: playGame) {
                        Label(level.history.isEmpty ? "Play Game" : "Play Again", systemImage: "play.circle.fill")
                            .font(.title2.bold())
                            .imageScale(.large)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .tint(accentColor)
                    .padding(.horizontal)
                    .animateOnAppear(delay: 0.2)
                        
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Objectives")
                            .font(.title2.bold())
                            .padding(.horizontal)
                            
                        objectivesCardContentView
                    }
                    .animateOnAppear(delay: 0.3)
                        
                    if !level.history.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Score History")
                                .font(.title2.bold())
                                .padding(.horizontal)
                                
                            historyCardView
                        }
                        .animateOnAppear(delay: 0.4)
                    }
                }
                .padding(.vertical)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.backward")
                                .font(.system(size: 17))
                                .foregroundColor(accentColor)
                        }
                    }
                }
        
        .fullScreenCover(isPresented: $showPostGameFlow) {
            if let session = sessionForModal {
                PostGameContainerView(
                    newSession: session,
                    game: game,
                    accentColor: accentColor,
                    targetScore: level.requiredScoreToUnlockNext,
                    oldBestScore: oldScoreForModal,
                    onDismiss: {
                        onComplete(session.score)
                        showPostGameFlow = false
                        dismiss()
                    }
                )
            }
        }
        
        .fullScreenCover(item: $scoreToView) { session in
            PostGameView(
                session: session,
                game: game,
                oldBestScore: Int.max,
                onDismiss: {
                    scoreToView = nil
                }
            )
        }
    }
    
    // 2. Add function to update the reminder
    private func updateRequiredReminder(for gameTitle: String) {
        // Find the index of the reminder to update
        guard let reminderIndex = patientModel.patient.reminders.firstIndex(where: {
            !$0.isCompleted && // It's not already done
            Calendar.current.isDateInToday($0.date) && // It's for today
            $0.tags.contains(where: { $0.name == gameTitle }) // It has the matching game tag
        }) else {
            return // No matching, incomplete reminder found
        }
        
        // Set it to completed
        withAnimation {
            patientModel.patient.reminders[reminderIndex].isCompleted = true
        }
    }
    
    // MARK: - Updated playGame() function in EnhancedLevelDetailView
    // Replace the existing playGame() function with this version

    private func playGame() {
        let originalBestScore = level.score ?? 0
        
        // Generate mock score and duration
        let newScoreValue = Int.random(in: 70...100)
        let mockDuration = Int.random(in: 90...240) // 1.5 to 4 minutes
        let newSession = GameScore(date: Date(), score: newScoreValue)
        
        // Update level history
        level.history.insert(newSession, at: 0)
        level.status = .completed
        if newScoreValue > originalBestScore {
            level.score = newScoreValue
        }
        
        // MARK: - NEW: Create GamePlaySession for dashboard
        var gamePlaySession = GamePlaySession(
            patientId: patientModel.patient.id.uuidString,
            gameTitle: game.title,
            date: Date(),
            score: newScoreValue,
            durationInSeconds: mockDuration
        )
        
        // Add game-specific metrics based on game type
        switch game.title {
        case "Tremor Control":
            gamePlaySession.steadiness = Double.random(in: 80...98)
            
        case "Cognitive Focus":
            gamePlaySession.averageReactionTimeMS = Int.random(in: 300...800)
            
        case "Voice Strength":
            gamePlaySession.pitchStability = Double.random(in: 85...99)
            gamePlaySession.decibelLevel = Double.random(in: 50...85)
            
        default:
            break
        }
        
        // MARK: - NEW: Add session to patient's history
        patientModel.patient.sessions.append(gamePlaySession)
        
        // Update reminder (existing code)
        updateRequiredReminder(for: game.title)
        
        // Show post-game flow
        sessionForModal = newSession
        oldScoreForModal = originalBestScore
        showPostGameFlow = true
    }
    
    // MARK: - View Components
    
    private var heroCardView: some View {
        VStack(spacing: 25) {
            LevelHeaderView(level: level)
            ScoreProgressView(score: level.score ?? 0, accentColor: accentColor)
            HStack(spacing: 16) {
                LevelStatPill(
                    label: "Target Score",
                    value: "\(level.requiredScoreToUnlockNext) pts",
                    color: .red,
                    systemImage: "target"
                )
                LevelStatPill(
                    label: "Attempts",
                    value: "\(level.history.count)",
                    color: .purple,
                    systemImage: "play.counter.fill"
                )
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 45))
        .padding(.horizontal)
    }
    
    private var objectivesCardContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(levelDescription)
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Divider()

            VStack(alignment: .leading, spacing: 16) {
                let hasMetTarget = (level.score ?? 0) >= level.requiredScoreToUnlockNext
                
                ObjectiveRow(
                    text: "Score **\(level.requiredScoreToUnlockNext)+ points** to unlock",
                    isComplete: hasMetTarget,
                    color: .green
                )
                
                ObjectiveRow(
                    text: "Set a new **Best Score**!",
                    isComplete: false,
                    color: .yellow,
                    systemImage: "star.fill"
                )
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 30))
        .padding(.horizontal)
    }
    
    private var historyCardView: some View {
        let recentHistory = Array(level.history.prefix(5))
        
        return VStack(spacing: 0) {
            ForEach(recentHistory) { entry in
                Button(action: {
                    scoreToView = entry
                }) {
                    LevelStatCardView(
                        title: entry.date.formatted(date: .abbreviated, time: .omitted),
                        value: "\(entry.score) pts",
                        systemImage: "calendar",
                        color: accentColor.opacity(0.8)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if entry.id != recentHistory.last?.id {
                    Divider().padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
        .glassEffect(in: .rect(cornerRadius: 30))
        .padding(.horizontal)
        
    }
}
