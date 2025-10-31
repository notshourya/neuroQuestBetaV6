//
//  AdminHealthView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI

struct AdminHealthView: View {
    @EnvironmentObject var patientStore: PatientDataStore
    @State private var selectedDate: Date = Date()
    @State private var selectedPatientID: UUID?

    @Namespace private var transition
    private let themeColor: Color = .pink
    private var selectedPatientIndex: Int? {
        guard let selectedID = selectedPatientID else { return nil }
        return patientStore.patients.firstIndex { $0.id == selectedID }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Schedule")
                            .font(.largeTitle.bold())
                            .padding(.horizontal, 20)
                            .padding(.top, -25)
                            .padding(.bottom, -16)
                        Text("Manage Patient Schedules")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.bottom, -30)

                        CalendarHeaderView(selectedDate: $selectedDate, themeColor: themeColor)
                            .padding(.horizontal)

                        patientListSection

                        scheduleSection
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedPatientID)
                    .padding(.bottom)
                }
                .safeAreaPadding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AdminAddItemView(patients: $patientStore.patients, transition: transition) { patientID, newAppt, newReminder in
                            
                            
                            patientStore.handleSave(patientID: patientID, newAppointment: newAppt, newReminder: newReminder)
                            
            
                            if selectedPatientID == patientID, let index = selectedPatientIndex {
                                let id = patientStore.patients[index].id
                                self.selectedPatientID = nil
                                self.selectedPatientID = id
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(themeColor)
                            .frame(width: 50, height: 50)
                            .contentShape(Circle())
                    }
                    .matchedTransitionSource(id: "addItemButton", in: transition)
                }
            }
        }
    }

    // MARK: - View Components

    private var backgroundGradient: some View {
        RadialGradient(
            gradient: Gradient(colors: [themeColor.opacity(0.15), Color(.systemGroupedBackground)]),
            center: .top, startRadius: 10, endRadius: 1000
        ).ignoresSafeArea()
    }

    private var patientListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Patients")
                        .font(.system(size: 24, weight: .bold))
                    Text("Select to view schedule")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(patientStore.patients.count)")
                    .font(.title3.bold())
                    .foregroundStyle(themeColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(themeColor.opacity(0.12))
                            .overlay(
                                Circle()
                                    .strokeBorder(themeColor.opacity(0.3), lineWidth: 1.5)
                            )
                    )
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach($patientStore.patients) { $patient in
                        AdminPatientCard(
                            patient: $patient,
                            selectedDate: selectedDate,
                            isSelected: patient.id == selectedPatientID,
                            themeColor: themeColor
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                selectedPatientID = (selectedPatientID == patient.id) ? nil : patient.id
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        if let patientIndex = selectedPatientIndex {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Schedule")
                            .font(.system(size: 24, weight: .bold))
                        Text(patientStore.patients[patientIndex].name) // Use store
                            .font(.subheadline)
                            .foregroundStyle(themeColor)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                AdminScheduleView(
                    patient: $patientStore.patients[patientIndex],
                    selectedDate: $selectedDate,
                    themeColor: themeColor
                )
                .padding(20)
                .glassEffect(in: .rect(cornerRadius: 28))
                .padding(.horizontal, 20)
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.92).combined(with: .opacity),
                removal: .scale(scale: 0.96).combined(with: .opacity)
            ))
        } else {
            EmptyStateView(
                message: "Select a patient to view their schedule",
                systemImage: "hand.tap.fill"
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
}
// MARK: - Patient Card
struct AdminPatientCard: View {
    @Binding var patient: Patient
    let selectedDate: Date
    let isSelected: Bool
    let themeColor: Color

    // MARK: - Computed Properties
    private var totalTasksToday: Int {
        let appts = patient.appointments.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }.count
        let rems = patient.reminders.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }.count
        return appts + rems
    }

    private var cardGradient: LinearGradient {
        if isSelected {
            LinearGradient(
                colors: [themeColor, themeColor.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Badge
    private var taskBadge: some View {
        let badgeBackground = isSelected ? Color.white.opacity(0.25) : themeColor
        let badgeBorder = isSelected ? Color.white.opacity(0.4) : Color.clear

        return Text("\(totalTasksToday)")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(Circle().fill(badgeBackground))
            .overlay(Circle().strokeBorder(badgeBorder, lineWidth: 1.5))
            .offset(x: 40, y: -22)
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.25) : themeColor.opacity(0.1))
                        .frame(width: 40, height: 64)
                    ProfileAvatarView(
                        initials: patient.initials,
                        color: isSelected ? .white : themeColor,
                        size: 42
                    )
                }
                .overlay {
                    if totalTasksToday > 0 { taskBadge }
                }

                VStack(spacing: 2) {
                    Text(patient.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .lineLimit(1)
                    Text(patient.condition)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }
            }

            // Details button
            NavigationLink {
                PatientDetailView(patient: $patient)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                    Text("Details")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(isSelected ? .white.opacity(0.9) : themeColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 120)
        .padding(.vertical, 8)
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.15),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .shadow(
            color: isSelected ? themeColor.opacity(0.4) : Color.black.opacity(0.06),
            radius: isSelected ? 10 : 6,
            x: 0,
            y: isSelected ? 5 : 3
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
    }
}

// MARK: - Schedule View
struct AdminScheduleView: View {
    @Binding var patient: Patient
    @Binding var selectedDate: Date
    let themeColor: Color

    private var appointmentIndices: [Int] {
        patient.appointments.indices
            .filter { Calendar.current.isDate(patient.appointments[$0].date, inSameDayAs: selectedDate) }
            .sorted { patient.appointments[$0].date < patient.appointments[$1].date }
    }
    
    private var reminderIndices: [Int] {
        patient.reminders.indices
            .filter { Calendar.current.isDate(patient.reminders[$0].date, inSameDayAs: selectedDate) }
            .sorted { patient.reminders[$0].date < patient.reminders[$1].date }
    }

    var body: some View {
        VStack(spacing: 24) {
            if !appointmentIndices.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Appointments", count: appointmentIndices.count, color: themeColor)
                    ForEach(appointmentIndices, id: \.self) { index in
                        NavigationLink {
                            AppointmentsView(appointment: $patient.appointments[index], userRole: .admin)
                        } label: {
                            PatientAppointmentCard(appointment: patient.appointments[index])
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !reminderIndices.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Reminders", count: reminderIndices.count, color: .orange)
                    ForEach(reminderIndices, id: \.self) { index in
                        NavigationLink {
                            ReminderView(reminder: $patient.reminders[index], userRole: .admin)
                        } label: {
                            PatientReminderCard(reminder: $patient.reminders[index])
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if appointmentIndices.isEmpty && reminderIndices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    Text("No schedule items")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
            }
        }
    }
}

// MARK: - Patient Appointment Card
struct PatientAppointmentCard: View {
    let appointment: remAppointment

    private var appointmentGradient: LinearGradient {
        LinearGradient(
            colors: [appointment.color.opacity(0.25), appointment.color.opacity(0.08)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(appointmentGradient)
                .glassEffect(in: .rect(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(appointment.color.opacity(0.3), lineWidth: 1))
                .shadow(color: appointment.color.opacity(0.12), radius: 6, y: 3)

            VStack(spacing: 14) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text(appointment.date, style: .time)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(appointment.color.gradient, in: Capsule())
                    .shadow(color: appointment.color.opacity(0.3), radius: 4, y: 2)

                    Spacer()

                    if appointment.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider().opacity(0.3)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appointment.doctorName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        HStack(spacing: 5) {
                            Image(systemName: appointment.icon)
                                .font(.caption)
                                .foregroundStyle(appointment.color)
                            Text(appointment.specialty)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundStyle(appointment.color)
                            Text(appointment.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if appointment.origin == .admin {
                            HStack(spacing: 4) {
                                Image(systemName: "person.badge.shield.checkmark.fill")
                                    .font(.system(size: 9))
                                Text("Admin")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.regularMaterial, in: Capsule())
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Patient Reminder Card
struct PatientReminderCard: View {
    @Binding var reminder: remReminder

    private var accentColor: Color {
        reminder.isCompleted ? .green : (reminder.tags.first?.color ?? .orange)
    }

    private var tintGradient: LinearGradient {
        if reminder.isCompleted {
            return LinearGradient(colors: [.green.opacity(0.25), .green.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if reminder.tags.isEmpty {
            return LinearGradient(colors: [.orange.opacity(0.25), .orange.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if reminder.tags.count == 1 {
            let color = reminder.tags[0].color
            return LinearGradient(colors: [color.opacity(0.25), color.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            let colors = reminder.tags.map { $0.color.opacity(0.2) }
            return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tintGradient)
                .glassEffect(.clear, in: .rect(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(accentColor.opacity(0.25), lineWidth: 1))
                .shadow(color: accentColor.opacity(0.1), radius: 6, y: 3)

            HStack(spacing: 14) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        reminder.isCompleted.toggle()
                    }
                } label: {
                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            reminder.isCompleted ? .white : accentColor.opacity(0.7),
                            reminder.isCompleted ? accentColor : .clear
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Circle())

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
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

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    if !reminder.details.isEmpty {
                        Text(reminder.details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    if !reminder.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(reminder.tags) { tag in
                                    remTagPillView(tag: tag)
                                }
                            }
                        }
                        .frame(height: 28)
                    }
                }
                .opacity(reminder.isCompleted ? 0.7 : 1.0)
            }
            .padding(16)
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
            Spacer()
            Text("\(count)")
                .font(.caption.bold())
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
        }
    }
}

// MARK: - Preview
#Preview {
    TabView {
        AdminHealthView()
            .tabItem { Label("Assign", systemImage: "calendar.badge.plus") }
            .environmentObject(PatientDataStore())
    }
}


