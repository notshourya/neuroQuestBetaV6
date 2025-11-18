import SwiftUI

struct ExerciseView: View {
    @EnvironmentObject var gameDataStore: GameDataStore
    @EnvironmentObject var patientModel: PatientDataModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [Color.teal.opacity(0.12), .clear]),
                    center: .top,
                    startRadius: 10,
                    endRadius: 1000
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Games")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.primary)
                                .padding(.top, 15)
                            Text("Your plan and full game library.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        
                        RequiredGamesView()
                            .padding(.horizontal)

                        Text("All Games")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                            .padding(.top, 20)
                            .padding(.horizontal)

                        ForEach($gameDataStore.games) { $game in
                            GameCardView(game: $game)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - UPDATED: Required Games View
struct RequiredGamesView: View {
    @EnvironmentObject var gameDataStore: GameDataStore
    @EnvironmentObject var patientModel: PatientDataModel
    @State private var animateRing = false
    
    private var gameReminderIndices: [Int] {
        patientModel.patient.reminders.indices.filter { index in
            let reminder = patientModel.patient.reminders[index]
            return Calendar.current.isDateInToday(reminder.date) &&
                   reminder.tags.contains(where: { remTag.gameTagNames.contains($0.name) })
        }
        .sorted {
            !patientModel.patient.reminders[$0].isCompleted && patientModel.patient.reminders[$1].isCompleted
        }
    }
 
    private var completedGamesCount: Int {
        gameReminderIndices.filter { patientModel.patient.reminders[$0].isCompleted }.count
    }
    
    private var totalGamesCount: Int {
        gameReminderIndices.count
    }
    
    private var progress: Double {
        totalGamesCount == 0 ? 0 : min(Double(completedGamesCount) / Double(totalGamesCount), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            if gameReminderIndices.isEmpty {
                VStack(spacing: 8) {
                    
                    Text("Today's Plan")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.top, .leading], 20)
                        .padding(.bottom, 12)
                    
                    Image(systemName: "moon.stars")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No Games Required Today")
                        .font(.headline)
                    Text("Feel free to explore the library below.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .padding(.bottom, 12)
                
            } else {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Plan")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        
                        Text("\(completedGamesCount) of \(totalGamesCount) completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                    
                    Spacer()
                   
                    SmallProgressRing(
                        progress: progress,
                        accentColor: .blue
                    )
                    .frame(width: 50, height: 50)
                }
                .padding(20)
                .onAppear {
                    
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                        animateRing = true
                    }
                }
                
                 Divider()

                VStack(spacing: 0) {
                    ForEach(gameReminderIndices, id: \.self) { index in
                        let reminderBinding = $patientModel.patient.reminders[index]
                        
                        if let gameName = reminderBinding.wrappedValue.tags.first(where: { remTag.gameTagNames.contains($0.name) })?.name {
                            
                            if let gameIndex = gameDataStore.games.firstIndex(where: { $0.card.title == gameName }) {
                                let gameBinding = $gameDataStore.games[gameIndex]
                                
                                NavigationLink {
                                    GameDetailView(game: gameBinding.card.wrappedValue, tiers: gameBinding.tiers)
                                } label: {
                                    RequiredGameRow(
                                        game: gameBinding.wrappedValue,
                                        isCompleted: reminderBinding.wrappedValue.isCompleted
                                    )
                                }
                                .buttonStyle(.plain)

                                if index != gameReminderIndices.last {
                                   // Divider().padding(.leading, 56)
                                }
                            }
                        }
                    }
                }
            }
        }
        .glassEffect(in: .rect(cornerRadius: 35))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Required Game Row

struct RequiredGameRow: View {
    let game: Game
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(game.card.accentColor.opacity(0.15))
                Image(systemName: game.card.imageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(game.card.accentColor)
                    .frame(width: 22, height: 22)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(game.card.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(isCompleted ? "Completed" : "Pending")
                    .font(.caption)
                    .foregroundStyle(isCompleted ? .green : .secondary)
            }
            
             Spacer()
            
            ZStack {
                Circle()
                    .fill(isCompleted ? game.card.accentColor.opacity(0.2) : Color.clear)
                    .frame(width: 32, height: 32)
                
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        isCompleted ? .white : game.card.accentColor.opacity(0.6),
                        isCompleted ? game.card.accentColor : .clear
                    )
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}


// MARK: - GameCardView (Unchanged)

struct GameCardView: View {
    @Binding var game: Game
    
    private var lastPlayedString: String {
        guard let date = game.lastPlayedDate else { return "Not played yet" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return "Last played: \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    var body: some View {
        NavigationLink(destination: GameDetailView(game: game.card, tiers: $game.tiers)) {
            VStack(alignment: .leading, spacing: 1) {
                
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .frame(width: 70, height: 70)
                            .foregroundStyle(game.card.accentColor.opacity(0.001))
                        Image(systemName: game.card.imageName)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(game.card.accentColor)
                            .frame(width: 55, height: 55)
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    SmallProgressRing(progress: game.overallProgress, accentColor: game.card.accentColor)
                        .padding(.top, 16)
                        .padding(.trailing, 20)
                }
                .padding(.horizontal)
                .padding(.top, 6)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.card.title)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(lastPlayedString)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.top, 1)
                            .padding(.horizontal, 2)
                    }

                    Spacer()
                    
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                        Text("Play")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassEffect(.clear.tint(game.card.accentColor))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .padding(.bottom,20)
            }
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 35))
            .glassEffect(.regular.tint(game.card.accentColor.opacity(0.15)), in: .rect(cornerRadius: 35))
            .shadow(color: game.card.accentColor.opacity(0.1), radius: 8, y: 4)
            .clipShape(RoundedRectangle(cornerRadius: 35))
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper View for Progress
struct SmallProgressRing: View {
    let progress: Double?
    let accentColor: Color
    
    private var actualProgress: Double {
        progress ?? 0.0
    }
    
    private var progressPercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: actualProgress)) ?? "0%"
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.2), lineWidth: 5)
            
            Circle()
                .trim(from: 0, to: actualProgress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: actualProgress)
            
            Text(progressPercentage)
                .font(.caption.bold())
                .foregroundStyle(accentColor)
                .contentTransition(.numericText())
        }
        .frame(width: 55, height: 55)
    }
}


#Preview {
    let previewStore = GameDataStore()
    let previewPatientModel = PatientDataModel()
    
    // Add a mock game reminder for the preview
    if let gameTag = remTag.sampleTags.first(where: { remTag.gameTagNames.contains($0.name) }) {
        previewPatientModel.patient.reminders.append(
            remReminder(
                title: "Practice \(gameTag.name)",
                details: "Test reminder",
                isCompleted: false,
                date: Date(),
                tags: [gameTag]
            )
        )
    }
    
    if !previewStore.games.isEmpty {
        previewStore.games[0].tiers[0].levels[0].history.append(
            GameScore(date: Date().addingTimeInterval(-3600 * 24 * 2), score: 75)
        )
    }
    
    return ExerciseView()
        .environmentObject(previewStore)
        .environmentObject(previewPatientModel)
}
