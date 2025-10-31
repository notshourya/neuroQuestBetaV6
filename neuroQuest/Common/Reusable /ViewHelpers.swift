//
//  ViewHelpers.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

// MARK: - Reusable Calendar Header
struct CalendarHeaderView: View {
    @Binding var selectedDate: Date
    var themeColor: Color = .blue
    
    private let calendar = Calendar.current
    @State private var scrollPosition: Date?
    
    
    private var weeks: [[Date]] {
        let today = Date()
        var allWeeks: [[Date]] = []
        
        
        for weekOffset in -1...1 {
            if let weekStart = getMonday(for: today, weekOffset: weekOffset) {
                let week = (0..<7).compactMap {
                    calendar.date(byAdding: .day, value: $0, to: weekStart)
                }
                allWeeks.append(week)
            }
        }
        
        return allWeeks
    }
    
    
    private var currentWeekFirstDay: Date? {
        weeks[safe: 1]?.first
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(weeks, id: \.self) { week in
                    if let firstDay = week.first {
                        WeekView(
                            dates: week,
                            selectedDate: $selectedDate,
                            themeColor: themeColor
                        )
                        .containerRelativeFrame(.horizontal)
                        .id(firstDay)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollPosition)
      
        .sensoryFeedback(.selection, trigger: scrollPosition)
        .defaultScrollAnchor(.center)
        .onAppear {
            if scrollPosition == nil {
            
             
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    scrollPosition = currentWeekFirstDay
                }
            }
        }
    }
    
    private func getMonday(for date: Date, weekOffset: Int) -> Date? {
        guard let targetWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: date) else {
            return nil
        }
        
        let weekday = calendar.component(.weekday, from: targetWeek)
        let daysFromMonday = (weekday == 1) ? -6 : -(weekday - 2)
        
        return calendar.date(byAdding: .day, value: daysFromMonday, to: targetWeek)
    }
}



struct WeekView: View {
    let dates: [Date]
    @Binding var selectedDate: Date
    var themeColor: Color
    
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(dates, id: \.self) { date in
                VStack(spacing: 4) {
                    Text(dayName(for: date))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(dayNumber(for: date))
                        .font(.title3)
                        .fontWeight(calendar.isDateInToday(date) ? .bold : .regular)
                        .foregroundStyle(
                            calendar.isDate(date, inSameDayAs: selectedDate)
                            ? .white
                            : calendar.isDateInToday(date) ? themeColor : .primary
                        )
                        .frame(width: 45, height: 45)
                        .background {
                            if calendar.isDate(date, inSameDayAs: selectedDate) {
                                Circle()
                                    .glassEffect(.clear.tint(themeColor), in: .circle)
                                    .opacity(0.8)
                            } else if calendar.isDateInToday(date) {
                                Circle()
                                    .stroke(themeColor, lineWidth: 2)
                                    .glassEffect(in: .circle)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

fileprivate struct DatePill: View {
    let date: Date
    let isSelected: Bool
    let themeColor: Color
    
    var body: some View {
        VStack {
            Text(date.formatted(.dateTime.weekday(.narrow)))
                .font(.caption).fontWeight(.medium).foregroundStyle(.secondary)
            Text(date.formatted(.dateTime.day()))
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 40, height: 40)
                .background {
                    if isSelected {
                        Circle()
                            .glassEffect(.regular.tint(themeColor), in: .circle)
                          
                    }
                }
        }
    }
}


// MARK: - Reusable Tag Filter
struct TagFilterView: View {
    @Binding var selectedTag: remTag?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                TagPill(icon: "list.bullet", color: .accentColor, isSelected: selectedTag == nil)
                    .onTapGesture { withAnimation(.spring) { selectedTag = nil } }

                ForEach(remTag.sampleTags) { tag in
                    TagPill(icon: tag.icon, color: tag.color, isSelected: selectedTag?.id == tag.id)
                        .onTapGesture {
                            withAnimation(.spring) {
                                selectedTag = (selectedTag?.id == tag.id) ? nil : tag
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}


fileprivate struct TagPill: View {
    let icon: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        Image(systemName: icon)
            .font(.headline.weight(.medium))
            .padding()
            .frame(width: 45, height: 45)
            .foregroundStyle(isSelected ? .white : color)
            .glassEffect(
                .regular.tint(isSelected ? color.opacity(0.8) : Color(.secondarySystemGroupedBackground)),
                in: .circle
            )
            .overlay(
                Circle()
                    .strokeBorder(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
    }
}

// MARK: - Reusable Empty State

struct EmptyStateView: View {
    let message: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .glassEffect(in: .rect(cornerRadius: 40))
    }
}

// MARK:
struct DashboardStatPill: View {
    let label: String
    let value: String
    let color: Color
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.callout)
                .foregroundStyle(color)
                .padding(8)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .glassEffect(in: .capsule)
    }
}




// MARK: - Reusable TagPillView
struct remTagPillView: View {
    let tag: remTag
    var isRemovable: Bool = false
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: tag.icon)
                .font(.caption2)
                .fontWeight(.bold)
            Text(tag.name)
                .fontWeight(.bold)

            if isRemovable {
                Button(action: { onRemove?() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .padding(0)
                .buttonStyle(.plain)
            }
        }
        .font(.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
//        .background(
//            Capsule()
//                .fill(tag.color.opacity(0.9))
//        )
        .glassEffect(.regular.tint(tag.color.opacity(0.9)), in: .capsule)
        .overlay(
            Capsule()
                .strokeBorder(tag.color.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: tag.color.opacity(0.4), radius: 4, y: 2)
    }
}

// MARK: - WrappingHStack for Tags
// (This struct is unchanged)
struct TagWrappingHStack: Layout {
    private var horizontalSpacing: CGFloat
    private var verticalSpacing: CGFloat

    init(alignment: HorizontalAlignment = .leading, horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        var rows: [[LayoutSubviews.Element]] = []
        var currentRow: [LayoutSubviews.Element] = []
        var currentRowWidth: CGFloat = 0
        let availableWidth = proposal.width ?? .infinity

        for view in subviews {
            let viewWidth = view.sizeThatFits(.unspecified).width
            if currentRowWidth + viewWidth + (currentRow.isEmpty ? 0 : horizontalSpacing) > availableWidth {
                 if !currentRow.isEmpty { rows.append(currentRow) }
                 currentRow = [view]
                 currentRowWidth = viewWidth
             } else {
                currentRow.append(view)
                currentRowWidth += viewWidth + (currentRow.count > 1 ? horizontalSpacing : 0)
            }
        }
        if !currentRow.isEmpty { rows.append(currentRow) }

        let totalHeight = CGFloat(rows.count) * height + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        return CGSize(width: proposal.width ?? 0, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        var x = bounds.minX
        var y = bounds.minY

        for view in subviews {
            let viewWidth = view.sizeThatFits(.unspecified).width
            if x + viewWidth > bounds.maxX {
                x = bounds.minX
                y += height + verticalSpacing
            }
            view.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
            x += viewWidth + horizontalSpacing
        }
    }
}

struct StatPill: View {
    let label: String, value: String, color: Color
    var body: some View {
        VStack {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2).fontWeight(.semibold).foregroundColor(color).contentTransition(.numericText())
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}

struct FormInputViewModifier: ViewModifier {
    var minHeight: CGFloat = 44
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .topLeading) // Make content fill width
            .padding()
            .frame(minHeight: minHeight, alignment: .topLeading)
            .contentShape(Rectangle()) // Make entire area clickable
            .glassEffect(in: .rect(cornerRadius: 25))
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(
                 RoundedRectangle(cornerRadius: 25, style: .continuous)
                     .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2.bold())
            }
            Spacer()
            Image(systemName: systemImage)
                .font(.title)
                .foregroundColor(color)
        }
        .padding()
    }
}
// Extension is unchanged
extension View {
    func formInputStyle(minHeight: CGFloat = 44) -> some View {
        self.modifier(FormInputViewModifier(minHeight: minHeight))
    }
}

struct LevelStatCardView: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
     
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2.bold())
                    .contentTransition(.numericText())
            }
            Spacer()
            Image(systemName: systemImage)
                .font(.title)
                .foregroundColor(color)
        }
        .padding()
    }
}

