import SwiftUI
import AppKit
import Combine

class OverlayManager: ObservableObject {

    static let shared = OverlayManager()
    
    // Manage multiple active windows
    private var activeControllers: [OverlayWindowController] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        ReminderScheduler.shared.triggerSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] item in
                self?.showOverlay(content: item.content)
            }
            .store(in: &cancellables)
    }
    
    func start() {
        print("OverlayManager started listening.")
    }
    
    private func showOverlay(content: String) {
        let controller = OverlayWindowController(content: content)
        controller.onDidClose = { [weak self] closedController in
            self?.remove(controller: closedController)
        }
        
        // Insert new notification at the BEGINNING (Top of stack)
        // This causes existing ones to be pushed down, like iOS/macOS notifications.
        activeControllers.insert(controller, at: 0)
        
        // Show window initially (it will be positioned by rearrangeWindows immediately)
        controller.show()
        
        // Force rearrange to stack them
        // We delay slightly to ensure window frame sizing is propagated if needed, 
        // though usually fittingSize is synchronous.
        DispatchQueue.main.async {
            self.rearrangeWindows()
        }
    }
    
    private func remove(controller: OverlayWindowController) {
        if let index = activeControllers.firstIndex(where: { $0 === controller }) {
            activeControllers.remove(at: index)
            // Animate close existing? Controller handles close animation.
            // We just need to close the gap.
            rearrangeWindows()
        }
    }
    
    private func rearrangeWindows() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let rightPadding: CGFloat = 20
        let topPadding: CGFloat = 20
        let spacing: CGFloat = 10
        
        var currentY = screenRect.maxY - topPadding
        
        for (index, controller) in activeControllers.enumerated() {
            guard let window = controller.window else { continue }
            
            // Critical Fix: If window isn't fully laid out, frame.height might be wrong.
            // We use the hosting controller's fitting size as a reliable source of truth.
            // Since we setContentSize(fittingSize) in init, window.frame should be close, 
            // but let's be safe.
            var windowHeight = window.frame.height
            if windowHeight < 10 {
                // Fallback to fitting size if window reports roughly 0
                 windowHeight = controller.window?.contentViewController?.view.fittingSize.height ?? 100
            }
            let windowWidth = window.frame.width > 10 ? window.frame.width : (controller.window?.contentViewController?.view.fittingSize.width ?? 300)
            
            // Log for debugging
            print("Layout Window \(index): Height \(windowHeight) (Frame: \(window.frame.height)), Y: \(currentY - windowHeight)")
            
            let targetY = currentY - windowHeight
            let targetX = screenRect.maxX - windowWidth - rightPadding
            let targetOrigin = NSPoint(x: targetX, y: targetY)
            
            // Disable animation temporarily to ensure logic is correct - sometimes CoreAnimation behaves oddly with multiple rapid updates
            window.setFrameOrigin(targetOrigin)
            
            currentY -= (windowHeight + spacing)
        }
    }
}

// Helper class to manage a single overlay window's lifecycle
class OverlayWindowController {
    var window: NSWindow?
    var onDidClose: ((OverlayWindowController) -> Void)?
    private var dismissTimer: Timer?
    private var isFadingOut = false
    
    init(content: String) {
        // Create NSWindow
        let overlayWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        overlayWindow.level = .floating
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = false
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.isReleasedWhenClosed = false
        
        let hostingController = NSHostingController(rootView: OverlayView(content: content))
        overlayWindow.contentViewController = hostingController
        
        // Pre-calculate size based on content
        let fittingSize = hostingController.view.fittingSize
        overlayWindow.setContentSize(fittingSize)
        
        self.window = overlayWindow
    }
    
    func show() {
        guard let window = window else { return }
        
        // Initial placement to avoid appearing at (0,0)
        if let screen = NSScreen.main {
             let screenRect = screen.visibleFrame
             // Default to top-right just to have a sane start position
             let xPos = screenRect.maxX - window.frame.width - 20
             let yPos = screenRect.maxY - window.frame.height - 20
             window.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        }
        
        window.alphaValue = 0
        window.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            window.animator().alphaValue = 1.0
        }
        
        startDismissTimer()
    }
    
    private func startDismissTimer() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.fadeOutAndClose()
        }
    }
    
    private func fadeOutAndClose() {
        guard let window = window else { return }
        isFadingOut = true
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            window.animator().alphaValue = 0
        }) { [weak self] in
            guard let self = self else { return }
            self.window?.close()
            self.window = nil
            self.onDidClose?(self)
        }
    }
}
