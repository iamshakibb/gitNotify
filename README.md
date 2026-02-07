# GitNotify (Fully AI Generated)

A native macOS menu bar application that delivers GitHub notifications directly to your desktop. Built with Swift, SwiftUI, and GRDB for a smooth, native experience.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Download Release (Recommended)](#option-1-download-release-recommended)
  - [Bypass Gatekeeper](#bypass-gatekeeper-required-for-first-launch)
  - [Build from Source](#option-2-build-from-source)
  - [Using Homebrew](#option-3-using-homebrew-coming-soon)
- [Setup Guide](#setup-guide)
  - [Creating a GitHub Token](#step-1-create-a-github-personal-access-token)
  - [Connecting GitNotify](#step-2-connect-gitnotify)
  - [Configuring Settings](#step-3-configure-settings)
- [Usage](#usage)
- [Architecture](#architecture)
- [Development](#development)
- [Releasing](#releasing)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

| Feature                     | Description                                                     |
| --------------------------- | --------------------------------------------------------------- |
| **Menu Bar Integration**    | Lives in your menu bar, no dock icon clutter                    |
| **Real-time Notifications** | Get native macOS notifications when new items arrive            |
| **Smart Categorization**    | Filter by All, Mentions, Assigned/Review Requested, or Comments |
| **Configurable Polling**    | Adjust sync interval from 5 to 60 minutes                       |
| **Secure Token Storage**    | Uses macOS Keychain for secure credential storage               |
| **Offline Support**         | Local SQLite database for offline access                        |
| **Open in Browser**         | Click any notification to open directly on GitHub               |
| **Dark Mode Support**       | Automatically adapts to your system appearance                  |
| **Menu Bar Badge**          | Optional unread count badge on the menu bar icon                |
| **Multiple Icon Styles**    | Choose from Bell, Git Branch, Network, or GitHub-style icons    |
| **Launch at Login**         | Optional auto-start with macOS                                  |

## Screenshots

```
┌─────────────────────────────────────────┐
│  GitNotify                    🔄  ⚙️    │
├─────────────────────────────────────────┤
│  [All]    [@Mentions]    [💬Comments]   │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐│
│  │ 🟣 owner/repo                       ││
│  │ PR: Add new feature #123            ││
│  │ Review Requested • 2h ago     →     ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │ 🟢 org/project                      ││
│  │ Issue: Fix the critical bug #456    ││
│  │ Mentioned • 5h ago            →     ││
│  └─────────────────────────────────────┘│
├─────────────────────────────────────────┤
│  [Mark All as Read]    Updated 2m ago  │
└─────────────────────────────────────────┘
```

## Requirements

### System Requirements

| Requirement      | Version                                   |
| ---------------- | ----------------------------------------- |
| **macOS**        | 13.0 (Ventura) or later                   |
| **Architecture** | Apple Silicon (M1/M2/M3) and Intel x86_64 |

### For Building from Source

| Requirement            | Version        |
| ---------------------- | -------------- |
| **Xcode**              | 15.0 or later  |
| **Swift**              | 5.9 or later   |
| **Command Line Tools** | Latest version |

### GitHub Requirements

- GitHub account
- Personal Access Token with `notifications` scope

## Installation

### Option 1: Download Release (Recommended)

1. Go to the [Releases](https://github.com/yourusername/GitNotify/releases) page
2. Download the latest `GitNotify.dmg` file
3. Open the DMG and drag GitNotify to your Applications folder
4. **Important:** Before first launch, see [Bypass Gatekeeper](#bypass-gatekeeper-required-for-first-launch) below
5. Launch GitNotify from Applications or Spotlight

#### Bypass Gatekeeper (Required for First Launch)

This app is not notarized with Apple (requires $99/year Developer Program). macOS will show a security warning when you first try to open it. Use **one** of these methods:

**Method 1 - Terminal (Recommended):**
```bash
xattr -cr /Applications/GitNotify.app
```

**Method 2 - System Settings:**
1. Try to open the app (it will be blocked)
2. Go to **System Settings > Privacy & Security**
3. Scroll down and click **"Open Anyway"** next to the GitNotify message

**Method 3 - Right-click:**
1. Right-click (or Control-click) on GitNotify.app in Applications
2. Select **"Open"** from the context menu
3. Click **"Open"** in the dialog that appears (you may need to do this twice)

### Option 2: Build from Source

#### Prerequisites

1. **Install Xcode** from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835)

2. **Install Command Line Tools** (if not already installed):

   ```bash
   xcode-select --install
   ```

3. **Accept Xcode License**:
   ```bash
   sudo xcodebuild -license accept
   ```

#### Build Steps

1. **Clone the repository**:

   ```bash
   git clone https://github.com/yourusername/GitNotify.git
   cd GitNotify
   ```

2. **Open in Xcode**:

   ```bash
   open GitNotify/GitNotify.xcodeproj
   ```

3. **Resolve Swift Packages** (automatic):
   - Xcode will automatically fetch GRDB.swift dependency
   - Wait for "Resolving Package Graph" to complete

4. **Select Build Target**:
   - In Xcode, select `GitNotify` scheme from the scheme dropdown
   - Select `My Mac` as the run destination

5. **Build and Run**:
   - Press `Cmd + R` to build and run
   - The app will appear in your menu bar

#### Command Line Build (Alternative)

```bash
# Navigate to project directory
cd GitNotify

# Build for release
xcodebuild -project GitNotify.xcodeproj \
           -scheme GitNotify \
           -configuration Release \
           -derivedDataPath build \
           build

# The app will be at:
# build/Build/Products/Release/GitNotify.app
```

#### Creating a DMG for Distribution

```bash
# After building, create a DMG
hdiutil create -volname "GitNotify" \
               -srcfolder "build/Build/Products/Release/GitNotify.app" \
               -ov -format UDZO \
               "GitNotify.dmg"
```

### Option 3: Using Homebrew (Coming Soon)

```bash
# Will be available after release
brew install --cask gitnotify
```

## Setup Guide

### Step 1: Create a GitHub Personal Access Token

1. **Navigate to GitHub Token Settings**:
   - Direct link: [Create New Token](https://github.com/settings/tokens/new?scopes=notifications&description=GitNotify%20App)
   - Or: GitHub.com → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Configure the Token**:
   | Field | Value |
   |-------|-------|
   | **Note** | `GitNotify App` (or any descriptive name) |
   | **Expiration** | Choose based on preference (90 days, 1 year, or no expiration) |
   | **Scopes** | Check only `notifications` |

3. **Generate and Copy**:
   - Click "Generate token"
   - **Important**: Copy the token immediately - you won't see it again!

> **Security Tip**: The `notifications` scope only allows reading and managing notifications. It cannot access your code, repositories, or other sensitive data.

### Step 2: Connect GitNotify

1. **Launch GitNotify**:
   - Open from Applications folder or Spotlight
   - Look for the icon in your menu bar (top-right of screen)

2. **Click the Menu Bar Icon**:
   - A popup will appear asking for your GitHub token

3. **Enter Your Token**:
   - Paste the token you copied from GitHub
   - Click "Connect GitHub"

4. **Verify Connection**:
   - You should see "Syncing..." briefly
   - Your notifications will appear in the list

### Step 3: Configure Settings

Click the gear icon (⚙️) in the top-right of the popup to access settings:

| Setting                  | Options                           | Default    | Description                     |
| ------------------------ | --------------------------------- | ---------- | ------------------------------- |
| **Refresh Interval**     | 5, 10, 15, 20, 30, 45, 60 min     | 20 min     | How often to check GitHub       |
| **System Notifications** | On/Off                            | On         | Show macOS notification banners |
| **Menu Bar Badge**       | On/Off                            | On         | Show unread count on icon       |
| **Launch at Login**      | On/Off                            | Off        | Auto-start with macOS           |
| **Menu Bar Icon**        | Bell, Git Branch, Network, GitHub | Git Branch | Icon style                      |

### Step 4: Grant Notification Permission (if prompted)

When GitNotify first tries to send a notification:

1. macOS will ask for permission
2. Click "Allow" to receive notification banners
3. Or configure in: System Settings → Notifications → GitNotify

## Usage

### Understanding the Interface

```
┌─────────────────────────────────────────────┐
│  [Logo] GitNotify              [🔄] [⚙️]   │  ← Header with refresh and settings
├─────────────────────────────────────────────┤
│  [All]  [Mentions]  [Assigned]  [Comments]  │  ← Category filters
├─────────────────────────────────────────────┤
│                                             │
│  📋 Notification List                       │  ← Scrollable list
│                                             │
├─────────────────────────────────────────────┤
│  [Mark All as Read]     Last sync: 2m ago  │  ← Footer actions
└─────────────────────────────────────────────┘
```

### Notification Categories

| Tab          | Shows                                          | Icon |
| ------------ | ---------------------------------------------- | ---- |
| **All**      | All GitHub notifications                       | 📬   |
| **Mentions** | Where you were @mentioned                      | 💬   |
| **Assigned** | Issues/PRs assigned to you or review requested | 👤   |
| **Comments** | Threads you're participating in                | 💭   |

### Notification Types

| Type               | Description                    | Icon |
| ------------------ | ------------------------------ | ---- |
| **Issue**          | GitHub Issues                  | ⚠️   |
| **Pull Request**   | PRs and code reviews           | ↗️   |
| **Commit**         | Direct commit comments         | ⏺   |
| **Release**        | New releases                   | 🏷   |
| **Discussion**     | GitHub Discussions             | 💬   |
| **Security Alert** | Dependabot/Security advisories | 🛡   |
| **CI Activity**    | GitHub Actions                 | ✓    |

### Actions

| Action             | How To                        | Result                          |
| ------------------ | ----------------------------- | ------------------------------- |
| **Open in GitHub** | Click notification            | Opens in browser, marks as read |
| **Refresh**        | Click 🔄 button               | Force sync with GitHub          |
| **Mark All Read**  | Click button in footer        | Clears all unread               |
| **Open Settings**  | Click ⚙️ button               | Opens settings panel            |
| **Disconnect**     | In settings, click Disconnect | Removes token, logs out         |

### Keyboard Shortcuts

| Shortcut  | Action                                     |
| --------- | ------------------------------------------ |
| `Cmd + R` | Refresh notifications (when popup is open) |
| `Esc`     | Close popup                                |

## Architecture

```
GitNotify/
├── App/
│   ├── GitNotifyApp.swift           # @main entry point, MenuBarExtra
│   └── AppDelegate.swift            # NSApplicationDelegate lifecycle
│
├── Models/
│   ├── GitHubNotification.swift     # Notification data model (GRDB)
│   └── AppSettings.swift            # User preferences model
│
├── ViewModels/
│   ├── NotificationsViewModel.swift # Notifications state & logic
│   ├── SettingsViewModel.swift      # Settings state management
│   └── AuthViewModel.swift          # Authentication handling
│
├── Views/
│   ├── MainPopoverView.swift        # Main popup container
│   ├── NotificationListView.swift   # Notification list component
│   ├── NotificationRowView.swift    # Individual notification row
│   ├── CategoryTabsView.swift       # Filter tab bar
│   ├── SettingsView.swift           # Settings panel
│   ├── TokenInputView.swift         # Token entry form
│   └── EmptyStateView.swift         # Empty state display
│
├── Services/
│   ├── GitHubAPIService.swift       # GitHub REST API client (actor)
│   ├── KeychainManager.swift        # Secure token storage
│   ├── DatabaseManager.swift        # SQLite operations (actor)
│   ├── SystemNotificationService.swift  # macOS notifications
│   └── PollingService.swift         # Background sync service
│
├── Utilities/
│   ├── Constants.swift              # App-wide constants
│   └── Extensions/
│       ├── Date+Extensions.swift
│       └── String+Extensions.swift
│
└── Resources/
    ├── Info.plist                   # App configuration
    ├── GitNotify.entitlements       # Sandbox permissions
    └── Assets.xcassets/             # Icons and images
```

### Technical Details

| Component        | Technology                  |
| ---------------- | --------------------------- |
| **Language**     | Swift 5.9+                  |
| **UI Framework** | SwiftUI                     |
| **Architecture** | MVVM                        |
| **Concurrency**  | Swift async/await + Combine |
| **Database**     | SQLite via GRDB.swift       |
| **Security**     | macOS Keychain              |

### Dependencies

| Package                                           | Version | Purpose                 |
| ------------------------------------------------- | ------- | ----------------------- |
| [GRDB.swift](https://github.com/groue/GRDB.swift) | 6.24.0+ | SQLite database wrapper |

### Data Storage

| Data             | Location                                                   | Security             |
| ---------------- | ---------------------------------------------------------- | -------------------- |
| **GitHub Token** | macOS Keychain                                             | Encrypted, sandboxed |
| **Database**     | `~/Library/Application Support/GitNotify/gitnotify.sqlite` | App sandbox          |
| **Settings**     | In database                                                | Same as above        |

### API Integration

Uses [GitHub Notifications API](https://docs.github.com/en/rest/activity/notifications):

- **Authentication**: Bearer token
- **Polling**: Respects `X-Poll-Interval` header
- **Caching**: Uses `If-Modified-Since` for efficiency
- **API Version**: 2022-11-28

## Development

### Building for Development

```bash
# Clone repository
git clone https://github.com/yourusername/GitNotify.git
cd GitNotify

# Open in Xcode
open GitNotify/GitNotify.xcodeproj
```

### Debug vs Release Builds

| Mode        | Use Case             | Command                        |
| ----------- | -------------------- | ------------------------------ |
| **Debug**   | Development, testing | `Cmd + R` in Xcode             |
| **Release** | Distribution         | `Cmd + Shift + R` or see below |

```bash
# Release build
xcodebuild -project GitNotify/GitNotify.xcodeproj \
           -scheme GitNotify \
           -configuration Release \
           build
```

### Running Tests

```bash
xcodebuild -project GitNotify/GitNotify.xcodeproj \
           -scheme GitNotify \
           -configuration Debug \
           test
```

### Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint (if configured)
- Prefer async/await over callbacks
- Use actors for thread-safe state

## Releasing

This section explains how to release GitNotify on GitHub.

### Prerequisites for Releasing

1. **Apple Developer Account** (optional, for code signing)
2. **GitHub Account** with repository access
3. **Xcode** for building

### Creating a Release Build

1. **Update Version Number**:
   - Open `GitNotify.xcodeproj` in Xcode
   - Select the project in Navigator
   - Update "Version" (e.g., `1.0.0`) and "Build" (e.g., `1`)

2. **Archive the App**:

   ```bash
   # Using Xcode UI
   Product → Archive

   # Or command line
   xcodebuild -project GitNotify/GitNotify.xcodeproj \
              -scheme GitNotify \
              -configuration Release \
              -archivePath build/GitNotify.xcarchive \
              archive
   ```

3. **Export the App**:
   - In Xcode Organizer: Window → Organizer
   - Select the archive → Distribute App
   - Choose "Copy App" for direct distribution
   - Or use:

   ```bash
   xcodebuild -exportArchive \
              -archivePath build/GitNotify.xcarchive \
              -exportPath build/export \
              -exportOptionsPlist ExportOptions.plist
   ```

4. **Create DMG**:

   ```bash
   # Create a temporary folder
   mkdir -p build/dmg
   cp -R "build/export/GitNotify.app" build/dmg/

   # Create symbolic link to Applications
   ln -s /Applications build/dmg/Applications

   # Create DMG
   hdiutil create -volname "GitNotify" \
                  -srcfolder build/dmg \
                  -ov -format UDZO \
                  "GitNotify-1.0.0.dmg"
   ```

### Publishing to GitHub Releases

#### Method 1: GitHub Web Interface

1. Go to your repository on GitHub
2. Click "Releases" in the right sidebar (or Code → Releases)
3. Click "Draft a new release"
4. Fill in:
   | Field | Example |
   |-------|---------|
   | **Tag** | `v1.0.0` |
   | **Title** | `GitNotify v1.0.0` |
   | **Description** | Release notes (see template below) |
5. Drag and drop `GitNotify-1.0.0.dmg` to attach
6. Click "Publish release"

#### Method 2: GitHub CLI

```bash
# Install GitHub CLI (if needed)
brew install gh

# Authenticate
gh auth login

# Create release with assets
gh release create v1.0.0 \
   --title "GitNotify v1.0.0" \
   --notes "$(cat RELEASE_NOTES.md)" \
   GitNotify-1.0.0.dmg
```

### Release Notes Template

```markdown
## GitNotify v1.0.0

### What's New

- Initial release of GitNotify
- Native macOS menu bar integration
- Real-time GitHub notifications
- Smart categorization (All, Mentions, Assigned, Comments)

### Installation

1. Download `GitNotify-1.0.0.dmg` below
2. Open the DMG file
3. Drag GitNotify to Applications
4. Launch and connect your GitHub token

### Requirements

- macOS 13.0 (Ventura) or later

### SHA256 Checksum
```

sha256: <run `shasum -a 256 GitNotify-1.0.0.dmg`>

```

### Notes
- First launch may require right-click → Open due to Gatekeeper
- Requires a GitHub Personal Access Token with `notifications` scope
```

### Automated Releases with GitHub Actions

Create `.github/workflows/release.yml` in your repository:

```yaml
name: Build and Release

on:
  push:
    tags:
      - "v*"

jobs:
  build:
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: "15.0"

      - name: Build
        run: |
          xcodebuild -project GitNotify/GitNotify.xcodeproj \
                     -scheme GitNotify \
                     -configuration Release \
                     -derivedDataPath build \
                     build

      - name: Create DMG
        run: |
          mkdir -p dist
          cp -R "build/Build/Products/Release/GitNotify.app" dist/
          ln -s /Applications dist/Applications
          hdiutil create -volname "GitNotify" \
                        -srcfolder dist \
                        -ov -format UDZO \
                        "GitNotify-${{ github.ref_name }}.dmg"

      - name: Generate Checksum
        run: |
          shasum -a 256 GitNotify-${{ github.ref_name }}.dmg > checksums.txt

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            GitNotify-${{ github.ref_name }}.dmg
            checksums.txt
          draft: true
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Using the Workflow

1. Commit and push the workflow file
2. Create and push a tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. GitHub Actions will automatically build and create a draft release
4. Review the draft release on GitHub and publish it

### Code Signing (Optional but Recommended)

For distribution outside the App Store, consider code signing:

1. **Get a Developer ID Certificate**:
   - Requires Apple Developer Program ($99/year)
   - Create at: developer.apple.com → Certificates

2. **Sign the App**:

   ```bash
   codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" \
            "GitNotify.app"
   ```

3. **Notarize for Gatekeeper**:

   ```bash
   # Create ZIP for notarization
   ditto -c -k --keepParent "GitNotify.app" "GitNotify.zip"

   # Submit for notarization
   xcrun notarytool submit "GitNotify.zip" \
         --apple-id "your@email.com" \
         --team-id "TEAM_ID" \
         --password "app-specific-password" \
         --wait

   # Staple the ticket
   xcrun stapler staple "GitNotify.app"
   ```

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):

| Version           | When to Use                        |
| ----------------- | ---------------------------------- |
| `1.0.0` → `1.0.1` | Bug fixes                          |
| `1.0.0` → `1.1.0` | New features (backward compatible) |
| `1.0.0` → `2.0.0` | Breaking changes                   |

## Troubleshooting

### Common Issues

<details>
<summary><strong>Token Invalid Error</strong></summary>

**Cause**: Token is expired, revoked, or missing required scope.

**Solution**:

1. Go to [GitHub Token Settings](https://github.com/settings/tokens)
2. Check if your token exists and hasn't expired
3. Verify it has the `notifications` scope
4. If needed, create a new token
5. In GitNotify: Settings → Disconnect → Reconnect with new token
</details>

<details>
<summary><strong>No Notifications Showing</strong></summary>

**Cause**: No unread notifications, or sync issue.

**Solution**:

1. Check [GitHub Notifications](https://github.com/notifications) directly
2. Click the refresh button (🔄) in GitNotify
3. Verify your token is still valid
4. Check GitHub notification settings (Settings → Notifications)
</details>

<details>
<summary><strong>App Not Appearing in Menu Bar</strong></summary>

**Cause**: Too many menu bar items, or app crashed.

**Solution**:

1. Check if GitNotify is running (Activity Monitor)
2. Try dragging menu bar items while holding Cmd to rearrange
3. Check System Settings → Control Center → Menu Bar Only
4. Quit and restart GitNotify
</details>

<details>
<summary><strong>macOS Security Warning / "App is Damaged" Error</strong></summary>

**Cause**: App is not notarized with Apple. This is normal for apps distributed outside the Mac App Store without a paid Apple Developer account ($99/year).

**Solution** (use one of these methods):

**Method 1 - Terminal (Most Reliable):**
```bash
xattr -cr /Applications/GitNotify.app
```
Then open the app normally.

**Method 2 - System Settings:**
1. Try to open the app (it will be blocked)
2. Go to **System Settings > Privacy & Security**
3. Scroll down and click **"Open Anyway"** next to the GitNotify message

**Method 3 - Right-click:**
1. Right-click (or Control-click) on GitNotify.app
2. Select **"Open"** from the menu
3. Click **"Open"** in the dialog (may need to do this twice)
</details>

<details>
<summary><strong>Database/Cache Issues</strong></summary>

**Cause**: Corrupted database or settings.

**Solution**:

```bash
# Quit GitNotify first, then:
rm -rf ~/Library/Application\ Support/GitNotify/
# Restart GitNotify - it will recreate the database
```

</details>

<details>
<summary><strong>High CPU/Memory Usage</strong></summary>

**Cause**: Database issue or polling loop.

**Solution**:

1. Quit GitNotify
2. Clear database (see above)
3. Restart and reconnect
4. If persists, check Console.app for errors
</details>

### Getting Help

1. **Search existing issues**: [GitHub Issues](https://github.com/yourusername/GitNotify/issues)
2. **Create new issue**: Include macOS version, app version, and steps to reproduce
3. **Collect logs**: Open Console.app, filter by "GitNotify"

## Contributing

We welcome contributions! Here's how to get started:

### Development Setup

1. **Fork the repository** on GitHub

2. **Clone your fork**:

   ```bash
   git clone https://github.com/YOUR_USERNAME/GitNotify.git
   cd GitNotify
   ```

3. **Create a branch**:

   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make changes** and test thoroughly

5. **Commit with clear messages**:

   ```bash
   git commit -m "Add: description of feature"
   # or
   git commit -m "Fix: description of bug fix"
   ```

6. **Push and create PR**:
   ```bash
   git push origin feature/your-feature-name
   ```
   Then open a Pull Request on GitHub.

### Guidelines

- Follow existing code style
- Add comments for complex logic
- Test on both Intel and Apple Silicon if possible
- Update documentation if needed

### What to Contribute

- Bug fixes
- New features (discuss first in Issues)
- Documentation improvements
- Localization/translations
- Performance improvements

## License

MIT License - see [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 GitNotify Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Acknowledgments

- [GRDB.swift](https://github.com/groue/GRDB.swift) by Gwendal Roue - Excellent SQLite wrapper
- [GitHub REST API](https://docs.github.com/en/rest) - For notification access
- [SF Symbols](https://developer.apple.com/sf-symbols/) - For beautiful icons
- All contributors and users

---

**GitNotify** - Stay on top of your GitHub notifications, right from your menu bar.

[Report Bug](https://github.com/yourusername/GitNotify/issues/new?template=bug_report.md) · [Request Feature](https://github.com/yourusername/GitNotify/issues/new?template=feature_request.md)
# gitNotify
