//
//  AdminActivityView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI
import Charts

// MARK: - Main Admin Activity Dashboard 
struct ActivityView: View {

    @EnvironmentObject var patientStore: PatientDataStore
    @State private var selectedPatientID: UUID? = nil
    @State private var timeFilter: TimeFilter = .week
    @State private var selectedGameForDetail: GameCard?

    private var selectedPatient: Patient? {
        guard let selectedID = selectedPatientID else { return nil }
        return patientStore.patients.first { $0.id == selectedID }
    }
     
    private var filteredSessions: [GamePlaySession] {
        let now = Date()
        let calendar = Calendar.current
        let baseSessions: [GamePlaySession] = selectedPatient?.sessions ?? patientStore.patients.flatMap { $0.sessions }
         
        return baseSessions.filter { session in
            switch timeFilter {
            case .day: return calendar.isDateInToday(session.date)
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return session.date > weekAgo
            case .month:
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
                return session.date > monthAgo
            }
        }
    }

    private var playedGames: [GameCard] {
        let playedTitles = Set(filteredSessions.map { $0.gameTitle })
        return GameCard.allGames.filter { playedTitles.contains($0.title) }
    }

    private var mainAccentColor: Color {
        .blue
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(spacing: 30) {
                        headerSection
                        timeFilterPicker
                         
                        if filteredSessions.isEmpty {
                            emptyStateView
                        } else {
                            adminSummaryCard
                            gameModulesList
                        }
                    }
                    .padding(.vertical)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedPatientID)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: timeFilter)
                }
            }
            .navigationDestination(item: $selectedGameForDetail) { game in
                GameDetailedAnalyticsView(
                    game: game,
                    sessions: filteredSessions.filter { $0.gameTitle == game.title },
                    timeFilter: timeFilter
                )
            }
            //.navigationTitle("Clinical Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        RadialGradient(
            gradient: Gradient(colors: [mainAccentColor.opacity(0.15), Color(.systemGroupedBackground)]),
            center: .top,
            startRadius: 10,
            endRadius: 1000
        )
        .animation(.easeInOut, value: mainAccentColor)
        .ignoresSafeArea()
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Dashboard")
                .font(.largeTitle.bold())
                .padding(.top)
            
            HStack(spacing: 8) {
                Text("Viewing:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                 
                Menu {
                    Button {
                        withAnimation { selectedPatientID = nil }
                    } label: {
                        Label("All Patients", systemImage: selectedPatientID == nil ? "checkmark.circle.fill" : "circle")
                    }
                    Divider()
                    ForEach(patientStore.patients) { patient in
                        Button {
                            withAnimation { selectedPatientID = patient.id }
                        } label: {
                            Label(patient.name, systemImage: selectedPatientID == patient.id ? "checkmark.circle.fill" : "circle")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedPatient?.name ?? "All Patients")
                            .font(.subheadline.bold())
                            .foregroundStyle(mainAccentColor)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(mainAccentColor.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var timeFilterPicker: some View {
        Picker("Filter", selection: $timeFilter) {
            ForEach(TimeFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("No Activity Found")
                .font(.title3.bold())
            Text("No activity recorded for this selection in this period.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(minHeight: 300)
        .padding()
        .glassEffect(in: .rect(cornerRadius: 30))
        .padding(.horizontal)
    }

    private var adminSummaryCard: some View {
        AdminActivitySummaryCard(
            sessions: filteredSessions,
            timeFilter: timeFilter,
            selectedPatient: selectedPatient,
            accentColor: mainAccentColor
        )
        .padding(.horizontal)
    }

    private var gameModulesList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Therapy Module Performance")
                .font(.title2.bold())
                .padding(.horizontal)

            if playedGames.isEmpty && !filteredSessions.isEmpty {
                Text("No specific games played in this period.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .glassEffect(in: .rect(cornerRadius: 20))
                    .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(playedGames) { game in
                        let gameSessions = filteredSessions.filter { $0.gameTitle == game.title }
                        Button {
                            selectedGameForDetail = game
                        } label: {
                            GameModuleRow(game: game, sessions: gameSessions)
                        }
                        .buttonStyle(.plain)
                         
                        if game.id != playedGames.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding()
                .glassEffect(in: .rect(cornerRadius: 30))
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Compatibility helpers
extension GameCard: Hashable {
    public static func == (lhs: GameCard, rhs: GameCard) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Summary Card
struct AdminActivitySummaryCard: View {
    let sessions: [GamePlaySession]
    let timeFilter: TimeFilter
    let selectedPatient: Patient?
    let accentColor: Color

    struct GameDailySummary: Identifiable {
        let id = UUID()
        let date: Date
        let gameTitle: String
        let totalDurationSeconds: Int
    }
     
    private var gameDailyData: [GameDailySummary] {
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.date) }
        var summaries: [GameDailySummary] = []
         
        for (date, sessionsOnDay) in groupedByDay {
            let groupedByGame = Dictionary(grouping: sessionsOnDay) { $0.gameTitle }
            for (gameTitle, sessionsForGame) in groupedByGame {
                summaries.append(.init(
                    date: date,
                    gameTitle: gameTitle,
                    totalDurationSeconds: sessionsForGame.reduce(0) { $0 + $1.durationInSeconds }
                ))
            }
        }
        return summaries.sorted { $0.date < $1.date }
    }

    private var totalSeconds: Int { sessions.reduce(0) { $0 + $1.durationInSeconds } }
    private var totalSessionsCount: Int { sessions.count }
    private var activePatientsCount: Int { Set(sessions.map { $0.patientId }).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Active Time")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(totalSeconds / 60) min")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
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
            .chartLegend(position: .top, alignment: .center, spacing: 10)
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
                if selectedPatient == nil {
                    StatItem(title: "Active Patients", value: "\(activePatientsCount)", color: .indigo)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(25)
        .glassEffect(in: .rect(cornerRadius: 45))
    }

    // Chart Helpers
    private var xAxisUnit: Calendar.Component {
        switch timeFilter {
        case .day: return .hour
        default: return .day
        }
    }
     
    private var strideComponent: Calendar.Component {
        switch timeFilter {
        case .day: return .hour
        default: return .day
        }
    }
     
    private var strideCount: Int {
        switch timeFilter {
        case .day: return 4
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

// MARK: - Enhanced Game Module Row
struct GameModuleRow: View {
    let game: GameCard
    let sessions: [GamePlaySession]
     
    private var avgScore: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.score }) / Double(sessions.count)
    }
     
    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + $1.durationInSeconds } / 60
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
                Text(game.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let subtitle = game.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
             
            Spacer()
             
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f pts", avgScore))
                    .font(.headline.bold())
                    .foregroundStyle(game.accentColor)
                    .lineLimit(1)
                Text("\(totalMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
             
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Game Detailed Analytics View (Router)
struct GameDetailedAnalyticsView: View {
    let game: GameCard
    let sessions: [GamePlaySession]
    let timeFilter: TimeFilter
     
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()
             
            ScrollView {
                VStack(spacing: 30) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(game.accentColor.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Image(systemName: game.imageName)
                                    .font(.largeTitle)
                                    .foregroundStyle(game.accentColor)
                            }
                             
                            VStack(alignment: .leading, spacing: 4) {
                                Text(game.title)
                                    .font(.title.bold())
                                if let subtitle = game.subtitle {
                                    Text(subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal)

                    // Router Switch
                    switch game.title {
                    case "Tremor Control":
                        TremorControlDetailView(sessions: sessions, color: game.accentColor)
                    case "Cognitive Focus":
                        CognitiveFocusDetailView(sessions: sessions, color: game.accentColor)
                    case "Voice Strength":
                        VoiceStrengthDetailView(sessions: sessions, color: game.accentColor)
                    case "Balance Practice":
                        BalancePracticeDetailView(sessions: sessions, color: game.accentColor)
                    case "Fine Motor Skills":
                        FineMotorSkillsDetailView(sessions: sessions, color: game.accentColor)
                    case "Walking Rhythm":
                        WalkingRhythmDetailView(sessions: sessions, color: game.accentColor)
                    default:
                        Text("Detailed view coming soon for \(game.title).")
                            .padding()
                            .glassEffect(in: .rect(cornerRadius: 30))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(game.accentColor)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [generateShareText()])
        }
    }
     
    private var backgroundGradient: some View {
        RadialGradient(
            gradient: Gradient(colors: [game.accentColor.opacity(0.15), Color(.systemGroupedBackground)]),
            center: .top,
            startRadius: 10,
            endRadius: 1000
        )
    }
     
    private func generateShareText() -> String {
        let avgScore = sessions.isEmpty ? 0 : Double(sessions.reduce(0) { $0 + $1.score }) / Double(sessions.count)
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationInSeconds } / 60
         
        return """
        📊 \(game.title) Progress Report
        
        Period: \(timeFilter.rawValue)
        Sessions: \(sessions.count)
        Avg Score: \(String(format: "%.1f", avgScore)) pts
        Total Time: \(totalMinutes) min
        
        Shared from Clinical Dashboard
        """
    }
}

// MARK: - ShareSheet UIViewControllerRepresentable
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
     
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
     
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Previews
#Preview {
    NavigationStack {
        ActivityView()
            .environmentObject(PatientDataStore())
    }
}
