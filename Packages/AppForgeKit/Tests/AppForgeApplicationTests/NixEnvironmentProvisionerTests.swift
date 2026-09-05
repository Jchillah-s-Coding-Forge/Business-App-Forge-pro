import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class NixEnvironmentProvisionerTests: XCTestCase {
    func testProvisionerLocksValidatesAndPublishesEnvironment() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent(
            "nix-environment",
            isDirectory: true
        )
        let runner = NixProvisioningRunner()
        let plan = try makePlan()

        let result = try ProvisionNixEnvironmentUseCase(
            runner: runner
        )(
            NixEnvironmentProvisioningInput(
                plan: plan,
                nixExecutablePath: "/nix/bin/nix",
                targetURL: targetURL
            )
        )

        XCTAssertEqual(
            result.environmentPath,
            targetURL.standardizedFileURL.path
        )
        try assertPublishedFiles(
            targetURL: targetURL,
            result: result
        )
        assertCommandContract(runner.requests)
        try assertReceiptIsPathFree(
            targetURL: targetURL,
            parentURL: parentURL
        )
        XCTAssertTrue(stagingDirectories(in: parentURL).isEmpty)
    }

    func testLockFailureDoesNotPublishOrLeaveStaging() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent(
            "failed-environment",
            isDirectory: true
        )
        let runner = NixProvisioningRunner(failingCommand: .lock)

        XCTAssertThrowsError(
            try ProvisionNixEnvironmentUseCase(
                runner: runner
            )(
                NixEnvironmentProvisioningInput(
                    plan: try makePlan(),
                    nixExecutablePath: "/nix/bin/nix",
                    targetURL: targetURL
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? NixEnvironmentError,
                .commandFailed(
                    command: "nix flake lock",
                    exitCode: 2,
                    output: "simulated lock failure"
                )
            )
        }

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: targetURL.path)
        )
        XCTAssertTrue(stagingDirectories(in: parentURL).isEmpty)
    }

    func testIncompatibleNixVersionFailsBeforeLocking() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent(
            "old-nix",
            isDirectory: true
        )
        let runner = NixProvisioningRunner(
            nixVersionOutput: "nix (Nix) 2.3.16"
        )

        XCTAssertThrowsError(
            try ProvisionNixEnvironmentUseCase(
                runner: runner
            )(
                NixEnvironmentProvisioningInput(
                    plan: try makePlan(),
                    nixExecutablePath: "/nix/bin/nix",
                    targetURL: targetURL
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? NixEnvironmentError,
                .incompatibleNixVersion(
                    actual: "2.3.16",
                    minimum: "2.4.0"
                )
            )
        }

        XCTAssertEqual(runner.requests.count, 1)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: targetURL.path)
        )
        XCTAssertTrue(stagingDirectories(in: parentURL).isEmpty)
    }

    func testExistingTargetFailsBeforeExecutingNix() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent(
            "existing",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: targetURL,
            withIntermediateDirectories: false
        )
        let runner = NixProvisioningRunner()

        XCTAssertThrowsError(
            try ProvisionNixEnvironmentUseCase(
                runner: runner
            )(
                NixEnvironmentProvisioningInput(
                    plan: try makePlan(),
                    nixExecutablePath: "/nix/bin/nix",
                    targetURL: targetURL
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? NixEnvironmentError,
                .targetAlreadyExists
            )
        }

        XCTAssertTrue(runner.requests.isEmpty)
    }

    func testRelativeNixExecutableFailsClosed() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        XCTAssertThrowsError(
            try ProvisionNixEnvironmentUseCase(
                runner: NixProvisioningRunner()
            )(
                NixEnvironmentProvisioningInput(
                    plan: try makePlan(),
                    nixExecutablePath: "nix",
                    targetURL: parentURL.appendingPathComponent("invalid")
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? NixEnvironmentError,
                .invalidNixExecutable
            )
        }
    }

    private func assertPublishedFiles(
        targetURL: URL,
        result: NixEnvironmentProvisioningResult
    ) throws {
        for name in [
            "flake.nix",
            "flake.lock",
            NixEnvironmentReceipt.defaultFileName
        ] {
            XCTAssertTrue(
                FileManager.default.fileExists(
                    atPath: targetURL.appendingPathComponent(name).path
                )
            )
        }

        XCTAssertEqual(result.receipt.nixVersion, "2.32.1")
        XCTAssertEqual(result.receipt.validationTool, "flutter")
        XCTAssertEqual(result.receipt.validationVersion, "3.47.2")
        XCTAssertEqual(
            result.receipt.nixpkgsLockedRevision,
            String(repeating: "a", count: 40)
        )
        XCTAssertEqual(result.receipt.flakeLockSHA256.count, 64)
    }

    private func assertCommandContract(
        _ requests: [ToolchainCommandRequest]
    ) {
        XCTAssertEqual(requests.count, 3)
        XCTAssertTrue(
            requests.allSatisfy {
                $0.executablePath == "/nix/bin/nix"
            }
        )
        XCTAssertTrue(
            requests.allSatisfy {
                !$0.executablePath.contains("/bin/sh")
            }
        )

        XCTAssertEqual(requests[0].arguments, ["--version"])
        XCTAssertEqual(
            requests[1].arguments,
            [
                "--extra-experimental-features",
                "nix-command flakes",
                "flake",
                "lock"
            ]
        )
        XCTAssertEqual(
            requests[2].arguments,
            [
                "--extra-experimental-features",
                "nix-command flakes",
                "develop",
                "--command",
                "flutter",
                "--version"
            ]
        )
        XCTAssertNil(requests[1].environment["GITHUB_TOKEN"])
        XCTAssertNil(requests[1].environment["OPENAI_API_KEY"])
    }

    private func assertReceiptIsPathFree(
        targetURL: URL,
        parentURL: URL
    ) throws {
        let data = try Data(
            contentsOf: targetURL.appendingPathComponent(
                NixEnvironmentReceipt.defaultFileName
            )
        )
        let decoded = try NixEnvironmentReceiptCodec().decode(data)
        let text = String(bytes: data, encoding: .utf8) ?? ""

        XCTAssertEqual(decoded.validationTool, "flutter")
        XCTAssertFalse(text.contains(parentURL.path))
        XCTAssertFalse(text.contains("/nix/bin/nix"))
    }

    private func makePlan() throws -> NixEnvironmentPlan {
        let specification = ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )
        return try NixEnvironmentPlanner().plan(for: specification)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "appforge-nix-tests-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )
        return url
    }

    private func stagingDirectories(
        in parentURL: URL
    ) -> [URL] {
        let contents = (
            try? FileManager.default.contentsOfDirectory(
                at: parentURL,
                includingPropertiesForKeys: nil
            )
        ) ?? []

        return contents.filter {
            $0.lastPathComponent.hasPrefix(".appforge-nix-")
        }
    }
}

