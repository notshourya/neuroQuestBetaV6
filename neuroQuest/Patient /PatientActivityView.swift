//
//  PatientActivityView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI
import Charts

struct PatientActivityView: View {
    var sessions: [GamePlaySession] = GamePlaySession.generateMockData(for: GameCard.allGames, count: 50)
    @State private var timeFilter: TimeFilter = .week
    @State private var selectedGame: String? = nil 

    private var timeFilteredSessions: [GamePlaySession] {
        let now = Date()
        let calendar = Calendar.current

        return sessions.filter { session in
            switch timeFilter {
            case .day: return calendar.isDateInToday(session.date)
            case .week:
                guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return session.date > oneWeekAgo
            case .month:
                guard let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
                return session.date > oneMonthAgo
            }
        }
    }
    
    private var filteredSessions: [GamePlaySession] {
        guard let selectedGame = selectedGame else {
            return timeFilteredSessions
        }
        return timeFilteredSessions.filter { $0.gameTitle == selectedGame }
    }

    private var totalSeconds: Int {
        filteredSessions.reduce(0) { $0 + $1.durationInSeconds }
    }
    private var totalSessionsCount: Int {
        filteredSessions.count
    }
    private var uniqueGamesPlayed: Int {
        Set(filteredSessions.map { $0.gameTitle }).count
    }
    
    private var mainAccentColor: Color {
        guard let gameName = selectedGame else {
            return .accentColor
        }
        return GameCard.allGames.first { $0.title == gameName }?.accentColor ?? .accentColor
    }

    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [mainAccentColor.opacity(0.15), Color(.systemGroupedBackground)]),
                center: .top, startRadius: 10, endRadius: 1000
            )
            .animation(.easeInOut, value: mainAccentColor)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Activity").font(.largeTitle.bold())
                        Text("See your progress over time.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    Picker("Filter", selection: $timeFilter) {
                        ForEach(TimeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    GameFilterView(
                        selectedGame: $selectedGame,
                        allGames: GameCard.allGames
                    )
                    
                    if filteredSessions.isEmpty {
                        emptyStateView
                    } else {
                        PatientActivitySummaryCard(
                            sessions: filteredSessions,
                            timeFilter: timeFilter,
                            selectedGame: selectedGame,
                            totalSeconds: totalSeconds,
                            totalSessionsCount: totalSessionsCount,
                            uniqueGamesPlayed: uniqueGamesPlayed
                        )
                        
                        RecentSessionsListView(sessions: filteredSessions)
                    }
                }
                .padding(.vertical)
            }
        }
        .onChange(of: timeFilter) {
            withAnimation {
                selectedGame = nil
            }
        }
    }

    private var emptyStateView: some View {
         VStack(spacing: 12) {
             Image(systemName: "chart.bar.xaxis").font(.system(size: 50)).foregroundStyle(.secondary)
             Text("No Activity Recorded").font(.title3.bold())
             Text("Play some games to see your progress here.")
                 .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
         }
         .frame(minHeight: 300)
         .padding()
         .glassEffect(in: .rect(cornerRadius: 30))
         .padding()
    }
}

// MARK: - Subviews for PatientActivityView

// MARK: - GameFilterView
struct GameFilterView: View {
    @Binding var selectedGame: String?
    let allGames: [GameCard]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button("All") {
                    withAnimation { selectedGame = nil }
                }
                .buttonStyle(GameFilterPillStyle(
                    isSelected: selectedGame == nil,
                    color: .accentColor
                ))
                
                ForEach(allGames) { game in
                    Button(game.title) {
                        withAnimation { selectedGame = game.title }
                    }
                    .buttonStyle(GameFilterPillStyle(
                        isSelected: selectedGame == game.title,
                        color: game.accentColor
                    ))
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
    }
}

// MARK: - GameFilterPillStyle
struct GameFilterPillStyle: ButtonStyle {
    let isSelected: Bool
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : color)
            .glassEffect(
                isSelected ? .regular.tint(color) : .regular.tint(color.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(isSelected ? 0 : 0.2), lineWidth: 1)
            )
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}


// MARK: - ActivitySummaryCard
struct PatientActivitySummaryCard: View {
    let sessions: [GamePlaySession]
    let timeFilter: TimeFilter
    let selectedGame: String?
    let totalSeconds: Int
    let totalSessionsCount: Int
    let uniqueGamesPlayed: Int
    
    struct GameDailySummary: Identifiable {
        let id = UUID()
        let date: Date
        let gameTitle: String
        let totalDurationSeconds: Int
    }

