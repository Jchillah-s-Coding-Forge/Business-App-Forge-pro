@testable import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class MacOSOpenLauncherTests: XCTestCase {
    func testSystemRunnerCompletesSuccessfulChildProcess() {
        let runner = SystemMacOSOpenCommandRunner(
            executablePath: "/usr/bin/true"
        )

        XCTAssertNoThrow(
            try runner.run(arguments: [])
        )
    }

    func testSystemRunnerRejectsNonZeroChildProcess() {
        let runner = SystemMacOSOpenCommandRunner(
            executablePath: "/usr/bin/false"
        )

        XCTAssertThrowsError(
            try runner.run(arguments: [])
        )
    }

    func testGeneratedProjectOpenerMapsEveryIDEToOneOpenInvocation() throws {
        let runner = RecordingMacOSOpenCommandRunner()
        let opener = SystemGeneratedProjectOpener(
            runner: runner
        )
        let projectURL = URL(
            fileURLWithPath: "/tmp/appforge-project",
            isDirectory: true
        )
        let expectations: [(PreferredIDE, [String])] = [
            (
                .vsCode,
                ["-a", "Visual Studio Code", projectURL.path]
            ),
            (
                .androidStudio,
                ["-a", "Android Studio", projectURL.path]
            ),
            (
                .xcode,
                ["-a", "Xcode", projectURL.path]
            ),
            (
                .finder,
                ["-R", projectURL.path]
            ),
            (
                .terminal,
                ["-a", "Terminal", projectURL.path]
            )
        ]

        for (ide, arguments) in expectations {
            try opener.open(
                projectURL: projectURL,
                preferredIDE: ide
            )
            XCTAssertEqual(
                runner.invocations.last,
                arguments
            )
        }

        XCTAssertEqual(
            runner.invocations.count,
            expectations.count
        )
    }

    func testGeneratedProjectOpenerPropagatesRunnerFailure() {
        let runner = RecordingMacOSOpenCommandRunner(
            error: TestOpenError.failed
        )
        let opener = SystemGeneratedProjectOpener(
            runner: runner
        )

        XCTAssertThrowsError(
            try opener.open(
                projectURL: URL(
                    fileURLWithPath: "/tmp/project"
                ),
                preferredIDE: .finder
            )
        )
        XCTAssertEqual(runner.invocations.count, 1)
    }

    func testExternalURLLauncherOnlyRunsValidatedHTTPSURL() throws {
        let runner = RecordingMacOSOpenCommandRunner()
        let launcher = SystemExternalURLLauncher(
            runner: runner
        )

        try launcher.open(
            urlString: "https://example.com/setup"
        )

        XCTAssertEqual(
            runner.invocations,
            [["https://example.com/setup"]]
        )

        XCTAssertThrowsError(
            try launcher.open(
                urlString: "http://example.com/insecure"
            )
        )
        XCTAssertEqual(runner.invocations.count, 1)
    }

    func testNixBootstrapLauncherRunsExactTerminalCommand() throws {
        let runner = RecordingMacOSOpenCommandRunner()
        let launcher = SystemNixBootstrapTerminalLauncher(
            runner: runner
        )
        let commandURL = URL(
            fileURLWithPath:
                "/tmp/.appforge-nix-bootstrap-test/install.command"
        )

        try launcher.launch(commandURL: commandURL)

        XCTAssertEqual(
            runner.invocations,
            [[
                "-a",
                "Terminal",
                commandURL.standardizedFileURL.path
            ]]
        )
    }

    func testNixBootstrapLauncherMapsRunnerFailure() {
        let runner = RecordingMacOSOpenCommandRunner(
            error: TestOpenError.failed
        )
        let launcher = SystemNixBootstrapTerminalLauncher(
            runner: runner
        )

        XCTAssertThrowsError(
            try launcher.launch(
                commandURL: URL(
                    fileURLWithPath: "/tmp/install.command"
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? NixBootstrapError,
                .terminalLaunchFailed
            )
        }
        XCTAssertEqual(runner.invocations.count, 1)
    }
}

private enum TestOpenError: Error {
    case failed
}

private final class RecordingMacOSOpenCommandRunner:
    MacOSOpenCommandRunning,
    @unchecked Sendable
{
    private let lock = NSLock()
    private let error: Error?
    private var storedInvocations: [[String]] = []

    init(
        error: Error? = nil
    ) {
        self.error = error
    }

    var invocations: [[String]] {
        lock.lock()
        defer { lock.unlock() }
        return storedInvocations
    }

    func run(
        arguments: [String]
    ) throws {
        lock.lock()
        storedInvocations.append(arguments)
        lock.unlock()

        if let error {
            throw error
        }
    }
}
