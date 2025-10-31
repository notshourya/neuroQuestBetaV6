// HomeView.swift


import SwiftUI
import Charts

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject var auth: Authentication
    @EnvironmentObject var gameDataStore: GameDataStore
    @EnvironmentObject var patientModel: PatientDataModel
    
    @State private var hasAppeared = false
    @State private var isShowingProfileSheet = false


    @Namespace private var transition
    
    // MARK: - COMPUTED PROPERTIES
    
    private var sessionsToday: [GamePlaySession] {
        patientModel.patient.sessions.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    private var weeklyConsistency: [DayCompletion] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return []
        }

        let weekStart = calendar.firstWeekday == 2 ? startOfWeek : calendar.date(byAdding: .day, value: 1, to: startOfWeek)!

        var results: [DayCompletion] = []
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: i, to: weekStart) else { continue }
            let isToday = calendar.isDateInToday(date)
            let dayLabel = date.formatted(.dateTime.weekday(.abbreviated))
            let hasSession = patientModel.patient.sessions.contains { calendar.isDate($0.date, inSameDayAs: date) }

            results.append(
                DayCompletion(dayInitial: dayLabel, completed: hasSession, isToday: isToday)
            )
        }
        return results
    }

    private var suggestedGame: Game? {
        let sortedGames = gameDataStore.games.sorted {
            ($0.lastPlayedDate ?? .distantPast) < ($1.lastPlayedDate ?? .distantPast)
        }
        return sortedGames.first ?? gameDataStore.games.first
    }
    
    private var suggestedGameIndex: Int? {
        guard let suggestedGame = suggestedGame else { return nil }
        return gameDataStore.games.firstIndex(where: { $0.id == suggestedGame.id })
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [Color.accentColor.opacity(0.15), Color(.systemGroupedBackground)]),
                    center: .top, startRadius: 10, endRadius: 1000
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        HeaderView(
                            isShowingProfileSheet: $isShowingProfileSheet,
                            transition: transition
                        )
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5), value: hasAppeared)
                        HomeDashboardCard(sessionsToday: sessionsToday)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: hasAppeared)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Focus for Today").font(.title2.bold()).padding(.horizontal)
                            
                            HStack(spacing: 16) {
                                NavigationLink(destination: MindfulWellnessView()) {
                                    MindfulnessSmallCard()
                                }.buttonStyle(.plain)
                                if let game = suggestedGame, let gameIndex = suggestedGameIndex {
                                    NavigationLink(destination: GameDetailView(game: game.card, tiers: $gameDataStore.games[gameIndex].tiers)) {
                                        FocusExerciseSmallCard(game: game.card)
                                    }.buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: hasAppeared)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Weekly Consistency").font(.title2.bold()).padding(.horizontal)
                            NavigationLink(destination: PatientActivityView()) {
                                WeeklyConsistencyView(data: weeklyConsistency)
                            }.buttonStyle(.plain).padding(.horizontal)
                        }
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: hasAppeared)

                    }
                    .padding(.vertical)
                }
                .navigationBarHidden(true)
            }
            .onAppear {
                withAnimation { hasAppeared = true }
            }
            .fullScreenCover(isPresented: $isShowingProfileSheet) {
                NavigationStack {
                    PatientProfileView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    isShowingProfileSheet = false
                                }
                                .glassEffect(.regular)
                            }
                        }
                }
                .environmentObject(auth)
                .navigationTransition(.zoom(sourceID: "profileButton", in: transition))
            }
            .onChange(of: auth.isSigningOut) { _, isSigningOut in
                if isSigningOut {
                    isShowingProfileSheet = false
                }
            }
        }
    }
}

// MARK: - Component Views for Home Screen

struct HeaderView: View {
    @Binding var isShowingProfileSheet: Bool
    let transition: Namespace.ID
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome Back").font(.largeTitle.bold())
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.subheadline).foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                isShowingProfileSheet = true
            }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.secondary.opacity(0.8))
            }
            .matchedTransitionSource(id: "profileButton", in: transition)
        }
        .padding([.top, .horizontal])
    }
}

struct HomeDashboardCard: View {
    let sessionsToday: [GamePlaySession]
    @State private var animateRing = false
    
    private var totalSeconds: Int {
        sessionsToday.reduce(0) { $0 + $1.durationInSeconds }
    }
    private var exercisesCompleted: Int {
        Set(sessionsToday.map { $0.gameTitle }).count
    }
    private var bestScore: Int {
        sessionsToday.map { $0.score }.max() ?? 0
    }
    private var progress: Double {
        min(Double(totalSeconds) / 1800.0, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Label("Today's Summary", systemImage: "sparkles")
                .font(.title2.bold())
                .foregroundColor(.cyan)
            
            ZStack {
                Circle().stroke(Color.cyan.opacity(0.15), lineWidth: 15)
                Circle()
                    .trim(from: 0, to: animateRing ? progress : 0)
                    .stroke(Color.cyan.gradient, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("Active Time").font(.caption).bold().foregroundColor(.secondary)
                    Text("\(totalSeconds / 60) min")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                        .contentTransition(.numericText())
                }
            }
            .frame(height: 150)
            .padding(.vertical)
            
            HStack(spacing: 15) {
                StatPill(label: "Exercises", value: "\(exercisesCompleted)", color: .purple)
                    .glassEffect(in: .capsule)
                
                StatPill(label: "Best Score", value: "\(bestScore) pts", color: .orange)
                    .glassEffect(in: .capsule)
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 45))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animateRing = true
            }
        }
    }
}

struct MindfulnessSmallCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "wind")
                .font(.title.bold())
                .foregroundStyle(.cyan)
            
            Spacer()
            
            Text("Mindfulness")
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            Text("Breathing & Doodles")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .frame(height: 150)
        .glassEffect(in: .rect(cornerRadius: 30))
    }
}

struct FocusExerciseSmallCard: View {
    let game: GameCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: game.imageName)
                .font(.title.bold())
                .foregroundStyle(game.accentColor)
            
            Spacer()
            
            Text(game.title)
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            Text("Suggested Exercise")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .frame(height: 150)
        .glassEffect(in: .rect(cornerRadius: 30))
    }
}


struct WeeklyConsistencyView: View {
    let data: [DayCompletion]
    private var daysCompleted: Int { data.filter { $0.completed }.count }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Goal")
                        .font(.headline.bold())
                    Text("You've exercised on \(daysCompleted) of 7 days.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                Group {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: CGFloat(daysCompleted) / 7)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.0), value: daysCompleted)
                        
                        Text("\(daysCompleted)/7")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                    }
                    .frame(width: 80, height: 80)
                    .padding(.vertical, 8)
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                ForEach(data) { day in
                    VStack(spacing: 8) {
                        Text(day.dayInitial)
                            .font(.caption.bold())
                            .foregroundStyle(day.isToday ? .primary : .secondary)
                        ZStack {
                            Circle()
                                .fill(day.completed ? Color.green : Color.secondary.opacity(0.15))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(day.isToday ? .green.opacity(0.8) : .clear, lineWidth: 2)
                                )
                            if day.completed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .heavy))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 30))
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(Authentication())
        .environmentObject(GameDataStore())
        .environmentObject(PatientDataModel())
}
