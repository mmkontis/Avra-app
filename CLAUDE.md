# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WhisperMe (also called "Avra") is a macOS menu bar application for voice transcription and AI chat completion. The project consists of three main components:

1. **macOS Swift App** (`whisperme/`) - Native SwiftUI menu bar app with hotkey recording
2. **Python Backend** (`whisperme-python/`) - FastAPI server for transcription and chat completion
3. **Next.js Web App** (`whisperme-nextapp/`) - Web interface for user management

## Build Commands

### macOS App

**Development Build & Install:**
```bash
./build_and_install.sh
```
This script builds the Xcode project, installs to /Applications, and launches the app.

**Build Only (via Xcode CLI):**
```bash
xcodebuild -scheme whisperme -configuration Release -workspace whisperme.xcodeproj/project.xcworkspace -destination "platform=macOS,arch=arm64" clean build
```

**Create Distribution DMG:**
```bash
./create_custom_dmg.sh
```
Requires `create-dmg` tool and builds a distributable installer.

### Python Backend

**Development Server:**
```bash
cd whisperme-python
uv run uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Testing:**
```bash
cd whisperme-python
python test_backend.py
```

### Next.js Web App

**Development Server:**
```bash
cd whisperme-nextapp
npm run dev
```

**Production Build:**
```bash
cd whisperme-nextapp
npm run build
npm start
```

**Linting:**
```bash
cd whisperme-nextapp
npm run lint
```

## Architecture

### macOS App Architecture

The Swift app follows MVVM pattern with these key components:

- **whispermeApp.swift** - Main app entry point, global hotkey handling (Fn key), window management
- **StatusBarManager.swift** - Menu bar icon management, context menu with recording options
- **ContentView.swift** - Main UI and view model containing recording logic
- **AudioService.swift** - AVFoundation-based audio recording service
- **APIService.swift** - HTTP client for backend communication
- **HotkeyManager.swift** - Global hotkey detection system
- **WindowManager.swift** - Floating recording window management

**Key Features:**
- Fn key press/hold for quick transcription recording
- Fn+Shift for chat completion recording
- Menu bar integration with comprehensive settings
- Real-time audio level visualization
- Automatic text pasting via accessibility APIs

### Python Backend Architecture

FastAPI-based backend with these endpoints:

- `/transcribe` - Audio transcription using OpenAI Whisper API
- `/chat` - Chat completion with optional function calling
- `/functions` - Available function definitions
- `/transcriptions` - Database operations for transcription history

**Key Components:**
- Supabase PostgreSQL database integration
- OpenAI API integration (Whisper + GPT models)
- Multipart form handling for audio uploads
- Function calling system for enhanced AI capabilities

### Database Schema

Uses Supabase PostgreSQL with these main tables:
- `users` - macOS app device-based authentication
- `web_users` - Web app email/password authentication
- `transcriptions` - Transcription history and metadata

## Configuration

### Environment Variables

**Python Backend (.env in whisperme-python/):**
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key
- `OPENAI_API_KEY` - OpenAI API key

**Next.js App (.env.local in whisperme-nextapp/):**
- `NEXT_PUBLIC_SUPABASE_URL` - Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Supabase anonymous key

### Key Files

- `whisperme/Info.plist` - macOS app configuration, permissions, versioning
- `whisperme/whisperme.entitlements` - Sandbox and capability settings
- `whisperme-python/config.py` - Backend configuration management
- `supabase/config.toml` - Supabase project configuration

## Development Workflow

1. **Setting up Backend**: Run the Python backend first for API endpoints
2. **macOS App Development**: Use Xcode or command line builds, requires backend running
3. **Web App Development**: Independent Next.js development server
4. **Database Changes**: Use Supabase migrations in `supabase/migrations/`

## Key Hotkeys & UI

- **Fn Key**: Press and hold for quick transcription recording
- **Fn + Shift**: Press and hold for chat completion recording
- **Menu Bar Click**: Access all settings and options
- **Recording Window**: Floating borderless window with real-time audio visualization

## Update System

The app includes a robust OTA (Over-The-Air) update system:
- **RobustUpdateManager.swift** - Comprehensive update manager with atomic updates
- **Background Downloads** - Non-blocking downloads with progress tracking
- **Update Channels** - Support for Stable and Beta channels
- **Atomic Installation** - Guarantees app never left in broken state
- **Signature Verification** - Security verification of updates (framework ready)
- **User Control** - Users control update timing and preferences
- **Test Infrastructure** - Complete testing framework with mock server

### Testing the Update System:
```bash
# Start test server
python3 test_update_server.py

# Run automated tests
./test_update_system.sh

# Manual testing
# 1. Launch WhisperMe
# 2. Click menu bar icon → "Check for Updates"
# 3. Test download and installation process
```

## Testing

- **Backend**: `python test_backend.py` in whisperme-python/
- **macOS App**: Built-in XCTest suite in whispermeTests/
- **Manual Testing**: Use build_and_install.sh for quick iteration

## Deployment

- **Backend**: Configured for Sevalla deployment with Docker
- **Web App**: Next.js deployment via Vercel or similar platforms
- **macOS App**: DMG distribution via create_custom_dmg.sh script