//
//  GamesVisualData.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI
import Charts

struct TremorControlDetailView: View {
    let sessions: [GamePlaySession]
    let color: Color

    var body: some View {
        VStack(spacing: 24) {
            keyMetricsSection
            steadinessProgressionChart
            scoreVsSteadinessChart
            performanceDistributionChart
            SessionHistoryList(sessions: sessions, color: color)
        }
    }

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Motor Control Metrics")
                .font(.title2.bold())
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Average Steadiness",
                    value: String(format: "%.1f%%", avgSteadiness),
                    icon: "hand.raised.fill",
                    color: color
                )
                MetricCard(
                    title: "Improvement",
                    value: String(format: "%+.1f%%", improvement),
                    icon: improvement >= 0 ? "arrow.up.right" : "arrow.down.right",
                    color: improvement >= 0 ? .green : .orange
                )
            }
            .padding(.horizontal)
        }
    }

    private var steadinessProgressionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Steadiness Progression")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(steadinessData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Steadiness %", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Steadiness %", item.value)
                    )
                    .foregroundStyle(color.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(steadinessMovingAverage, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Avg Steadiness", item.value)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text("\(Int(val))%")
                        }
                    }
                }
            }
            .frame(height: 250)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var scoreVsSteadinessChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score vs. Steadiness")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(scoreSteadinessData, id: \.steadiness) { item in
                    PointMark(
                        x: .value("Steadiness %", item.steadiness),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(color.opacity(0.7))
                }
            }
            .chartXScale(domain: (steadinessData.map{$0.value}.min() ?? 70)...100)
            .chartYScale(domain: 0...110)
            .chartXAxisLabel("Steadiness (%)")
            .chartYAxisLabel("Score (pts)")
            .frame(height: 200)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var performanceDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            let distribution = calculateDistribution(data: steadinessData.map { $0.value })
            Chart(distribution, id: \.range) { item in
                BarMark(
                    x: .value("Range", item.range),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(8)
            }
            .chartXAxis {
                AxisMarks(values: distribution.map { $0.range }) {
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private func calculateDistribution(data: [Double]) -> [(range: String, count: Int)] {
        let ranges = [
            (0..<20, "0-20%"),
            (20..<40, "20-40%"),
            (40..<60, "40-60%"),
            (60..<80, "60-80%"),
            (80..<101, "80-100%")
        ]
        var counts = [String: Int]()
        for (range, label) in ranges {
            counts[label] = data.filter { range.contains(Int($0)) }.count
        }
        return ranges.map { (range: $0.1, count: counts[$0.1] ?? 0) }
    }
}

extension TremorControlDetailView {
    private var steadinessData: [(date: Date, value: Double)] {
        sessions.compactMap { session in
            guard let steadiness = session.steadiness else { return nil }
            return (date: session.date, value: steadiness)
        }.sorted { $0.date < $1.date }
    }
    
    private var scoreSteadinessData: [(score: Int, steadiness: Double)] {
        sessions.compactMap { session in
            guard let steadiness = session.steadiness else { return nil }
            return (score: session.score, steadiness: steadiness)
        }
    }
    
    private var steadinessMovingAverage: [(date: Date, value: Double)] {
        calculateMovingAverage(data: steadinessData)
    }
    
    private var avgSteadiness: Double {
        let values = steadinessData.map { $0.value }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private var improvement: Double {
        guard steadinessData.count > 1 else { return 0 }
        let first = steadinessData.first!.value
        let last = steadinessData.last!.value
        guard first != 0 else { return 0 }
        return ((last - first) / first) * 100
    }
}

// MARK: - Cognitive Focus Detail View
struct CognitiveFocusDetailView: View {
    let sessions: [GamePlaySession]
    let color: Color

    var body: some View {
        VStack(spacing: 24) {
            keyMetricsSection
            responseTimeProgressionChart
            scoreVsReactionTimeChart
            responseTimeDistributionChart
            SessionHistoryList(sessions: sessions, color: color)
        }
    }

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cognitive Performance Metrics")
                .font(.title2.bold())
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Avg Response Time",
                    value: String(format: "%.0f ms", avgReactionTime),
                    icon: "bolt.fill",
                    color: color
                )
                MetricCard(
                    title: "Best Time",
                    value: String(format: "%.0f ms", bestReactionTime),
                    icon: "star.fill",
                    color: .green
                )
            }
            .padding(.horizontal)
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Improvement",
                    value: String(format: "%+.1f%%", improvement),
                    icon: improvement > 0 ? "arrow.down.right" : "arrow.up.right",
                    color: improvement > 0 ? .green : .orange
                )
                MetricCard(
                    title: "Sessions",
                    value: "\(sessions.count)",
                    icon: "gamecontroller.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }

    private var responseTimeProgressionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Response Time Progression")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(reactionTimeData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Time (ms)", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Time (ms)", item.value)
                    )
                    .foregroundStyle(color.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(reactionTimeMovingAverage, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Avg Time", item.value)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text("\(Int(val)) ms")
                        }
                    }
                }
            }
            .frame(height: 250)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var scoreVsReactionTimeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score vs. Response Time")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(scoreReactionTimeData, id: \.rt) { item in
                    PointMark(
                        x: .value("Response Time (ms)", item.rt),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(color.opacity(0.7))
                }
            }
            .chartXScale(domain: (reactionTimeData.map{$0.value}.min() ?? 200)...(reactionTimeData.map{$0.value}.max() ?? 1000))
            .chartYScale(domain: 0...110)
            .chartXAxisLabel("Response Time (ms)")
            .chartYAxisLabel("Score (pts)")
            .frame(height: 200)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var responseTimeDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Response Time Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            if let stats = reactionTimeStats {
                Chart {
                    BoxMark(category: "Response Time", stats: stats, color: color)
                }
                .chartYAxisLabel("Response Time (ms)")
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 280)
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .glassEffect(in: .rect(cornerRadius: 30))
                .padding(.horizontal)
            } else {
                Text("Not enough data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 30))
                    .padding(.horizontal)
            }
        }
    }
}

