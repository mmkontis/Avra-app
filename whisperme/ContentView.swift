//
//  ContentView.swift
//  whisperme
//
//  Created by Minas marios kontis on 2/6/25.
//

import SwiftUI
import AVFoundation



struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Whisper Transcription")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Audio level indicator
            if viewModel.isRecording {
                VStack {
                    Text("Audio Level")
                        .font(.headline)
                    ProgressView(value: viewModel.audioLevel, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 20)
                    Text(String(format: "Level: %.2f", viewModel.audioLevel))
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Status message
            Text(viewModel.permissionStatusMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Control buttons
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.startRecording()
                }) {
                    Label("Start Recording", systemImage: "mic.fill")
                        .frame(width: 150)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isRecording || viewModel.isTranscribing)
                
                Button(action: {
                    viewModel.stopRecording()
                }) {
                    Label("Stop Recording", systemImage: "stop.fill")
                        .frame(width: 150)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.isRecording)
            }
            
            // Transcription result
            if viewModel.isTranscribing {
                ProgressView("Transcribing...")
                    .padding()
            } else if !viewModel.transcriptionText.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Transcription:")
                        .font(.headline)
                    ScrollView {
                        Text(viewModel.transcriptionText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .frame(maxHeight: 200)
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            viewModel.checkPermissionAndSetup()
        }
    }
}

#Preview {
    ContentView()
}
