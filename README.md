# MacDiskCleaner
Keep your Mac clean, organized, and running smoothly with an intelligent storage cleanup tool built for speed, safety, and privacy.

## What it does

MacDiskCleaner lives in your menu bar (shown as "MDC"). Click the icon to open a popover that lists cleanup targets, shows how much space each one is using, and lets you clean them individually or all at once.

| Option | Shortcut | Description |
|---|---|---|
| Available Storage | - | Shows available disk space on your Mac; refreshes automatically every 30 seconds. |
| Derived Data | ⇧⌘C | Clears everything inside `~/Library/Developer/Xcode/DerivedData` to free up space and resolve stale build issues. |
| Xcode Caches | ⇧⌘X | Clears everything inside `~/Library/Caches/com.apple.dt.Xcode`. |
| Archives | ⇧⌘A | Clears everything inside `~/Library/Developer/Xcode/Archives`. |
| iOS Device Support | ⇧⌘I | Clears everything inside `~/Library/Developer/Xcode/iOS DeviceSupport`. |
| watchOS Device Support | ⇧⌘W | Clears everything inside `~/Library/Developer/Xcode/watchOS DeviceSupport`. |
| tvOS Device Support | ⇧⌘T | Clears everything inside `~/Library/Developer/Xcode/tvOS DeviceSupport`. |
| Old Simulators | ⇧⌘R | Deletes simulator devices whose runtime is no longer installed (`simctl delete unavailable`). |
| Simulator Previews | ⇧⌘O | Deletes cached simulator preview thumbnails for every runtime (`simctl --set previews delete all`). |
| Simulators Data | ⇧⌘L | Erases all content and settings on every simulator device, keeping the devices themselves (`simctl erase all`). |
| System Caches | ⇧⌘S | Clears `~/Library/Caches`, excluding Xcode's own cache and this app's cache so neither is wiped out mid-use. |
| CocoaPods Cache | ⇧⌘P | Clears `~/Library/Caches/CocoaPods` and `~/.cocoapods`. |
| Empty Trash | ⇧⌘D | Empties `~/.Trash` and the iCloud Trash through Finder (AppleScript), rather than `FileManager`. |
| Clean All | ⇧⌘E | Runs every cleanup task above in one pass, after a single confirmation. |
| Quit | ⌘Q | Exits the application and removes the menu bar icon. |

Every destructive action (single task or "Clean All") shows a confirmation alert first, explaining what will be removed.

### Permissions

- **Full Disk Access** — needed to reliably scan and clean most folders (especially system caches and some Trash locations). The popover shows a banner with a button to open System Settings if it isn't granted yet.

## Requirements

- macOS 14.6+
- Xcode 16+ (Swift 6 language mode)

## 📦 Installation Guide

Follow the steps below to install and use the application.

1. **Download and Locate the Application**

   After downloading the MacDiskCleaner application, navigate to the Applications folder in Finder and locate MacDiskCleaner.

2. **Open the Application**

   Double-click on MacDiskCleaner to open it. If you see a warning stating that "Apple cannot verify the application," proceed to the next step.

3. **Allow the Application in Privacy & Security**

   Go to **System Settings > Privacy & Security**.
   Scroll down to the **Security** section.
   Click **Open Anyway** to allow the application to run.

4. **Confirm the Security Prompt**

   A new dialog will appear asking you to confirm the action. Click **Open Anyway**.

5. **Enter Administrator Credentials**

   To finalize the process, enter your administrator username and password, then click **OK**.

6. **Grant Full Disk Access**

   MacDiskCleaner needs Full Disk Access to reliably scan and clean most folders (especially system caches and some Trash locations). If it isn't granted yet, the app's menu bar popover shows a banner with a button that opens this screen directly, or you can get there manually:

   - Go to **System Settings > Privacy & Security > Full Disk Access**.
   - Find **MacDiskCleaner** in the list of applications.
   - Toggle it **on**.

## Built With

- **Swift 6** — strict concurrency checking throughout
- **SwiftUI** — menu bar popover UI (`MenuBarView`)
- **AppKit** — status bar item, popover hosting, and the floating progress window
- **Combine** — `@Published` state on `MenuViewModel`, driving the UI and the progress window
- **ServiceManagement (`SMAppService`)** — login item registration for auto-launch at login
- **Foundation `Process`/`xcrun simctl`** — simulator cleanup operations
- **AppleScript (`NSAppleScript`)** — Trash size/empty via Finder, avoiding a Full Disk Access dependency for that one task

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contact

For questions or feature requests, reach out at kalsariyakalpesh993@gmail.com or open an issue on GitHub.

## Author

Kalpesh Kalsariya — [github.com/KalpeshKalsariya](https://github.com/KalpeshKalsariya)

