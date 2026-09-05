import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class NixBootstrapLaunchTests: XCTestCase {
    func testValidConfirmationLaunchesExactPreparedCommand() async throws {
        let fixture = try await prepareFixture()
        defer { try? FileManager.default.removeItem(at: fixture.parent) }

        let launcher = RecordingNixBootstrapLauncher()
        try LaunchNixBootstrapUseCase(
            launcher: launcher
        )(
            prepared: fixture.prepared,
            confirmation: NixBootstrapConfirmation(
                approvedInstallerSHA256: fixture.prepared.installerSHA256
            )
        )

        XCTAssertEqual(launcher.commandURLs.count, 1)
        XCTAssertEqual(
            launcher.commandURLs.first?.standardizedFileURL.path,
            URL(
                fileURLWithPath: fixture.prepared.commandPath
            ).standardizedFileURL.path
        )
    }

    func testWrongDigestConfirmationDoesNotLaunch() async throws {
        let fixture = try await prepareFixture()
        defer { try? FileManager.default.removeItem(at: fixture.parent) }

        let launcher = RecordingNixBootstrapLauncher()

        XCTAssertThrowsError(
            try LaunchNixBootstrapUseCase(
                launcher: launcher
            )(
                prepared: fixture.prepared,
                confirmation: NixBootstrapConfirmation(
                    approvedInstallerSHA256: String(
                        repeating: "0",
                        count: 64
                    )
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? NixBootstrapError,
                .confirmationMismatch
            )
        }
        XCTAssertTrue(launcher.commandURLs.isEmpty)
    }

    func testTamperedInstallerDoesNotLaunch() async throws {
        let fixture = try await prepareFixture()
        defer { try? FileManager.default.removeItem(at: fixture.parent) }

        let installerURL = URL(
            fileURLWithPath: fixture.prepared.installerPath
        )
        var data = try Data(contentsOf: installerURL)
        data.append(Data("\n# tampered".utf8))
        try data.write(to: installerURL, options: .atomic)

        let launcher = RecordingNixBootstrapLauncher()

        XCTAssertThrowsError(
            try LaunchNixBootstrapUseCase(
                launcher: launcher
            )(
                prepared: fixture.prepared,
                confirmation: NixBootstrapConfirmation(
                    approvedInstallerSHA256: fixture.prepared.installerSHA256
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? NixBootstrapError,
                .installerDigestMismatch
            )
        }
        XCTAssertTrue(launcher.commandURLs.isEmpty)
    }

    func testTamperedCommandDoesNotLaunch() async throws {
        let fixture = try await prepareFixture()
        defer { try? FileManager.default.removeItem(at: fixture.parent) }

        try "#!/bin/sh\necho changed\n".write(
            toFile: fixture.prepared.commandPath,
            atomically: true,
            encoding: .utf8
        )
        let launcher = RecordingNixBootstrapLauncher()

        XCTAssertThrowsError(
            try LaunchNixBootstrapUseCase(
                launcher: launcher
            )(
                prepared: fixture.prepared,
                confirmation: NixBootstrapConfirmation(
                    approvedInstallerSHA256: fixture.prepared.installerSHA256
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? NixBootstrapError,
                .invalidPreparedWorkspace
            )
        }
        XCTAssertTrue(launcher.commandURLs.isEmpty)
    }

    func testCleanupRemovesOnlyValidatedBootstrapWorkspace() async throws {
        let fixture = try await prepareFixture()
        defer { try? FileManager.default.removeItem(at: fixture.parent) }

        try CleanupNixBootstrapUseCase()(prepared: fixture.prepared)

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: fixture.prepared.workspacePath
            )
        )
    }

    func testFabricatedWorkspacePathIsRejected() {
        let prepared = NixBootstrapPreparedInstaller(
            version: NixBootstrapReleasePolicy.current.version,
            installerSHA256: String(repeating: "a", count: 64),
            workspacePath: "/tmp/not-appforge",
            installerPath: "/tmp/not-appforge/install.sh",
            commandPath: "/tmp/not-appforge/install.command"
        )

        XCTAssertThrowsError(
            try CleanupNixBootstrapUseCase()(prepared: prepared)
        ) { error in
            XCTAssertEqual(
                error as? NixBootstrapError,
                .invalidPreparedWorkspace
            )
        }
    }

    private func prepareFixture() async throws -> BootstrapFixture {
        let parent = try NixBootstrapTestSupport.temporaryDirectory(
            prefix: "appforge-nix-launch-tests"
        )
        let downloader = StubNixInstallerDownloader(
            result: NixBootstrapTestSupport.download()
        )
        let prepared = try await PrepareNixBootstrapUseCase(
            downloader: downloader
        )(
            workspaceParentURL: parent
        )
        return BootstrapFixture(
            parent: parent,
            prepared: prepared
        )
    }
}

private struct BootstrapFixture {
    let parent: URL
    let prepared: NixBootstrapPreparedInstaller
}
