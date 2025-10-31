//
//  PatientModel.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
// PatientModel.swift

import SwiftUI
import Combine

struct Patient: Identifiable {
    var id = UUID()
    var name: String
    var age: Int
    var condition: String
    var sessions: [GamePlaySession]
    var reminders: [remReminder]
    var appointments: [remAppointment]
    
    var adherenceRate: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let last7Days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        let activeDays = last7Days.filter { day in
            sessions.contains { calendar.isDate($0.date, inSameDayAs: day) }
        }
        return Double(activeDays.count) / 7.0
    }
    
    var averageScore: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.map { $0.score }.reduce(0, +)) / Double(sessions.count)
    }
    
    // MOCK DATA
    static var sampleData: [Patient] {
        let allGames = GameCard.allGames
        return [
            Patient(
                name: "Arjun Mehta",
                age: 58,
                condition: "Parkinson’s Stage II",
                sessions: GamePlaySession.generateMockData(for: allGames, count: 25),
                reminders: [
                    remReminder(title: "Follow-up Check", details: "Admin scheduled a check-in.", isCompleted: false, date: Date().addingTimeInterval(86400 * 2), tags: [remTag.sampleTags[8]], origin: .admin),
                    remReminder(title: "Pick up prescription", details: "Local pharmacy before 5 PM", isCompleted: true, date: Date(), tags: [remTag.sampleTags[6]]),
                    remReminder(title: "Afternoon walk", details: "30 minutes in the park", isCompleted: false, date: Date(), tags: [remTag.sampleTags[1]], origin: .patient),
                    remReminder(title: "Practice Voice", details: "Do the voice strength exercise.", isCompleted: false, date: Date(), tags: [remTag.sampleTags[2]], origin: .patient)
                ],
                appointments: [
                    remAppointment(doctorName: "Dr. Singh", specialty: "Neurologist", date: .now.addingTimeInterval(86400 * 5), icon: "brain.head.profile", location: "City Neurology Clinic", color: .blue, origin: .admin),
                    remAppointment(doctorName: "Dr. Verma", specialty: "Dentist", date: .now.addingTimeInterval(86400 * 10), icon: "mouth.fill", location: "Downtown Dental", color: .teal, origin: .patient)
                ]
            ),
            Patient(
                name: "Neha Sharma",
                age: 62,
                condition: "Tremor-dominant",
                sessions: GamePlaySession.generateMockData(for: allGames, count: 18),
                reminders: [
                    remReminder(title: "Voice Exercise", details: "Practice speaking aloud", isCompleted: false, date: Date(), tags: [remTag.sampleTags[2]], origin: .patient)
                ],
                appointments: [
                    remAppointment(doctorName: "Dr. Lee", specialty: "Physical Therapy", date: .now.addingTimeInterval(86400 * 3), icon: "figure.walk.motion", location: "Motion Therapeutics", color: .green, origin: .admin)
                ]
            ),
            Patient(
                name: "Rahul Verma",
                age: 65,
                condition: "Postural instability",
                sessions: GamePlaySession.generateMockData(for: allGames, count: 30),
                reminders: [],
                appointments: []
            )
        ]
    }
}

extension Patient {
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: name) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
}


class PatientDataModel: ObservableObject {
    @Published var patient = Patient.sampleData[0]
}
