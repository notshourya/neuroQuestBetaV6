// ReminderView.swift

import SwiftUI

// MARK: - Main Reminder View
struct ReminderView: View {
    @Binding var reminder: remReminder
    var userRole: UserRole
    @EnvironmentObject var gameDataStore: GameDataStore
    @EnvironmentObject var auth: Authentication
    @State private var isShowingDeleteConfirmation = false
    
    init(reminder: Binding<remReminder>, userRole: UserRole) {
        self._reminder = reminder
        self.userRole = userRole
    }
    private var accentColor: Color {
        reminder.isCompleted ? .green : (reminder.tags.first?.color ?? .orange)
    }
    
    private var gameCards: [GameCard] {
        let gameTagNamesInReminder = reminder.tags
            .map { $0.name }
            .filter { remTag.gameTagNames.contains($0) }
        
        let cards = gameTagNamesInReminder.compactMap { tagName in
            GameCard.allGames.first { $0.title == tagName }
        }
        return cards
    }

    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [accentColor.opacity(0.15), .clear]),
                center: .top, startRadius: 10, endRadius: 1000
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    ReminderHeroHeader(reminder: $reminder, color: accentColor, userRole: userRole)
                    ScheduleCard(date: $reminder.date, userRole: userRole)
                    DetailsCard(details: $reminder.details, userRole: userRole)
                    TagsCard(tags: $reminder.tags, userRole: userRole)
                    
                    if !gameCards.isEmpty && userRole == .patient {
                        
                        LinkedActivitiesCard(gameCards: gameCards)
                    }
                    actionButtons
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
        .alert("Delete Reminder?",
               isPresented: $isShowingDeleteConfirmation) {
            Button("Delete Reminder", role: .destructive) {
                print("Reminder Deleted")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. Are you sure you want to permanently delete this reminder?")
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring()) { reminder.isCompleted.toggle() }
            }) {
                Label(
                    reminder.isCompleted ? "Mark as Pending" : "Mark as Complete",
                    systemImage: reminder.isCompleted ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill"
                )
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .tint(reminder.isCompleted ? .red : .green)
          
        }
    }
}

// MARK: - Subviews & Cards

struct ReminderHeroHeader: View {
    @Binding var reminder: remReminder
    let color: Color
    var userRole: UserRole
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(color.gradient.opacity(0.2))
                Circle().stroke(color.gradient, lineWidth: 2)
                Image(systemName: "bell.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(width: 100, height: 100)
            
            TextField("Reminder Title", text: $reminder.title, axis: .vertical)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .disabled(userRole == .patient)
        }
        .padding(.vertical)
    }
}

struct ScheduleCard: View {
    @Binding var date: Date
    var userRole: UserRole
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Schedule", systemImage: "clock")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding([.horizontal, .top])
                .padding(.bottom, 8)
            
            Divider()
            
            DatePicker("Remind on", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .padding(10)
        }
        .padding(10)
        .glassEffect( in: .rect(cornerRadius: 34))
        .disabled(userRole == .patient)
    }
}

struct DetailsCard: View {
    @Binding var details: String
    var userRole: UserRole
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Notes & Details", systemImage: "note.text")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            TextEditor(text: $details)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(10)
                .glassEffect(in: .rect(cornerRadius: 25))
                .disabled(userRole == .patient)
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 35))
    }
}

struct TagsCard: View {
    @Binding var tags: [remTag]
    var userRole: UserRole
    
    private let allTags = remTag.sampleTags
    private var availableTags: [remTag] {
        allTags.filter { tag in !tags.contains(where: { $0.id == tag.id }) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Tags", systemImage: "tag.fill")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            TagWrappingHStack(alignment: .leading) {
                if tags.isEmpty {
                    Text("No tags added.").font(.callout).foregroundStyle(.secondary)
                } else {
                    ForEach(tags) { tag in
                        remTagPillView(
                            tag: tag,
                            isRemovable: userRole == .admin
                        ) {
                            withAnimation { tags.removeAll { $0.id == tag.id } }
                        }
                    }
                }
            }
            
            if userRole == .admin && !availableTags.isEmpty {
                Divider()
                Menu {
                    ForEach(availableTags) { tag in
                        Button { withAnimation { tags.append(tag) } } label: {
                            Label(tag.name, systemImage: tag.icon)
                        }
                    }
                } label: {
                    Label("Add Tag", systemImage: "plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 35))
    }
}


// MARK: - Linked Activities Card
struct LinkedActivitiesCard: View {
    let gameCards: [GameCard]
    
    @EnvironmentObject var gameDataStore: GameDataStore
    @EnvironmentObject var auth: Authentication

    private func getGameIndex(for gameCard: GameCard) -> Int? {
        gameDataStore.games.firstIndex(where: { $0.card.id == gameCard.id })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Linked Activities", systemImage: "play.circle.fill")
                .font(.headline)
                .foregroundStyle(.secondary)
       
            TagWrappingHStack(alignment: .leading) {
                ForEach(gameCards) { game in
                    
                    if let gameIndex = getGameIndex(for: game) {
                    
                        NavigationLink(destination: GameDetailView(game: game, tiers: $gameDataStore.games[gameIndex].tiers)
                            .environmentObject(gameDataStore)
                            .environmentObject(auth)
                        ) {
                            
                            Label(game.title, systemImage: "play.fill")
                                .font(.caption.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .foregroundStyle(.white)
                                .glassEffect(.regular.tint(game.accentColor.opacity(0.8)), in: .capsule)
                                .overlay(
                                    Capsule().strokeBorder(game.accentColor.opacity(0.3), lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 35))
    }
}


// MARK: - Preview Provider
#Preview {
    struct ReminderView_Preview: View {
        @State var sampleReminder = remReminder(
            title: "Practice Balance",
            details: "Complete the balance practice exercise.",
            isCompleted: false,
            date: Date(),
            tags: [remTag.sampleTags[1]]
        )
        
        var body: some View {
            NavigationView {
                ReminderView(reminder: $sampleReminder, userRole: .patient)
                    .environmentObject(GameDataStore())
                    .environmentObject(Authentication()) 
            }
        }
    }
    
    return ReminderView_Preview()
}