extension CognitiveFocusDetailView {
    private var reactionTimeData: [(date: Date, value: Double)] {
        sessions.compactMap { session in
            guard let rt = session.averageReactionTimeMS else { return nil }
            return (date: session.date, value: Double(rt))
        }.sorted { $0.date < $1.date }
    }
    
    private var scoreReactionTimeData: [(score: Int, rt: Double)] {
        sessions.compactMap { session in
            guard let rt = session.averageReactionTimeMS else { return nil }
            return (score: session.score, rt: Double(rt))
        }
    }
    
    private var reactionTimeMovingAverage: [(date: Date, value: Double)] {
        calculateMovingAverage(data: reactionTimeData)
    }
    
    private var reactionTimeStats: BoxPlotStats? {
        calculateBoxPlotStats(data: reactionTimeData.map { $0.value })
    }
    
    private var avgReactionTime: Double {
        let values = reactionTimeData.map { $0.value }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private var bestReactionTime: Double {
        reactionTimeData.map { $0.value }.min() ?? 0
    }
    
    private var improvement: Double {
        guard reactionTimeData.count > 1 else { return 0 }
        let first = reactionTimeData.first!.value
        let last = reactionTimeData.last!.value
        guard first != 0 else { return 0 }
        return ((first - last) / first) * 100
    }
}

// MARK: - Voice Strength Detail View
struct VoiceStrengthDetailView: View {
    let sessions: [GamePlaySession]
    let color: Color
    let volumeColor: Color = .orange

    @State private var pose: Chart3DPose = .default

