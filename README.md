# WhisperMe

A macOS menu bar app that records audio and transcribes it using OpenAI's Whisper API with automatic text pasting.

## Features

- **Menu Bar Integration**: Lives in your menu bar for easy access
- **Hotkey Recording**: Press and hold F1 to record audio
- **Floating Recording Window**: Visual feedback during recording
- **Automatic Transcription**: Uses OpenAI's Whisper API
- **Auto-Paste**: Automatically pastes transcribed text to any text field
- **Real-time Audio Levels**: Visual feedback during recording

## Requirements

- macOS 15.5 or later
- Xcode 16.0 or later
- Swift 5.0 or later
- OpenAI API key

## Setup

1. **Get an OpenAI API Key**
   - Sign up at [OpenAI](https://platform.openai.com/)
   - Generate an API key from your account dashboard
   - Replace the API key in `ContentView.swift` (line ~165) with your own key

2. **Important**: The API key in the code is for demonstration only. Never commit real API keys to version control.

## Building and Running

### Using Xcode

1. Open `whisperme.xcodeproj` in Xcode
2. Select your target device (Mac)
3. Press `Cmd+R` to build and run

### Using Command Line

```bash
# Build the project
xcodebuild -scheme whisperme -configuration Debug build

# Run the app
open ~/Library/Developer/Xcode/DerivedData/whisperme-*/Build/Products/Debug/whisperme.app
```

## Usage

1. **Launch**: The app appears as a microphone icon in your menu bar
2. **Grant Permissions**: Allow microphone and accessibility access when prompted
3. **Record**: Press and hold the **F1 key** to start recording
4. **Visual Feedback**: A floating window shows recording status and audio levels
5. **Stop & Transcribe**: Release F1 to stop recording and start transcription
6. **Auto-Paste**: Text is automatically pasted into the currently selected text field

### Menu Bar Features

- Click the menu bar icon to see options
- View recording instructions
- Quit the application

## Permissions

The app requires the following permissions:

- **Microphone Access**: For recording audio
  - `NSMicrophoneUsageDescription` in Info.plist
  - `com.apple.security.device.audio-input` entitlement
- **Network Access**: For OpenAI API calls
  - `com.apple.security.network.client` entitlement
- **Accessibility Access**: For automatic text pasting (system prompt)

## Project Structure

- `whispermeApp.swift` - Menu bar app setup, hotkey handling, and auto-paste functionality
- `ContentView.swift` - Audio recording logic and OpenAI Whisper integration
- `Info.plist` - App configuration including microphone usage description
- `whisperme.entitlements` - App sandbox, microphone, and network entitlements

## How It Works

1. **Menu Bar**: Uses `NSStatusItem` to create a menu bar presence
2. **Global Hotkey**: Monitors F1 key press/release events globally
3. **Recording**: Uses `AVAudioEngine` to capture audio when F1 is held
4. **Floating Window**: Shows a borderless recording window with visual feedback
5. **Transcription**: Sends audio to OpenAI's Whisper API
6. **Auto-Paste**: Uses `CGEvent` to simulate Cmd+V for automatic pasting

## Hotkey Configuration

- **Default**: F1 key (virtual key code 122)
- **Customization**: Modify `setupGlobalHotkey()` in `whispermeApp.swift` to change the key
- **Alternative Keys**: You can change to other function keys (F2=120, F3=99, etc.)

## Security Notes

- **API Key Security**: For production apps, store API keys securely using:
  - Environment variables
  - macOS Keychain
  - Secure configuration files (not in version control)
- **Accessibility**: The app needs accessibility permissions to paste text automatically
- Never commit API keys to Git repositories

## Troubleshooting

### Hotkey Not Working
- Ensure F1 is not being used by other applications
- Check System Preferences > Keyboard > Function Keys settings
- Try running the app with administrator privileges

### Accessibility Issues
- Go to System Preferences > Security & Privacy > Privacy > Accessibility
- Add WhisperMe to the list of allowed applications

### Network Errors
If you see "server with the specified hostname could not be found":
- Check your internet connection
- Verify the API key is valid
- Ensure network entitlement is enabled

### Compilation Errors in Xcode
If you see errors in Xcode:
1. Clean the build folder (`Cmd+Shift+K`)
2. Close and reopen Xcode
3. Delete derived data if needed

The project builds successfully from the command line even if Xcode shows false positive errors. # Avra-app
# Avra-app
