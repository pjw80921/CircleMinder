import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force the app to be a regular app (shows in Dock) and activate it
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Ensure main window is key
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
        
        // Set App Icon
        // Set App Icon
        // Set App Icon
        // Use SPM's generated Bundle.module to locate resources reliability
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = iconImage
        } else {
            print("Warning: Could not load AppIcon from Bundle.module")
        }
    }
}

@main
struct CircleMinderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var reminderStore = ReminderStore()
    
    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environmentObject(reminderStore)
                .background(.ultraThinMaterial)
                .fixedSize()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    init() {
        OverlayManager.shared.start()
    }
}

