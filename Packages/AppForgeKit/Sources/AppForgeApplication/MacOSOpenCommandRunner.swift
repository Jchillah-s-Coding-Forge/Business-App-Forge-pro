import AppForgeCore
import Foundation

protocol MacOSOpenCommandRunning: Sendable {
    func run(arguments: [String]) throws
}

struct SystemMacOSOpenCommandRunner: MacOSOpenCommandRunning {
    private let executablePath: String

    init(
        executablePath: String = "/usr/bin/open"
    ) {
        self.executablePath = executablePath
    }

    func run(
        arguments: [String]
    ) throws {
        let process = Process()
        process.executableURL = URL(
            fileURLWithPath: executablePath
        )
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            throw AppForgeError.configuration(
                message: "macOS-Handoff konnte nicht gestartet werden: \(error.localizedDescription)"
            )
        }

        guard process.terminationStatus == 0 else {
            throw AppForgeError.configuration(
                message: "macOS-Handoff wurde mit Status \(process.terminationStatus) beendet."
            )
        }
    }
}
