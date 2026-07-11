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

Kalpesh Kalsariya — github.com/KalpeshKalsariya

## ☕ Support Me

