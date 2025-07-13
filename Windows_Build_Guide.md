# Building WhisperMe for Windows

This guide explains how to create a Windows version of the WhisperMe voice transcription app, which allows users to hold a key (like Fn) to record audio and automatically transcribe it using OpenAI's Whisper API.

## Technology Stack Options

### Option 1: Electron + Node.js (Recommended for Cross-Platform)
- **Pros**: Cross-platform, web technologies, large ecosystem
- **Cons**: Larger memory footprint
- **Best for**: Teams familiar with JavaScript/TypeScript

### Option 2: .NET WPF/WinUI 3 (Native Windows)
- **Pros**: Native performance, smaller footprint, Windows integration
- **Cons**: Windows-only
- **Best for**: Windows-specific deployment

### Option 3: Tauri + Rust (Modern Alternative)
- **Pros**: Small bundle size, fast performance, web frontend
- **Cons**: Newer ecosystem, learning curve
- **Best for**: Performance-critical applications

## Implementation Guide: Electron Version

### 1. Project Setup

```bash
# Initialize project
npm init -y
npm install electron electron-builder
npm install --save-dev @types/node typescript

# Audio processing
npm install node-record-lpcm16 speaker
npm install @types/node-record-lpcm16

# UI Framework (choose one)
npm install react react-dom @types/react @types/react-dom
# OR
npm install vue @vue/cli-service
```

### 2. Main Process (main.js)

```javascript
const { app, BrowserWindow, globalShortcut, ipcMain } = require('electron');
const path = require('path');
const recorder = require('node-record-lpcm16');
const fs = require('fs');

class WhisperMeApp {
  constructor() {
    this.mainWindow = null;
    this.overlayWindow = null;
    this.isRecording = false;
    this.audioStream = null;
  }

  createMainWindow() {
    this.mainWindow = new BrowserWindow({
      width: 400,
      height: 300,
      show: false, // Hidden by default
      webPreferences: {
        nodeIntegration: true,
        contextIsolation: false
      }
    });
  }

  createOverlayWindow() {
    this.overlayWindow = new BrowserWindow({
      width: 280,
      height: 80,
      frame: false,
      transparent: true,
      alwaysOnTop: true,
      skipTaskbar: true,
      resizable: false,
      show: false,
      webPreferences: {
        nodeIntegration: true,
        contextIsolation: false
      }
    });

    // Position at bottom center
    const { screen } = require('electron');
    const primaryDisplay = screen.getPrimaryDisplay();
    const { width, height } = primaryDisplay.workAreaSize;
    
    this.overlayWindow.setPosition(
      Math.round((width - 280) / 2),
      height - 150
    );

    this.overlayWindow.loadFile('overlay.html');
  }

  setupGlobalHotkeys() {
    // Register Fn key (or alternative like F24)
    globalShortcut.register('F24', () => {
      if (!this.isRecording) {
        this.startRecording();
      }
    });

    // Handle key release (you might need a different approach)
    globalShortcut.register('F23', () => {
      if (this.isRecording) {
        this.stopRecording();
      }
    });
  }

  startRecording() {
    this.isRecording = true;
    this.overlayWindow.show();
    this.overlayWindow.webContents.send('recording-started');

    // Start audio recording
    this.audioStream = recorder.record({
      sampleRate: 16000,
      channels: 1,
      audioType: 'wav'
    });

    const audioChunks = [];
    this.audioStream.stream().on('data', (chunk) => {
      audioChunks.push(chunk);
      // Send audio level for visualization
      const audioLevel = this.calculateAudioLevel(chunk);
      this.overlayWindow.webContents.send('audio-level', audioLevel);
    });

    this.audioChunks = audioChunks;
  }

  stopRecording() {
    if (!this.isRecording) return;
    
    this.isRecording = false;
    this.overlayWindow.webContents.send('recording-stopped');
    
    if (this.audioStream) {
      this.audioStream.stop();
      
      // Save audio file
      const audioBuffer = Buffer.concat(this.audioChunks);
      const audioPath = path.join(__dirname, 'temp_recording.wav');
      fs.writeFileSync(audioPath, audioBuffer);
      
      // Transcribe
      this.transcribeAudio(audioPath);
    }
  }

  calculateAudioLevel(chunk) {
    // Simple RMS calculation
    let sum = 0;
    for (let i = 0; i < chunk.length; i += 2) {
      const sample = chunk.readInt16LE(i);
      sum += sample * sample;
    }
    const rms = Math.sqrt(sum / (chunk.length / 2));
    return Math.min(rms / 32768, 1.0); // Normalize to 0-1
  }

  async transcribeAudio(audioPath) {
    this.overlayWindow.webContents.send('transcribing-started');
    
    try {
      const FormData = require('form-data');
      const axios = require('axios');
      
      const form = new FormData();
      form.append('file', fs.createReadStream(audioPath));
      form.append('model', 'whisper-1');
      
      const response = await axios.post(
        'https://api.openai.com/v1/audio/transcriptions',
        form,
        {
          headers: {
            ...form.getHeaders(),
            'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
          }
        }
      );
      
      const transcription = response.data.text;
      this.pasteText(transcription);
      
    } catch (error) {
      console.error('Transcription error:', error);
    } finally {
      // Clean up
      fs.unlinkSync(audioPath);
      setTimeout(() => {
        this.overlayWindow.hide();
      }, 500);
    }
  }

  pasteText(text) {
    const { clipboard } = require('electron');
    const robot = require('robotjs');
    
    // Copy to clipboard
    clipboard.writeText(text);
    
    // Simulate Ctrl+V
    robot.keyTap('v', 'control');
  }
}

// App initialization
app.whenReady().then(() => {
  const whisperApp = new WhisperMeApp();
  whisperApp.createMainWindow();
  whisperApp.createOverlayWindow();
  whisperApp.setupGlobalHotkeys();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
```

