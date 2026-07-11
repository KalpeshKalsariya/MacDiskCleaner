import Foundation

/// Reads and empties the Trash through Finder (AppleScript) instead of `FileManager`.
/// Finder already owns the Trash, so this only needs Automation permission for Finder —
/// not the heavier Full Disk Access that direct `FileManager` access to ~/.Trash requires.
nonisolated enum FinderTrashService {
    struct FinderScriptError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func size() -> FileSizeResult {
        let script = "tell application \"Finder\" to get size of every item of the trash"
        guard let descriptor = run(script) else {
            return FileSizeResult(bytes: 0, isAccessRestricted: true)
        }
        var total: Int64 = 0
        if descriptor.numberOfItems > 0 {
            for index in 1...descriptor.numberOfItems {
                total += Int64(descriptor.atIndex(index)?.int32Value ?? 0)
            }
        } else if descriptor.descriptorType != typeNull {
            total += Int64(descriptor.int32Value)
        }
        return FileSizeResult(bytes: total, isAccessRestricted: false)
    }

    static func empty() throws {
        guard run("tell application \"Finder\" to empty the trash") != nil else {
            throw FinderScriptError(message: "Couldn't empty the Trash via Finder.")
        }
    }

    private static func run(_ source: String) -> NSAppleEventDescriptor? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            NSLog("MacDiskCleaner: Finder AppleScript failed: \(error)")
            return nil
        }
        return result
    }
}
