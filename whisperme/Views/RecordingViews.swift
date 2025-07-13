import SwiftUI

// MARK: - Recording View Components

// Main recording view container
struct RecordingView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var animationTimer: Timer?
    
    var body: some View {
        ZStack {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Group {
                if viewModel.isRecording {
                    ActiveRecordingView(viewModel: viewModel)
                } else if viewModel.isTranscribing {
                    TranscribingView(recordingMode: viewModel.currentRecordingMode)
                } else {
                    IdleRecordingView(recordingMode: viewModel.currentRecordingMode)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Active recording state view with proper dynamic volume visualization
struct ActiveRecordingView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var barHeights: [CGFloat] = Array(repeating: 2, count: 15)
    @State private var animationTimer: Timer?
    
    var body: some View {
        HStack(spacing: 2) {
            // Recording dot
            Circle()
                .fill(backgroundColorForMode(viewModel.currentRecordingMode))
                .frame(width: 10, height: 10)
                .opacity(0.8 + (CGFloat(viewModel.audioLevel) * 0.2))
                .scaleEffect(1.0 + (CGFloat(viewModel.audioLevel) * 0.3))
                .animation(.easeInOut(duration: 0.1), value: viewModel.audioLevel)
            
            Spacer().frame(width: 4)
            
            // Dynamic volume bars
            HStack(spacing: 1.5) {
                ForEach(0..<15, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 2.5, height: barHeights[index])
                        .animation(.easeInOut(duration: 0.08), value: barHeights[index])
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(backgroundColorForMode(viewModel.currentRecordingMode).opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(backgroundColorForMode(viewModel.currentRecordingMode).opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: backgroundColorForMode(viewModel.currentRecordingMode).opacity(0.25), radius: 8, x: 0, y: 3)
        .padding(10)  // Add padding to prevent shadow cropping
        .onAppear {
            startVolumeAnimation()
        }
        .onDisappear {
            stopVolumeAnimation()
        }
    }
    
    private func startVolumeAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            updateBarHeights()
        }
    }
    
    private func stopVolumeAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateBarHeights() {
        let audioLevel = CGFloat(viewModel.audioLevel)
        
        // Create more realistic volume visualization
        for i in 0..<barHeights.count {
            // Each bar has different sensitivity and decay
            let sensitivity = 1.0 - (CGFloat(abs(i - 7)) / 10.0) // Center bars more sensitive
            let randomVariation = CGFloat.random(in: 0.7...1.3) // Add natural variation
            
            // Calculate target height based on audio level
            let baseHeight: CGFloat = 2
            let maxHeight: CGFloat = 18
            let targetHeight = baseHeight + (audioLevel * sensitivity * randomVariation * (maxHeight - baseHeight))
            
            // Smooth interpolation towards target
            let currentHeight = barHeights[i]
            let difference = targetHeight - currentHeight
            barHeights[i] = currentHeight + (difference * 0.6) // Smooth follow
            
            // Ensure minimum and maximum bounds
            barHeights[i] = max(baseHeight, min(maxHeight, barHeights[i]))
        }
    }
}

// Volume bars view (simplified for when needed)
struct VolumeBarView: View {
    let audioLevel: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.25)
                    .fill(Color.white)
                    .frame(width: 3, height: CGFloat(2 + audioLevel * 16))
                    .animation(.easeInOut(duration: 0.1), value: audioLevel)
            }
        }
        .frame(width: 70, height: 22)
    }
}

// Recording background view
struct RecordingBackgroundView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.blue.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.blue.opacity(0.4), lineWidth: 1)
            )
    }
}

// Recording dot view
struct RecordingDotView: View {
    let audioLevel: Float
    
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 8, height: 8)
            .position(x: 15, y: 11)
            .opacity(0.9)
            .scaleEffect(1.0 + (CGFloat(audioLevel) * 0.2))
            .animation(.easeInOut(duration: 0.1), value: audioLevel)
    }
}

// Transcribing state view with loading animation
struct TranscribingView: View {
    let recordingMode: RecordingMode
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 2) {
            // Blue dot with circular loader
            ZStack {
                // Colored dot in center based on recording mode
                Circle()
                    .fill(backgroundColorForMode(recordingMode))
                    .frame(width: 10, height: 10)
                    .opacity(0.9)
                
                // White circular loader
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.white.opacity(0), .white.opacity(0.9)],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            Spacer().frame(width: 4)
            
            // Three animated dots instead of bars
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 3, height: 3)
                        .opacity(0.3)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                        .opacity(isAnimating ? 1.0 : 0.3)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(backgroundColorForMode(recordingMode).opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(backgroundColorForMode(recordingMode).opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: backgroundColorForMode(recordingMode).opacity(0.25), radius: 8, x: 0, y: 3)
        .padding(10)  // Add padding to prevent shadow cropping
        .onAppear {
            isAnimating = true
        }
    }
}

