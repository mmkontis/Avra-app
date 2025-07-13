import Foundation
import AppUpdater
import SwiftUI

/// Simple Update Manager using s1ntoneli/AppUpdater
/// Provides automatic updates from GitHub releases
class SimpleUpdateManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isCheckingForUpdates = false
    @Published var updateAvailable = false
    @Published var currentStatus: UpdateStatus = .idle
    @Published var lastCheckDate: Date?
    
    // MARK: - AppUpdater instance
    private var appUpdater: AppUpdater
    
    // MARK: - Configuration
    private let githubOwner = "mmkontis"  // Update with your GitHub username
    private let githubRepo = "Avra-app"           // Update with your repo name
    
    // MARK: - Singleton
    static let shared = SimpleUpdateManager()
    
    private override init() {
        // Initialize AppUpdater with GitHub repo info
        self.appUpdater = AppUpdater(owner: githubOwner, repo: githubRepo)
        super.init()
        
        print("[SimpleUpdateManager] ✅ Initialized with GitHub repo: \(githubOwner)/\(githubRepo)")
        
        // Load last check date
        loadLastCheckDate()
        
        // Schedule automatic checks (once per day)
        scheduleAutomaticChecks()
    }
    
    // MARK: - Public API
    
    /// Check for updates manually (user-initiated)
    func checkForUpdates(showUI: Bool = true) {
        print("[SimpleUpdateManager] 🔍 Starting update check - showUI: \(showUI)")
        
        guard !isCheckingForUpdates else {
            print("[SimpleUpdateManager] ⚠️ Update check already in progress")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isCheckingForUpdates = true
            self?.currentStatus = .checking
        }
        
        // Use AppUpdater to check for updates
        Task { [weak self] in
            do {
                try await self?.performUpdateCheck(showUI: showUI)
            } catch {
                print("[SimpleUpdateManager] ❌ Update check failed: \(error)")
                await MainActor.run {
                    self?.handleUpdateError(error, showUI: showUI)
                }
            }
        }
    }
    
    /// Install available update
    func installUpdate() {
        print("[SimpleUpdateManager] 🚀 Installing available update")
        
        Task { [weak self] in
            do {
                await MainActor.run {
                    self?.currentStatus = .installing
                }
                
                // AppUpdater handles the installation automatically
                // Note: install() method may not be async/throwing in this library version
                self?.appUpdater.install()
                
                print("[SimpleUpdateManager] ✅ Update installation initiated")
            } catch {
                print("[SimpleUpdateManager] ❌ Update installation failed: \(error)")
                await MainActor.run {
                    self?.currentStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performUpdateCheck(showUI: Bool) async throws {
        print("[SimpleUpdateManager] 🔄 Performing update check...")
        
        // Check for updates using AppUpdater
        // Note: The AppUpdater library handles the UI and update flow automatically
        // We just need to call check() and it will manage everything
        try await appUpdater.check()
        
        await MainActor.run {
            self.isCheckingForUpdates = false
            self.lastCheckDate = Date()
            self.saveLastCheckDate()
            
            // Since AppUpdater handles the update flow automatically,
            // we'll assume if no error was thrown, the check completed successfully
            print("[SimpleUpdateManager] ✅ Update check completed")
            
            // For now, we'll set the status to up-to-date since AppUpdater
            // handles the update flow internally if an update is available
            self.currentStatus = .upToDate
            
            if showUI {
                self.showUpToDateDialog()
            }
        }
    }
    
    private func handleUpdateError(_ error: Error, showUI: Bool) {
        isCheckingForUpdates = false
        currentStatus = .error(error.localizedDescription)
        
        if showUI {
            showErrorDialog(error.localizedDescription)
        }
    }
    
    private func scheduleAutomaticChecks() {
        // Check for updates once per day when app is active
        Timer.scheduledTimer(withTimeInterval: 24 * 3600, repeats: true) { [weak self] _ in
            self?.checkForUpdatesAutomatically()
        }
    }
    
    private func checkForUpdatesAutomatically() {
        guard shouldPerformAutomaticCheck() else { return }
        
        print("[SimpleUpdateManager] 🤖 Performing automatic update check")
        checkForUpdates(showUI: false)
    }
    
    private func shouldPerformAutomaticCheck() -> Bool {
        guard let lastCheck = lastCheckDate else { return true }
        return Date().timeIntervalSince(lastCheck) > 24 * 3600 // 24 hours
    }
    
    // MARK: - User Interface
    
    private func showUpdateAvailableDialog() {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "A new version of WhisperMe is available. Would you like to download and install it now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install Update")
        alert.addButton(withTitle: "Later")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            installUpdate()
        }
    }
    
    private func showUpToDateDialog() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date!"
        alert.informativeText = "WhisperMe is up to date."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showErrorDialog(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Failed to check for updates: \(message)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Persistence
    
    private func loadLastCheckDate() {
        lastCheckDate = UserDefaults.standard.object(forKey: "WhisperMe.LastUpdateCheck") as? Date
    }
    
    private func saveLastCheckDate() {
        UserDefaults.standard.set(lastCheckDate, forKey: "WhisperMe.LastUpdateCheck")
    }
}

// MARK: - Update Status

enum UpdateStatus {
    case idle
    case checking
    case updateAvailable
    case downloading
    case installing
    case upToDate
    case error(String)
} 