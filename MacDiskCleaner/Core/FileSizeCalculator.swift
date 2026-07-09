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
    /// Filesystem-generated metadata files that never represent real user content,
    /// regardless of which folder they turn up in.
    private static let ignoredFileNames: Set<String> = [".DS_Store", ".localized"]

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
        // Not .skipsHiddenFiles — that option skips anything with the invisible flag set,
        // not just dot-prefixed names, and that includes real trashed content (e.g. some
        // apps mark exported/generated files invisible). We only want to ignore known
        // filesystem junk by exact name, not every hidden file.
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [],
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
            guard !ignoredFileNames.contains(fileURL.lastPathComponent),
                  let values = try? fileURL.resourceValues(forKeys: keys),
                  values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return FileSizeResult(bytes: total, isAccessRestricted: accessRestricted)
    }

    /// Like `size(of:)`, but skips any top-level child whose name is in `excludedNames` —
    /// entirely, not just its contents — mirroring what a cleanup pass that excludes those
    /// same names will actually leave behind on disk.
    static func size(of url: URL, excludingTopLevelNames excludedNames: Set<String>) -> FileSizeResult {
        guard !excludedNames.isEmpty else { return size(of: url) }
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return size(of: url)
        }
        guard let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
            return FileSizeResult(bytes: 0, isAccessRestricted: true)
        }
        return contents
            .filter { !excludedNames.contains($0.lastPathComponent) }
            .reduce(FileSizeResult.zero) { $0 + size(of: $1) }
    }

    private static func fileSize(at url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]) else {
            return 0
        }
        return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
    }
}
