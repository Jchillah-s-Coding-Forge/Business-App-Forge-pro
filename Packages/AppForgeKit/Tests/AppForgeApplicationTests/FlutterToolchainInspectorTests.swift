import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class FlutterToolchainInspectorTests: XCTestCase {
    func testInspectorUsesSelectedSDKExecutableAndParsesMachineIdentity() throws {
        let sdkURL = try makeFakeSDK()
        defer { try? FileManager.default.removeItem(at: sdkURL) }

        let runner = RecordingToolchainRunner(
            result: ToolchainCommandResult(
                exitCode: 0,
                output: machineVersionJSON(version: "3.47.2"),
                timedOut: false
            )
        )
        let inspection = try SystemFlutterToolchainInspector(
            runner: runner
        ).inspect(sdkRootPath: sdkURL.path)

        XCTAssertEqual(inspection.identity.flutterVersion, "3.47.2")
        XCTAssertEqual(inspection.identity.channel, "stable")
        XCTAssertEqual(
            inspection.identity.frameworkRevision,
            String(repeating: "a", count: 40)
        )
        XCTAssertEqual(
            inspection.identity.engineRevision,
            String(repeating: "b", count: 40)
        )

        let request = try XCTUnwrap(runner.requests.first)
        XCTAssertEqual(
            request.executablePath,
            sdkURL
                .appendingPathComponent("bin/flutter")
                .resolvingSymlinksInPath()
                .path
        )
        XCTAssertEqual(
            request.arguments,
            ["--no-version-check", "--version", "--machine"]
        )
        XCTAssertFalse(request.executablePath.contains("/bin/sh"))
        XCTAssertNil(request.environment["GITHUB_TOKEN"])
        XCTAssertTrue(
            request.environment["PATH"]?.hasPrefix(sdkURL.path + "/bin:") == true
        )
    }

    func testInspectorRejectsFlutterBelowMinimumVersion() throws {
        let sdkURL = try makeFakeSDK()
        defer { try? FileManager.default.removeItem(at: sdkURL) }

        let runner = RecordingToolchainRunner(
            result: ToolchainCommandResult(
                exitCode: 0,
                output: machineVersionJSON(version: "3.20.0"),
                timedOut: false
            )
        )

        XCTAssertThrowsError(
            try SystemFlutterToolchainInspector(
                runner: runner
            ).inspect(sdkRootPath: sdkURL.path)
        ) { error in
            XCTAssertEqual(
                error as? FlutterMaterializationError,
                .incompatibleFlutterVersion(
                    actual: "3.20.0",
                    minimum: "3.44.0"
                )
            )
        }
    }

    func testInspectorRejectsMalformedProvenance() throws {
        let sdkURL = try makeFakeSDK()
        defer { try? FileManager.default.removeItem(at: sdkURL) }

        let malformed = machineVersionJSON(
            version: "3.47.2",
            frameworkRevision: "not-a-revision"
        )
        let runner = RecordingToolchainRunner(
            result: ToolchainCommandResult(
                exitCode: 0,
                output: malformed,
                timedOut: false
            )
        )

        XCTAssertThrowsError(
            try SystemFlutterToolchainInspector(
                runner: runner
            ).inspect(sdkRootPath: sdkURL.path)
        ) { error in
            XCTAssertEqual(
                error as? FlutterMaterializationError,
                .invalidFlutterToolchainMetadata
            )
        }
    }

    private func makeFakeSDK() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "appforge-sdk-tests-\(UUID().uuidString)",
            isDirectory: true
        )
        let bin = root.appendingPathComponent("bin", isDirectory: true)
        try FileManager.default.createDirectory(
            at: bin,
            withIntermediateDirectories: true
        )

        let executable = bin.appendingPathComponent("flutter")
        guard FileManager.default.createFile(
            atPath: executable.path,
            contents: Data()
        ) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: executable.path
        )
        return root
    }

    private func machineVersionJSON(
        version: String,
        frameworkRevision: String = String(repeating: "a", count: 40)
    ) -> String {
        """
        {
          "flutterVersion": "\(version)",
          "channel": "stable",
          "frameworkRevision": "\(frameworkRevision)",
          "engineRevision": "\(String(repeating: "b", count: 40))",
          "dartSdkVersion": "3.11.0"
        }
        """
    }
}

private final class RecordingToolchainRunner: ToolchainCommandRunning, @unchecked Sendable {
    private let result: ToolchainCommandResult
    private(set) var requests: [ToolchainCommandRequest] = []

    init(result: ToolchainCommandResult) {
        self.result = result
    }

    func run(
        _ request: ToolchainCommandRequest
    ) throws -> ToolchainCommandResult {
        requests.append(request)
        return result
    }
}
