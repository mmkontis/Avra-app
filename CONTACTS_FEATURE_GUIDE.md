# 📱 WhisperMe Contacts Feature Guide

## 🎯 Overview

The WhisperMe macOS app now includes a contacts feature that allows you to send your contacts to a localhost server for logging and processing.

## 🔧 Setup

### 1. Start the Contacts Logger Server

Open Terminal and navigate to your WhisperMe project directory, then start the logger server:

```bash
# Option 1: Using the shell script
./run_contacts_logger.sh

# Option 2: Direct Python command
python3 contacts_logger.py
```

The server will start on `http://localhost:3001` and display:

```
╔══════════════════════════════════════════════════════════════╗
║                    📋 Contacts Logger Server                 ║
║                                                              ║
║   🌐 Server running on: http://localhost:3001                ║
║   📡 Endpoint: POST /contacts                                ║
║   🔍 Health check: GET /health                               ║
║                                                              ║
║   💡 Usage:                                                  ║
║   - Open WhisperMe macOS app                                 ║
║   - Click the status bar icon                                ║
║   - Click the contacts button (👥)                          ║
║   - Contacts will be logged here line by line               ║
║                                                              ║
║   ⏹️  Press Ctrl+C to stop the server                       ║
╚══════════════════════════════════════════════════════════════╝
```

### 2. Using the WhisperMe App

1. **Open WhisperMe**: Look for the 🎤 icon in your menu bar
2. **Click the menu bar icon** to open the WhisperMe popover
3. **Find the contacts button**: Look for the blue 👥 icon next to the settings gear
4. **Click the contacts button**: This will send all your contacts to the localhost server

## 📊 What Happens

When you click the contacts button:

1. **Contacts are fetched** from your macOS Contacts app (requires permission)
2. **Data is sent** to `http://localhost:3001/contacts` via HTTP POST
3. **Server logs each contact** line by line in the terminal
4. **Toast notification** appears in WhisperMe showing success/failure

## 📋 Contact Data Format

Each contact includes:
- **First Name**
- **Last Name** 
- **Display Name** (formatted)
- **Phone Number** (raw)
- **Formatted Phone Number** (display-friendly)

## 📝 Example Server Output

```
============================================================
📋 CONTACTS RECEIVED at 2025-07-08 17:05:23
📊 Total contacts: 3
============================================================
  1. 👤 John Smith
     📞 (555) 123-4567
     📝 John Smith
     🔢 Raw: +15551234567
     ────────────────────────────────────────
  2. 👤 Jane Doe  
     📞 (555) 987-6543
     📝 Jane Doe
     🔢 Raw: 5559876543
     ────────────────────────────────────────
  3. 👤 Bob Johnson
     📞 (555) 555-0123
     📝 Bob Johnson  
     🔢 Raw: (555) 555-0123
     ────────────────────────────────────────
✅ Successfully logged 3 contacts
============================================================
```

## 🔒 Privacy & Permissions

- **Contacts Permission**: WhisperMe will request access to your contacts on first use
- **Local Processing**: All data is sent to your local server only (`localhost:3001`)
- **No Cloud Upload**: Contacts are never sent to external servers
- **User Control**: You choose when to send contacts by clicking the button

## 🛠️ Troubleshooting

### Server Not Running
- **Error**: "Failed to send contacts: Could not connect to the server"
- **Solution**: Make sure the contacts logger server is running on port 3001

### No Contacts Permission
- **Error**: "No contacts to send"
- **Solution**: Grant contacts permission in System Settings > Privacy & Security > Contacts

### Port Already in Use
- **Error**: Server fails to start on port 3001
- **Solution**: Use a different port: `python3 contacts_logger.py 3002`
- **Note**: Update the port in MenuBarView.swift if you change it

## 🧪 Testing

1. **Health Check**: Visit `http://localhost:3001/health` in your browser
2. **Manual Test**: Use the contacts button in WhisperMe
3. **Check Logs**: Monitor the terminal running the server

## 🔄 Stopping the Server

Press `Ctrl+C` in the terminal where the server is running:

```
🛑 Server stopped by user
👋 Contacts Logger Server stopped.
```

## 📂 Files Created

- `contacts_logger.py` - Python server script
- `run_contacts_logger.sh` - Shell script to start the server
- Updated `whisperme/Views/MenuBarView.swift` - Added contacts button

## 🎯 Use Cases

- **Development**: Test contact integration features
- **Backup**: Log contacts for local backup purposes  
- **Integration**: Prepare contact data for other applications
- **Debugging**: Monitor contact access and formatting 