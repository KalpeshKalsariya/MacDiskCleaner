import Foundation

enum SimulatorManager {
    struct SimctlError: LocalizedError {
        let output: String
        var errorDescription: String? { "simctl failed: \(output)" }
    }

    /// Removes simulator devices whose runtime is no longer installed.
    /// Shelling out to simctl is safer than deleting device directories by hand,
    /// since it keeps CoreSimulator's own device registry consistent.
    static func deleteUnavailableSimulators() throws {
        try run(["simctl", "delete", "unavailable"])
    }

    @discardableResult
    private static func run(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw SimctlError(output: errorOutput.isEmpty ? output : errorOutput)
        }
        return output
    }
}
