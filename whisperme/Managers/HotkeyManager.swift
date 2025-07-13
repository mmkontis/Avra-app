import Foundation
import AppKit
import IOKit

class HotkeyManager: ObservableObject {
    // MARK: - Properties
    
    private var fnKeyMonitor: Any?
    private var shiftKeyMonitor: Any?
    private var cancelKeyMonitor: Any?
    private var cancelKeyMonitorLocal: Any?
    private var fnCurrentlyPressed = false
    private var shiftCurrentlyPressed = false
    private var bothKeysWerePressed = false
    private var lockedRecordingMode: RecordingMode?
    private var isRecordingActive = false
    
    weak var viewModel: ContentViewModel?
    weak var windowManager: WindowManager?
    
    // MARK: - Callbacks
    
    var onStartRecording: (() -> Void)?
    var onStopRecording: (() -> Void)?
    var onCancelRecording: (() -> Void)?
    var onRecordingModeChange: ((RecordingMode) -> Void)?
    
    // MARK: - Initialization
    
    init() {
        setupGlobalHotkey()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    func setViewModel(_ viewModel: ContentViewModel) {
        self.viewModel = viewModel
    }
    
    func setWindowManager(_ windowManager: WindowManager) {
        self.windowManager = windowManager
    }
    
    func setupGlobalHotkey() {
        // Monitor Fn key (key code 63)
        fnKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.handleFnKeyEvent(event)
        }
        
        // Monitor Shift key (key code 56 for left shift, 60 for right shift)
        shiftKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.handleShiftKeyEvent(event)
        }
        
