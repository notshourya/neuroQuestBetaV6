//
//  PatientWellnessView.swift
//  neuroQuest
//
//  Created by Shourya Thakur on 10/30/25.

import SwiftUI
import PencilKit

// MARK: - Doodle Model (Using PencilKit Data)
struct Doodle: Identifiable, Equatable, Codable {
    let id: UUID
    var drawingData: Data 
    let date: Date
    var title: String?
    var mood: String?
    
    init(id: UUID = UUID(), drawingData: Data = Data(), date: Date = Date(), title: String? = nil, mood: String? = nil) {
        self.id = id
        self.drawingData = drawingData
        self.date = date
        self.title = title
        self.mood = mood
    }
    
    var drawing: PKDrawing {
        (try? PKDrawing(data: drawingData)) ?? PKDrawing()
    }
    
    static func == (lhs: Doodle, rhs: Doodle) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, drawingData, date, title, mood
    }
}

// MARK: - Main Wellness View
struct MindfulWellnessView: View {
    
    @State private var isBreathing = false
    @State private var breathLabel = "Tap to Start"
    @State private var breathScale: CGFloat = 0.5
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: CGFloat = 0.0
    @State private var cardScale: CGFloat = 1.0
    
    @State private var showHeader = false
    
    @State private var savedDoodles: [Doodle] = []
    @State private var isDoodling = false
    @State private var selectedDoodle: Doodle? = nil
    
    @State private var selectedMoodFilter: String? = nil
    @State private var selectedDateFilter: DateFilter = .allTime
    
    enum DateFilter: String, CaseIterable, Identifiable {
        case allTime = "All Time"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        
        var id: String { self.rawValue }
    }
    
    private let moods = ["Calm", "Happy", "Reflective", "Sad", "Playful"]

