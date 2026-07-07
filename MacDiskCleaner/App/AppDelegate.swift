import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let viewModel = MenuViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = NSImage(named: "MenuBarIcon")
        icon?.size = NSSize(width: 18, height: 18)
        icon?.isTemplate = false // full-color icon — template mode would flatten it to a monochrome silhouette
        icon?.accessibilityDescription = "Mac Disk Cleaner"
        statusItem.button?.image = icon
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
        self.statusItem = statusItem

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 420)
        popover.contentViewController = NSHostingController(rootView: MenuBarView(viewModel: viewModel))
        self.popover = popover
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            viewModel.scanAll()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
