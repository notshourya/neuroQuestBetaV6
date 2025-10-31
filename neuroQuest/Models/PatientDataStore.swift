//
//  PatientDataStore.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/31/25.
//

import SwiftUI
import Combine

class PatientDataStore: ObservableObject {
    @Published var patients = Patient.sampleData
   
    func handleSave(patientID: UUID, newAppointment: remAppointment?, newReminder: remReminder?) {
       
        guard let index = patients.firstIndex(where: { $0.id == patientID }) else { return }

        if let newAppointment {
            patients[index].appointments.append(newAppointment)
            patients[index].appointments.sort { $0.date < $1.date }
        }
        
      
        if let newReminder {
            patients[index].reminders.append(newReminder)
            patients[index].reminders.sort { $0.date < $1.date }
        }
    }
}