    // MARK: - Body
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Color.cyan.opacity(0.15), Color(.systemGroupedBackground)]),
                center: .top,
                startRadius: 10,
                endRadius: 1000
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    headerView
                        .opacity(showHeader ? 1 : 0)
                        .offset(y: showHeader ? 0 : 20)
                    
                    breathingExerciseCard
                        .opacity(showHeader ? 1 : 0)
                        .offset(y: showHeader ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showHeader)

                    doodleCard
                        .opacity(showHeader ? 1 : 0)
                        .offset(y: showHeader ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: showHeader)
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showHeader = true
            }
            loadDoodles()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: savedDoodles) { oldValue, newValue in
            saveDoodles()
        }
        .fullScreenCover(isPresented: $isDoodling) {
            DoodleEditorView(
                savedDoodles: $savedDoodles,
                doodleToEdit: nil,
                onDismiss: { }
            )
            .background(.regularMaterial)
            .ignoresSafeArea()
        }

        .fullScreenCover(item: $selectedDoodle) { doodle in
            DoodleSheetContainer(
                doodle: doodle,
                savedDoodles: $savedDoodles,
                onDelete: { doodleToDelete in
                    self.delete(doodle: doodleToDelete)
                    self.selectedDoodle = nil
                }
            )
            .background(.regularMaterial)
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Find Your Calm")
                .font(.largeTitle.bold())
            Text("A quiet space to focus and reflect.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding([.top, .horizontal])
    }
    
    private var breathingExerciseCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Guided Breathing", systemImage: "wind")
                .font(.title2.bold())
                .foregroundStyle(.cyan)
            
            Text("Follow the breathing technique to calm your mind.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ZStack {
                 Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.cyan.opacity(0.3), Color.cyan.opacity(0.0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 200, height: 200)
                    .scaleEffect(rippleScale)
                    .blur(radius: 10)
                    .opacity(rippleOpacity)

                 Circle()
                    .fill(RadialGradient(
                        gradient: Gradient(colors: [Color.cyan.opacity(0.5), Color.cyan]),
                        center: .center,
                        startRadius: 25,
                        endRadius: 75
                    ))
                    .frame(width: 150, height: 150)
                    .scaleEffect(breathScale)
                    .blur(radius: 15)
                
                 Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 75, height: 75)
                    .scaleEffect(breathScale)
                    .blur(radius: 20)

                 Text(breathLabel)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary.opacity(0.9))
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: breathLabel)
             }
            .frame(height: 200)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 30))
        .padding(.horizontal)
        .scaleEffect(cardScale)
        .onTapGesture {
            isBreathing.toggle()
            
            if isBreathing {
                runBreathingCycle()
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    breathScale = 0.5
                    rippleScale = 1.0
                    rippleOpacity = 0.0
                    cardScale = 1.0
                }
                withAnimation {
                    breathLabel = "Tap to Start"
                }
            }
        }
        .sensoryFeedback(.selection, trigger: breathLabel) { old, new in
            return new == "Breathe In" || new == "Breathe Out"
        }
    }
    
    // MARK: - Breathing Animation Logic
    
    private func runBreathingCycle() {
         Task {
             while isBreathing {
                 await setPhase(label: "Breathe In", scale: 1.1, ripple: 1.2, rippleOp: 0.6, cardScale: 1.015, duration: 4.0)
                 if !isBreathing { break }

                 await setPhase(label: "Hold", scale: 1.1, ripple: 1.2, rippleOp: 0.6, cardScale: 1.015, duration: 7.0)
                 if !isBreathing { break }
                
                 await setPhase(label: "Breathe Out", scale: 0.5, ripple: 1.0, rippleOp: 0.0, cardScale: 1.0, duration: 8.0)
                 if !isBreathing { break }
             }
         }
     }

     private func setPhase(label: String, scale: CGFloat, ripple: CGFloat, rippleOp: CGFloat, cardScale: CGFloat, duration: TimeInterval) async {
         guard isBreathing else { return }
        
         withAnimation(.easeInOut(duration: 0.8)) {
             self.breathLabel = label
         }
        
         let animation: Animation
         if label == "Breathe In" {
             animation = .easeIn(duration: duration)
         } else if label == "Breathe Out" {
             animation = .easeOut(duration: duration)
         } else {
             animation = .easeInOut(duration: 0.5) // Hold phase animation
         }
        
         if label != "Hold" {
             withAnimation(animation) {
                 self.breathScale = scale
                 self.rippleScale = ripple
                 self.rippleOpacity = rippleOp
                 self.cardScale = cardScale
             }
         } else {
             withAnimation(animation) {
                 self.cardScale = cardScale
             }
         }
        
         try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
     }

    // MARK: - Doodle Card
    

    private var doodleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Doodle for Today", systemImage: "pencil.and.scribble")
                .font(.title2.bold())
                .foregroundStyle(.orange)
            
            Text("Clear your mind with a creative doodle. Your saved drawings will appear below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button(action: {
                print("Start Doodling tapped")
                isDoodling = true
            }) {
                Text("Start Doodling")
                    .foregroundStyle(Color(.label))
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.orange.opacity(1))
                    .glassEffect()
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
            
            if !savedDoodles.isEmpty {
                HStack {
                    Text("Previous Doodles")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    filterMenu
                }
                .padding(.top, 10)
                
                if filteredDoodles.isEmpty {
                    Text("No doodles match your filters.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(filteredDoodles) { doodle in
                                Button(action: {
                                    print("Tapped on doodle: \(doodle.id)")
                                    selectedDoodle = doodle
                                }) {
                                    DoodleThumbnailView(doodle: doodle)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 30))
        .padding(.horizontal)
    }
    
    // MARK: - Filter Menu View
    
    private var filterMenu: some View {
        Menu {
            if selectedMoodFilter != nil || selectedDateFilter != .allTime {
                Button(role: .destructive, action: {
                    withAnimation {
                        selectedMoodFilter = nil
                        selectedDateFilter = .allTime
                    }
                }) {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
                Divider()
            }
            
            Picker("Filter by Mood", selection: $selectedMoodFilter) {
                Text("All Moods").tag(String?.none)
                ForEach(moods, id: \.self) { mood in
                    Text(mood).tag(String?.some(mood))
                }
            }
            .pickerStyle(.menu)
            
            Picker("Filter by Date", selection: $selectedDateFilter) {
                ForEach(DateFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.menu)
            
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.title3)
                .foregroundStyle(selectedMoodFilter != nil || selectedDateFilter != .allTime ? .blue : .secondary)
        }
        .sensoryFeedback(.selection, trigger: selectedMoodFilter)
        .sensoryFeedback(.selection, trigger: selectedDateFilter)
    }
    
    // MARK: - Filtered Doodles Logic
    
    private var filteredDoodles: [Doodle] {
        var doodles = savedDoodles

        if let mood = selectedMoodFilter {
            doodles = doodles.filter { $0.mood == mood }
        }

        switch selectedDateFilter {
        case .allTime:
            break
        case .today:
            doodles = doodles.filter { Calendar.current.isDateInToday($0.date) }
        case .thisWeek:
            doodles = doodles.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        case .thisMonth:
            doodles = doodles.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        }
        
        return doodles.sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Data Persistence Logic
    
    private var doodlesFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("doodles_pk.json")
    }
    
    private func saveDoodles() {
        do {
            let data = try JSONEncoder().encode(savedDoodles)
            try data.write(to: doodlesFileURL, options: .atomic)
             print("Doodles saved successfully to \(doodlesFileURL.path)")
        } catch {
            print("Failed to save doodles: \(error.localizedDescription)")
        }
    }
    
    private func loadDoodles() {
        guard FileManager.default.fileExists(atPath: doodlesFileURL.path) else {
            print("Doodle file does not exist, starting fresh.")
            return
        }
        
        do {
            let data = try Data(contentsOf: doodlesFileURL)
            savedDoodles = try JSONDecoder().decode([Doodle].self, from: data)
            print("Doodles loaded successfully: \(savedDoodles.count) doodles.")
        } catch {
            print("Failed to load doodles: \(error.localizedDescription)")
            savedDoodles = []
        }
    }
    
    private func delete(doodle: Doodle) {
        savedDoodles.removeAll { $0.id == doodle.id }
        saveDoodles()
    }
}

// MARK: - Doodle Thumbnail (Using Image from PKDrawing)
struct DoodleThumbnailView: View {
    let doodle: Doodle
    
    @State private var thumbnailImage: Image? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
             Group {
                 if let image = thumbnailImage {
                     image
                         .resizable()
                         .scaledToFit()
                 } else {
                     Rectangle()
                         .fill(Color.gray.opacity(0.1))
                         .overlay(ProgressView())
                 }
             }
            .frame(width: 120, height: 120)
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .glassEffect()
            .allowsHitTesting(false)
            
            if let title = doodle.title, !title.isEmpty {
                Text(title)
                    .font(.caption.bold())
                    .lineLimit(1)
            }
            Text(doodle.date, style: .date)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .onAppear {
             if thumbnailImage == nil {
                 generateThumbnail()
             }
         }
    }
    
    private func generateThumbnail() {
         Task(priority: .background) {
             let drawing = doodle.drawing
             let uiImage = await drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
             await MainActor.run {
                 thumbnailImage = Image(uiImage: uiImage)
             }
         }
     }
}


