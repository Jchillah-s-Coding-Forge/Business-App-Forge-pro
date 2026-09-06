@testable import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class IDEHandoffTests: XCTestCase {
    func testDetectorUsesBundleIdentifiersAndAlwaysOffersSafeFallbacks() {
        let locator = StubMacOSApplicationLocator(
            paths: [
                "com.microsoft.VSCode":
                    "/Applications/Visual Studio Code.app",
                "com.google.android.studio":
                    "/Applications/Android Studio.app",
                "com.apple.Terminal":
                    "/System/Applications/Utilities/Terminal.app"
            ]
        )
        let detector = SystemIDEHandoffDetector(
            locator: locator
        )

        let results = detector.detect()

        XCTAssertEqual(
            availability(.vsCode, in: results)?.applicationPath,
            "/Applications/Visual Studio Code.app"
        )
        XCTAssertEqual(
            availability(.androidStudio, in: results)?.applicationPath,
            "/Applications/Android Studio.app"
        )
        XCTAssertFalse(
            availability(.xcode, in: results)?.isAvailable
                ?? true
        )
        XCTAssertTrue(
            availability(.finder, in: results)?.isAvailable
                ?? false
        )
        XCTAssertTrue(
            availability(.systemDefault, in: results)?.isAvailable
                ?? false
        )
        XCTAssertEqual(
            Set(locator.requestedBundleIdentifiers),
            [
                "com.microsoft.VSCode",
                "com.google.android.studio",
                "com.apple.dt.Xcode",
                "com.apple.Terminal"
            ]
        )
    }

    func testExecutableToolDetectorUsesBundleAwareApplicationLocator() {
        let locator = StubMacOSApplicationLocator(
            paths: [
                "com.microsoft.VSCode":
                    "/Users/test/Applications/Visual Studio Code.app"
            ]
        )
        let detector = ExecutableToolDetector(
            applicationLocator: locator
        )
        let requirement = ToolRequirement(
            id: .vsCode,
            displayName: "VS Code",
            purpose: "IDE Handoff",
            isRequired: false,
            installStrategy: .externalApplication
        )

        let result = detector.detect(
            requirement: requirement,
            flutterSDKPath: nil
        )

        XCTAssertEqual(result.availability, .ready)
        XCTAssertEqual(
            result.path,
            "/Users/test/Applications/Visual Studio Code.app"
        )
        XCTAssertEqual(
            locator.requestedBundleIdentifiers,
            ["com.microsoft.VSCode"]
        )
    }

    func testSystemLocatorPrefersKnownApplicationPath() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "appforge-ide-locator-\(UUID().uuidString)",
                isDirectory: true
            )
        let applicationURL = root.appendingPathComponent(
            "Test IDE.app",
            isDirectory: true
        )
        defer {
            try? FileManager.default.removeItem(at: root)
        }
        try FileManager.default.createDirectory(
            at: applicationURL,
            withIntermediateDirectories: true
        )

        let path = SystemMacOSApplicationLocator().locate(
            bundleIdentifier: "com.example.not-indexed",
            knownPaths: [applicationURL.path]
        )

        XCTAssertEqual(
            path,
            applicationURL.standardizedFileURL.path
        )
    }

    func testCommandBuilderUsesBundleIDsAndProjectRoot() {
        let builder = IDEHandoffCommandBuilder()
        let projectURL = URL(
            fileURLWithPath: "/tmp/appforge-project",
            isDirectory: true
        )
        let expectations = expectedCommands(
            projectURL: projectURL
        )

        for ide in PreferredIDE.allCases {
            XCTAssertEqual(
                builder.arguments(
                    for: ide,
                    projectURL: projectURL
                ),
                expectations[ide]
            )
        }
    }

    private func expectedCommands(
        projectURL: URL
    ) -> [PreferredIDE: [String]] {
        [
            .vsCode: [
                "-b",
                "com.microsoft.VSCode",
                projectURL.path
            ],
            .androidStudio: [
                "-b",
                "com.google.android.studio",
                projectURL.path
            ],
            .xcode: [
                "-b",
                "com.apple.dt.Xcode",
                projectURL.path
            ],
            .finder: [
                "-R",
                projectURL.path
            ],
            .terminal: [
                "-b",
                "com.apple.Terminal",
                projectURL.path
            ],
            .systemDefault: [
                projectURL.path
            ]
        ]
    }

    private func availability(
        _ ide: PreferredIDE,
        in results: [IDEHandoffAvailability]
    ) -> IDEHandoffAvailability? {
        results.first { $0.ide == ide }
    }
}

private final class StubMacOSApplicationLocator: MacOSApplicationLocating, @unchecked Sendable {
    private let lock = NSLock()
    private let paths: [String: String]
    private var storedBundleIdentifiers: [String] = []

    init(paths: [String: String]) {
        self.paths = paths
    }

    var requestedBundleIdentifiers: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storedBundleIdentifiers
    }

    func locate(
        bundleIdentifier: String,
        knownPaths: [String]
    ) -> String? {
        lock.lock()
        storedBundleIdentifiers.append(bundleIdentifier)
        lock.unlock()
        return paths[bundleIdentifier]
    }
}
