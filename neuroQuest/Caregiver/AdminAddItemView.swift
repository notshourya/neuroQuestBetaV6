//
//  AdminAddItemView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

private enum ItemType: String, CaseIterable {
    case reminder = "Reminder"
    case appointment = "Appointment"
}

// MARK: - Add Item View 
struct AdminAddItemView: View {
    @Binding var patients: [Patient]
    let transition: Namespace.ID
    var onSave: (_ patientID: UUID, _ newAppointment: remAppointment?, _ newReminder: remReminder?) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedItemType: ItemType = .reminder
    @State private var selectedPatientID: UUID?
    @State private var title: String = ""
    @State private var details: String = ""
    @State private var date = Date()
    @State private var doctorName: String = ""
    @State private var specialty: String = ""
    @State private var location: String = ""
    @State private var selectedTags: [remTag] = []
    @State private var previewReminder: remReminder = .empty()
    
    private var isFormValid: Bool {
        guard selectedPatientID != nil else { return false }
        if selectedItemType == .appointment {
            return !doctorName.isEmpty && !specialty.isEmpty
        } else {
            return !title.isEmpty
        }
    }
    
    private let themeColor: Color = .pink
    
    // MARK: - Body
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [themeColor.opacity(0.15), Color(.systemGroupedBackground)]),
                center: .top, startRadius: 10, endRadius: 1000
            ).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    selectionCard
                    detailsCard
                        .animation(.default, value: selectedItemType)
                    dateCard
                    
                    previewCard
                        .animation(.default, value: selectedItemType)
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(selectedItemType == .appointment ? "New Appointment" : "New Reminder")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: saveItem)
                    .disabled(!isFormValid)
            }
        }
        .tint(themeColor)
        .onChange(of: title) { previewReminder.title = title.isEmpty ? "Reminder Title" : title }
        .onChange(of: details) { previewReminder.details = details }
        .onChange(of: date) { previewReminder.date = date }
        .onChange(of: selectedTags) { previewReminder.tags = selectedTags }
    }
    
    // MARK: - Card Subviews
    
    private var selectionCard: some View {
        VStack(spacing: 20) {
            Picker("Item Type", selection: $selectedItemType.animation(.spring())) {
                ForEach(ItemType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            
            Divider()
            
            HStack {
                Label("Assign to Patient", systemImage: "person.fill")
                    .font(.headline).foregroundStyle(.secondary)
                Spacer()
                Picker("Select Patient", selection: $selectedPatientID) {
                    Text("Select...").tag(nil as UUID?)
                    ForEach(patients) { Text($0.name).tag($0.id as UUID?) }
                }
                .pickerStyle(.menu)
                .tint(themeColor)
            }
        }
        .padding(25)
        .glassEffect(in: .rect(cornerRadius: 35))
    }
    
    @ViewBuilder
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if selectedItemType == .appointment {
                appointmentForm
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    reminderForm
                    tagSelectorForm
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .padding(25)
        .glassEffect(in: .rect(cornerRadius: 35))
    }
    
    private var dateCard: some View {
        DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(.graphical)
            .padding()
            .glassEffect(in: .rect(cornerRadius: 35))
    }
    
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                selectedItemType == .appointment ? "Appointment Preview" : "Reminder Preview",
                systemImage: "eye.fill"
            )
            .font(.headline).foregroundStyle(.secondary)
            
            Divider()
            
            if selectedItemType == .appointment {
                let previewAppt = remAppointment(
                    doctorName: doctorName.isEmpty ? "Doctor's Name" : doctorName,
                    specialty: specialty.isEmpty ? "Specialty" : specialty,
                    date: date,
                    icon: "cross.case.fill",
                    location: location.isEmpty ? "Location" : location,
                    color: .blue,
                    origin: .admin
                )
                
                PatientAppointmentRowView(appointment: previewAppt)
                    .padding(.vertical, 8)
            } else {
                PatientReminderRowView(reminder: $previewReminder)
                    .environmentObject(GameDataStore())
                    .padding(.vertical, 8)
            }
        }
        .padding(25)
        .glassEffect(in: .rect(cornerRadius: 35))
        .disabled(true)
    }
    
    // MARK: - Form Component Subviews
    
    private var appointmentForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Appointment Details", systemImage: "doc.text.fill")
                .font(.headline).foregroundStyle(.secondary)
            
            TextField("Doctor's Name", text: $doctorName)
                .formInputStyle()
            TextField("Specialty", text: $specialty)
                .formInputStyle()
            TextField("Location", text: $location)
                .formInputStyle()
        }
    }
    
    private var reminderForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Reminder Details", systemImage: "bell.fill")
                .font(.headline).foregroundStyle(.secondary)
            
            TextField("Title", text: $title)
                .formInputStyle()
            TextField("Details (Optional)", text: $details, axis: .vertical)
                .formInputStyle(minHeight: 100)
        }
    }
    
    private var tagSelectorForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Tags", systemImage: "tag.fill")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            TagWrappingHStack(alignment: .leading) {
                if selectedTags.isEmpty {
                    Text("No tags added.").font(.callout).foregroundStyle(.secondary)
                        .padding(.vertical, 5)
                } else {
                    ForEach(selectedTags) { tag in
                        remTagPillView(tag: tag, isRemovable: true) {
                            withAnimation { selectedTags.removeAll { $0.id == tag.id } }
                        }
                    }
                }
            }
            
            let availableTags = remTag.sampleTags.filter { t in !selectedTags.contains(where: {$0.id == t.id}) }
            
            if !availableTags.isEmpty {
                Divider()
                Menu {
                    ForEach(availableTags) { tag in
                        Button { withAnimation { selectedTags.append(tag) } } label: {
                            HStack {
                                Image(systemName: tag.icon)
                                Text(tag.name)
                                Circle()
                                    .fill(tag.color)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                } label: {
                    Label("Add Tag", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(themeColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Save Logic
    private func saveItem() {
        guard let patientID = selectedPatientID else { return }
        
        var newAppt: remAppointment? = nil
        var newRem: remReminder? = nil
        
        let origin: ReminderOrigin = .admin
        
        if selectedItemType == .appointment {
            newAppt = remAppointment(
                doctorName: doctorName,
                specialty: specialty,
                date: date,
                icon: "cross.case.fill",
                location: location,
                color: .blue,
                origin: origin,
                isCompleted: false
            )
        } else {
            newRem = remReminder(
                title: title,
                details: details,
                isCompleted: false,
                date: date,
                tags: selectedTags,
                origin: origin
            )
        }
        
        onSave(patientID, newAppt, newRem)
        dismiss()
    }
}


// MARK: - Preview
#Preview {
    NavigationStack {
        AdminAddItemView(
            patients: .constant(Patient.sampleData),
            transition: Namespace().wrappedValue
        ) { _, _, _ in
            print("Item Saved (Preview)")
        }
    }
}
