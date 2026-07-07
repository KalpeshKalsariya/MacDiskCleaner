import Foundation

/// Aggregates the per-item failures from a best-effort directory clean, so one
/// locked file doesn't abort the whole pass and hide how much space was freed.
struct CleanupError: LocalizedError {
    let failures: [(url: URL, error: Error)]

    var errorDescription: String? {
        let names = failures.map { $0.url.lastPathComponent }.joined(separator: ", ")
        return "Couldn't remove \(failures.count) item(s): \(names)"
    }
}

enum CleanupManager {
    static func calculateSize(for kind: CleanupTaskKind) async -> FileSizeResult {
        await Task.detached(priority: .utility) {
            kind.paths.reduce(FileSizeResult.zero) { $0 + FileSizeCalculator.size(of: $1) }
        }.value
    }

    static func clean(_ kind: CleanupTaskKind) async throws {
        try await Task.detached(priority: .utility) {
            switch kind {
            case .simulators:
                try SimulatorManager.deleteUnavailableSimulators()
            case .systemCaches:
                try cleanDirectory(at: PathProvider.systemCaches, excluding: PathProvider.systemCachesExcludeList)
            default:
                for path in kind.paths {
                    try removeContents(of: path)
                }
            }
        }.value
    }

    private static func removeContents(of directory: URL, excluding excludedNames: Set<String> = []) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else { return }

        // Not try? — a permission error here (e.g. ~/.Trash without Full Disk Access) must
        // surface to the user instead of silently looking like "nothing to clean."
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        var failures: [(url: URL, error: Error)] = []
        for item in contents where !excludedNames.contains(item.lastPathComponent) {
            do {
                try fileManager.removeItem(at: item)
            } catch {
                failures.append((item, error))
            }
        }
        if !failures.isEmpty {
            throw CleanupError(failures: failures)
        }
    }

    private static func cleanDirectory(at directory: URL, excluding excludedNames: Set<String>) throws {
        try removeContents(of: directory, excluding: excludedNames)
    }
}
