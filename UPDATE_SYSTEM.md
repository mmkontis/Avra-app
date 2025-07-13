# WhisperMe Update System

WhisperMe now uses a modern, simplified update system based on **s1ntoneli/AppUpdater** and **release-it** for automated releases. This provides seamless automatic updates via GitHub releases.

## Overview

The new update system consists of:

1. **s1ntoneli/AppUpdater** - Swift library for automatic app updates from GitHub releases
2. **release-it** - npm tool for automated version management and GitHub releases
3. **GitHub Actions** - CI/CD for automated release builds
4. **SimpleUpdateManager** - Simplified Swift update manager replacing the complex RobustUpdateManager

## Key Benefits

- ✅ **Simplified**: Much simpler than the previous custom update system
- ✅ **Reliable**: Uses proven open-source libraries
- ✅ **Automatic**: Fully automated release process
- ✅ **Secure**: Code signing verification built into AppUpdater
- ✅ **GitHub Native**: Uses GitHub releases as the distribution mechanism
- ✅ **Maintenance-Free**: No custom server infrastructure needed

## How It Works

### For Users
1. WhisperMe automatically checks for updates daily
2. When an update is available, users see a dialog asking if they want to install
3. AppUpdater downloads and installs the update seamlessly
4. The app restarts with the new version

### For Developers
1. Make changes and commit with conventional commit messages
2. Run `./release.sh` or `npm run release` to create a new release
3. release-it builds the app, packages it, and creates a GitHub release
4. AppUpdater in distributed apps will detect the new release automatically

## File Structure

```
whisperme/
├── package.json                    # release-it configuration
├── release.sh                      # Interactive release script
├── package_for_distribution.sh     # Creates AppUpdater-compatible ZIP files
├── .github/workflows/release.yml   # GitHub Actions for automated releases
├── whisperme/Services/
│   └── SimpleUpdateManager.swift   # New simplified update manager
└── UPDATE_SYSTEM.md                # This documentation
```

## AppUpdater Requirements

AppUpdater requires specific naming conventions for release assets:

- **Asset naming**: `{app-name}-{version}-{arch}.zip`
- **Example**: `whisperme-1.0.3-arm64.zip`
- **GitHub release tag**: `v{version}` (e.g., `v1.0.3`)

## Configuration

### package.json
Contains release-it configuration:

```json
{
  "release-it": {
    "git": {
      "commitMessage": "chore: release v${version}",
      "tagName": "v${version}"
    },
    "github": {
      "release": true,
      "releaseName": "WhisperMe v${version}",
      "assets": ["whisperme-${version}-arm64.zip"]
    },
    "hooks": {
      "before:github:release": "./package_for_distribution.sh ${version}"
    }
  }
}
```

### SimpleUpdateManager.swift
Key configuration:

```swift
private let githubOwner = "minasmarioskontis"  // Your GitHub username
private let githubRepo = "whisperme"           // Your repo name
```

## Release Process

### Option 1: Interactive Release (Recommended)

```bash
./release.sh
```

This script will:
1. Show current version
2. Ask what type of release (patch/minor/major)
3. Build the app
4. Package it correctly for AppUpdater
5. Create GitHub release with the asset

### Option 2: Command Line Release

```bash
# Install dependencies (first time only)
npm install

# Patch release (1.0.1 → 1.0.2)
npm run release -- patch

# Minor release (1.0.1 → 1.1.0)
npm run release -- minor

# Major release (1.0.1 → 2.0.0)
npm run release -- major

# Custom version
npm run release -- 1.2.3

# Dry run (see what would happen)
npm run release -- --dry-run
```

### Option 3: GitHub Actions (Automated)

Push a tag or use the GitHub Actions workflow dispatch:

```bash
git tag v1.0.3
git push origin v1.0.3
```

## Environment Setup

### Required Tools
- **Node.js 18+** for release-it
- **Xcode** for building the macOS app
- **GitHub CLI** (optional, for manual releases)

### Environment Variables
- `GITHUB_TOKEN` - Personal access token for GitHub API (for releases)

### First Time Setup

1. Install Node.js and npm:
   ```bash
   # Install Node.js from https://nodejs.org/
   # Or using Homebrew:
   brew install node
   ```

2. Install project dependencies:
   ```bash
   npm install
   ```

3. Set up GitHub token (optional, for GitHub releases):
   ```bash
   export GITHUB_TOKEN="your_github_personal_access_token"
   ```

## Testing the Update System

### Local Testing

1. **Build and install current version**:
   ```bash
   ./build_and_install.sh
   ```

2. **Create a test release**:
   ```bash
   ./release.sh
   # Choose "5" for dry run to test without creating actual release
   ```

3. **Test update checking**:
   - Open WhisperMe
   - Go to Settings → Updates
   - Click "Check for Updates"

### End-to-End Testing

1. **Create a real release** with a higher version number
2. **Install an older version** of WhisperMe
3. **Run the app** and check for updates
4. **Verify** the update is detected and can be installed

## Troubleshooting

### Common Issues

**"AppUpdater module not found"**
- Make sure Xcode has resolved the Swift Package dependencies
- Try: Product → Clean Build Folder, then rebuild

**"No updates found" when update should be available**
- Check GitHub release has the correctly named ZIP asset
- Verify the release is not marked as "Draft"
- Check GitHub repo owner/name in SimpleUpdateManager.swift

**Release script fails**
- Ensure Node.js and npm are installed
- Run `npm install` to install dependencies
- Check that GITHUB_TOKEN is set if creating GitHub releases

**Build fails during release**
- Ensure Xcode project builds successfully with `./build_and_install.sh`
- Check that all Swift dependencies are resolved

### Debug Logging

The SimpleUpdateManager provides extensive logging:

```bash
# View logs in Console.app, filter by "SimpleUpdateManager"
# Or check Xcode debug console for real-time logs
```

## Migration from Old System

The migration has already been completed:

✅ **Removed**:
- RobustUpdateManager.swift (complex custom update system)
- UpdateSettingsView.swift (complex update settings)
- All custom update test scripts and servers
- Sparkle framework dependency

✅ **Added**:
- s1ntoneli/AppUpdater Swift package
- SimpleUpdateManager.swift
- release-it npm package and configuration
- GitHub Actions workflow
- Simplified update settings in SettingsView

✅ **Updated**:
- App delegate to use SimpleUpdateManager
- Settings view with simplified update controls
- Package scripts for AppUpdater compatibility

## Security Considerations

- **Code Signing**: AppUpdater verifies code signatures before installing
- **HTTPS**: All downloads happen over HTTPS via GitHub
- **Integrity**: GitHub provides checksums and integrity verification
- **Permissions**: Updates require user approval (non-silent)

## Future Enhancements

Possible future improvements:
- [ ] Beta release channel support
- [ ] Delta updates (only download changes)
- [ ] Custom release notes display
- [ ] Update scheduling (install at app quit)
- [ ] Rollback mechanism for failed updates

## Support

For issues with the update system:

1. **Check logs** in Console.app (filter: "SimpleUpdateManager")
2. **Verify GitHub releases** have correct asset naming
3. **Test with dry run** using `./release.sh`
4. **Check AppUpdater documentation**: https://github.com/s1ntoneli/AppUpdater
5. **Check release-it documentation**: https://github.com/release-it/release-it 