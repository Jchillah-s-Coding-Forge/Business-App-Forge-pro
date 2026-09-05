import AppForgeDomain
import Foundation

public protocol NixBootstrapTerminalLaunching: Sendable {
    func launch(commandURL: URL) throws
}

public struct SystemNixBootstrapTerminalLauncher: NixBootstrapTerminalLaunching {
    public init() {}

    public func launch(
        commandURL: URL
    ) throws {
        let process = Process()
        process.executableURL = URL(
            fileURLWithPath: "/usr/bin/open"
        )
        process.arguments = [
            "-a",
            "Terminal",
            commandURL.standardizedFileURL.path
        ]

        do {
            try process.run()
        } catch {
            throw NixBootstrapError.terminalLaunchFailed
        }
    }
}
