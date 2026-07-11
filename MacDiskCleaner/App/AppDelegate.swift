import AppKit
import SwiftUI
import ServiceManagement
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var progressWindow: ProgressWindow?
    private let viewModel = MenuViewModel()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerLoginItem()

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "MDC"
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
        self.statusItem = statusItem

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.contentViewController = NSHostingController(rootView: MenuBarView(viewModel: viewModel))
        self.popover = popover

        observeCleaningProgress()
    }

    /// Shows a floating "Cleaning..." window whenever at least one task is cleaning,
    /// tracking the average fraction complete across all tasks currently in progress.
    private func observeCleaningProgress() {
        viewModel.$taskStates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] states in
                self?.updateProgressWindow(for: states)
            }
            .store(in: &cancellables)
    }

    private func updateProgressWindow(for states: [CleanupTaskState]) {
        let cleaning = states.filter { $0.isCleaning }
        guard !cleaning.isEmpty else {
            progressWindow?.close()
            progressWindow = nil
            return
        }

        let fraction = cleaning.reduce(0.0) { $0 + $1.cleanProgress } / Double(cleaning.count)
        if progressWindow == nil {
            let window = ProgressWindow()
            window.makeKeyAndOrderFront(nil)
            progressWindow = window
        }
        progressWindow?.progress = fraction
    }

    private func registerLoginItem() {
        let service = SMAppService.mainApp

        if service.status == .notRegistered {
            do {
                try service.register()
            } catch {
                NSLog("MacDiskCleaner: failed to register login item: \(error)")
            }
        }

        if service.status == .requiresApproval {
            promptForLoginItemApproval()
        }
    }

    private func promptForLoginItemApproval() {
        let alert = NSAlert()
        alert.messageText = "Enable Login Item"
        alert.informativeText = "MacDiskCleaner needs your approval to start automatically. Open System Settings and turn it on under Login Items & Extensions."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            viewModel.scanIfStale()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
