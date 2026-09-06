import AppForgeDomain
import Foundation

public protocol NixBootstrapTerminalLaunching: Sendable {
    func launch(commandURL: URL) throws
}

public struct SystemNixBootstrapTerminalLauncher: NixBootstrapTerminalLaunching {
    private let runner: any MacOSOpenCommandRunning

    public init() {
        runner = SystemMacOSOpenCommandRunner()
    }

    init(runner: any MacOSOpenCommandRunning) {
        self.runner = runner
    }

    public func launch(
        commandURL: URL
    ) throws {
        do {
            try runner.run(
                arguments: [
                    "-a",
                    "Terminal",
                    commandURL.standardizedFileURL.path
                ]
            )
        } catch {
            throw NixBootstrapError.terminalLaunchFailed
        }
    }
}
