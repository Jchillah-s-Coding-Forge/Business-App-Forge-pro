import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class NixFlutterProjectMaterializerTests: XCTestCase {
    func testNixMaterializerUsesPinnedEnvironmentAndWritesProvenance() throws {
        let fixture = try NixFlutterMaterializerTestSupport.makeFixture()
        defer {
            try? FileManager.default.removeItem(
                at: fixture.rootURL
            )
        }
        let runner = NixMaterializationToolchainRunner()

        let result = try MaterializeFlutterProjectUseCase(
            runner: runner
        )(
            NixFlutterMaterializerTestSupport.input(fixture)
        )

        XCTAssertEqual(
            result.projectPath,
            fixture.targetURL.path
        )
        try assertPublishedProject(
            fixture: fixture
        )
        assertNixCommandContract(
            runner.requests,
            fixture: fixture
        )
        try assertNixReceipt(
            result,
            fixture: fixture
        )
    }

    func testTamperedFlakeFailsBeforeProcessOrStaging() throws {
        let fixture = try NixFlutterMaterializerTestSupport.makeFixture()
        defer {
            try? FileManager.default.removeItem(
                at: fixture.rootURL
            )
        }
        let flakeURL = fixture.environmentURL
            .appendingPathComponent("flake.nix")
        try "\n# tampered\n".append(to: flakeURL)
        let runner = NixMaterializationToolchainRunner()

        assertPreflightFailure(
            fixture: fixture,
            runner: runner,
            expected: .nixEnvironmentReceiptMismatch
        )
    }

    func testTamperedLockFailsBeforeProcessOrStaging() throws {
        let fixture = try NixFlutterMaterializerTestSupport.makeFixture()
        defer {
            try? FileManager.default.removeItem(
                at: fixture.rootURL
            )
        }
        let lockURL = fixture.environmentURL
            .appendingPathComponent("flake.lock")
        try "\n".append(to: lockURL)
        let runner = NixMaterializationToolchainRunner()

        assertPreflightFailure(
            fixture: fixture,
            runner: runner,
            expected: .nixEnvironmentReceiptMismatch
        )
    }

    func testReceiptLockDigestMismatchFailsClosed() throws {
        let fixture = try NixFlutterMaterializerTestSupport.makeFixture(
            receiptLockSHA256: String(
                repeating: "0",
                count: 64
            )
        )
        defer {
            try? FileManager.default.removeItem(
                at: fixture.rootURL
            )
        }
        let runner = NixMaterializationToolchainRunner()

        assertPreflightFailure(
            fixture: fixture,
            runner: runner,
            expected: .nixEnvironmentReceiptMismatch
        )
    }

    func testReceiptRevisionMismatchFailsClosed() throws {
        let fixture = try NixFlutterMaterializerTestSupport.makeFixture(
            receiptRevision: String(
                repeating: "d",
                count: 40
            )
        )
        defer {
            try? FileManager.default.removeItem(
                at: fixture.rootURL
            )
        }
        let runner = NixMaterializationToolchainRunner()

        assertPreflightFailure(
            fixture: fixture,
            runner: runner,
            expected: .nixEnvironmentReceiptMismatch
        )
    }

    func testEnvironmentWithoutFlutterFailsBeforeProcess() throws {
        let fixture = try NixFlutterMaterializerTestSupport.makeFixture(
            packages: [.git]
        )
        defer {
            try? FileManager.default.removeItem(
                at: fixture.rootURL
            )
        }
        let runner = NixMaterializationToolchainRunner()

        assertPreflightFailure(
            fixture: fixture,
            runner: runner,
            expected: .nixEnvironmentMissingFlutter
        )
    }

    private func assertPreflightFailure(
        fixture: NixFlutterMaterializationFixture,
        runner: NixMaterializationToolchainRunner,
        expected: FlutterMaterializationError
    ) {
        XCTAssertThrowsError(
            try MaterializeFlutterProjectUseCase(
                runner: runner
            )(
                NixFlutterMaterializerTestSupport.input(
                    fixture
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterMaterializationError,
                expected
            )
        }

        XCTAssertTrue(runner.requests.isEmpty)
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: fixture.targetURL.path
            )
        )
        XCTAssertTrue(
            NixFlutterMaterializerTestSupport.stagingDirectories(
                in: fixture.rootURL
            ).isEmpty
        )
    }

    private func assertPublishedProject(
        fixture: NixFlutterMaterializationFixture
    ) throws {
        for relativePath in [
            "ios",
            "android",
            "test/app_smoke_test.dart",
            "pubspec.lock"
        ] {
            XCTAssertTrue(
                FileManager.default.fileExists(
                    atPath: fixture.targetURL
                        .appendingPathComponent(relativePath)
                        .path
                )
            )
        }

        XCTAssertTrue(
            NixFlutterMaterializerTestSupport.stagingDirectories(
                in: fixture.rootURL
            ).isEmpty
        )
    }

    private func assertNixCommandContract(
        _ requests: [ToolchainCommandRequest],
        fixture: NixFlutterMaterializationFixture
    ) {
        XCTAssertEqual(requests.count, 6)
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
        XCTAssertEqual(
            requests[0].arguments,
            ["--version"]
        )

        for request in requests.dropFirst() {
            XCTAssertEqual(
                Array(request.arguments.prefix(7)),
                [
                    "--extra-experimental-features",
                    "nix-command flakes",
                    "develop",
                    fixture.environmentURL.path,
                    "--command",
                    "flutter",
                    "--no-version-check"
                ]
            )
            XCTAssertNil(
                request.environment["GITHUB_TOKEN"]
            )
            XCTAssertNil(
                request.environment["OPENAI_API_KEY"]
            )
        }

        XCTAssertTrue(
            requests[2].arguments.contains("create")
        )
        XCTAssertTrue(
            requests[3].arguments.contains("pub")
        )
        XCTAssertTrue(
            requests[4].arguments.contains("analyze")
        )
        XCTAssertTrue(
            requests[5].arguments.contains("test")
        )
    }

    private func assertNixReceipt(
        _ result: FlutterMaterializationResult,
        fixture: NixFlutterMaterializationFixture
    ) throws {
        let receiptURL = fixture.targetURL
            .appendingPathComponent(
                FlutterToolchainReceipt.defaultFileName
            )
        let data = try Data(contentsOf: receiptURL)
        let receipt = try FlutterToolchainReceiptCodec()
            .decode(data)

        XCTAssertEqual(receipt, result.receipt)
        XCTAssertEqual(receipt.schemaVersion, 2)
        XCTAssertEqual(
            receipt.executionMode,
            .nixEnvironment
        )
        XCTAssertEqual(
            receipt.nixEnvironment,
            FlutterNixEnvironmentProvenance(
                nixpkgsLockedRevision: fixture.nixpkgsRevision,
                flakeLockSHA256: fixture.flakeLockSHA256
            )
        )
        XCTAssertEqual(
            receipt.flutter.flutterVersion,
            "3.47.2"
        )

        let text = String(
            bytes: data,
            encoding: .utf8
        ) ?? ""
        XCTAssertFalse(
            text.contains(fixture.environmentURL.path)
        )
        XCTAssertFalse(text.contains("/nix/bin/nix"))
    }
}

private extension String {
    func append(
        to url: URL
    ) throws {
        let existing = try String(
            contentsOf: url,
            encoding: .utf8
        )
        try (existing + self).write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }
}
