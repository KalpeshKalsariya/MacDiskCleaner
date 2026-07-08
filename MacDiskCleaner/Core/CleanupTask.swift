import Foundation

enum CleanupTaskKind: String, CaseIterable, Identifiable {
    case derivedData
    case xcodeCaches
    case archives
    case iosDeviceSupport
    case watchosDeviceSupport
    case tvosDeviceSupport
    case simulators
    case systemCaches
    case cocoapodsCache
    case trash

    var id: String { rawValue }

    var title: String {
        switch self {
        case .derivedData: return "Derived Data"
        case .xcodeCaches: return "Xcode Caches"
        case .archives: return "Archives"
        case .iosDeviceSupport: return "iOS Device Support"
        case .watchosDeviceSupport: return "watchOS Device Support"
        case .tvosDeviceSupport: return "tvOS Device Support"
        case .simulators: return "Old Simulators"
        case .systemCaches: return "System Caches"
        case .cocoapodsCache: return "CocoaPods Cache"
        case .trash: return "Trash"
        }
    }

    /// Paired with ⌘⇧ in the menu — letters match the reference MSC app exactly,
    /// not a first-letter mnemonic (e.g. Trash is D, Simulators is R).
    var shortcutKey: Character {
        switch self {
        case .derivedData: return "c"
        case .xcodeCaches: return "x"
        case .archives: return "a"
        case .iosDeviceSupport: return "i"
        case .watchosDeviceSupport: return "w"
        case .tvosDeviceSupport: return "t"
        case .simulators: return "r"
        case .systemCaches: return "s"
        case .cocoapodsCache: return "p"
        case .trash: return "d"
        }
    }

    var shortcutLabel: String {
        "⇧⌘\(String(shortcutKey).uppercased())"
    }

    var paths: [URL] {
        PathProvider.paths(for: self)
    }
}

struct CleanupTaskState: Identifiable {
    let kind: CleanupTaskKind
    var sizeBytes: Int64 = 0
    var isCalculating: Bool = false
    var isCleaning: Bool = false
    var cleanProgress: Double = 0
    var lastError: String?
    var isAccessRestricted: Bool = false

    var id: String { kind.id }

    /// True once we've confirmed there's something to clean, or we can't yet be sure
    /// (still scanning, or access is restricted so the real size is unknown). False only
    /// once a scan has definitively confirmed 0 bytes with no permission issue.
    var isCleanable: Bool {
        isCalculating || isAccessRestricted || sizeBytes > 0
    }
}
