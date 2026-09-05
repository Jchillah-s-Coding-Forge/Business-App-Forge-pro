import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class NixBootstrapPreparationTests: XCTestCase {
    func testPrepareDownloadsPinnedReleaseAndCreatesControlledWorkspace() async throws {
        let parent = try NixBootstrapTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parent) }

        let downloader = StubNixInstallerDownloader(
            result: NixBootstrapTestSupport.download()
        )
        let prepared = try await PrepareNixBootstrapUseCase(
            downloader: downloader
        )(
            workspaceParentURL: parent
        )

        XCTAssertEqual(downloader.requestedURLs.count, 1)
        XCTAssertEqual(
            downloader.requestedURLs.first?.absoluteString,
            NixBootstrapReleasePolicy.current.installerURLString
        )
        XCTAssertEqual(prepared.version, "2.35.2")
        XCTAssertEqual(prepared.installerSHA256.count, 64)

        let command = try String(
            contentsOfFile: prepared.commandPath,
            encoding: .utf8
        )
        XCTAssertTrue(
            command.contains(
                "exec /bin/sh \"$SCRIPT_DIR/install.sh\" --daemon"
            )
        )
        XCTAssertFalse(command.contains(parent.path))
        XCTAssertFalse(command.contains("curl"))
        XCTAssertFalse(command.contains("sh -c"))
        XCTAssertEqual(
            NixBootstrapTestSupport.bootstrapDirectories(
                in: parent
            ).count,
            1
        )
    }

    func testPrepareRejectsUnexpectedRedirectTargetWithoutWorkspace() async throws {
        let parent = try NixBootstrapTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parent) }

        let downloader = StubNixInstallerDownloader(
            result: NixBootstrapTestSupport.download(
                responseURL: URL(
                    string: "https://example.com/install"
                )!
            )
        )

        await XCTAssertThrowsErrorAsync(
            try await PrepareNixBootstrapUseCase(
                downloader: downloader
            )(
                workspaceParentURL: parent
            )
        ) { error in
            XCTAssertEqual(
                error as? NixBootstrapError,
                .unexpectedResponseURL
            )
        }
        XCTAssertTrue(
            NixBootstrapTestSupport.bootstrapDirectories(
                in: parent
            ).isEmpty
        )
    }

    func testPrepareRejectsInstallerMissingPinnedDarwinHash() async throws {
        let parent = try NixBootstrapTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parent) }

        var text = String(
            data: NixBootstrapTestSupport.installer(),
            encoding: .utf8
        )!
        text = text.replacingOccurrences(
            of: NixBootstrapReleasePolicy.current
                .aarch64DarwinTarballSHA256,
            with: "missing"
        )
        let downloader = StubNixInstallerDownloader(
            result: NixBootstrapTestSupport.download(
                data: Data(text.utf8)
            )
        )

        await XCTAssertThrowsErrorAsync(
            try await PrepareNixBootstrapUseCase(
                downloader: downloader
            )(
                workspaceParentURL: parent
            )
        ) { error in
            XCTAssertEqual(
                error as? NixBootstrapError,
                .installerStructureMismatch
            )
        }
        XCTAssertTrue(
            NixBootstrapTestSupport.bootstrapDirectories(
                in: parent
            ).isEmpty
        )
    }

    func testPrepareRejectsOversizedInstaller() async throws {
        let parent = try NixBootstrapTestSupport.temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parent) }

        let policy = NixBootstrapReleasePolicy.current
        let oversized = Data(
            repeating: 0x61,
            count: policy.maximumInstallerBytes + 1
        )
        let downloader = StubNixInstallerDownloader(
            result: NixBootstrapTestSupport.download(
                data: oversized
            )
        )

        await XCTAssertThrowsErrorAsync(
            try await PrepareNixBootstrapUseCase(
                downloader: downloader
            )(
                workspaceParentURL: parent
            )
        ) { error in
            XCTAssertEqual(
                error as? NixBootstrapError,
                .installerTooLarge(
                    maximumBytes: policy.maximumInstallerBytes
                )
            )
        }
    }
}

private func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ errorHandler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error")
    } catch {
        errorHandler(error)
    }
}