### 3. Overlay UI (overlay.html)

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      margin: 0;
      padding: 0;
      background: transparent;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    }
    
    .overlay {
      display: flex;
      align-items: center;
      padding: 12px 16px;
      background: rgba(0, 0, 0, 0.85);
      border-radius: 30px;
      box-shadow: 0 10px 20px rgba(0, 0, 0, 0.3);
      gap: 8px;
    }
    
    .overlay.idle {
      width: 200px;
      height: 30px;
      background: rgba(0, 0, 0, 0.6);
      border-radius: 15px;
    }
    
    .recording-dot {
      width: 12px;
      height: 12px;
      background: #007AFF;
      border-radius: 50%;
      opacity: 0.6;
    }
    
    .recording-dot.active {
      opacity: 1;
      animation: pulse 0.6s ease-in-out infinite alternate;
    }
    
    .waveform {
      display: flex;
      gap: 2px;
      height: 35px;
      align-items: end;
    }
    
    .waveform-bar {
      width: 3px;
      background: rgba(255, 255, 255, 0.8);
      border-radius: 2px;
      transition: height 0.1s ease;
      min-height: 5px;
    }
    
    @keyframes pulse {
      from { transform: scale(1); }
      to { transform: scale(1.2); }
    }
  </style>
</head>
<body>
  <div id="overlay" class="overlay idle">
    <div id="recording-dot" class="recording-dot"></div>
    <div id="waveform" class="waveform"></div>
  </div>

  <script>
    const { ipcRenderer } = require('electron');
    
    const overlay = document.getElementById('overlay');
    const recordingDot = document.getElementById('recording-dot');
    const waveform = document.getElementById('waveform');
    
    // Create waveform bars
    const barCount = 15;
    for (let i = 0; i < barCount; i++) {
      const bar = document.createElement('div');
      bar.className = 'waveform-bar';
      bar.style.height = '5px';
      waveform.appendChild(bar);
    }
    
    const bars = document.querySelectorAll('.waveform-bar');
    let audioLevels = new Array(barCount).fill(0);
    
    ipcRenderer.on('recording-started', () => {
      overlay.classList.remove('idle');
      recordingDot.classList.add('active');
    });
    
    ipcRenderer.on('recording-stopped', () => {
      recordingDot.classList.remove('active');
    });
    
    ipcRenderer.on('transcribing-started', () => {
      // Gentle pulsing animation
      animateTranscribing();
    });
    
    ipcRenderer.on('audio-level', (event, level) => {
      updateWaveform(level);
    });
    
    function updateWaveform(audioLevel) {
      // Shift array left
      audioLevels.shift();
      audioLevels.push(audioLevel * 2.5); // Sensitivity
      
      // Update bars
      bars.forEach((bar, index) => {
        const height = Math.max(5, audioLevels[index] * 30);
        bar.style.height = `${height}px`;
      });
    }
    
    function animateTranscribing() {
      let frame = 0;
      const animate = () => {
        bars.forEach((bar, index) => {
          const phase = index * 0.8 + frame * 0.2;
          const height = 15 + 10 * Math.sin(phase);
          bar.style.height = `${height}px`;
        });
        frame++;
        
        if (frame < 100) { // Continue for a while
          requestAnimationFrame(animate);
        }
      };
      animate();
    }
  </script>
