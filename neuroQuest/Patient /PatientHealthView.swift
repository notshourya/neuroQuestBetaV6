//
//  PatientHealthView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI

struct PatientHealthView: View {
    @EnvironmentObject var gameDataStore: GameDataStore
    @EnvironmentObject var auth: Authentication
    
    @EnvironmentObject var patientModel: PatientDataModel
    
    @State private var selectedDate: Date = Date()
    @State private var selectedTag: remTag? = nil
    
    private let themeColor: Color = .blue

    private var appointmentIndicesForSelectedDate: [Int] {
        patientModel.patient.appointments.indices
            .filter { Calendar.current.isDate(patientModel.patient.appointments[$0].date, inSameDayAs: selectedDate) }
            .sorted { patientModel.patient.appointments[$0].date < patientModel.patient.appointments[$1].date }
    }
    
    private var reminderIndicesForSelectedDate: [Int] {
        let dailyReminders = patientModel.patient.reminders.indices
            .filter { Calendar.current.isDate(patientModel.patient.reminders[$0].date, inSameDayAs: selectedDate) }
        
        guard let tag = selectedTag else {
            return dailyReminders.sorted { patientModel.patient.reminders[$0].date < patientModel.patient.reminders[$1].date }
        }
        
        return dailyReminders
            .filter { patientModel.patient.reminders[$0].tags.contains(where: { $0.id == tag.id }) }
            .sorted { patientModel.patient.reminders[$0].date < patientModel.patient.reminders[$1].date }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [themeColor.opacity(0.15), Color(.systemGroupedBackground)]),
                center: .top,
                startRadius: 10,
                endRadius: 1000
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    headerView
                    
                    TodayProgressDashboard(
                        appointments: appointmentIndicesForSelectedDate.map { patientModel.patient.appointments[$0] },
                        reminders: reminderIndicesForSelectedDate.map { patientModel.patient.reminders[$0] },
                        themeColor: themeColor
                    )
                    .padding(.horizontal)
                    
                    CalendarHeaderView(selectedDate: $selectedDate, themeColor: themeColor)
                        .padding(.horizontal)