    var body: some View {
        VStack(spacing: 24) {
            keyMetricsSection
            correlation3DChart
            pitchProgressionChart
            volumeProgressionChart
            scoreDistributionChart
            SessionHistoryList(sessions: sessions, color: color)
        }
    }

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vocal Performance Metrics")
                .font(.title2.bold())
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Pitch Stability",
                    value: String(format: "%.1f%%", avgPitch),
                    icon: "waveform",
                    color: color
                )
                MetricCard(
                    title: "Avg Volume",
                    value: String(format: "%.1f dB", avgDecibel),
                    icon: "speaker.wave.3.fill",
                    color: volumeColor
                )
            }
            .padding(.horizontal)
        }
    }

    private var correlation3DChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance 3D Correlation")
                .font(.headline)
                .padding(.horizontal)
            
            Chart3D(validSessions) { session in
                PointMark(
                    x: .value("Pitch Stability", session.pitchStability!),
                    y: .value("Score", session.score),
                    z: .value("Volume (dB)", session.decibelLevel!)
                )
                .foregroundStyle(by: .value("Date", session.date))
            }
            .chart3DPose($pose)
            .chartXAxisLabel("Pitch Stability (%)")
            .chartYAxisLabel("Score (pts)")
            .chartZAxisLabel("Volume (dB)")
            .chartXScale(domain: 70...100, range: -0.5...0.5)
            .chartYScale(domain: 0...110, range: -0.5...0.5)
            .chartZScale(domain: 40...90, range: -0.5...0.5)
            .frame(height: 400)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var pitchProgressionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pitch Stability Progression")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(pitchData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Stability %", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Stability %", item.value)
                    )
                    .foregroundStyle(color.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(pitchMovingAverage, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Avg Stability", item.value)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text("\(Int(val))%")
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var volumeProgressionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Volume Level Progression")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(decibelData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("dB", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [volumeColor.opacity(0.3), volumeColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("dB", item.value)
                    )
                    .foregroundStyle(volumeColor.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(decibelMovingAverage, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Avg dB", item.value)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text("\(Int(val)) dB")
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var scoreDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            if let stats = scoreStats {
                Chart {
                    BoxMark(category: "Score", stats: stats, color: color)
                }
                .chartYScale(domain: 0...110)
                .chartYAxisLabel("Score (pts)")
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .glassEffect(in: .rect(cornerRadius: 30))
                .padding(.horizontal)
            } else {
                Text("Not enough data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 30))
                    .padding(.horizontal)
            }
        }
    }
}

extension VoiceStrengthDetailView {
    private var validSessions: [GamePlaySession] {
        sessions.filter { $0.pitchStability != nil && $0.decibelLevel != nil }
    }
    
    private var scoreData: [Int] {
        sessions.map { $0.score }
    }
    
    private var pitchData: [(date: Date, value: Double)] {
        validSessions.compactMap { session in
            guard let pitch = session.pitchStability else { return nil }
            return (date: session.date, value: pitch)
        }.sorted { $0.date < $1.date }
    }
    
    private var decibelData: [(date: Date, value: Double)] {
        validSessions.compactMap { session in
            guard let db = session.decibelLevel else { return nil }
            return (date: session.date, value: db)
        }.sorted { $0.date < $1.date }
    }
    
    private var pitchMovingAverage: [(date: Date, value: Double)] {
        calculateMovingAverage(data: pitchData)
    }
    
    private var decibelMovingAverage: [(date: Date, value: Double)] {
        calculateMovingAverage(data: decibelData)
    }
    
    private var scoreStats: BoxPlotStats? {
        calculateBoxPlotStats(data: scoreData.map { Double($0) })
    }
    
    private var avgPitch: Double {
        let values = pitchData.map { $0.value }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private var avgDecibel: Double {
        let values = decibelData.map { $0.value }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

// MARK: - Balance Practice Detail View
struct BalancePracticeDetailView: View {
    let sessions: [GamePlaySession]
    let color: Color

    var body: some View {
        VStack(spacing: 24) {
            keyMetricsSection
            scoreProgressionChart
            balanceScoreDistributionChart
            SessionHistoryList(sessions: sessions, color: color)
        }
    }

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Balance Performance Metrics")
                .font(.title2.bold())
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Average Score",
                    value: String(format: "%.1f", avgScore),
                    icon: "star.fill",
                    color: color
                )
                MetricCard(
                    title: "Total Sessions",
                    value: "\(sessions.count)",
                    icon: "gamecontroller.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }

    private var scoreProgressionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Progression")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(scoreData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(color.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(scoreMovingAverage, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Avg Score", item.value)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...110)
            .frame(height: 250)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var balanceScoreDistributionChart: some View {
        scoreDistributionChart
    }
}

extension BalancePracticeDetailView {
    private var scoreData: [(date: Date, score: Int)] {
        sessions.map { (date: $0.date, score: $0.score) }.sorted { $0.date < $1.date }
    }
    
    private var scoreValues: [Int] {
        sessions.map { $0.score }
    }
    
    private var scoreMovingAverage: [(date: Date, value: Double)] {
        calculateMovingAverage(data: scoreData.map { (date: $0.date, value: Double($0.score)) })
    }
    
    private var scoreStats: BoxPlotStats? {
        calculateBoxPlotStats(data: scoreValues.map { Double($0) })
    }
    
    private var avgScore: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.score }) / Double(sessions.count)
    }
    
    fileprivate var scoreDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            if let stats = scoreStats {
                Chart {
                    BoxMark(category: "Score", stats: stats, color: color)
                }
                .chartYScale(domain: 0...110)
                .chartYAxisLabel("Score (pts)")
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 20)
                .padding(.horizontal, 30)
                .glassEffect(in: .rect(cornerRadius: 30))
                .padding(.horizontal)
            } else {
                Text("Not enough data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 30))
                    .padding(.horizontal)
            }
        }
    }
}

