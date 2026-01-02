import Foundation

struct ReminderItem: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var interval: TimeInterval
    var activeDuration: TimeInterval
    var isEnabled: Bool
    var startTime: Date?
    var lastTriggerTime: Date?
    
    init(id: UUID = UUID(), content: String = "", interval: TimeInterval = 300, activeDuration: TimeInterval = 3600, isEnabled: Bool = false) {
        self.id = id
        self.content = content
        self.interval = interval
        self.activeDuration = activeDuration
        self.isEnabled = isEnabled
        self.startTime = nil
        self.lastTriggerTime = nil
    }
}
