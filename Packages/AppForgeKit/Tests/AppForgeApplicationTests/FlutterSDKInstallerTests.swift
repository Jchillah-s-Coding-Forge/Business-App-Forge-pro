import AppForgeApplication
import AppForgeCore
import AppForgeDomain
import Foundation
import XCTest

final class FlutterSDKInstallerTests: XCTestCase {
    func testSuccessfulInstallReportsOrderedPhasesAndSDKPath() async throws {
        let fixture = try InstallationFixture()
        defer { fixture.cleanup() }
        let recorder = PhaseRecorder()
        let installer = fixture.makeInstaller(checksumMatches: true)

        let result = try await installer.install(into: fixture.parentURL.path) { phase in
            await recorder.append(phase)
        }

        XCTAssertEqual(result.sdkPath, fixture.parentURL.appendingPathComponent("flutter").path)
        XCTAssertEqual(result.version, "3.47.0")
        let phases = await recorder.phases
        XCTAssertEqual(
            phases,
            [.resolvingRelease, .downloading, .verifying, .extracting, .validating, .completed]
        )
    }

    func testChecksumMismatchStopsBeforeExtraction() async throws {
        let fixture = try InstallationFixture()
        defer { fixture.cleanup() }
        let installer = fixture.makeInstaller(
            checksumMatches: false,
            extractor: FailingIfCalledExtractor()
        )

        do {
            _ = try await installer.install(into: fixture.parentURL.path) { _ in }
            XCTFail("Expected checksum validation to fail")
        } catch let error as AppForgeError {
            XCTAssertTrue(error.technicalMessage.contains("Prüfsumme"))
        }
    }

    func testExistingFlutterDirectoryIsNeverOverwritten() async throws {
        let fixture = try InstallationFixture()
        defer { fixture.cleanup() }
        let existingSDK = fixture.parentURL.appendingPathComponent("flutter", isDirectory: true)
        try FileManager.default.createDirectory(at: existingSDK, withIntermediateDirectories: false)
        let installer = fixture.makeInstaller(checksumMatches: true)

        do {
            _ = try await installer.install(into: fixture.parentURL.path) { _ in }
            XCTFail("Expected existing target to be rejected")
        } catch let error as AppForgeError {
            XCTAssertTrue(error.technicalMessage.contains("existiert bereits"))
        }
    }

    func testValidationFailureLeavesNoPartialInstallation() async throws {
        let fixture = try InstallationFixture()
        defer { fixture.cleanup() }
        let installer = fixture.makeInstaller(
            checksumMatches: true,
            validator: FailingValidator()
        )

        do {
            _ = try await installer.install(into: fixture.parentURL.path) { _ in }
            XCTFail("Expected validation to fail")
        } catch {
            let flutterURL = fixture.parentURL.appendingPathComponent("flutter")
            XCTAssertFalse(FileManager.default.fileExists(atPath: flutterURL.path))
            let contents = try FileManager.default.contentsOfDirectory(atPath: fixture.parentURL.path)
            let stagingEntries = contents.filter { $0.hasPrefix(".appforge-flutter-install-") }
            XCTAssertTrue(stagingEntries.isEmpty)
        }
    }
}

private struct InstallationFixture {
    let parentURL: URL
    let archiveURL: URL

    init() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("appforge-installer-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let archive = root.appendingPathComponent("flutter.zip")
        try Data("archive".utf8).write(to: archive)

        parentURL = root.appendingPathComponent("sdk", isDirectory: true)
        archiveURL = archive
        try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
    }

    func makeInstaller(
        checksumMatches: Bool,
        extractor: any FlutterArchiveExtracting = StagingExtractor(),
        validator: any FlutterSDKValidating = NoopValidator()
    ) -> VerifiedFlutterSDKInstaller {
        VerifiedFlutterSDKInstaller(
            catalog: StubCatalog(),
            downloader: StubDownloader(sourceURL: archiveURL),
            checksumVerifier: StubChecksumVerifier(matches: checksumMatches),
            extractor: extractor,
            validator: validator
        )
    }

    func cleanup() {
        let root = parentURL.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: root)
    }
}

private struct StubCatalog: FlutterReleaseCatalogProviding {
    func latestStable(for architecture: FlutterSDKArchitecture) async throws -> FlutterReleaseArtifact {
        FlutterReleaseArtifact(
            version: "3.47.0",
            architecture: architecture,
            archivePath: "stable/macos/flutter.zip",
            sha256: String(repeating: "a", count: 64)
        )
    }
}

private struct StubDownloader: FlutterArchiveDownloading {
    let sourceURL: URL

    func download(_ artifact: FlutterReleaseArtifact) async throws -> URL {
        let copyURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("appforge-download-test-\(UUID().uuidString).zip")
        try FileManager.default.copyItem(at: sourceURL, to: copyURL)
        return copyURL
    }
}

private struct StubChecksumVerifier: FlutterArchiveChecksumVerifying {
    let matches: Bool

    func verify(fileURL: URL, expectedSHA256: String) throws -> Bool {
        matches
    }
}

private struct StagingExtractor: FlutterArchiveExtracting {
    func extract(archiveURL: URL, into parentDirectoryURL: URL) throws {
        let flutterURL = parentDirectoryURL.appendingPathComponent("flutter", isDirectory: true)
        try FileManager.default.createDirectory(at: flutterURL, withIntermediateDirectories: false)
    }
}

private struct FailingIfCalledExtractor: FlutterArchiveExtracting {
    func extract(archiveURL: URL, into parentDirectoryURL: URL) throws {
        XCTFail("Extractor must not run after checksum mismatch")
    }
}

private struct NoopValidator: FlutterSDKValidating {
    func validate(sdkURL: URL) throws {}
}

private struct FailingValidator: FlutterSDKValidating {
    func validate(sdkURL: URL) throws {
        throw AppForgeError.configuration(message: "Validation failed")
    }
}

private actor PhaseRecorder {
    private(set) var phases: [FlutterInstallationPhase] = []

    func append(_ phase: FlutterInstallationPhase) {
        phases.append(phase)
    }
}
