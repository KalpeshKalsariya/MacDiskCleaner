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
            switch kind {
            case .systemCaches:
                // Excludes the same names `clean(.systemCaches)` never removes, so the size
                // shown here matches what a cleanup pass will actually free.
                return FileSizeCalculator.size(
                    of: PathProvider.systemCaches,
                    excludingTopLevelNames: PathProvider.systemCachesExcludeList
                )
            default:
                return kind.paths.reduce(FileSizeResult.zero) { $0 + FileSizeCalculator.size(of: $1) }
            }
        }.value
    }

    static func clean(_ kind: CleanupTaskKind, progress: @escaping (Double) -> Void = { _ in }) async throws {
        try await Task.detached(priority: .utility) {
            switch kind {
            case .simulators:
                try SimulatorManager.deleteUnavailableSimulators()
                progress(1)
            case .systemCaches:
                try removeContents(
                    of: [PathProvider.systemCaches],
                    excluding: PathProvider.systemCachesExcludeList,
                    progress: progress
                )
            default:
                try removeContents(of: kind.paths, progress: progress)
            }
        }.value
    }

    // Collects every item across all given directories up front so progress reflects the
    // true total instead of restarting at 0% for each directory in a multi-path task.
    private static func removeContents(
        of directories: [URL],
        excluding excludedNames: Set<String> = [],
        progress: @escaping (Double) -> Void
    ) throws {
        let fileManager = FileManager.default
        var items: [URL] = []
        for directory in directories {
            guard fileManager.fileExists(atPath: directory.path) else { continue }
            // Not try? — a permission error here (e.g. ~/.Trash without Full Disk Access) must
            // surface to the user instead of silently looking like "nothing to clean."
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            items += contents.filter { !excludedNames.contains($0.lastPathComponent) }
        }

        guard !items.isEmpty else {
            progress(1)
            return
        }

        var failures: [(url: URL, error: Error)] = []
        for (index, item) in items.enumerated() {
            do {
                try fileManager.removeItem(at: item)
            } catch {
                failures.append((item, error))
            }
            progress(Double(index + 1) / Double(items.count))
        }
        if !failures.isEmpty {
            throw CleanupError(failures: failures)
        }
    }
}
