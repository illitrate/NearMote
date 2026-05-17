# MacRemote - Setup Instructions

All Swift source files have been created for the MacRemote iOS app. Follow these steps to complete the setup in Xcode.

## Files Created

### Models
- ✅ `RemoteCommand.swift` - Command definitions and metadata
- ✅ `SSHCredentials.swift` - SSH credential model

### Services
- ✅ `SSHService.swift` - SSH connection and command execution
- ✅ `KeychainManager.swift` - Secure credential storage
- ✅ `CommandBuilder.swift` - Command to shell script translation

### ViewModels
- ✅ `RemoteControlViewModel.swift` - UI state management

### Views
- ✅ `ContentView.swift` - Main UI with grid layout
- ✅ `SettingsView.swift` - SSH configuration interface
- ✅ `MacRemoteApp.swift` - App entry point

### Configuration
- ✅ `Info.plist` - Network permissions

## Required Setup Steps in Xcode

### 1. Add Swift Files to Xcode Project

All `.swift` files are in the `MacRemote/` folder but need to be added to the Xcode project:

1. In Xcode, right-click the **MacRemote** folder in the project navigator
2. Select **Add Files to "MacRemote"...**
3. Navigate to `/Users/illitrate/Documents/Dev/Dev 2025/MacRemote/MacRemote/`
4. Select all `.swift` files:
   - RemoteCommand.swift
   - SSHCredentials.swift
   - CommandBuilder.swift
   - KeychainManager.swift
   - SSHService.swift
   - RemoteControlViewModel.swift
   - SettingsView.swift
   - ContentView.swift
   - MacRemoteApp.swift
5. Ensure **"Copy items if needed"** is UNCHECKED (files are already in the right location)
6. Ensure **"Add to targets"** has **MacRemote** checked
7. Click **Add**

### 2. Configure Info.plist

1. In Xcode, select the **MacRemote** project
2. Select the **MacRemote** target
3. Go to the **Info** tab
4. Right-click in the custom properties area and select **Add Row**
5. Add the key: `NSLocalNetworkUsageDescription`
6. Set the value to: `MacRemote needs local network access to connect to your Mac via SSH for remote control.`

**Alternative**: The `Info.plist` file has already been created in the MacRemote folder. You can add it to the project using the same process as step 1.

### 3. Add Swift Package Dependencies

#### Add SwiftNIO SSH (SSH Library)

1. In Xcode, go to **File > Add Package Dependencies...**
2. Enter the URL: `https://github.com/apple/swift-nio-ssh`
3. Click **Add Package**
4. Select **NIOSSHClient** and click **Add Package**

**Note**: SwiftNIO SSH is Apple's official SSH implementation - modern, reliable, and fully supported.

**Keychain Storage**: The app uses the native iOS Security framework for credential storage - no external dependencies needed!

### 4. Build the Project

1. Select an iOS Simulator or physical device
2. Press **Cmd+B** to build
3. Fix any remaining compilation errors (there should be none if all steps were followed)

### 5. Run on Device (Recommended)

Since this app requires local network access to SSH into your Mac, it's best tested on a physical iPhone:

1. Connect your iPhone via USB
2. Select your iPhone as the run destination
3. Press **Cmd+R** to build and run
4. If prompted, trust the developer certificate on your iPhone

## Mac Configuration Requirements

Before using MacRemote, ensure your Mac is configured properly:

### Enable SSH (Remote Login)

1. Open **System Settings** (or **System Preferences** on older macOS)
2. Go to **General > Sharing** (or just **Sharing**)
3. Enable **Remote Login**
4. Note your Mac's hostname or IP address (shown in the Remote Login panel)

### Grant Terminal Accessibility Permissions

For osascript commands to work via SSH, Terminal needs accessibility permissions:

1. Open **System Settings > Privacy & Security > Accessibility**
2. Add **Terminal** (or **sshd**) to the allowed apps
3. Toggle the switch to enable it

### Find Your Mac's IP Address

You'll need this for the SSH hostname:

1. Open **System Settings > Network**
2. Select your active connection (Wi-Fi or Ethernet)
3. Note the **IP Address** (e.g., 192.168.1.100)

Or use Terminal:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

## Using MacRemote

### First Launch

1. Launch MacRemote on your iPhone
2. Tap the **gear icon** in the top-right to open Settings
3. Enter your Mac's details:
   - **Hostname or IP**: Your Mac's IP address (e.g., 192.168.1.100)
   - **Username**: Your Mac username
   - **Password**: Your Mac password
4. Tap **Test Connection** to verify
5. If successful, tap **Save Credentials**

### Controlling Your Mac

Once configured, use the buttons on the main screen:

- **Volume Up/Down**: Adjust system volume by 10%
- **Play/Pause/Stop**: Control the Music app
- **Wake**: Wake the display (if sleeping)
- **Sleep**: Put the Mac to sleep

## Troubleshooting

### SSH Connection Issues

**Problem**: "Connection failed: Connection refused"
- **Solution**: Ensure Remote Login is enabled on your Mac (see Mac Configuration)

**Problem**: "Authentication failed"
- **Solution**: Double-check your username and password. Use your Mac account credentials.

**Problem**: "Network unavailable"
- **Solution**: Ensure your iPhone and Mac are on the same Wi-Fi network

### Permission Issues

**Problem**: Commands execute but nothing happens
- **Solution**: Grant Terminal accessibility permissions on your Mac (see Mac Configuration)

### SwiftNIO SSH Build Errors

**Problem**: SwiftNIO SSH package fails to build in Xcode
- **Solution**: SwiftNIO SSH is Apple's official library and should build successfully on iOS 26. Make sure you selected **NIOSSHClient** product when adding the package.

## Future Enhancements

The architecture supports easy addition of:
- Spotify, Netflix, Disney+ controls
- Apple TV library search and playback
- Custom AppleScript execution
- SSH key authentication

To add new commands, modify `RemoteCommand.swift` and `CommandBuilder.swift`.

## Project Structure

```
MacRemote/
├── MacRemote/
│   ├── Models/
│   │   ├── RemoteCommand.swift
│   │   └── SSHCredentials.swift
│   ├── Services/
│   │   ├── SSHService.swift
│   │   ├── KeychainManager.swift
│   │   └── CommandBuilder.swift
│   ├── ViewModels/
│   │   └── RemoteControlViewModel.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   └── SettingsView.swift
│   ├── MacRemoteApp.swift
│   ├── Info.plist
│   └── Assets.xcassets/
└── MacRemote.xcodeproj/
```

## Support

If you encounter issues:
1. Check that all Swift files are added to the Xcode target
2. Verify SPM packages are successfully resolved
3. Check Mac SSH configuration and permissions
4. If you encounter deprecated API warnings, report them so they can be fixed

---

**Built with SwiftUI, SwiftNIO SSH (Apple's official SSH library), and native iOS Security framework**