                    remindersSection
                    appointmentsSection
                }
                .padding(.vertical)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Components
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Daily Plan")
                    .font(.largeTitle.bold())
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding([.top, .horizontal])
    }
    
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminders")
                .font(.title2.bold())
                .padding(.horizontal)
            
            TagFilterView(selectedTag: $selectedTag)
            
            if reminderIndicesForSelectedDate.isEmpty {
                let message = selectedTag == nil
                    ? "You have no reminders for today."
                    : "No reminders with this tag."
                EmptyStateView(message: message, systemImage: "bell.badge.fill")
                    .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(reminderIndicesForSelectedDate, id: \.self) { index in
                        PatientReminderRowView(reminder: $patientModel.patient.reminders[index])
                            .environmentObject(gameDataStore)
                            .environmentObject(auth)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appointments")
                .font(.title2.bold())
                .padding(.horizontal)
            
            if appointmentIndicesForSelectedDate.isEmpty {
                EmptyStateView(
                    message: "You have no appointments scheduled for today.",
                    systemImage: "calendar.badge.exclamationmark"
                )
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(appointmentIndicesForSelectedDate, id: \.self) { index in
                        NavigationLink(destination: AppointmentsView(appointment: $patientModel.patient.appointments[index], userRole: .patient)) {
                            PatientAppointmentRowView(appointment: patientModel.patient.appointments[index])
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Dashboard Card
struct TodayProgressDashboard: View {
    let appointments: [remAppointment]
    let reminders: [remReminder]
    let themeColor: Color
    @State private var animateRing = false

    private var completedCount: Int {
        appointments.filter { $0.isCompleted }.count + reminders.filter { $0.isCompleted }.count
    }
    
    private var totalCount: Int {
        appointments.count + reminders.count
    }
    
    private var progress: Double {
        totalCount == 0 ? 0 : min(Double(completedCount) / Double(totalCount), 1.0)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle().stroke(themeColor.opacity(0.15), lineWidth: 15)
                Circle()
                    .trim(from: 0, to: animateRing ? progress : 0)
                    .stroke(themeColor.gradient, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("Tasks Completed")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("\(completedCount)/\(totalCount)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(themeColor)
                        .contentTransition(.numericText())
                }
            }
            .frame(height: 150)
            .padding(.vertical)
            
            HStack(spacing: 12) {
                DashboardStatPill(
                    label: "Appointments",
                    value: "\(appointments.count)",
                    color: themeColor,
                    systemImage: "calendar"
                )
                
                DashboardStatPill(
                    label: "Reminders",
                    value: "\(reminders.count)",
                    color: .orange,
                    systemImage: "bell.fill"
                )
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

// MARK: - Patient Appointment Row
struct PatientAppointmentRowView: View {
    let appointment: remAppointment
    
    private var appointmentGradient: LinearGradient {
        LinearGradient(
            colors: [
                appointment.color.opacity(0.25),
                appointment.color.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(appointmentGradient)
                .glassEffect(in: .rect(cornerRadius: 35))
                .overlay(
                    RoundedRectangle(cornerRadius: 35)
                        .strokeBorder(appointment.color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: appointment.color.opacity(0.15), radius: 8, y: 4)
            
            VStack(spacing: 18) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                        
                        Text(appointment.date, style: .time)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(appointment.color.gradient)
                    )
                    .shadow(color: appointment.color.opacity(0.4), radius: 5, y: 2)
                    .glassEffect()
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider().opacity(0.4)
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appointment.doctorName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "stethoscope")
                                .font(.subheadline)
                                .foregroundStyle(appointment.color)
                            
                            Text(appointment.specialty)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.subheadline)
                                .foregroundStyle(appointment.color)
                            
                            Text(appointment.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if appointment.origin == .admin {
                            HStack(spacing: 6) {
                                Image(systemName: "person.badge.shield.checkmark.fill")
                                    .font(.caption2)
                                Text("Admin Scheduled")
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Reminder Row View
struct PatientReminderRowView: View {
    @Binding var reminder: remReminder
    
    @EnvironmentObject var gameDataStore: GameDataStore
    
    @EnvironmentObject var auth: Authentication
    
    private var accentColor: Color {
        reminder.isCompleted ? .green : (reminder.tags.first?.color ?? .orange)
    }
    
    private var tintGradient: LinearGradient {
        if reminder.isCompleted {
            return LinearGradient(colors: [.green.opacity(0.3), .green.opacity(0.1)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if reminder.tags.isEmpty {
            return LinearGradient(colors: [.orange.opacity(0.3), .orange.opacity(0.1)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if reminder.tags.count == 1 {
            let color = reminder.tags[0].color
            return LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            let colors = reminder.tags.map { $0.color.opacity(0.25) }
            return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        NavigationLink(destination: ReminderView(reminder: $reminder, userRole: .patient)
            .environmentObject(gameDataStore)
            .environmentObject(auth)
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: 35, style: .continuous)
                    .fill(tintGradient)
                    .glassEffect(.clear, in: .rect(cornerRadius: 35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 35, style: .continuous)
                            .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: accentColor.opacity(0.1), radius: 8, y: 4)
                
                HStack(spacing: 15) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            reminder.isCompleted.toggle()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(
                                    reminder.isCompleted ? .white : accentColor.opacity(0.6),
                                    reminder.isCompleted ? accentColor : .clear
                                )
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 8) {
                        
                        HStack(alignment: .top) {
                            Text(reminder.title)
                                .font(.headline)
                                .strikethrough(reminder.isCompleted, color: .secondary)
                                .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                            
                            Spacer()

                            Text(reminder.date, style: .time)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(accentColor.opacity(0.15), in: Capsule())
                                .glassEffect()
                                .padding(.trailing, -20)
                            
                        }
                        
                        if !reminder.details.isEmpty {
                            Text(reminder.details)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if !reminder.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(reminder.tags) { tag in
                                        remTagPillView(tag: tag)
                                    }
                                }
                            }
                            .frame(height: 28)
                        }
                    }
                    .opacity(reminder.isCompleted ? 0.7 : 1.0)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PatientHealthView()
        .environmentObject(GameDataStore())
        .environmentObject(Authentication())
        .environmentObject(PatientDataModel())
}
