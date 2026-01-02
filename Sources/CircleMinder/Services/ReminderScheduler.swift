import Foundation
import Combine
import AppKit

class ReminderScheduler: ObservableObject {
    static let shared = ReminderScheduler()
    
    // Subject to notify UI/App to show overlay. 
    // Sends the ReminderItem that needs to be shown.
    let triggerSubject = PassthroughSubject<ReminderItem, Never>()
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Reference to the store to update items (e.g. disable them)
    // We will inject this or set it later.
    weak var store: ReminderStore?
    
    private init() {
        startTimer()
        setupSleepObserver()
    }
    
    private func startTimer() {
        // High precision check (10Hz) to ensure we catch the interval trigger close to its exact time.
        // A 1s timer can cause up to 0.99s delay if phase-misaligned.
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    private func setupSleepObserver() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.handleWake()
            }
            .store(in: &cancellables)
    }
    
    private func handleWake() {
        print("System woke up. Resetting lastTriggerTime for active items to avoid immediate spam.")
        // When waking up, we might have missed a huge chunk of time.
        // As per requirement: "休眠唤醒后，直接忽略"
        // We simply reset 'lastTriggerTime' to now so the interval starts counting fresh from now.
        guard let store = store else { return }
        
        // We need to mutate the items in the store using the main actor context usually, 
        // but here we are in a simple service. We'll ask store to handle it.
        DispatchQueue.main.async {
            store.resetTimersForActiveItems()
        }
    }
    
    private func tick() {
        guard let store = store else { return }
        let now = Date()
        
        // We perform a copy of items to iterate
        let items = store.items
        
        for item in items {
            // Check based on ID to ensure we are looking at the current state if we wanted to be super Strict,
            // but for 'reading' the copy is fine. For 'writing' we MUST use ID.
            guard item.isEnabled, let start = item.startTime else { continue }
            
            // 1. Check expiration
            // If (now - start) > activeDuration, disable it.
            if now.timeIntervalSince(start) >= item.activeDuration {
                print("Item \(item.content) expired. Disabling.")
                DispatchQueue.main.async {
                    store.disableItem(id: item.id)
                }
                continue // No need to check trigger if expired
            }
            
            // 2. Check Interval Trigger
            if let lastTrigger = item.lastTriggerTime {
                if now.timeIntervalSince(lastTrigger) >= item.interval {
                    // TRIGGER!
                    print("Triggering item: \(item.content)")
                    triggerSubject.send(item)
                    
                    // Update lastTriggerTime
                    DispatchQueue.main.async {
                        // Fix for drift: Instead of setting to 'now' (which accumulates delays),
                        // add the interval to the previous trigger time to maintain a strict schedule.
                        var nextTriggerBase = lastTrigger.addingTimeInterval(item.interval)
                        
                        // Anti-Burst Protection:
                        // If we are significantly behind (e.g. computer lagged for 20s), 
                        // strict scheduling would cause immediate rapid-fire triggering to catch up.
                        // If we are more than one interval behind, we resync to 'now' to avoid spam.
                        if now.timeIntervalSince(nextTriggerBase) > item.interval {
                            print("Lag detected, resyncing trigger time to now.")
                            nextTriggerBase = now
                        }
                        
                        store.updateLastTriggerTime(for: item.id, to: nextTriggerBase)
                    }
                }
            }
        }
    }
}
