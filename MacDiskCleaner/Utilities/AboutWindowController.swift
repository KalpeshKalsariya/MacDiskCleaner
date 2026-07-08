import AppKit
import SwiftUI

/// Kept as a singleton so repeated clicks on the About button reuse the same
/// window instead of stacking up new ones.
@MainActor
final class AboutWindowController {
    static let shared = AboutWindowController()

    private var window: NSWindow?

    private init() {}

    func show() {
        if window == nil {
            let hostingController = NSHostingController(rootView: AboutView())
            let window = NSWindow(contentViewController: hostingController)
            window.title = "About MacDiskCleaner"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
