# MacDiskCleaner
Keep your Mac clean, organized, and running smoothly with an intelligent storage cleanup tool built for speed, safety, and privacy.

A lightweight macOS menu bar app that helps developers reclaim disk space by finding and clearing common developer clutter: Xcode caches, derived data, archives, simulator data, CocoaPods cache, and Trash.

## What it does

MacDiskCleaner lives in your menu bar (shown as "MDC"). Click the icon to open a popover that lists cleanup targets, shows how much space each one is using, and lets you clean them individually or all at once.

It can scan and clean:

| Task | What it removes |
|---|---|
| Derived Data | `~/Library/Developer/Xcode/DerivedData` |
| Xcode Caches | `~/Library/Caches/com.apple.dt.Xcode` |
| Archives | `~/Library/Developer/Xcode/Archives` |
| iOS Device Support | `~/Library/Developer/Xcode/iOS DeviceSupport` |
| watchOS Device Support | `~/Library/Developer/Xcode/watchOS DeviceSupport` |
| tvOS Device Support | `~/Library/Developer/Xcode/tvOS DeviceSupport` |
| Old Simulators | Deletes simulator devices whose runtime is no longer installed (`simctl delete unavailable`) |
| Simulator Previews | Deletes cached simulator preview thumbnails (`simctl --set previews delete all`) |
| Simulators Data | Erases all content/settings on every simulator device, keeping the devices themselves (`simctl erase all`) |
| System Caches | `~/Library/Caches` (excluding Xcode's own cache and this app's cache, so it doesn't clean out things mid-use) |
| CocoaPods Cache | `~/Library/Caches/CocoaPods` and `~/.cocoapods` |
| Empty Trash | Empties `~/.Trash` and the iCloud Trash, via Finder (AppleScript) |

Every destructive action (single task or "Clean All") shows a confirmation alert first, explaining what will be removed.

## How it works

The app is a menu-bar-only (accessory) app — it has no Dock icon and no main window, just a status item and a popover.

- **`MacDiskCleanerApp.swift`** — SwiftUI `App` entry point. It only hosts an empty `Settings` scene; the actual app lives in `AppDelegate`.
- **`AppDelegate.swift`** — sets up the status bar item and popover, registers the app as a login item (via `SMAppService`) so it can relaunch automatically after restart/login, and shows a floating "Cleaning..." progress window while any task is running.
- **`MenuViewModel.swift`** — the `@MainActor` view model driving the UI. It scans every task's size on launch and periodically (every 5 minutes), refreshes available disk space every 30 seconds, tracks per-task cleaning progress, and manages confirmation prompts.
- **`CleanupManager.swift`** — does the actual work: computing folder sizes and deleting contents, off the main thread (`Task.detached`), reporting progress back as it removes each item.
- **`CleanupTask.swift`** — defines `CleanupTaskKind`, the enum of everything the app can clean, along with display titles and keyboard shortcuts.
- **`PathProvider.swift`** — resolves the actual file system paths for each cleanup task.
- **`SimulatorManager.swift`** — wraps `xcrun simctl` calls for simulator-related cleanup.
- **`FinderTrashService.swift`** — empties/measures the Trash through Finder (AppleScript) instead of `FileManager`, so it only needs Finder Automation permission instead of full disk access.
- **`FileSizeCalculator.swift`** — recursively sums folder sizes, distinguishing "genuinely empty" from "couldn't read due to a permissions error."
- **`ProgressWindow.swift`** — a small floating `NSWindow` with a progress bar, shown whenever a cleanup task is running.
- **`PermissionsHelper.swift`** — checks/prompts for Full Disk Access, needed to reliably scan and clean most of the folders above.

### Concurrency

The app targets Swift 6's strict concurrency checking. The UI layer (`MenuViewModel`, `AppDelegate`, views) is `@MainActor`-isolated. The file-system/process utilities (`PathProvider`, `CleanupManager`, `SimulatorManager`, `FinderTrashService`, `FileSizeCalculator`, `CleanupTaskKind`) are explicitly marked `nonisolated`, since they do blocking disk/process work and are meant to run off the main thread inside `Task.detached`.

### Permissions

- **Full Disk Access** — needed to reliably scan and clean most folders (especially system caches and some Trash locations). The popover shows a banner with a button to open System Settings if it isn't granted yet.
- **Automation (Finder)** — needed for the AppleScript-based Trash operations.
- **Login Items** — the app registers itself via `SMAppService` on first launch; macOS may require you to approve it once in System Settings → Login Items & Extensions.

## Requirements

- macOS 14.6+
- Xcode 16+ (Swift 6 language mode)

## Building & running

Open `MacDiskCleaner.xcodeproj` in Xcode and run the `MacDiskCleaner` scheme. The app has no Dock icon — look for "MDC" in the menu bar after it launches.

For reliable auto-relaunch-after-restart behavior, build a Release/Archive copy and run it from `/Applications` rather than running directly from Xcode — login item registration is tied to the app's bundle path, and Xcode's Debug build path (inside `DerivedData`) can change between builds.
