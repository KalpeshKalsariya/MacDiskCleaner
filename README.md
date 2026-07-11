# MacDiskCleaner
Keep your Mac clean, organized, and running smoothly with an intelligent storage cleanup tool built for speed, safety, and privacy.

## What it does

MacDiskCleaner lives in your menu bar (shown as "MDC"). Click the icon to open a popover that lists cleanup targets, shows how much space each one is using, and lets you clean them individually or all at once.

| Option | Shortcut | Description |
|---|---|---|
| Available Storage | - | Shows available disk space on your Mac, automatically updates every 30 seconds. |
| Clean Derived Data | ⇧⌘C | Deletes Xcode's DerivedData folder to free up space and resolve build issues. |
| Clear Xcode Caches | ⇧⌘X | Removes cached data related to Xcode projects. |
| Clear Archives | ⇧⌘A | Deletes old archived builds from Xcode to save storage. |
| Clear iOS Device Support | ⇧⌘I | Removes unnecessary iOS device support files. |
| Clear watchOS Device Support | ⇧⌘W | Deletes outdated watchOS device support files. |
| Clear tvOS Device Support | ⇧⌘T | Removes old tvOS device support files. |
| Remove Old Simulators | ⇧⌘R | Deletes simulator devices whose runtime is no longer installed. |
| Simulator Previews | ⇧⌘O | Deletes cached simulator preview thumbnails. |
| Simulators Data | ⇧⌘L | Erases all content and settings on every simulator device, keeping the devices themselves. |
| Clear Caches | ⇧⌘S | Clears general system cache files to optimize performance. |
| Clear CocoaPods Cache | ⇧⌘P | Deletes cached dependencies from CocoaPods to reclaim space. |
| Empty Trash | ⇧⌘D | Empties the system trash (and iCloud Trash) to free up storage. |
| Clear All | ⇧⌘E | Runs all cleaning operations at once for a full cleanup. |
| Quit | ⌘Q | Exits the application and removes the menu bar icon. |

Every destructive action (single task or "Clear All") shows a confirmation alert first, explaining what will be removed.

### Permissions

- **Full Disk Access** — needed to reliably scan and clean most folders (especially system caches and some Trash locations). The popover shows a banner with a button to open System Settings if it isn't granted yet.
- **Automation (Finder)** — needed for the AppleScript-based Trash operations.
- **Login Items** — the app registers itself via `SMAppService` on first launch; macOS may require you to approve it once in System Settings → Login Items & Extensions.

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

## 💡 Best Practices

- Grant **Full Disk Access** the first time the app asks — without it, some folders (like `~/Library/Caches` or `~/.Trash`) will show as "Permission needed" instead of a real size.
- Use **Clear All** sparingly — it also empties the Trash and clears every app's cache on your Mac, which is convenient but irreversible. Review the confirmation message before confirming.
- **Simulators Data** resets every simulator device to factory-fresh (like a real device erase) — use it only when you don't need any existing simulator app data, not just to "clean up a bit."
- Run the app from `/Applications` (not directly from Xcode's `DerivedData` build) if you want the login item to reliably relaunch it after every restart — `SMAppService` ties registration to the app's bundle path.
- Let the background rescans do their job — sizes refresh automatically every few minutes, so you don't need to manually hit refresh unless you just freed up space outside the app (e.g. deleted files yourself in Finder).
