import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            if !viewModel.hasFullDiskAccess {
                fullDiskAccessBanner
                Divider()
            }

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(CleanupTaskKind.allCases) { kind in
                        CleanupRow(kind: kind, state: viewModel.state(for: kind), viewModel: viewModel)
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(maxHeight: 360)

            Divider()
            footer
        }
        .frame(width: 320)
        .alert(
            viewModel.pendingConfirmation?.alertTitle ?? "Confirm Cleanup",
            isPresented: Binding(
                get: { viewModel.pendingConfirmation != nil },
                set: { isPresented in
                    if !isPresented { viewModel.cancelPendingClean() }
                }
            ),
            presenting: viewModel.pendingConfirmation
        ) { target in
            Button("Clean", role: .destructive) { viewModel.confirmPendingClean() }
            Button("Cancel", role: .cancel) { viewModel.cancelPendingClean() }
        } message: { target in
            Text(target.alertMessage)
        }
        .onAppear { viewModel.scanAll() }
    }

    private var header: some View {
        HStack {
            Image(systemName: "internaldrive")
            Text("\(viewModel.availableCapacityText) available")
                .font(.headline)
            Spacer()
            Button {
                viewModel.scanAll()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
        }
        .padding(12)
    }

    private var fullDiskAccessBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Full Disk Access needed", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(.orange)
            Text("Grant access in System Settings to scan and clean every location reliably.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Open System Settings") {
                PermissionsHelper.openFullDiskAccessSettings()
            }
            .font(.caption)
        }
        .padding(12)
    }

    private var footer: some View {
        HStack {
            Button("Clean All") {
                viewModel.requestCleanAll()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(!viewModel.hasCleanableContent)
            Text("⇧⌘E")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("⌘Q")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .padding(12)
    }
}

private struct CleanupRow: View {
    let kind: CleanupTaskKind
    let state: CleanupTaskState
    @ObservedObject var viewModel: MenuViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(kind.title)
                    .font(.body)
                if state.isCalculating {
                    Text("Calculating…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if state.isAccessRestricted && state.sizeBytes == 0 {
                    Text("Permission needed")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text(ByteCountFormatter.string(fromByteCount: state.sizeBytes, countStyle: .file))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let error = state.lastError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }
            Spacer()
            Text(kind.shortcutLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            if state.isCleaning {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button("Clean") {
                    viewModel.requestClean(kind)
                }
                .keyboardShortcut(KeyEquivalent(kind.shortcutKey), modifiers: [.command, .shift])
                .disabled(!state.isCleanable)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
