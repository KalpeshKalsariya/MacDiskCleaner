import Foundation

/// `bytes` alone can't distinguish "genuinely empty" from "TCC denied us access" (e.g. ~/.Trash
/// without Full Disk Access) — both read as 0. `isAccessRestricted` carries that distinction.
struct FileSizeResult {
    let bytes: Int64
    let isAccessRestricted: Bool

    static let zero = FileSizeResult(bytes: 0, isAccessRestricted: false)

    static func + (lhs: FileSizeResult, rhs: FileSizeResult) -> FileSizeResult {
        FileSizeResult(bytes: lhs.bytes + rhs.bytes, isAccessRestricted: lhs.isAccessRestricted || rhs.isAccessRestricted)
    }
}

enum FileSizeCalculator {
    /// Recursively sums the on-disk size of everything under `url`.
    /// Synchronous and potentially slow — callers should run this off the main thread.
    static func size(of url: URL) -> FileSizeResult {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return .zero
        }
        guard isDirectory.boolValue else {
            return FileSizeResult(bytes: fileSize(at: url), isAccessRestricted: false)
        }

        let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        var accessRestricted = false
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in
                accessRestricted = true
                return true
            }
        ) else {
            return FileSizeResult(bytes: 0, isAccessRestricted: true)
        }

        // Only regular files contribute size — a directory's own resourceValues
        // report its metadata size, not the recursive size of its contents,
        // which would otherwise double-count everything inside it.
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: keys),
                  values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return FileSizeResult(bytes: total, isAccessRestricted: accessRestricted)
    }

    private static func fileSize(at url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]) else {
            return 0
        }
        return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
    }
}