    private var gameDailyData: [GameDailySummary] {
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: sessions) { session -> Date in
            calendar.startOfDay(for: session.date)
        }
        
        var summaries: [GameDailySummary] = []
        
        for (date, sessionsOnDay) in groupedByDay {
            let groupedByGame = Dictionary(grouping: sessionsOnDay) { $0.gameTitle }
            
            for (gameTitle, sessionsForGame) in groupedByGame {
                let totalDuration = sessionsForGame.reduce(0) { $0 + $1.durationInSeconds }
                summaries.append(GameDailySummary(
                    date: date,
                    gameTitle: gameTitle,
                    totalDurationSeconds: totalDuration
                ))
            }
        }
        return summaries.sorted { $0.date < $1.date }
    }

    private var xAxisUnit: Calendar.Component {
        switch timeFilter {
        case .day: return .hour
        case .week: return .day
        case .month: return .day
        }
    }
    
    private var mainAccentColor: Color {
        guard let gameName = selectedGame else {
            return .cyan
        }
        return GameCard.allGames.first { $0.title == gameName }?.accentColor ?? .cyan
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Active Time")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(totalSeconds / 60) min")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(mainAccentColor)
                    .contentTransition(.numericText())
            }
            
            Chart(gameDailyData) { gameSummary in
                BarMark(
                    x: .value("Date", gameSummary.date, unit: xAxisUnit),
                    y: .value("Minutes", Double(gameSummary.totalDurationSeconds) / 60.0)
                )
                .foregroundStyle(by: .value("Game", gameSummary.gameTitle))
                .cornerRadius(6)
            }
            .chartForegroundStyleScale(
                domain: GameCard.allGames.map { $0.title },
                range: GameCard.allGames.map { $0.accentColor }
            )
            .chartLegend(position: .top, alignment: .center)
            .chartXAxis {
                AxisMarks(values: .stride(by: strideComponent, count: strideCount)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let dateValue = value.as(Date.self) {
                            Text(dateValue, format: xAxisLabelFormat)
                        }
                    }
                }
            }
            .frame(height: 180)
            
            Divider()
            
            HStack(spacing: 16) {
                StatItem(title: "Sessions", value: "\(totalSessionsCount)", color: .indigo)
                Spacer()
                if selectedGame == nil {
                    StatItem(title: "Games Played", value: "\(uniqueGamesPlayed)", color: .indigo)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding(25)
        .glassEffect(in: .rect(cornerRadius: 45))
        .padding(.horizontal)
    }
    
    private var strideComponent: Calendar.Component {
         switch timeFilter {
         case .day: return .hour
         case .week: return .day
         case .month: return .day
         }
    }

    private var strideCount: Int {
         switch timeFilter {
         case .day: return 1
         case .week: return 1
         case .month: return 7
         }
    }

    private var xAxisLabelFormat: Date.FormatStyle {
        switch timeFilter {
        case .day: return .dateTime.hour(.defaultDigits(amPM: .narrow))
        case .week: return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.month(.abbreviated).day()
        }
    }
}

// MARK: - Helper for Secondary Stats
struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
                .contentTransition(.numericText())
        }
    }
}


// MARK: - UPDATED: Recent Sessions List (List-in-a-Card)
struct RecentSessionsListView: View {
    let sessions: [GamePlaySession]
    
    private var recentSessions: [GamePlaySession] {
        Array(sessions.sorted(by: { $0.date > $1.date }).prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.title2.bold())
                .padding(.horizontal)

            if recentSessions.isEmpty {
                Text("No recent sessions to display.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 30))
                    .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(recentSessions) { session in
                        NavigationLink(destination: Text("Session Detail View for \(session.id) (Stub)")) {
                            SessionRowView(session: session)
                        }
                        .buttonStyle(.plain)

                        if session.id != recentSessions.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 45))
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - NEW: SessionRowView (Replaces SessionCardView)
struct SessionRowView: View {
    let session: GamePlaySession
    
    private var game: GameCard {
        GameCard.allGames.first { $0.title == session.gameTitle } ?? GameCard.allGames[0]
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(game.accentColor.opacity(0.15))
                Image(systemName: game.imageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(game.accentColor)
                    .frame(width: 22, height: 22)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.gameTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(session.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.score) pts")
                    .font(.headline.bold())
                    .foregroundStyle(game.accentColor)
                    .lineLimit(1)
                Text("\(session.durationInSeconds / 60) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
    }
}


// MARK: - Preview
#Preview {
    NavigationStack {
        PatientActivityView()
    }
}
