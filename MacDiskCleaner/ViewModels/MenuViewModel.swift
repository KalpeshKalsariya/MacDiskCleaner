import Foundation
import Combine

enum CleanupConfirmationTarget: Identifiable {
    case single(CleanupTaskKind)
    case all

    var id: String {
        switch self {
        case .single(let kind): return kind.id
        case .all: return "all"
        }
    }

    var alertTitle: String {
        switch self {
        case .single(let kind): return "Clean \(kind.title)?"
        case .all: return "Clean Everything?"
        }
    }

    var alertMessage: String {
        switch self {
        case .single(let kind):
            switch kind {
            case .systemCaches:
                return "This removes cached data for every app on your Mac. Most apps rebuild their caches automatically, but some may need to relaunch or resync."
            case .trash:
                return "This permanently empties the Trash. Files cannot be recovered afterward."
            case .simulatorsData:
                return "This erases all content and settings on every simulator device, restoring them to a factory-fresh state. The devices themselves are kept."
            case .simulatorPreviews:
                return "This removes cached preview thumbnails for every simulator runtime. They'll be regenerated automatically as needed."
            default:
                return "This action cannot be undone."
            }
        case .all:
            return "This runs every cleanup task below, including emptying the Trash and clearing system caches. This action cannot be undone."
        }
    }
}

@MainActor
final class MenuViewModel: ObservableObject {
    @Published private(set) var taskStates: [CleanupTaskState]
    @Published var availableCapacityText: String = "—"
    @Published var hasFullDiskAccess: Bool = PermissionsHelper.hasFullDiskAccess
    @Published var pendingConfirmation: CleanupConfirmationTarget?
    @Published var lastErrorMessage: String?

    private var refreshTimer: Timer?
    private var rescanTimer: Timer?
    // Auto-refresh, manual refresh, and the post-clean rescan can all target the same kind
    // in overlapping windows; without this, whichever scan happens to finish last wins,
    // even if it was the older/slower one — silently reverting a fresh size to a stale one.
    private var scanGenerations: [CleanupTaskKind: Int] = [:]
    private var lastScanDate = Date()

    init() {
        taskStates = CleanupTaskKind.allCases.map { CleanupTaskState(kind: $0) }
        refreshAvailableCapacity()
        scanAll()
        startAutoRefresh()
    }

    func state(for kind: CleanupTaskKind) -> CleanupTaskState {
        taskStates.first { $0.kind == kind } ?? CleanupTaskState(kind: kind)
    }

    var hasCleanableContent: Bool {
        taskStates.contains { $0.isCleanable }
    }

    var totalCleanableBytes: Int64 {
        taskStates.reduce(0) { $0 + $1.sizeBytes }
    }

    var isCleaningAll: Bool {
        taskStates.contains { $0.isCleaning }
    }

    func scanAll() {
        lastScanDate = Date()
        for kind in CleanupTaskKind.allCases {
            scan(kind)
        }
    }

    /// Called when the popover opens. Skips rescanning if the last scan (from launch,
    /// the 5-minute timer, or a previous open) is still recent, so opening the popover
    /// stays instant most of the time — only catching up when data is actually old.
    func scanIfStale(olderThan threshold: TimeInterval = 60) {
        guard Date().timeIntervalSince(lastScanDate) > threshold else { return }
        scanAll()
    }

    func scan(_ kind: CleanupTaskKind) {
        let generation = (scanGenerations[kind] ?? 0) + 1
        scanGenerations[kind] = generation
        setState(for: kind) { $0.isCalculating = true }
        Task {
            let result = await CleanupManager.calculateSize(for: kind)
            guard scanGenerations[kind] == generation else { return }
            setState(for: kind) {
                $0.sizeBytes = result.bytes
                $0.isAccessRestricted = result.isAccessRestricted
                $0.isCalculating = false
            }
        }
    }

    func requestClean(_ kind: CleanupTaskKind) {
        pendingConfirmation = .single(kind)
    }

    func requestCleanAll() {
        pendingConfirmation = .all
    }

    func confirmPendingClean() {
        guard let target = pendingConfirmation else { return }
        pendingConfirmation = nil
        switch target {
        case .single(let kind):
            clean(kind)
        case .all:
            for kind in CleanupTaskKind.allCases {
                clean(kind)
            }
        }
    }

    func cancelPendingClean() {
        pendingConfirmation = nil
    }

    func refreshAvailableCapacity() {
        let wasFullDiskAccess = hasFullDiskAccess
        hasFullDiskAccess = PermissionsHelper.hasFullDiskAccess
        if hasFullDiskAccess && !wasFullDiskAccess {
            // The user just granted access (e.g. via the banner's "Open System Settings"
            // button) — rows scanned before that point are stuck showing stale/blocked
            // results until something rescans them, so do it the moment access appears.
            scanAll()
        }
        guard let values = try? PathProvider.home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let capacity = values.volumeAvailableCapacityForImportantUsage else {
            availableCapacityText = "—"
            return
        }
        availableCapacityText = ByteCountFormatter.string(fromByteCount: capacity, countStyle: .file)
    }

    private func clean(_ kind: CleanupTaskKind) {
        setState(for: kind) {
            $0.isCleaning = true
            $0.cleanProgress = 0
            $0.lastError = nil
        }
        Task {
            do {
                try await CleanupManager.clean(kind) { [weak self] fraction in
                    Task { @MainActor in
                        self?.setState(for: kind) { $0.cleanProgress = fraction }
                    }
                }
            } catch {
                lastErrorMessage = error.localizedDescription
                setState(for: kind) { $0.lastError = error.localizedDescription }
            }
            setState(for: kind) { $0.isCleaning = false }
            scan(kind)
            refreshAvailableCapacity()
        }
    }

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.refreshAvailableCapacity()
            }
        }
        // Keeps sizes reasonably current without redoing a full disk scan every time the
        // popover opens — the manual refresh button in the header still covers "I want it now."
        rescanTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task { @MainActor [weak self] in
                self?.scanAll()
            }
        }
    }

    private func setState(for kind: CleanupTaskKind, mutate: (inout CleanupTaskState) -> Void) {
        guard let index = taskStates.firstIndex(where: { $0.kind == kind }) else { return }
        mutate(&taskStates[index])
    }
}