</body>
</html>
```

### 4. Package Configuration (package.json)

```json
{
  "name": "whisperme-windows",
  "version": "1.0.0",
  "main": "main.js",
  "scripts": {
    "start": "electron .",
    "build": "electron-builder",
    "build-win": "electron-builder --win"
  },
  "build": {
    "appId": "com.yourcompany.whisperme",
    "productName": "WhisperMe",
    "directories": {
      "output": "dist"
    },
    "win": {
      "target": "nsis",
      "icon": "assets/icon.ico"
    },
    "nsis": {
      "oneClick": false,
      "allowToChangeInstallationDirectory": true
    }
  }
}
```

## Implementation Guide: .NET WPF Version

### 1. Project Setup

```xml
<!-- WhisperMe.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net6.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageReference Include="NAudio" Version="2.1.0" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
    <PackageReference Include="System.Windows.Forms" Version="6.0.0" />
  </ItemGroup>
</Project>
```

### 2. Main Application Class

```csharp
using System;
using System.Windows;
using System.Windows.Forms;
using NAudio.Wave;
using System.Runtime.InteropServices;

namespace WhisperMe
{
    public partial class App : System.Windows.Application
    {
        private GlobalKeyboardHook keyboardHook;
        private OverlayWindow overlayWindow;
        private AudioRecorder audioRecorder;
        
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);
            
            // Hide main window, run in system tray
            this.ShutdownMode = ShutdownMode.OnExplicitShutdown;
            
            SetupSystemTray();
            SetupGlobalHotkeys();
            SetupOverlay();
            SetupAudioRecorder();
        }
        
        private void SetupGlobalHotkeys()
        {
            keyboardHook = new GlobalKeyboardHook();
            keyboardHook.KeyDown += OnGlobalKeyDown;
            keyboardHook.KeyUp += OnGlobalKeyUp;
        }
        
        private void OnGlobalKeyDown(object sender, Keys key)
        {
            if (key == Keys.F24) // Map to your desired key
            {
                audioRecorder.StartRecording();
                overlayWindow.ShowRecording();
            }
        }
        
        private void OnGlobalKeyUp(object sender, Keys key)
        {
            if (key == Keys.F24)
            {
                audioRecorder.StopRecording();
            }
        }
    }
}
```

### 3. Audio Recording Class

```csharp
using NAudio.Wave;
using System;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;

public class AudioRecorder
{
    private WaveInEvent waveIn;
    private WaveFileWriter writer;
    private string tempFilePath;
    
    public event Action<float> AudioLevelChanged;
    public event Action<string> TranscriptionCompleted;
    
    public void StartRecording()
    {
        tempFilePath = Path.GetTempFileName() + ".wav";
        
        waveIn = new WaveInEvent();
        waveIn.WaveFormat = new WaveFormat(16000, 1);
        waveIn.DataAvailable += OnDataAvailable;
        waveIn.RecordingStopped += OnRecordingStopped;
        
        writer = new WaveFileWriter(tempFilePath, waveIn.WaveFormat);
        waveIn.StartRecording();
    }
    
