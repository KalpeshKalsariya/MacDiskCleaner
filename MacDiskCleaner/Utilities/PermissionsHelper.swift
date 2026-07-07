import AppKit
import Foundation

enum PermissionsHelper {
    /// macOS doesn't expose an API to query Full Disk Access directly, so we probe
    /// a file that's only readable with FDA granted (Apple's own recommended trick).
    static var hasFullDiskAccess: Bool {
        let tccURL = PathProvider.home.appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
        guard let handle = try? FileHandle(forReadingFrom: tccURL) else { return false }
        handle.closeFile()
        return true
    }

    static func openFullDiskAccessSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else { return }
        NSWorkspace.shared.open(url)
    }
}
