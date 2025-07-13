import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showingSettings = false
    let onRestart: () -> Void
    let onCheckForUpdates: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with status and controls
            HeaderView(viewModel: viewModel, showingSettings: $showingSettings)
            
            Divider()
                .padding(.horizontal, 12)
            
            // Main content area
            MainContentView(viewModel: viewModel)
            
            Divider()
                .padding(.horizontal, 12)
            
            // Quick Settings
            QuickSettingsView(viewModel: viewModel)
            
            // Footer with function calls if enabled
            if viewModel.enableFunctions && !viewModel.functionCalls.isEmpty {
                Divider()
                    .padding(.horizontal, 12)
                
                FunctionCallsView(viewModel: viewModel)
            }
            
            Divider()
                .padding(.horizontal, 12)
            
            // Version and Update section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Version \(getVersionString())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Check for Updates") {
                        checkForUpdates()
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Quit") {
                        quitApp()
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 380)
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showingSettings) {
            SettingsView(viewModel: viewModel)
                .frame(width: 500, height: 600)
        }
    }
    
    // MARK: - Helper Functions
    private func getVersionString() -> String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    private func checkForUpdates() {
        NSLog("[MenuBarView] Check for Updates button clicked")
        onCheckForUpdates()
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Header View
struct HeaderView: View {
    @ObservedObject var viewModel: ContentViewModel
    @Binding var showingSettings: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Avra")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.bottom, 2)
            if let email = viewModel.userEmail, !email.isEmpty {
                Text("Welcome, \(email)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚠️ Login Required")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                    
                    Button(action: {
                        if let url = URL(string: "https://hireavra.com/connect") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("Connect / Login")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}



// MARK: - Main Content View
struct MainContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.isUserAuthenticated() {
                // Show login requirement message
                VStack(alignment: .leading, spacing: 4) {
                    Text("🔒 Login Required")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Text("Please log in to use recording features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.isRecording {
                Text("Recording \(viewModel.currentRecordingMode.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else {
                Text("Ready to Record")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Hold Fn for transcription")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Hold Fn + Shift for chat")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}



// MARK: - Quick Settings View
struct QuickSettingsView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(spacing: 6) {
                // Model Selection
                HStack {
                    Text("Model:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Picker("Model", selection: $viewModel.selectedModel) {
                        Text("whisper-1").tag("whisper-1")
                        Text("gpt-4o-transcribe").tag("gpt-4o-transcribe")
                    }
                    .pickerStyle(.menu)
                    .font(.caption)
                    .frame(maxWidth: 120)
                }
                
                // Language Selection
                HStack {
                    Text("Language:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Picker("Language", selection: $viewModel.selectedLanguage) {
                        Text("Auto").tag("auto")
                        Text("EN").tag("en")
                        Text("ES").tag("es")
                        Text("FR").tag("fr")
                        Text("DE").tag("de")
                        Text("IT").tag("it")
                        Text("PT").tag("pt")
                        Text("RU").tag("ru")
                        Text("JA").tag("ja")
                        Text("KO").tag("ko")
                        Text("ZH").tag("zh")
                        Text("AR").tag("ar")
                        Text("HI").tag("hi")
                        Text("EL").tag("el")
                    }
                    .pickerStyle(.menu)
                    .font(.caption)
                    .frame(maxWidth: 120)
                }
                
                // Key Toggles
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Chat Mode", isOn: $viewModel.chatModeEnabled)
                        .font(.caption)
                    Toggle("Translation", isOn: $viewModel.translationEnabled)
                        .font(.caption)
                    Toggle("Privacy Mode", isOn: $viewModel.privacyModeEnabled)
                        .font(.caption)
                    Toggle("Functions", isOn: $viewModel.enableFunctions)
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Function Calls View
struct FunctionCallsView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Function Calls")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.functionCalls.suffix(3), id: \.id) { functionCall in
                        FunctionCallRow(functionCall: functionCall)
                    }
                }
            }
            .frame(maxHeight: 120)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Function Call Row
struct FunctionCallRow: View {
    let functionCall: FunctionCall
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(functionCall.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("(\(functionCall.status))")
                    .font(.caption2)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "hide" : "show")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    if !functionCall.argumentsDisplay.isEmpty {
                        Text("Arguments: \(functionCall.argumentsDisplay)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let result = functionCall.result, !result.isEmpty {
                        Text("Result: \(result)")
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    private var statusColor: Color {
        switch functionCall.status {
        case "completed":
            return .green
        case "failed":
            return .red
        case "executing":
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    MenuBarView(viewModel: ContentViewModel(), onRestart: {}, onCheckForUpdates: {})
        .frame(width: 380, height: 400)
} 