    public void StopRecording()
    {
        waveIn?.StopRecording();
    }
    
    private void OnDataAvailable(object sender, WaveInEventArgs e)
    {
        writer.Write(e.Buffer, 0, e.BytesRecorded);
        
        // Calculate audio level
        float level = CalculateAudioLevel(e.Buffer, e.BytesRecorded);
        AudioLevelChanged?.Invoke(level);
    }
    
    private void OnRecordingStopped(object sender, StoppedEventArgs e)
    {
        writer?.Dispose();
        waveIn?.Dispose();
        
        _ = TranscribeAudioAsync(tempFilePath);
    }
    
    private float CalculateAudioLevel(byte[] buffer, int bytesRecorded)
    {
        float sum = 0;
        for (int i = 0; i < bytesRecorded; i += 2)
        {
            short sample = BitConverter.ToInt16(buffer, i);
            sum += sample * sample;
        }
        float rms = (float)Math.Sqrt(sum / (bytesRecorded / 2));
        return Math.Min(rms / 32768f, 1.0f);
    }
    
    private async Task TranscribeAudioAsync(string audioPath)
    {
        try
        {
            using var client = new HttpClient();
            using var form = new MultipartFormDataContent();
            
            var audioContent = new ByteArrayContent(File.ReadAllBytes(audioPath));
            audioContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("audio/wav");
            
            form.Add(audioContent, "file", "audio.wav");
            form.Add(new StringContent("whisper-1"), "model");
            
            client.DefaultRequestHeaders.Authorization = 
                new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", "YOUR_API_KEY");
            
            var response = await client.PostAsync("https://api.openai.com/v1/audio/transcriptions", form);
            var json = await response.Content.ReadAsStringAsync();
            
            var result = Newtonsoft.Json.JsonConvert.DeserializeObject<dynamic>(json);
            string transcription = result.text;
            
            TranscriptionCompleted?.Invoke(transcription);
        }
        finally
        {
            File.Delete(audioPath);
        }
    }
}
```

## Key Considerations for Windows

### 1. Global Hotkey Handling
- Use `RegisterHotKey` Win32 API or libraries like `GlobalKeyboardHook`
- Consider alternative keys since Fn key behavior varies by manufacturer
- Handle key combinations (Ctrl+Shift+Space, etc.)

### 2. Audio Permissions
- Request microphone permissions in app manifest
- Handle Windows privacy settings gracefully
- Provide clear error messages for permission issues

### 3. System Integration
- Create system tray icon for easy access
- Auto-start with Windows (registry or startup folder)
- Handle Windows sleep/wake events

### 4. Deployment
- Code signing certificate for Windows Defender
- NSIS or WiX installer for professional deployment
- Consider Microsoft Store distribution

### 5. Performance Optimization
- Use efficient audio processing (NAudio for .NET)
- Minimize memory usage during recording
- Handle large audio files gracefully

## Security Considerations

1. **API Key Management**: Store OpenAI API key securely (Windows Credential Manager)
2. **Audio Data**: Ensure temporary files are properly deleted
3. **Network Security**: Validate SSL certificates for API calls
4. **User Privacy**: Clear audio data handling policies

## Testing Strategy

1. **Audio Quality**: Test with various microphones and noise levels
2. **Hotkey Conflicts**: Test with common applications
3. **Performance**: Monitor CPU/memory usage during recording
4. **Edge Cases**: Handle network failures, API rate limits
5. **Accessibility**: Ensure compatibility with screen readers

## Distribution Options

1. **Direct Download**: Simple installer from website
2. **Microsoft Store**: Broader reach, automatic updates
3. **Package Managers**: Chocolatey, winget
4. **Enterprise**: MSI packages for corporate deployment

This guide provides a solid foundation for building a Windows version of WhisperMe. Choose the technology stack that best fits your team's expertise and deployment requirements. 