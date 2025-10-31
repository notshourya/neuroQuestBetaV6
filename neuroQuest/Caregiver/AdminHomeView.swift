//
//  AdminHomeView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.
//

import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject var auth: Authentication
    @EnvironmentObject var patientStore: PatientDataStore
    @State private var hasAppeared = false
    @State private var isShowingProfileSheet = false
    @Namespace private var transition
    
    private var averageAdherence: Double {
        guard !patientStore.patients.isEmpty else { return 0 }
        return patientStore.patients.map { $0.adherenceRate }.reduce(0, +) / Double(patientStore.patients.count)
    }
    
    private var adherenceColor: Color {
        switch averageAdherence {
        case 0.8...: return .green
        case 0.4..<0.8: return .yellow
        default: return .red
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [adherenceColor.opacity(0.12), .clear]),
                    center: .top, startRadius: 10, endRadius: 1000
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        AdminHeaderView(
                            isShowingProfileSheet: $isShowingProfileSheet,
                            transition: transition
                        )
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
    
                        AdminDashboardCard(patients: patientStore.patients, color: adherenceColor)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: hasAppeared)
                        
                        patientList
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: hasAppeared)
                    }
                    .padding(.vertical)
                }
                .navigationBarHidden(true)
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { hasAppeared = true }
            }
            .fullScreenCover(isPresented: $isShowingProfileSheet) {
                NavigationStack {
                    AdminProfileView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    isShowingProfileSheet = false
                                }
                            }
                        }
                }
                .environmentObject(auth)
                .navigationTransition(.zoom(sourceID: "adminProfileButton", in: transition))
            }
            .onChange(of: auth.isSigningOut) { _, isSigningOut in
                if isSigningOut {
                    isShowingProfileSheet = false
                }
            }
        }
    }
    
    private var patientList: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("All Patients")
                    .font(.title2.bold())
                    .padding(.horizontal)
                ForEach(patientStore.patients.indices, id: \.self) { index in
                    NavigationLink(destination: PatientDetailView(patient: $patientStore.patients[index])) {
                        PatientCard(patient: patientStore.patients[index])
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }
        }
}

// MARK: - Subviews

struct AdminHeaderView: View {
    @Binding var isShowingProfileSheet: Bool
    let transition: Namespace.ID
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome, Admin").font(.largeTitle.bold())
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.subheadline).foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                isShowingProfileSheet = true
            }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.secondary.opacity(0.8))
            }
            .matchedTransitionSource(id: "adminProfileButton", in: transition)
        }
        .padding([.top, .horizontal])
    }
}

struct AdminDashboardCard: View {
    let patients: [Patient]
    let color: Color
    @State private var animateRing = false
    
    private var averageAdherence: Double {
        guard !patients.isEmpty else { return 0 }
        return patients.map { $0.adherenceRate }.reduce(0, +) / Double(patients.count)
    }
    
    private var totalSessions: Int {
        patients.reduce(0) { $0 + $1.sessions.count }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Label("Overall Performance", systemImage: "chart.pie.fill")
                .font(.title2.bold())
                .foregroundColor(color)
            
            ZStack {
                Circle().stroke(color.opacity(0.15), lineWidth: 15)
                Circle()
                    .trim(from: 0, to: animateRing ? averageAdherence : 0)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("Avg. Adherence").font(.caption2).bold().foregroundColor(.secondary)
                    Text(averageAdherence, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                }
            }
            .frame(height: 150)
            .padding(.vertical)
            
            HStack(spacing: 15) {
                StatPill(label: "Total Patients", value: "\(patients.count)", color: .blue)
                    .glassEffect(in: .capsule)

                
                StatPill(label: "Total Sessions", value: "\(totalSessions)", color: .purple)
                    .glassEffect(in: .capsule)
            }
        }
        .padding(15)
        .glassEffect(in: .rect(cornerRadius: 35))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animateRing = true
            }
        }
        .padding(.horizontal)
    }
}

struct PatientCard: View {
    let patient: Patient
    @State private var animateRing = false

    private var adherenceColor: Color {
        switch patient.adherenceRate {
        case 0.8...: return .green
        case 0.4..<0.8: return .yellow
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(adherenceColor).frame(width: 12)
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(patient.name).font(.headline.bold())
                        Text(patient.condition).font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("\(Int(patient.adherenceRate * 100))%")
                        .font(.headline).fontWeight(.bold).foregroundColor(adherenceColor)
                }
                Divider()
                HStack(spacing: 12) {
                    ZStack {
                        Circle().stroke(adherenceColor.opacity(0.2), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: animateRing ? CGFloat(patient.adherenceRate) : 0)
                            .stroke(adherenceColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(patient.adherenceRate * 7))/7").font(.caption.bold())
                    }
                    .frame(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Adherence").font(.subheadline.bold())
                        Text("Days exercised this week").font(.caption).foregroundColor(.secondary)
                    }
                }
                Divider()
                HStack(spacing: 12) {
                    StatPill(label: "Sessions", value: "\(patient.sessions.count)", color: .blue)
                        .glassEffect(in: .capsule)
                    StatPill(label: "Avg. Score", value: "\(Int(patient.averageScore))", color: .orange)
                        .glassEffect(in: .capsule)
                }
            }
            .padding()
        }
        .glassEffect(in: .rect(cornerRadius: 35))
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateRing = true
            }
        }
    }
}

#Preview {
    AdminHomeView()
        .environmentObject(Authentication())
        .environmentObject(PatientDataStore()) 
}
