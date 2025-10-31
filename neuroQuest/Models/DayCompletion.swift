//
//  DayCompletion.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//
// DayCompletion.swift

import Foundation

struct DayCompletion: Identifiable {
    let id = UUID()
    let dayInitial: String
    let completed: Bool
    let isToday: Bool
}
