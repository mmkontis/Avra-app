import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "gear")
                    .font(.title2)
                    .foregroundColor(.primary)
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Model Selection
                    ModelSelectionSection(viewModel: viewModel)
                    
                    // Language Selection
                    LanguageSelectionSection(viewModel: viewModel)
                    
                    // Translation Settings
                    TranslationSettingsSection(viewModel: viewModel)
                    
                    // Privacy Settings
                    PrivacySettingsSection(viewModel: viewModel)
                    
                    // Function Settings
                    FunctionSettingsSection(viewModel: viewModel)
                    
                    // Update Settings
                    UpdateSettingsSection()
                    
                    // Advanced Settings
                    AdvancedSettingsSection(viewModel: viewModel)
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 450, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Model Selection Section
struct ModelSelectionSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Model Selection", systemImage: "cpu")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(viewModel.availableModels, id: \.code) { model in
                    HStack {
                        Button(action: {
                            viewModel.selectedModel = model.code
                        }) {
                            HStack {
                                Image(systemName: viewModel.selectedModel == model.code ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.selectedModel == model.code ? .blue : .gray)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text(model.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(viewModel.selectedModel == model.code ? Color.blue.opacity(0.1) : Color.clear)
                                    .stroke(viewModel.selectedModel == model.code ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .onChange(of: viewModel.selectedModel) { _ in
            viewModel.saveUserPreferences()
        }
    }
}

// MARK: - Language Selection Section
struct LanguageSelectionSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Language Selection", systemImage: "globe")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Language", selection: $viewModel.selectedLanguage) {
                ForEach(viewModel.supportedLanguages, id: \.code) { language in
                    Text(language.name).tag(language.code)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: viewModel.selectedLanguage) { _ in
                viewModel.saveUserPreferences()
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Translation Settings Section
struct TranslationSettingsSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Translation", systemImage: "translate")
                .font(.headline)
                .foregroundColor(.primary)
            
            Toggle("Enable Translation", isOn: $viewModel.translationEnabled)
                .onChange(of: viewModel.translationEnabled) { _ in
                    viewModel.saveUserPreferences()
                }
            
            if viewModel.translationEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Language")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Picker("Translation Language", selection: $viewModel.selectedTranslationLanguage) {
                        ForEach(viewModel.translationLanguages, id: \.code) { language in
                            Text(language.name).tag(language.code)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: viewModel.selectedTranslationLanguage) { _ in
                        viewModel.saveUserPreferences()
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Privacy Settings Section
struct PrivacySettingsSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Privacy & Security", systemImage: "lock.shield")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Privacy Mode", isOn: $viewModel.privacyModeEnabled)
                    .onChange(of: viewModel.privacyModeEnabled) { _ in
                        viewModel.saveUserPreferences()
                    }
                
                if !viewModel.privacyModeEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Real-time Preview", isOn: $viewModel.realTimePreviewEnabled)
                            .onChange(of: viewModel.realTimePreviewEnabled) { _ in
                                viewModel.saveUserPreferences()
                            }
                        
                        Text("Show transcription in real-time while recording")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Function Settings Section
struct FunctionSettingsSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Function Calling", systemImage: "function")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Function Calls", isOn: $viewModel.enableFunctions)
                    .onChange(of: viewModel.enableFunctions) { _ in
                        viewModel.saveUserPreferences()
                    }
                
                if viewModel.enableFunctions {
                    Text("Allows the AI to call functions like weather, web search, time, and calculator")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Advanced Settings Section
struct AdvancedSettingsSection: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Advanced", systemImage: "gearshape.2")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Auto-start on Login", isOn: $viewModel.autoStartEnabled)
                    .onChange(of: viewModel.autoStartEnabled) { _ in
                        viewModel.saveUserPreferences()
                        viewModel.toggleAutoStart()
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Prompt")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $viewModel.customPrompt)
                        .frame(height: 60)
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: viewModel.customPrompt) { _ in
                            viewModel.saveUserPreferences()
                        }
                    
                    Text("Additional instructions for the AI transcription")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Update Settings Section
struct UpdateSettingsSection: View {
    @ObservedObject private var updateManager = SimpleUpdateManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Updates", systemImage: "arrow.down.circle")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                // Status
                HStack {
                    Text("Status:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(statusColor)
                }
                
                // Last Check
                if let lastCheck = updateManager.lastCheckDate {
                    HStack {
                        Text("Last checked:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDate(lastCheck))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // App Info
                HStack {
                    Text("Update Source:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("GitHub Releases")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Check Button
                Button(action: {
                    let message = "[SettingsView] ✅ Check for Updates button clicked!"
                    print(message)
                    NSLog(message)
                    
                    updateManager.checkForUpdates(showUI: true)
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Check for Updates")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(updateManager.isCheckingForUpdates)
                
                // Install button (when update is available)
                if updateManager.updateAvailable {
                    Button(action: {
                        print("[SettingsView] Installing available update...")
                        updateManager.installUpdate()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Install Update")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private var statusText: String {
        switch updateManager.currentStatus {
        case .idle:
            return "Ready"
        case .checking:
            return "Checking..."
        case .updateAvailable:
            return "Update available"
        case .downloading:
            return "Downloading..."
        case .installing:
            return "Installing..."
        case .upToDate:
            return "Up to date"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var statusColor: Color {
        switch updateManager.currentStatus {
        case .upToDate:
            return .green
        case .updateAvailable:
            return .orange
        case .error(_):
            return .red
        default:
            return .secondary
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    SettingsView(viewModel: ContentViewModel())
        .frame(width: 450, height: 600)
} 