// --- I've also moved your other helper views here ---

struct LevelStatPill: View {
    let label: String
    let value: String
    let color: Color
    let systemImage: String
     
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.callout)
                .foregroundStyle(color)
                .padding(8)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .glassEffect(in: .capsule)
    }
}

struct ObjectiveRow: View {
    let text: LocalizedStringKey
    let isComplete: Bool
    let color: Color
    var systemImage: String? = nil
     
    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: systemImage ?? (isComplete ? "checkmark.circle.fill" : "circle"))
                .foregroundColor(isComplete ? color : .secondary)
                .font(.body.weight(.medium))
        }
        .font(.callout)
        .foregroundStyle(isComplete ? .secondary : .primary)
    }
}

struct LevelHeaderView: View {
    let level: Level
     
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("Level \(level.id)")
                .font(.largeTitle.bold())
            Text(level.status == .completed ? "Completed" : "Ready to Play")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding([.top])
    }
}

struct ScoreProgressView: View {
    let score: Int
    let accentColor: Color
    @State private var animatedProgress: CGFloat = 0.0
     
    var body: some View {
        ZStack {
            Circle().stroke(lineWidth: 18.0).opacity(0.1).foregroundColor(accentColor)
             
            Circle()
                .trim(from: 0.0, to: animatedProgress)
                .stroke(style: StrokeStyle(lineWidth: 18.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(accentColor)
                .rotationEffect(Angle(degrees: 270.0))
             
            VStack {
                Text("Best Score")
                    .font(.caption.bold()).foregroundColor(.secondary)
                Text("\(score)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: 180, height: 180)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animatedProgress = CGFloat(score) / 100.0
            }
        }
        .onChange(of: score) { _, newValue in
             withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = CGFloat(newValue) / 100.0
            }
        }
    }
}

// --- ViewModifier for Staggered Animations ---
struct StaggeredFadeInModifier: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func animateOnAppear(delay: Double) -> some View {
        self.modifier(StaggeredFadeInModifier(delay: delay))
    }
}