        // Monitor any key press for canceling during recording/transcription
        // Use both local and global monitors for better coverage
        cancelKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleCancelKeyEvent(event)
        }
        
        cancelKeyMonitorLocal = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleCancelKeyEvent(event)
            return event  // Pass through the event
        }
        
        print("[HotkeyManager] Global hotkey monitoring started")
    }
    
    func cleanup() {
        cleanupGlobalEventMonitors()
    }
    
    // MARK: - Private Methods
    
    private func handleFnKeyEvent(_ event: NSEvent) {
        let fnKeyCode: UInt16 = 63
        
        if event.keyCode == fnKeyCode {
            let fnPressed = event.modifierFlags.contains(.function)
            
            if fnPressed && !fnCurrentlyPressed {
                // Fn key pressed
                fnCurrentlyPressed = true
                print("[HotkeyManager] Fn key pressed")
                
                // Check if both keys are now pressed
                if shiftCurrentlyPressed && (viewModel?.chatModeEnabled ?? false) {
                    bothKeysWerePressed = true
                    lockedRecordingMode = .chatCompletion
                    viewModel?.currentRecordingMode = .chatCompletion
                    onRecordingModeChange?(.chatCompletion)
                    print("[HotkeyManager] Both keys pressed - chat completion mode (locked)")
                } else {
                    // Only Fn pressed - transcription mode (or chat mode disabled)
                    lockedRecordingMode = .transcription
                    viewModel?.currentRecordingMode = .transcription
                    onRecordingModeChange?(.transcription)
                    print("[HotkeyManager] Fn only - transcription mode (locked)")
                }
                
                // Start recording
                isRecordingActive = true
                onStartRecording?()
                
            } else if !fnPressed && fnCurrentlyPressed {
                // Fn key released
                fnCurrentlyPressed = false
                print("[HotkeyManager] Fn key released")
                
                // If both keys were pressed together, only stop when both are released
                if bothKeysWerePressed {
                    if !shiftCurrentlyPressed {
                        // Both keys have been released
                        bothKeysWerePressed = false
                        lockedRecordingMode = nil
                        isRecordingActive = false
                        onStopRecording?()
                        print("[HotkeyManager] Both keys released - stopping recording")
                    } else {
                        // Shift still pressed, continue recording - keep locked mode
                        if let locked = lockedRecordingMode {
                            viewModel?.currentRecordingMode = locked
                            onRecordingModeChange?(locked)
                            print("[HotkeyManager] Fn released but Shift still pressed - maintaining locked mode: \(String(describing: locked))")
                        }
                    }
                } else {
                    // Only Fn was pressed, stop recording
                    lockedRecordingMode = nil
                    isRecordingActive = false
                    onStopRecording?()
                    print("[HotkeyManager] Fn only released - stopping recording")
                }
            }
        }
    }
    
    private func handleShiftKeyEvent(_ event: NSEvent) {
        let leftShiftKeyCode: UInt16 = 56
        let rightShiftKeyCode: UInt16 = 60
        
        if event.keyCode == leftShiftKeyCode || event.keyCode == rightShiftKeyCode {
            let shiftPressed = event.modifierFlags.contains(.shift)
            
            if shiftPressed && !shiftCurrentlyPressed {
                // Shift key pressed
                shiftCurrentlyPressed = true
                print("[HotkeyManager] Shift key pressed")
                
                // If Fn is already pressed and chat mode is enabled, mark that both keys are pressed and switch to chat completion mode
                if fnCurrentlyPressed && (viewModel?.chatModeEnabled ?? false) {
                    bothKeysWerePressed = true
                    lockedRecordingMode = .chatCompletion
                    viewModel?.currentRecordingMode = .chatCompletion
                    onRecordingModeChange?(.chatCompletion)
                    print("[HotkeyManager] Both keys pressed - switched to chat completion mode (locked)")
                }
                // Note: Shift alone no longer starts recording - only Fn or Fn+Shift combinations
                
            } else if !shiftPressed && shiftCurrentlyPressed {
                // Shift key released
                shiftCurrentlyPressed = false
                print("[HotkeyManager] Shift key released")
                
                // If both keys were pressed together, only stop when both are released
                if bothKeysWerePressed {
                    if !fnCurrentlyPressed {
                        // Both keys have been released
                        bothKeysWerePressed = false
                        lockedRecordingMode = nil
                        isRecordingActive = false
                        onStopRecording?()
                        print("[HotkeyManager] Both keys released - stopping recording")
                    } else {
                        // Fn still pressed, continue recording - KEEP THE LOCKED MODE
                        if let locked = lockedRecordingMode {
                            viewModel?.currentRecordingMode = locked
                            onRecordingModeChange?(locked)
                            print("[HotkeyManager] Shift released but Fn still pressed - maintaining locked mode: \(String(describing: locked))")
                        }
                    }
                } else {
                    // Only Shift was pressed (but didn't start recording since we removed that feature)
                    print("[HotkeyManager] Shift only released - no recording was active")
                }
            }
        }
    }
    
    private func handleCancelKeyEvent(_ event: NSEvent) {
        // Debug: Always log key presses to see if monitor is working
        print("[HotkeyManager] Key pressed: \(event.keyCode), recording active: \(isRecordingActive)")
        
        // Only cancel if we're currently recording or transcribing
        guard let viewModel = viewModel else { 
            print("[HotkeyManager] No viewModel available")
            return 
        }
        
        print("[HotkeyManager] ViewModel state - isRecording: \(viewModel.isRecording), isTranscribing: \(viewModel.isTranscribing)")
        
        // Check if recording is active or transcription is in progress
        if isRecordingActive || viewModel.isRecording || viewModel.isTranscribing {
            // Ignore Fn and Shift keys (they're handled by their own monitors)
            let fnKeyCode: UInt16 = 63
            let leftShiftKeyCode: UInt16 = 56
            let rightShiftKeyCode: UInt16 = 60
            
            if event.keyCode == fnKeyCode || event.keyCode == leftShiftKeyCode || event.keyCode == rightShiftKeyCode {
                print("[HotkeyManager] Ignoring Fn/Shift key")
                return
            }
            
            // Any other key cancels the recording
            print("[HotkeyManager] ✅ Cancel key pressed (keyCode: \(event.keyCode)) - canceling recording")
            
            // Reset all states
            fnCurrentlyPressed = false
            shiftCurrentlyPressed = false
            bothKeysWerePressed = false
            lockedRecordingMode = nil
            isRecordingActive = false
            
            // Trigger cancel callback
            onCancelRecording?()
        } else {
            print("[HotkeyManager] Not recording/transcribing, ignoring key press")
        }
    }
    
    private func cleanupGlobalEventMonitors() {
        if let fnMonitor = fnKeyMonitor {
            NSEvent.removeMonitor(fnMonitor)
            fnKeyMonitor = nil
            print("[HotkeyManager] Fn key monitor removed")
        }
        
        if let shiftMonitor = shiftKeyMonitor {
            NSEvent.removeMonitor(shiftMonitor)
            shiftKeyMonitor = nil
            print("[HotkeyManager] Shift key monitor removed")
        }
        
        if let cancelMonitor = cancelKeyMonitor {
            NSEvent.removeMonitor(cancelMonitor)
            cancelKeyMonitor = nil
            print("[HotkeyManager] Cancel key monitor removed")
        }
        
        if let cancelMonitorLocal = cancelKeyMonitorLocal {
            NSEvent.removeMonitor(cancelMonitorLocal)
            cancelKeyMonitorLocal = nil
            print("[HotkeyManager] Cancel key monitor (local) removed")
        }
    }
} 