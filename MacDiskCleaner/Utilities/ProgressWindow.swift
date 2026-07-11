import AppKit
import Combine

/// Small floating window shown while a cleanup task is running, mirroring the
/// classic "Cleaning..." indicator — bound to a 0...1 fraction rather than a raw count,
/// since cleanup progress here is tracked per-task as a fraction complete.
final class ProgressWindow: NSWindow {

    @Published var progress: Double = 0

    private let progressIndicator: NSProgressIndicator
    private var cancellables = Set<AnyCancellable>()

    init(maxValue: Double = 1) {
        progressIndicator = NSProgressIndicator(frame: NSMakeRect(20, 40, 260, 20))
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = maxValue

        super.init(contentRect: NSMakeRect(0, 0, 300, 100), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        title = "Cleaning..."
        level = .floating
        isReleasedWhenClosed = false
        center()
        contentView?.addSubview(progressIndicator)

        $progress
            .receive(on: DispatchQueue.main)
            .assign(to: \.doubleValue, on: progressIndicator)
            .store(in: &cancellables)
    }
}
