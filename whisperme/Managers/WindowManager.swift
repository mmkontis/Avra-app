import SwiftUI
import AppKit

class WindowManager: ObservableObject {
    // MARK: - Properties
    
    private var recordingWindow: NSWindow?
    private var idleRecordingWindow: NSWindow?
    private var toastWindow: ToastWindow?
    private var eventMonitor: EventMonitor?
    
    weak var viewModel: ContentViewModel?
    
    // MARK: - Initialization
    
    init() {
        setupEventMonitor()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    func setViewModel(_ viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }
    
    func showIdleRecordingWindow() {
        guard let viewModel = viewModel else { return }
        
        if idleRecordingWindow == nil {
            let contentView = RecordingView(viewModel: viewModel)
            
            idleRecordingWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 120, height: 40),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            idleRecordingWindow?.contentView = NSHostingView(rootView: contentView)
            idleRecordingWindow?.backgroundColor = NSColor.clear
            idleRecordingWindow?.isOpaque = false
            idleRecordingWindow?.level = NSWindow.Level.floating
            idleRecordingWindow?.ignoresMouseEvents = true
            idleRecordingWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
            
            // Position at top-right corner of screen
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = idleRecordingWindow!.frame
                let x = screenFrame.maxX - windowFrame.width - 20
                let y = screenFrame.maxY - windowFrame.height - 20
                idleRecordingWindow?.setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
        
        idleRecordingWindow?.orderFront(nil)
    }
    
    func enableFloatingBar() {
        showIdleRecordingWindow()
    }
    
    func disableFloatingBar() {
        idleRecordingWindow?.orderOut(nil)
        idleRecordingWindow = nil
    }
    
    func showRecordingWindow() {
        guard let viewModel = viewModel else { return }
        
        let contentView = RecordingView(viewModel: viewModel)
        
        recordingWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        recordingWindow?.contentView = NSHostingView(rootView: contentView)
        recordingWindow?.backgroundColor = NSColor.clear
        recordingWindow?.isOpaque = false
        recordingWindow?.level = NSWindow.Level.floating
        recordingWindow?.ignoresMouseEvents = true
        recordingWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Position at center-top of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = recordingWindow!.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.maxY - windowFrame.height - 50
            recordingWindow?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        recordingWindow?.orderFront(nil)
    }
    
    func hideRecordingWindow() {
        recordingWindow?.orderOut(nil)
        recordingWindow = nil
    }
    
    func showToastWindow(message: String, type: ToastType) {
        hideToastWindow() // Hide any existing toast
        
        guard let viewModel = viewModel else { return }
        
        let toastView = ToastView(message: message, type: type, isShowing: .constant(true))
        
        toastWindow = ToastWindow(viewModel: viewModel)
        toastWindow?.contentView = NSHostingView(rootView: toastView)
        toastWindow?.backgroundColor = NSColor.clear
        toastWindow?.isOpaque = false
        toastWindow?.level = NSWindow.Level.floating
        toastWindow?.ignoresMouseEvents = true
        toastWindow?.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // Position at top-right corner
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = CGSize(width: 300, height: 80)
            let x = screenFrame.maxX - windowSize.width - 20
            let y = screenFrame.maxY - windowSize.height - 20
            
            toastWindow?.setFrame(NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height), display: true)
        }
        
        toastWindow?.orderFront(nil)
    }
    
    func hideToastWindow() {
        toastWindow?.orderOut(nil)
        toastWindow = nil
    }
    
    func showWindow() {
        // Method for showing main application window if needed
        // This can be expanded based on your app's main window requirements
    }
    
    // MARK: - Private Methods
    
    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            // Handle clicks outside windows if needed
            // This can be used for closing popovers or other UI elements
        }
        eventMonitor?.start()
    }
    
    private func cleanup() {
        eventMonitor?.stop()
        eventMonitor = nil
        
        recordingWindow?.orderOut(nil)
        recordingWindow = nil
        
        idleRecordingWindow?.orderOut(nil)
        idleRecordingWindow = nil
        
        toastWindow?.orderOut(nil)
        toastWindow = nil
    }
}

// MARK: - Event Monitor

class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
} 