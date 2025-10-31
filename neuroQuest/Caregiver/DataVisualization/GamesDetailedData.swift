//
//  GamesDetailedData.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI
import Charts

// MARK: - Charting Helpers

struct BoxPlotStats {
    let median: Double
    let q1: Double
    let q3: Double
    let lowerWhisker: Double
    let upperWhisker: Double
}

func calculateMovingAverage(data: [(date: Date, value: Double)], windowSize: Int = 7) -> [(date: Date, value: Double)] {
    guard data.count >= windowSize else { return [] }
    var result: [(date: Date, value: Double)] = []
    let sortedData = data.sorted { $0.date < $1.date }

    for i in (windowSize - 1)..<sortedData.count {
        let window = sortedData[(i - windowSize + 1)...i]
        let sum = window.reduce(0) { $0 + $1.value }
        let average = sum / Double(windowSize)
        result.append((date: sortedData[i].date, value: average))
    }
    return result
}

func calculateBoxPlotStats(data: [Double]) -> BoxPlotStats? {
    guard !data.isEmpty else { return nil }
    let sortedData = data.sorted()
    let count = sortedData.count

    let median: Double
    if count % 2 == 1 {
        median = sortedData[count / 2]
    } else {
        median = (sortedData[count / 2 - 1] + sortedData[count / 2]) / 2.0
    }

    func quartile(_ p: Double) -> Double {
        let index = Double(count - 1) * p
        let lower = Int(floor(index))
        let upper = Int(ceil(index))
        if lower == upper {
            return sortedData[lower]
        } else {
            return sortedData[lower] + (sortedData[upper] - sortedData[lower]) * (index - Double(lower))
        }
    }

    let q1 = quartile(0.25)
    let q3 = quartile(0.75)
    let iqr = q3 - q1
    let lowerBound = q1 - 1.5 * iqr
    let upperBound = q3 + 1.5 * iqr

    let lowerWhisker = sortedData.first { $0 >= lowerBound } ?? sortedData.first!
    let upperWhisker = sortedData.last { $0 <= upperBound } ?? sortedData.last!

    return BoxPlotStats(median: median, q1: q1, q3: q3, lowerWhisker: lowerWhisker, upperWhisker: upperWhisker)
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Session History List
struct SessionHistoryList: View {
    let sessions: [GamePlaySession]
    let color: Color

    private var recentSessions: [GamePlaySession] {
        sessions.sorted { $0.date > $1.date }.prefix(10).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.headline)
                .padding(.horizontal)

            if recentSessions.isEmpty {
                Text("No recent sessions in this period.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .glassEffect(in: .rect(cornerRadius: 20))
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(recentSessions) { session in
                        SessionHistoryRow(session: session, color: color)
                        if session.id != recentSessions.last?.id {
                            Divider().padding(.leading, 60)
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

// MARK: - Session History Row
struct SessionHistoryRow: View {
    let session: GamePlaySession
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(color)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(session.date, style: .date)
                    .font(.subheadline.bold())
                Text(session.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.score)")
                    .font(.headline.bold())
                    .foregroundStyle(color)
                Text("points")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.durationInSeconds / 60)")
                    .font(.headline.bold())
                    .foregroundStyle(.secondary)
                Text("min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Box Plot Mark
struct BoxMark: ChartContent {
    let category: String
    let stats: BoxPlotStats
    let color: Color

    var body: some ChartContent {
        RuleMark(
            x: .value("Category", category),
            yStart: .value("Lower Whisker", stats.lowerWhisker),
            yEnd: .value("Upper Whisker", stats.upperWhisker)
        )
        .foregroundStyle(color.opacity(0.5))
        .lineStyle(StrokeStyle(lineWidth: 1.5))

        RectangleMark(
            x: .value("Category", category),
            yStart: .value("Q1", stats.q1),
            yEnd: .value("Q3", stats.q3),
            width: 60
        )
        .cornerRadius(4)
        .foregroundStyle(color.opacity(0.3))

        RectangleMark(
            x: .value("Category", category),
            yStart: .value("Q1", stats.q1),
            yEnd: .value("Q3", stats.q3),
            width: 60
        )
        .cornerRadius(4)
        .foregroundStyle(.clear)
        .lineStyle(StrokeStyle(lineWidth: 2))
        .foregroundStyle(color)

        BarMark(
            x: .value("Category", category),
            y: .value("Median", stats.median),
            width: 50,
            height: 3
        )
        .foregroundStyle(color)
        .annotation(position: .top, spacing: 8) {
            Text(String(format: "%.1f", stats.median))
                .font(.caption.bold())
                .foregroundStyle(color)
        }

        BarMark(
            x: .value("Category", category),
            y: .value("Lower Whisker", stats.lowerWhisker),
            width: 40,
            height: 2
        )
        .foregroundStyle(color.opacity(0.7))
        
        BarMark(
            x: .value("Category", category),
            y: .value("Upper Whisker", stats.upperWhisker),
            width: 40,
            height: 2
        )
        .foregroundStyle(color.opacity(0.7))
    }
}

