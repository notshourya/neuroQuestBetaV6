//
//  PatientDetailedView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
// PatientDetailView.swift

import SwiftUI
import Charts

struct PatientDetailView: View {
    @Binding var patient: Patient
    @State private var hasAppeared = false
    
    private var adherenceColor: Color {
        switch patient.adherenceRate {
        case 0.8...: return .green
        case 0.4..<0.8: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [adherenceColor.opacity(0.15), .clear]),
                center: .top, startRadius: 10, endRadius: 1000
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeroView(patient: patient)
                    ActivitySummaryCard(patient: patient)
                    UpcomingItemsCard(patient: $patient)
                }
                .padding()
                .opacity(hasAppeared ? 1 : 0)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                hasAppeared = true
            }
        }
    }
}


// MARK: - Components

struct ProfileHeroView: View {
    let patient: Patient
    
    var body: some View {
        VStack(spacing: 12) {
            ProfileAvatarView(initials: patient.initials, color: .blue)
            
            Text(patient.name).font(.largeTitle.bold())
            
            Text("Age: \(patient.age) | \(patient.condition)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
}

struct ActivitySummaryCard: View {
    let patient: Patient
    @State private var animateRing = false
    
    var adherenceColor: Color {
        switch patient.adherenceRate {
        case 0.8...: return .green
        case 0.4..<0.8: return .yellow
        default: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Label("Activity Summary", systemImage: "flame.fill")
                .font(.title2.bold())
                .foregroundColor(adherenceColor)
            
            ZStack {
                Circle().stroke(adherenceColor.opacity(0.15), lineWidth: 15)
                Circle()
                    .trim(from: 0, to: animateRing ? patient.adherenceRate : 0)
                    .stroke(adherenceColor.gradient, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("Weekly Goal").font(.caption).bold().foregroundColor(.secondary)
                    Text(patient.adherenceRate, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(adherenceColor)
                }
            }
            .frame(height: 150)
            .padding(.vertical)
            
            HStack(spacing: 12) {
                let totalMinutes = patient.sessions.reduce(0) { $0 + $1.durationInSeconds } / 60
                
                StatPill(label: "Total Time", value: "\(totalMinutes) min", color: .cyan)
                    .glassEffect(in: .capsule)
                
                StatPill(label: "Sessions", value: "\(patient.sessions.count)", color: .blue)
                    .glassEffect(in: .capsule)
                
                StatPill(label: "Avg Score", value: "\(Int(patient.averageScore))", color: .orange)
                    .glassEffect(in: .capsule)
            }
            
            
            NavigationLink(destination: Label("Patient Report.. Screen where youll be able to see the reports when u ask from the backend", systemImage: "")) {
                Label("View Full Report", systemImage: "arrow.right")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large).buttonStyle(.bordered).tint(adherenceColor)
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 35))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animateRing = true
            }
        }
    }
}

struct UpcomingItemsCard: View {
    @Binding var patient: Patient

    private var upcomingReminderIndices: [Int] {
        patient.reminders.indices.filter { !patient.reminders[$0].isCompleted }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Label("Upcoming Items", systemImage: "list.bullet.clipboard.fill")
                .font(.title2.bold())
                .foregroundColor(.purple)
                .padding()

            VStack(spacing: 0) {
                if !patient.appointments.isEmpty {
                    ForEach($patient.appointments) { $appointment in
                        VStack(spacing: 0) {
                            Divider().padding(.leading, 60)
                            NavigationLink(destination: AppointmentsView(appointment: $appointment, userRole: .admin)) {
                                AppointmentRowView(appointment: appointment)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                if !upcomingReminderIndices.isEmpty {
                    ForEach(upcomingReminderIndices, id: \.self) { index in
                        VStack(spacing: 0) {
                            Divider().padding(.leading, 60)
                            NavigationLink(destination: ReminderView(reminder: $patient.reminders[index], userRole: .admin)) {
                                ReminderRowView(reminder: patient.reminders[index])
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .glassEffect(in: .rect(cornerRadius: 35))
        .clipShape(RoundedRectangle(cornerRadius: 35))
    }
}

// MARK: - Row Views

struct ReminderRowView: View {
    let reminder: remReminder
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: reminder.tags.first?.icon ?? "bell.fill")
                .font(.headline.bold())
                .foregroundColor(reminder.tags.first?.color ?? .gray)
                .frame(width: 44, height: 44)
                .background((reminder.tags.first?.color ?? .gray).opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title).bold()
                
                if !reminder.details.isEmpty {
                    Text(reminder.details).font(.caption).foregroundColor(.secondary)
                }

                if reminder.origin == .admin {
                    Label("From your Admin", systemImage: "person.badge.shield.checkmark.fill")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            Spacer()
            if reminder.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green).font(.title2)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
    }
}

struct AppointmentRowView: View {
    let appointment: remAppointment
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: appointment.icon)
                .font(.headline.bold())
                .foregroundColor(appointment.color)
                .frame(width: 44, height: 44)
                .background(appointment.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.doctorName).bold()
                Text(appointment.specialty).font(.caption).foregroundColor(.secondary)

                if appointment.origin == .admin {
                    Label("Scheduled by Admin", systemImage: "person.badge.shield.checkmark.fill")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            Spacer()
            Text(appointment.date, style: .date)
                .font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

private struct PatientDetailView_PreviewWrapper: View {
    @State var patient = Patient.sampleData.first!
    
    var body: some View {
        PatientDetailView(patient: $patient)
    }
}

#Preview {
    NavigationView {
        PatientDetailView_PreviewWrapper()
    }
}

