import Foundation

enum PathProvider {
    static var home: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    static var library: URL {
        home.appendingPathComponent("Library")
    }

    static var derivedData: URL {
        library.appendingPathComponent("Developer/Xcode/DerivedData")
    }

    static var xcodeCaches: URL {
        library.appendingPathComponent("Caches/com.apple.dt.Xcode")
    }

    static var archives: URL {
        library.appendingPathComponent("Developer/Xcode/Archives")
    }

    static var iosDeviceSupport: URL {
        library.appendingPathComponent("Developer/Xcode/iOS DeviceSupport")
    }

    static var watchosDeviceSupport: URL {
        library.appendingPathComponent("Developer/Xcode/watchOS DeviceSupport")
    }

    static var tvosDeviceSupport: URL {
        library.appendingPathComponent("Developer/Xcode/tvOS DeviceSupport")
    }

    static var simulatorDevices: URL {
        library.appendingPathComponent("Developer/CoreSimulator/Devices")
    }

    static var systemCaches: URL {
        library.appendingPathComponent("Caches")
    }

    static var cocoapodsCaches: URL {
        library.appendingPathComponent("Caches/CocoaPods")
    }

    static var cocoapodsRepos: URL {
        home.appendingPathComponent(".cocoapods")
    }

    static var trash: URL {
        home.appendingPathComponent(".Trash")
    }

    /// Files trashed from an iCloud Drive-synced location (e.g. Desktop/Documents with
    /// "Desktop & Documents Folders" enabled) land here instead of ~/.Trash. Finder's
    /// unified Trash view quietly merges both locations into one list, so we need to
    /// check both too, or items visibly "in the Trash" would never be counted.
    static var iCloudTrash: URL {
        library.appendingPathComponent("Mobile Documents/.Trash")
    }

    /// Folder names under ~/Library/Caches that must survive a "Clear Caches" pass —
    /// removing our own cache or Xcode's mid-build would be self-defeating.
    static let systemCachesExcludeList: Set<String> = [
        "com.apple.dt.Xcode",
        Bundle.main.bundleIdentifier ?? "com.MacDiskCleaner"
    ]

    static func paths(for kind: CleanupTaskKind) -> [URL] {
        switch kind {
        case .derivedData: return [derivedData]
        case .xcodeCaches: return [xcodeCaches]
        case .archives: return [archives]
        case .iosDeviceSupport: return [iosDeviceSupport]
        case .watchosDeviceSupport: return [watchosDeviceSupport]
        case .tvosDeviceSupport: return [tvosDeviceSupport]
        case .simulators: return [simulatorDevices]
        case .systemCaches: return [systemCaches]
        case .cocoapodsCache: return [cocoapodsCaches, cocoapodsRepos]
        case .trash: return [trash, iCloudTrash]
        }
    }
}