private enum NixProvisioningCommand {
    case version
    case lock
    case validateFlutter
}

private final class NixProvisioningRunner: ToolchainCommandRunning, @unchecked Sendable {
    private let failingCommand: NixProvisioningCommand?
    private let nixVersionOutput: String
    private(set) var requests: [ToolchainCommandRequest] = []

    init(
        failingCommand: NixProvisioningCommand? = nil,
        nixVersionOutput: String = "nix (Nix) 2.32.1"
    ) {
        self.failingCommand = failingCommand
        self.nixVersionOutput = nixVersionOutput
    }

    func run(
        _ request: ToolchainCommandRequest
    ) throws -> ToolchainCommandResult {
        requests.append(request)
        let command = command(for: request.arguments)

        if failingCommand == command {
            return ToolchainCommandResult(
                exitCode: 2,
                output: "simulated \(failureName(command)) failure",
                timedOut: false
            )
        }

        switch command {
        case .version:
            return result(output: nixVersionOutput)
        case .lock:
            try writeLock(
                in: URL(
                    fileURLWithPath: request.workingDirectoryPath,
                    isDirectory: true
                )
            )
            return result(output: "")
        case .validateFlutter:
            return result(
                output: "Flutter 3.47.2 • channel stable • Dart 3.11.0"
            )
        }
    }

    private func command(
        for arguments: [String]
    ) -> NixProvisioningCommand {
        if arguments == ["--version"] {
            return .version
        }
        if arguments.contains("flake"),
           arguments.contains("lock") {
            return .lock
        }
        return .validateFlutter
    }

    private func failureName(
        _ command: NixProvisioningCommand
    ) -> String {
        switch command {
        case .version:
            "version"
        case .lock:
            "lock"
        case .validateFlutter:
            "validation"
        }
    }

    private func result(
        output: String
    ) -> ToolchainCommandResult {
        ToolchainCommandResult(
            exitCode: 0,
            output: output,
            timedOut: false
        )
    }

    private func writeLock(
        in directory: URL
    ) throws {
        let revision = String(repeating: "a", count: 40)
        let json = """
        {
          "nodes": {
            "nixpkgs": {
              "locked": {
                "lastModified": 1780000000,
                "narHash": "sha256-test",
                "owner": "NixOS",
                "repo": "nixpkgs",
                "rev": "\(revision)",
                "type": "github"
              }
            },
            "root": {
              "inputs": {
                "nixpkgs": "nixpkgs"
              }
            }
          },
          "root": "root",
          "version": 7
        }
        """
        try json.write(
            to: directory.appendingPathComponent("flake.lock"),
            atomically: true,
            encoding: .utf8
        )
    }
}
