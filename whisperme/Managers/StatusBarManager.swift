import SwiftUI
import AppKit

class StatusBarManager: ObservableObject {
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    
    weak var viewModel: ContentViewModel?
    
    // MARK: - Callbacks
    
    var onRestart: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        createStatusItem()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    func setViewModel(_ viewModel: ContentViewModel) {
        self.viewModel = viewModel
        updateStatusItemContent()
        createMenu()
    }
    
    func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusItem = statusItem {
            // Use text instead of icon
            statusItem.button?.title = "Avra"
            statusItem.button?.image = nil  // Remove any icon
            
            // Set tooltip
            statusItem.button?.toolTip = "Avra - Voice Transcription"
            
            print("[StatusBarManager] Status item created with text")
        }
    }
    
    private func createMenu() {
        guard let viewModel = viewModel else { return }
        
        menu = NSMenu()
        
        // Recording Controls
        let recordingSection = NSMenuItem(title: "Recording Options", action: nil, keyEquivalent: "")
        recordingSection.isEnabled = false
        menu?.addItem(recordingSection)
        
        // Quick Record
        let quickRecordItem = NSMenuItem(title: "Quick Record (⌘R)", action: #selector(quickRecord), keyEquivalent: "r")
        quickRecordItem.target = self
        menu?.addItem(quickRecordItem)
        
        // Chat Completion Record
        let chatRecordItem = NSMenuItem(title: "Chat Record (⌘C)", action: #selector(chatRecord), keyEquivalent: "c")
        chatRecordItem.target = self
        menu?.addItem(chatRecordItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Model Selection
        let modelSection = NSMenuItem(title: "Model", action: nil, keyEquivalent: "")
        modelSection.isEnabled = false
        menu?.addItem(modelSection)
        
        // Available models
        let models = ["whisper-1", "gpt-4o-transcribe"]
        for model in models {
            let modelItem = NSMenuItem(title: model, action: #selector(selectModel(_:)), keyEquivalent: "")
            modelItem.target = self
            modelItem.representedObject = model
            modelItem.state = (model == viewModel.selectedModel) ? .on : .off
            menu?.addItem(modelItem)
        }
        
        menu?.addItem(NSMenuItem.separator())
        
        // Language Selection
        let languageSection = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        languageSection.isEnabled = false
        menu?.addItem(languageSection)
        
        let languages = ["auto", "en", "es", "fr", "de", "it", "pt", "ru", "ja", "ko", "zh", "ar", "hi", "el"]
        for language in languages {
            let languageItem = NSMenuItem(title: language == "auto" ? "Auto Detect" : language.uppercased(), action: #selector(selectLanguage(_:)), keyEquivalent: "")
            languageItem.target = self
            languageItem.representedObject = language
            languageItem.state = (language == viewModel.selectedLanguage) ? .on : .off
            menu?.addItem(languageItem)
        }
        
        menu?.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsSection = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsSection.isEnabled = false
        menu?.addItem(settingsSection)
        
        // Translation toggle
        let translationItem = NSMenuItem(title: "Translation", action: #selector(toggleTranslation), keyEquivalent: "")
        translationItem.target = self
        translationItem.state = viewModel.translationEnabled ? .on : .off
        menu?.addItem(translationItem)
        
        // Privacy mode toggle
        let privacyItem = NSMenuItem(title: "Privacy Mode", action: #selector(togglePrivacyMode), keyEquivalent: "")
        privacyItem.target = self
        privacyItem.state = viewModel.privacyModeEnabled ? .on : .off
        menu?.addItem(privacyItem)
        
        // Real-time preview toggle
        let previewItem = NSMenuItem(title: "Real-time Preview", action: #selector(togglePreview), keyEquivalent: "")
        previewItem.target = self
        previewItem.state = viewModel.realTimePreviewEnabled ? .on : .off
        menu?.addItem(previewItem)
        
        // Functions toggle
        let functionsItem = NSMenuItem(title: "Functions", action: #selector(toggleFunctions), keyEquivalent: "")
        functionsItem.target = self
        functionsItem.state = viewModel.enableFunctions ? .on : .off
        menu?.addItem(functionsItem)
        
        // Auto-start toggle
        let autoStartItem = NSMenuItem(title: "Auto-start", action: #selector(toggleAutoStart), keyEquivalent: "")
        autoStartItem.target = self
        autoStartItem.state = viewModel.autoStartEnabled ? .on : .off
        menu?.addItem(autoStartItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Version info
        let versionString = getVersionString()
        let versionItem = NSMenuItem(title: "Version \(versionString)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu?.addItem(versionItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        // Action items
        let showMainWindowItem = NSMenuItem(title: "Show Main Window", action: #selector(showMainWindow), keyEquivalent: "")
        showMainWindowItem.target = self
        menu?.addItem(showMainWindowItem)
        
        let checkForUpdatesItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        checkForUpdatesItem.target = self
        menu?.addItem(checkForUpdatesItem)
        
        let restartItem = NSMenuItem(title: "Restart", action: #selector(restart), keyEquivalent: "")
        restartItem.target = self
        menu?.addItem(restartItem)
        
        let quitItem = NSMenuItem(title: "Quit Avra", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
        print("[StatusBarManager] Menu created with all options")
    }
    
    // MARK: - Menu Actions
    
    @objc private func quickRecord() {
        viewModel?.currentRecordingMode = .transcription
        viewModel?.startRecording()
    }
    
    @objc private func chatRecord() {
        viewModel?.currentRecordingMode = .chatCompletion
        viewModel?.startRecording()
    }
    
    @objc private func selectModel(_ sender: NSMenuItem) {
        guard let model = sender.representedObject as? String else { return }
        viewModel?.selectedModel = model
        createMenu() // Refresh menu to update checkmarks
    }
    
    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let language = sender.representedObject as? String else { return }
        viewModel?.selectedLanguage = language
        createMenu() // Refresh menu to update checkmarks
    }
    
    @objc private func toggleTranslation() {
        viewModel?.translationEnabled.toggle()
        createMenu() // Refresh menu to update checkmarks
    }
    
    @objc private func togglePrivacyMode() {
        viewModel?.privacyModeEnabled.toggle()
        createMenu() // Refresh menu to update checkmarks
    }
    
    @objc private func togglePreview() {
        viewModel?.realTimePreviewEnabled.toggle()
        createMenu() // Refresh menu to update checkmarks
    }
    
    @objc private func toggleFunctions() {
        viewModel?.enableFunctions.toggle()
        createMenu() // Refresh menu to update checkmarks
    }
    
    @objc private func toggleAutoStart() {
        viewModel?.autoStartEnabled.toggle()
        createMenu() // Refresh menu to update checkmarks
    }
    
    @objc private func showMainWindow() {
        // Show the main window
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func checkForUpdates() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.checkForUpdates()
        }
    }
    
    @objc private func restart() {
        onRestart?()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func updateStatusItemIcon(isRecording: Bool, recordingMode: RecordingMode) {
        guard let statusItem = statusItem else { return }
        
        // Update text based on recording state
        if isRecording {
            switch recordingMode {
            case .transcription:
                statusItem.button?.title = "Recording..."
            case .chatCompletion:
                statusItem.button?.title = "Chat Recording..."
            }
        } else {
            statusItem.button?.title = "Avra"
        }
        
        // Remove any icon
        statusItem.button?.image = nil
        statusItem.button?.alphaValue = 1.0
        
        print("[StatusBarManager] ✅ Updated text (recording: \(isRecording))")
    }
    
    func updateStatusItemTooltip(isRecording: Bool, recordingMode: RecordingMode) {
        guard let statusItem = statusItem else { return }
        
        let tooltip: String
        if isRecording {
            switch recordingMode {
            case .transcription:
                tooltip = "Avra - Recording for Transcription"
            case .chatCompletion:
                tooltip = "Avra - Recording for Chat Completion"
            }
        } else {
            tooltip = "Avra - Ready • Click for options • Fn to record • Fn+Shift for chat"
        }
        
        statusItem.button?.toolTip = tooltip
    }
    
    // MARK: - Private Methods
    
    private func getVersionString() -> String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    private func updateStatusItemContent() {
        guard let viewModel = viewModel else { return }
        
        updateStatusItemIcon(isRecording: viewModel.isRecording, recordingMode: viewModel.currentRecordingMode)
        updateStatusItemTooltip(isRecording: viewModel.isRecording, recordingMode: viewModel.currentRecordingMode)
        
        // Refresh menu when content updates
        createMenu()
    }
    
    private func cleanup() {
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
            print("[StatusBarManager] Status item removed")
        }
        
        menu?.removeAllItems()
        menu = nil
    }
} 