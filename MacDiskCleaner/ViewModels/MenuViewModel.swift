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

    init() {
        taskStates = CleanupTaskKind.allCases.map { CleanupTaskState(kind: $0) }
        refreshAvailableCapacity()
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

    var overallCleanProgress: Double {
        let cleaning = taskStates.filter { $0.isCleaning }
        guard !cleaning.isEmpty else { return 0 }
        return cleaning.reduce(0) { $0 + $1.cleanProgress } / Double(cleaning.count)
    }

    func scanAll() {
        for kind in CleanupTaskKind.allCases {
            scan(kind)
        }
    }

    func scan(_ kind: CleanupTaskKind) {
        setState(for: kind) { $0.isCalculating = true }
        Task {
            let result = await CleanupManager.calculateSize(for: kind)
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
        hasFullDiskAccess = PermissionsHelper.hasFullDiskAccess
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
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAvailableCapacity()
            }
        }
    }

    private func setState(for kind: CleanupTaskKind, mutate: (inout CleanupTaskState) -> Void) {
        guard let index = taskStates.firstIndex(where: { $0.kind == kind }) else { return }
        mutate(&taskStates[index])
    }
}
