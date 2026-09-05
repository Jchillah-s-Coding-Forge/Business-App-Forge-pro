import AppForgeApplication
import Foundation
import XCTest

final class ToolchainCommandRunnerTests: XCTestCase {
    func testRunnerExecutesDirectBinaryAndSanitizesANSIOutput() throws {
        let workingDirectory = FileManager.default.temporaryDirectory
        let request = ToolchainCommandRequest(
            executablePath: "/usr/bin/printf",
            arguments: ["hello \u{001B}[31mred\u{001B}[0m"],
            workingDirectoryPath: workingDirectory.path,
            environment: [:],
            timeoutSeconds: 5
        )

        let result = try SystemToolchainCommandRunner().run(request)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertFalse(result.timedOut)
        XCTAssertEqual(result.output, "hello red")
    }

    func testRunnerTerminatesTimedOutProcess() throws {
        let workingDirectory = FileManager.default.temporaryDirectory
        let request = ToolchainCommandRequest(
            executablePath: "/bin/sleep",
            arguments: ["5"],
            workingDirectoryPath: workingDirectory.path,
            environment: [:],
            timeoutSeconds: 0.1
        )

        let result = try SystemToolchainCommandRunner().run(request)

        XCTAssertTrue(result.timedOut)
        XCTAssertNotEqual(result.exitCode, 0)
    }
}
