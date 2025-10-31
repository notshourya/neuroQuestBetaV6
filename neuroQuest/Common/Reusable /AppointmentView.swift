//
//  AppointmentView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

struct AppointmentsView: View {
    @Binding var appointment: remAppointment
    var userRole: UserRole
    
    @State private var notes: String = "Ask about new medication side effects..."
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [appointment.color.opacity(0.15), .clear]),
                center: .top, startRadius: 10, endRadius: 1000
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    AppointmentHeroHeader(appointment: $appointment, userRole: userRole)
                    detailsCard
                    quickActionsCard
                    notesCard
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if userRole == .admin {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("Cancel Appointment?",
               isPresented: $isShowingDeleteConfirmation) {
            Button("Delete Appointment", role: .destructive) {
                print("Appointment Deleted")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. Are you sure you want to permanently delete this appointment?")
        }
    }

    // MARK: - Card Components
    
    private var detailsCard: some View {
        VStack(spacing: 12) {
            HStack {
                InfoRowIcon(icon: "calendar", color: .red)
                DatePicker("Date", selection: $appointment.date, displayedComponents: .date)
            }
            Divider().padding(.leading, 40)
            HStack {
                InfoRowIcon(icon: "clock.fill", color: .blue)
                DatePicker("Time", selection: $appointment.date, displayedComponents: .hourAndMinute)
            }
            Divider().padding(.leading, 40)
            HStack {
                InfoRowIcon(icon: "location.fill", color: .green)
                TextField("Location", text: $appointment.location)
            }
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: 35))
        .disabled(userRole == .patient)
    }
    
    private var quickActionsCard: some View {
        HStack(spacing: 16) {
            QuickActionButton(title: "Get Directions", icon: "arrow.triangle.turn.up.right.diamond.fill", color: appointment.color)
            QuickActionButton(title: "Call Office", icon: "phone.fill", color: appointment.color)
        }
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Questions & Notes", systemImage: "note.text")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $notes)
                .frame(height: 150)
                .scrollContentBackground(.hidden)
                .padding(10)
                .glassEffect(in: .rect(cornerRadius: 20))
                .disabled(userRole == .patient)
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 35))
    }
}

// MARK: - Subviews

struct AppointmentHeroHeader: View {
    @Binding var appointment: remAppointment
    var userRole: UserRole
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(appointment.color.gradient.opacity(0.2))
                Circle().stroke(appointment.color.gradient, lineWidth: 2)
                Image(systemName: appointment.icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(appointment.color)
            }
            .frame(width: 100, height: 100)
            
            VStack {
                TextField("Doctor Name", text: $appointment.doctorName)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                TextField("Specialty", text: $appointment.specialty)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .disabled(userRole == .patient)
        }
        .padding(.vertical)
    }
}

struct InfoRowIcon: View {
    let icon: String, color: Color
    var body: some View {
        Image(systemName: icon)
            .font(.headline)
            .foregroundColor(color)
            .frame(width: 24, alignment: .center)
    }
}

struct QuickActionButton: View {
    let title: String, icon: String, color: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2.bold())
                Text(title).font(.caption.bold())
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity, minHeight: 60)
            .padding(.vertical, 8)
        }
        .glassEffect()
    }
}

// MARK: - Preview
#Preview {
    struct AppointmentsView_Preview: View {
        @State var appointment = remAppointment(
            doctorName: "Dr. Evans",
            specialty: "Nutrition",
            date: Date(),
            icon: "carrot.fill",
            location: "123 Health St, MedCity",
            color: .orange
        )
        
        var body: some View {
            NavigationView {
                AppointmentsView(appointment: $appointment, userRole: .admin)
            }
        }
    }
    
    return AppointmentsView_Preview()
}