// MARK: - Doodle Editor (Using PencilKit)

struct DoodleEditorView: View {
    @Binding var savedDoodles: [Doodle]
    var doodleToEdit: Doodle?
    var onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentDrawing: PKDrawing
    @State private var title: String
    @State private var mood: String
    @State private var editingDoodleID: UUID?
    @State private var selectedColor: Color = .black
    @State private var selectedWidth: CGFloat = 5.0
    @State private var canvasUndoManager: UndoManager? = nil

    private let colors: [Color] = [.black, .red, .blue, .green, .orange, .purple, .pink]
    private let moods = ["Calm", "Happy", "Reflective", "Sad", "Playful"]

    init(savedDoodles: Binding<[Doodle]>, doodleToEdit: Doodle?, onDismiss: @escaping () -> Void) {
        self._savedDoodles = savedDoodles
        self.doodleToEdit = doodleToEdit
        self.onDismiss = onDismiss
        
        if let doodle = doodleToEdit {
            self._currentDrawing = State(initialValue: doodle.drawing)
            self._title = State(initialValue: doodle.title ?? "")
            self._mood = State(initialValue: doodle.mood ?? "Calm")
            self._editingDoodleID = State(initialValue: doodle.id)
        } else {
            self._currentDrawing = State(initialValue: PKDrawing())
            self._title = State(initialValue: "")
            self._mood = State(initialValue: "Calm")
            self._editingDoodleID = State(initialValue: nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        TextField("Give your doodle a name", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        Picker("Mood", selection: $mood) {
                            ForEach(moods, id: \.self) { mood in
                                Text(mood).tag(mood)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }
                    
                    VStack(spacing: 0) {
                        PencilKitCanvasView(
                            drawing: $currentDrawing,
                            selectedColor: $selectedColor,
                            selectedWidth: $selectedWidth,
                            undoManager: $canvasUndoManager
                        )
                        .frame(height: 400)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(colors, id: \.self) { color in
                                    ZStack {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 44, height: 44)
                                        
                                        if selectedColor == color {
                                            Circle()
                                                .strokeBorder(Color.blue, lineWidth: 3)
                                                .frame(width: 52, height: 52)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 2)
                                        }
                                    }
                                    .shadow(color: color.opacity(0.4), radius: 4, y: 2)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedColor = color
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Stroke Width")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(selectedColor)
                                .frame(width: selectedWidth * 2, height: selectedWidth * 2)
                                .shadow(color: selectedColor.opacity(0.4), radius: 2)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.tip")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Slider(value: $selectedWidth, in: 1...20, step: 1)
                                .tint(selectedColor)
                            
                            Image(systemName: "pencil.tip")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(editingDoodleID == nil ? "New Doodle" : "Edit Doodle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveDoodle()
                        dismiss()
                        onDismiss()
                    }
                    .disabled(currentDrawing.strokes.isEmpty)
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        canvasUndoManager?.undo()
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(!(canvasUndoManager?.canUndo ?? false))
                    
                    Spacer()
                    
                    Button {
                        currentDrawing = PKDrawing()
                        canvasUndoManager?.removeAllActions()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .tint(.red)
                    .disabled(currentDrawing.strokes.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Save Logic
    private func saveDoodle() {
        guard !currentDrawing.strokes.isEmpty else { return }
        
        let drawingData = currentDrawing.dataRepresentation()
        
        if let editingID = editingDoodleID,
           let index = savedDoodles.firstIndex(where: { $0.id == editingID }) {
            savedDoodles[index] = Doodle(
                id: editingID,
                drawingData: drawingData,
                date: savedDoodles[index].date,
                title: title.isEmpty ? nil : title,
                mood: mood
            )
        } else {
            let newDoodle = Doodle(
                drawingData: drawingData,
                date: Date(),
                title: title.isEmpty ? nil : title,
                mood: mood
            )
            savedDoodles.append(newDoodle)
        }
        
    }
}
// MARK: - Doodle Sheet Container (Handles Navigation for Detail/Edit)
struct DoodleSheetContainer: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var doodle: Doodle
    @Binding var savedDoodles: [Doodle]
    var onDelete: (Doodle) -> Void
    
    init(doodle: Doodle, savedDoodles: Binding<[Doodle]>, onDelete: @escaping (Doodle) -> Void) {
        self._doodle = State(initialValue: doodle)
        self._savedDoodles = savedDoodles
        self.onDelete = onDelete
    }
    
    var body: some View {
        NavigationStack {
            DoodleDetailView(
                doodle: $doodle,
                savedDoodles: $savedDoodles,
                onDelete: { doodleToDelete in
                    onDelete(doodleToDelete)
                    dismiss()
                }
            )
        }
        .onChange(of: savedDoodles) {
             if let updatedDoodle = savedDoodles.first(where: { $0.id == doodle.id }) {
                 if updatedDoodle.drawingData != self.doodle.drawingData ||
                    updatedDoodle.title != self.doodle.title ||
                    updatedDoodle.mood != self.doodle.mood {
                      self.doodle = updatedDoodle
                 }
             } else {
                 dismiss()
             }
         }
    }
}


// MARK: - Doodle Detail View (Using Image from PKDrawing)
struct DoodleDetailView: View {
    @Binding var doodle: Doodle
    @Binding var savedDoodles: [Doodle]
    var onDelete: (Doodle) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    
    @State private var drawingImage: Image? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
             VStack(alignment: .leading, spacing: 5) {
                 if let title = doodle.title, !title.isEmpty {
                     Text(title).font(.largeTitle.bold())
                 }
                 if let mood = doodle.mood, !mood.isEmpty {
                     Label(mood, systemImage: "face.smiling")
                         .font(.headline).foregroundStyle(.secondary).padding(.bottom, 5)
                 }
                 Text("Drawn on \(doodle.date.formatted(date: .long, time: .omitted))")
                     .font(.subheadline).foregroundStyle(.tertiary)
             }
             .padding(.horizontal, 25)
            
             Group {
                 if let image = drawingImage {
                     image
                         .resizable()
                         .scaledToFit()
                 } else {
                     Rectangle()
                         .fill(Color.gray.opacity(0.1))
                         .overlay(ProgressView())
                         .aspectRatio(1, contentMode: .fit)
                 }
             }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
            .padding()
            .allowsHitTesting(false)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Your Doodle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
             ToolbarItem(placement: .primaryAction) {
                 Button("Done") { dismiss() }
             }
             ToolbarItem(placement: .cancellationAction) {
                 Menu {
                     NavigationLink {
                         DoodleEditorView(
                             savedDoodles: $savedDoodles,
                             doodleToEdit: doodle,
                             onDismiss: {}
                         )
                     } label: {
                         Label("Edit", systemImage: "pencil")
                     }
                     Button(role: .destructive, action: { showDeleteAlert = true }) {
                         Label("Delete", systemImage: "trash")
                     }
                 } label: {
                     Image(systemName: "ellipsis.circle")
                 }
             }
         }
        .alert("Delete Doodle?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete(doodle)
            }
        } message: {
            Text("Are you sure you want to delete this doodle? This cannot be undone.")
        }
        .onAppear {
             generateImage()
         }
         .onChange(of: doodle.drawingData) { _, _ in
             generateImage()
         }
    }
    
    private func generateImage() {
         Task(priority: .userInitiated) {
             let drawing = doodle.drawing
             let uiImage = await drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
             await MainActor.run {
                 drawingImage = Image(uiImage: uiImage)
             }
         }
     }
}



// MARK: - Preview
#Preview {
    NavigationStack {
        MindfulWellnessView()
    }
}
