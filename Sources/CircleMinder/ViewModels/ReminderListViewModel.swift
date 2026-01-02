import Foundation
import Combine

class ReminderStore: ObservableObject {
    @Published var items: [ReminderItem] = [] {
        didSet {
            saveItems()
        }
    }
    
    private let fileURL: URL
    
    init() {
        // Setup file URL
        let fileManager = FileManager.default
        let appSup = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSup.appendingPathComponent("CircleMinder", isDirectory: true)
        
        // Ensure dir exists
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        self.fileURL = appDir.appendingPathComponent("reminders.json")
        
        loadItems()
        
        // Connect Store to Scheduler
        ReminderScheduler.shared.store = self
    }
    
    // MARK: - CRUD
    
    func addItem(_ item: ReminderItem) {
        items.append(item)
    }
    
    func deleteItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }
    
    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
    }
    
    func toggleItem(id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            var item = items[index]
            item.isEnabled.toggle()
            
            if item.isEnabled {
                // Starting fresh
                item.startTime = Date()
                item.lastTriggerTime = Date() // Reset trigger timer so it doesn't pop immediately or counts from now
            } else {
                item.startTime = nil
                item.lastTriggerTime = nil
            }
            items[index] = item
        }
    }
    
    // MARK: - Validation
    
    func isValid(interval: TimeInterval, duration: TimeInterval) -> Bool {
        return interval < duration
    }
    
    // MARK: - Scheduler Helpers
    
    func disableItem(id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isEnabled = false
            items[index].startTime = nil
            items[index].lastTriggerTime = nil
        }
    }
    
    // Legacy support or removal - removing 'at index' version to force usage of safe ID version
    // func disableItem(at index: Int) { ... }
    
    func resetTimersForActiveItems() {
        // Called after sleep wake
        let now = Date()
        for i in items.indices where items[i].isEnabled {
            // We just reset lastTriggerTime to NOW.
            // This means we wait a full 'interval' before next pop.
            items[i].lastTriggerTime = now
            // We DO NOT reset startTime because duration is "how long it stays active", 
            // sleeping shouldn't extend the absolute duration logic? 
            // User said: "duration refers to ... active time limit...".
            // If I sleep for 3 hours, and duration was 3 hours, it should probably be expired.
            // So we leave startTime alone. It will naturally expire in the tick() check if time passed.
        }
    }
    
    func updateLastTriggerTime(for id: UUID, to date: Date) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].lastTriggerTime = date
        }
    }
    
    // MARK: - Persistence
    
    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save items: \(error)")
        }
    }
    
    private func loadItems() {
        do {
            let data = try Data(contentsOf: fileURL)
            items = try JSONDecoder().decode([ReminderItem].self, from: data)
        } catch {
            print("Failed to load items (might be first run): \(error)")
            items = []
        }
    }
}