// MARK: - Fine Motor Skills Detail View
struct FineMotorSkillsDetailView: View {
    let sessions: [GamePlaySession]
    let color: Color

    var body: some View {
        VStack(spacing: 24) {
            keyMetricsSection
            scoreProgressionChart
            scoreDistributionChart
            SessionHistoryList(sessions: sessions, color: color)
        }
    }

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fine Motor Skill Metrics")
                .font(.title2.bold())
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Average Score",
                    value: String(format: "%.1f", avgScore),
                    icon: "star.fill",
                    color: color
                )
                MetricCard(
                    title: "Total Sessions",
                    value: "\(sessions.count)",
                    icon: "gamecontroller.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }

    private var scoreProgressionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Progression")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(scoreData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(color.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(scoreMovingAverage, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Avg Score", item.value)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...110)
            .frame(height: 250)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var scoreDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            if let stats = scoreStats {
                Chart {
                    BoxMark(category: "Score", stats: stats, color: color)
                }
                .chartYScale(domain: 0...110)
                .chartYAxisLabel("Score (pts)")
                .chartXAxis(.hidden)
                .frame(height: 200)
                .padding()
                .glassEffect(in: .rect(cornerRadius: 30))
                .padding(.horizontal)
            } else {
                Text("Not enough data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 30))
                    .padding(.horizontal)
            }
        }
    }
}

extension FineMotorSkillsDetailView {
    private var scoreData: [(date: Date, score: Int)] {
        sessions.map { (date: $0.date, score: $0.score) }.sorted { $0.date < $1.date }
    }
    
    private var scoreValues: [Int] {
        sessions.map { $0.score }
    }
    
    private var scoreMovingAverage: [(date: Date, value: Double)] {
        calculateMovingAverage(data: scoreData.map { (date: $0.date, value: Double($0.score)) })
    }
    
    private var scoreStats: BoxPlotStats? {
        calculateBoxPlotStats(data: scoreValues.map { Double($0) })
    }
    
    private var avgScore: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.score }) / Double(sessions.count)
    }
}

// MARK: - Walking Rhythm Detail View
struct WalkingRhythmDetailView: View {
    let sessions: [GamePlaySession]
    let color: Color

    var body: some View {
        VStack(spacing: 24) {
            keyMetricsSection
            scoreProgressionChart
            scoreDistributionChart
            SessionHistoryList(sessions: sessions, color: color)
        }
    }

    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gait & Rhythm Metrics")
                .font(.title2.bold())
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Average Score",
                    value: String(format: "%.1f", avgScore),
                    icon: "star.fill",
                    color: color
                )
                MetricCard(
                    title: "Total Sessions",
                    value: "\(sessions.count)",
                    icon: "gamecontroller.fill",
                    color: .purple
                )
            }
            .padding(.horizontal)
        }
    }

    private var scoreProgressionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Progression")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(scoreData, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(color.opacity(0.5))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(scoreMovingAverage, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Avg Score", item.value)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...110)
            .frame(height: 250)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 30))
            .padding(.horizontal)
        }
    }

    private var scoreDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score Distribution")
                .font(.headline)
                .padding(.horizontal)
            
            if let stats = scoreStats {
                Chart {
                    BoxMark(category: "Score", stats: stats, color: color)
                }
                .chartYScale(domain: 0...110)
                .chartYAxisLabel("Score (pts)")
                .chartXAxis(.hidden)
                .frame(height: 200)
                .padding()
                .glassEffect(in: .rect(cornerRadius: 30))
                .padding(.horizontal)
            } else {
                Text("Not enough data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 30))
                    .padding(.horizontal)
            }
        }
    }
}

extension WalkingRhythmDetailView {
    private var scoreData: [(date: Date, score: Int)] {
        sessions.map { (date: $0.date, score: $0.score) }.sorted { $0.date < $1.date }
    }
    
    private var scoreValues: [Int] {
        sessions.map { $0.score }
    }
    
    private var scoreMovingAverage: [(date: Date, value: Double)] {
        calculateMovingAverage(data: scoreData.map { (date: $0.date, value: Double($0.score)) })
    }
    
    private var scoreStats: BoxPlotStats? {
        calculateBoxPlotStats(data: scoreValues.map { Double($0) })
    }
    
    private var avgScore: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.reduce(0) { $0 + $1.score }) / Double(sessions.count)
    }
}

