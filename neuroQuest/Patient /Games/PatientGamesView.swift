import SwiftUI

struct ExerciseView: View {
    @EnvironmentObject var gameDataStore: GameDataStore

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
                            Text("Select an activity to begin.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
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

// MARK: - GameCardView (UPDATED)

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
    if !previewStore.games.isEmpty {
        previewStore.games[0].tiers[0].levels[0].history.append(
            GameScore(date: Date().addingTimeInterval(-3600 * 24 * 2), score: 75)
        )
    }
    
    return ExerciseView()
        .environmentObject(previewStore)
}
