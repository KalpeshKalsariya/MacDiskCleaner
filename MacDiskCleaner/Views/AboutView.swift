import SwiftUI

struct AboutView: View {
    private let repositoryURL = URL(string: "https://github.com/KalpeshKalsariya/MacDiskCleaner")!

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(version)"
    }

    var body: some View {
        VStack(spacing: 16) {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 96, height: 96)
            }

            VStack(spacing: 4) {
                Text("MacDiskCleaner")
                    .font(.title2.bold())
                Text(versionString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("MacDiskCleaner is a utility designed to help you reclaim disk space by identifying and removing unnecessary developer and system files. It targets Xcode derived data, build caches, archives, unused simulator and device support files, CocoaPods caches, and Trash contents — giving developers and everyday users alike a fast, safe way to keep their Mac running smoothly.")
                .font(.body)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 6) {
                Text("To learn more about this project and its author")
                    .font(.callout)
                Button("Click Here") {
                    NSWorkspace.shared.open(repositoryURL)
                }
                .buttonStyle(.plain)
                .font(.callout.bold())
                .foregroundStyle(.blue)
                .underline()
                .focusEffectDisabled()
            }

            Text("If you find it useful, feel free to star the repository and share your feedback!")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }
}