// Idle recording state view
struct IdleRecordingView: View {
    let recordingMode: RecordingMode
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
            )
            .frame(width: 60, height: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: backgroundColorForMode(recordingMode).opacity(0.15), radius: 6, x: 0, y: 3)
            .padding(10)  // Add padding to prevent shadow cropping
    }
}

// MARK: - Compact Chat View

struct CompactChatView: View {
    @ObservedObject var viewModel: ContentViewModel
    weak var recordingWindow: RecordingWindow?
    @State private var chatInput: String = ""
    @State private var showBubbles = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Transparent message bubbles above the input
            if showBubbles {
                VStack(spacing: 3) {
                    if !viewModel.conversationHistory.isEmpty {
                        // Show conversation history (last 3 messages for space)
                        let recentMessages = Array(viewModel.conversationHistory.suffix(3))
                        ForEach(recentMessages.indices, id: \.self) { index in
                            let message = recentMessages[index]
                            TransparentChatBubble(
                                text: message.content,
                                isUser: message.role == "user",
                                mode: viewModel.currentRecordingMode
                            )
                        }
                    } else if chatInput.isEmpty {
                        // Show placeholder message when no input and no conversation history
                        PlaceholderChatBubble()
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.8)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
            
            // Compact input bar
            HStack(spacing: 6) {
                // Status indicator (very small)
                statusIndicator
                
                // Input field (more compact)
                inputField
                
                // Send button (only show if there's text)
                if !chatInput.isEmpty {
                    sendButton
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.2), value: !chatInput.isEmpty)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(inputBackground)
            .shadow(color: backgroundColorForMode(viewModel.currentRecordingMode).opacity(0.3), radius: 6, x: 0, y: 2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThickMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.2))
                )
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).delay(0.15)) {
                showBubbles = true
            }
            // Auto-focus the text field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .onDisappear {
            showBubbles = false
            isTextFieldFocused = false
        }
    }
    
    private func sendMessage() {
        guard !chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Send the message via the view model
        let message = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.sendChatMessage(message)
        
        // Clear the input
        chatInput = ""
        
        // Keep focus on the input field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
    }
    
    private var statusIndicator: some View {
        Group {
            if viewModel.isRecording {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 5, height: 5)
                    .opacity(0.8 + (CGFloat(viewModel.audioLevel) * 0.2))
                    .scaleEffect(1.0 + (CGFloat(viewModel.audioLevel) * 0.3))
                    .animation(.easeInOut(duration: 0.1), value: viewModel.audioLevel)
            } else if viewModel.isTranscribing {
                ProgressView()
                    .scaleEffect(0.4)
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
            } else {
                Circle()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: 5, height: 5)
            }
        }
    }
    
    private var inputField: some View {
        TextField("Type message...", text: $chatInput)
            .textFieldStyle(PlainTextFieldStyle())
            .focused($isTextFieldFocused)
            .onSubmit {
                sendMessage()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.yellow.opacity(0.6), lineWidth: 0.5)
                    )
            )
            .foregroundColor(.white)
            .font(.caption2)
    }
    
    private var sendButton: some View {
        Button(action: {
            sendMessage()
        }) {
            Image(systemName: "paperplane.fill")
                .foregroundColor(Color.yellow.opacity(0.9))
                .font(.system(size: 10))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.thickMaterial)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
            )
    }
}

struct TransparentChatBubble: View {
    let text: String
    let isUser: Bool
    let mode: RecordingMode
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
            }
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.thickMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.yellow.opacity(0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.yellow.opacity(0.6), lineWidth: 0.8)
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                .frame(maxWidth: 200, alignment: isUser ? .trailing : .leading)
            
            if !isUser {
                Spacer()
            }
        }
    }
}

struct PlaceholderChatBubble: View {
    @State private var isBlinking = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 10))
                    .foregroundColor(Color.yellow.opacity(0.8))
                
                Text("Chat mode active • Type a message")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.thickMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 0.8)
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
            .opacity(isBlinking ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isBlinking)
            .onAppear {
                isBlinking = true
            }
            
            Spacer()
        }
        .frame(maxWidth: 200, alignment: .leading)
    }
}

struct ChatBubble: View {
    let text: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser {
                Spacer()
            }
            
            Text(text)
                .font(.caption)
                .foregroundColor(isUser ? .black : .white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isUser ? Color.white.opacity(0.9) : Color.white.opacity(0.2))
                )
                .frame(maxWidth: 200, alignment: isUser ? .trailing : .leading)
            
            if !isUser {
                Spacer()
            }
        }
    }
}

// MARK: - Helper Functions

func backgroundColorForMode(_ mode: RecordingMode) -> Color {
    switch mode {
    case .transcription:
        return .blue
    case .chatCompletion:
        return .yellow
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RecordingView(viewModel: ContentViewModel())
        ActiveRecordingView(viewModel: ContentViewModel())
        TranscribingView(recordingMode: .transcription)
        IdleRecordingView(recordingMode: .chatCompletion)
    }
    .frame(width: 300, height: 400)
} 