import Foundation
import AVFoundation

class AudioService: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    @Published var isRecording = false
    @Published var hasPermission = false
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    // MARK: - Permissions
    func checkPermissions() {
        // On macOS, we need to request microphone permission
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            hasPermission = true
        case .denied, .restricted:
            hasPermission = false
        case .notDetermined:
            requestPermission()
        @unknown default:
            hasPermission = false
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] allowed in
            DispatchQueue.main.async {
                self?.hasPermission = allowed
            }
        }
    }
    
    // MARK: - Recording Controls
    func startRecording() -> Bool {
        guard hasPermission else {
            print("No audio recording permission")
            return false
        }
        
        guard !isRecording else {
            print("Already recording")
            return false
        }
        
        // Create temporary file for recording
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        recordingURL = tempDirectory.appendingPathComponent(fileName)
        
        guard let url = recordingURL else {
            print("Failed to create recording URL")
            return false
        }
        
        // Audio recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            let success = audioRecorder?.record() ?? false
            if success {
                isRecording = true
                print("Started recording to: \(url)")
            } else {
                print("Failed to start recording")
            }
            return success
        } catch {
            print("Failed to create audio recorder: \(error)")
            return false
        }
    }
    
    func stopRecording() -> URL? {
        guard isRecording, let recorder = audioRecorder else {
            print("Not currently recording")
            return nil
        }
        
        recorder.stop()
        isRecording = false
        
        let url = recordingURL
        recordingURL = nil
        audioRecorder = nil
        
        return url
    }
    
    // MARK: - Audio Level Monitoring
    func getAudioLevel() -> Float {
        guard let recorder = audioRecorder, isRecording else {
            return 0.0
        }
        
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedLevel = pow(10, averagePower / 20)
        return normalizedLevel
    }
    
    // MARK: - Cleanup
    func cleanup() {
        if isRecording {
            _ = stopRecording()
        }
        
        // Clean up temporary files
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Audio recording finished successfully: \(flag)")
        if !flag {
            // Recording failed, clean up
            isRecording = false
            recordingURL = nil
            audioRecorder = nil
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Audio recording encode error: \(error?.localizedDescription ?? "Unknown error")")
        isRecording = false
        recordingURL = nil
        audioRecorder = nil
    }
} 