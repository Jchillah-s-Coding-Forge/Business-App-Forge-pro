import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class LiveFlutterMaterializationGateTests: XCTestCase {
    func testFreshGeneratedFormAppIsFormattedAndBuildsForIOS() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let sdkPath = environment["APPFORGE_LIVE_FLUTTER_SDK"],
              !sdkPath.isEmpty
        else {
            throw XCTSkip(
                "Set APPFORGE_LIVE_FLUTTER_SDK to run the live Flutter product gate."
            )
        }

        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "appforge-live-flutter-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: false
        )
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let targetURL = rootURL.appendingPathComponent(
            "inventory_app",
            isDirectory: true
        )
        let result = try BuildFlutterProjectUseCase()(
            specification: makeSpecification(),
            toolchain: .directSDK(path: sdkPath),
            targetURL: targetURL
        )

        XCTAssertEqual(result.projectPath, targetURL.path)
        XCTAssertTrue(
            result.toolchainReceipt.validatedSteps.contains(.format)
        )
        try assertFormattingIsStable(
            projectURL: targetURL,
            sdkPath: sdkPath
        )
        try assertIOSSimulatorBuilds(
            projectURL: targetURL,
            sdkPath: sdkPath
        )
    }
}

private extension LiveFlutterMaterializationGateTests {
    func assertFormattingIsStable(
        projectURL: URL,
        sdkPath: String
    ) throws {
        let result = try run(
            executablePath: sdkPath + "/bin/dart",
            arguments: [
                "format",
                "--output=none",
                "--set-exit-if-changed",
                "lib",
                "test"
            ],
            projectURL: projectURL,
            sdkPath: sdkPath,
            timeoutSeconds: 300
        )
        XCTAssertEqual(result.exitCode, 0, result.output)
        XCTAssertFalse(result.timedOut, result.output)
    }

    func assertIOSSimulatorBuilds(
        projectURL: URL,
        sdkPath: String
    ) throws {
        let result = try run(
            executablePath: sdkPath + "/bin/flutter",
            arguments: [
                "--no-version-check",
                "build",
                "ios",
                "--simulator",
                "--no-codesign"
            ],
            projectURL: projectURL,
            sdkPath: sdkPath,
            timeoutSeconds: 1200
        )
        XCTAssertEqual(result.exitCode, 0, result.output)
        XCTAssertFalse(result.timedOut, result.output)
    }

    func run(
        executablePath: String,
        arguments: [String],
        projectURL: URL,
        sdkPath: String,
        timeoutSeconds: TimeInterval
    ) throws -> ToolchainCommandResult {
        try SystemToolchainCommandRunner().run(
            ToolchainCommandRequest(
                executablePath: executablePath,
                arguments: arguments,
                workingDirectoryPath: projectURL.path,
                environment: processEnvironment(sdkPath: sdkPath),
                timeoutSeconds: timeoutSeconds
            )
        )
    }

    func processEnvironment(
        sdkPath: String
    ) -> [String: String] {
        let inherited = ProcessInfo.processInfo.environment
        var environment = [
            "PATH": sdkPath
                + "/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "CI": "true",
            "TERM": "dumb",
            "LANG": "en_US.UTF-8",
            "LC_ALL": "en_US.UTF-8",
            "PUB_ENVIRONMENT": "appforge-live-test"
        ]
        for key in ["HOME", "TMPDIR"] {
            if let value = inherited[key], !value.isEmpty {
                environment[key] = value
            }
        }
        return environment
    }

    func makeSpecification() -> ProjectSpecification {
        let asset = makeAsset()

        return ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "dev.appforge.integration"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS],
            backend: .localOnly,
            flutterStateManagement: .riverpod,
            entities: [asset],
            fieldPresentations: makePresentations(),
            screens: makeScreens(entityID: asset.id)
        )
    }

    func makeAsset() -> EntityDefinition {
        let nameField = FieldDefinition(
            identity: DefinitionIdentity(
                id: "field.asset.name",
                code: "name",
                label: "Name"
            ),
            dataType: .string,
            isRequired: true
        )
        let activeField = FieldDefinition(
            identity: DefinitionIdentity(
                id: "field.asset.active",
                code: "active",
                label: "Aktiv"
            ),
            dataType: .boolean,
            defaultValue: .boolean(true)
        )
        return EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: [nameField, activeField]
        )
    }

    func makePresentations() -> [FieldPresentationDefinition] {
        [
            FieldPresentationDefinition(
                id: "presentation.asset.name",
                target: .field("field.asset.name"),
                control: .textField
            ),
            FieldPresentationDefinition(
                id: "presentation.asset.active",
                target: .field("field.asset.active"),
                control: .checkbox
            )
        ]
    }

    func makeScreens(
        entityID: String
    ) -> [ScreenDefinition] {
        [
            ScreenDefinition(
                identity: DefinitionIdentity(
                    id: "screen.asset.form",
                    code: "asset_form",
                    label: "Asset erfassen"
                ),
                kind: .form,
                entityID: entityID,
                visibleFieldIDs: [
                    "field.asset.name",
                    "field.asset.active"
                ]
            )
        ]
    }
}
