//
//  DataModel.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
import SwiftUI

enum ReminderOrigin: Codable {
    case patient
    case admin
}

// MARK: - Shared Data Models

struct remCodableColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r); self.green = Double(g); self.blue = Double(b); self.opacity = Double(a)
    }

    var color: Color { Color(red: red, green: green, blue: blue, opacity: opacity) }
}

struct remTag: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var icon: String
    private var codableColor: remCodableColor
    
    var color: Color {
        get { codableColor.color }
        set { codableColor = remCodableColor(color: newValue) }
    }
    
    init(name: String, icon: String, color: Color) {
        self.name = name; self.icon = icon; self.codableColor = remCodableColor(color: color)
    }
    
    static var sampleTags: [remTag] = [
        remTag(name: "Tremor Control", icon: "hand.raised.fill", color: .teal),
        remTag(name: "Balance Practice", icon: "figure.walk", color: .blue),
        remTag(name: "Voice Strength", icon: "mic.fill", color: .purple),
        remTag(name: "Fine Motor Skills", icon: "hand.draw.fill", color: .orange),
        remTag(name: "Cognitive Focus", icon: "brain.head.profile", color: .pink),
        remTag(name: "Walking Rhythm", icon: "figure.stand", color: .mint),
  
        remTag(name: "Medication", icon: "pills.fill", color: .indigo),
        remTag(name: "Urgent", icon: "exclamationmark.triangle.fill", color: .yellow),
        remTag(name: "Nutrition", icon: "carrot.fill", color: .brown),
        remTag(name: "Symptom Log", icon: "list.bullet.clipboard.fill", color: .cyan)
    ]

    static var gameTagNames: [String] = [
        "Tremor Control", "Balance Practice", "Voice Strength",
        "Fine Motor Skills", "Cognitive Focus", "Walking Rhythm"
    ]
}

struct remAppointment: Identifiable, Codable {
    var id = UUID()
    var doctorName: String
    var specialty: String
    var date: Date
    var icon: String
    var location: String
    private var codableColor: remCodableColor
    var origin: ReminderOrigin
    var isCompleted: Bool

    var color: Color {
        get { codableColor.color }
        set { codableColor = remCodableColor(color: newValue) }
    }
 
    init(id: UUID = UUID(), doctorName: String, specialty: String, date: Date, icon: String, location: String = "", color: Color, origin: ReminderOrigin = .patient, isCompleted: Bool = false) {
        self.id = id
        self.doctorName = doctorName
        self.specialty = specialty
        self.date = date
        self.icon = icon
        self.location = location
        self.codableColor = remCodableColor(color: color)
        self.origin = origin
        self.isCompleted = isCompleted
    }
}

struct remReminder: Identifiable, Codable {
    let id: UUID
    var title: String
    var details: String
    var isCompleted: Bool
    var date: Date
    var tags: [remTag] = []
    var origin: ReminderOrigin
    
    init(id: UUID = UUID(), title: String, details: String, isCompleted: Bool, date: Date, tags: [remTag] = [], origin: ReminderOrigin = .patient) {
        self.id = id
        self.title = title
        self.details = details
        self.isCompleted = isCompleted
        self.date = date
        self.tags = tags
        self.origin = origin
    }

    static func empty() -> remReminder {
        .init(title: "", details: "", isCompleted: false, date: Date(), tags: [], origin: .patient)
    }
}

