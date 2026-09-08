import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class FlutterProjectMaterializerTests: XCTestCase {
    func testMaterializerCreatesValidatedNativeProjectAndReceipt() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent(
            "inventory_app",
            isDirectory: true
        )
        let fixture = try makeGenerationFixture()
        let runner = MaterializationToolchainRunner()
        let inspector = RecordingFlutterInspector()

        let result = try MaterializeFlutterProjectUseCase(
            inspector: inspector,
            runner: runner
        )(makeInput(fixture, targetURL: targetURL))

        XCTAssertEqual(
            result.projectPath,
            targetURL.standardizedFileURL.path
        )
        assertToolchainContract(
            runner: runner,
            inspector: inspector
        )
        try assertMaterializedProject(targetURL)
        try assertReceipt(
            result,
            targetURL: targetURL,
            parentURL: parentURL
        )
    }

    func testAnalyzeFailureDoesNotPublishOrLeaveStaging() throws {
        try assertFailureDoesNotPublish(step: .analyze)
    }

    func testFormatFailureDoesNotPublishOrLeaveStaging() throws {
        try assertFailureDoesNotPublish(step: .format)
    }

    func testExistingTargetFailsBeforeToolchainInspection() throws {
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
        let fixture = try makeGenerationFixture()
        let inspector = RecordingFlutterInspector()
        let runner = MaterializationToolchainRunner()

        XCTAssertThrowsError(
            try MaterializeFlutterProjectUseCase(
                inspector: inspector,
                runner: runner
            )(makeInput(fixture, targetURL: targetURL))
        ) { error in
            XCTAssertEqual(
                error as? FlutterMaterializationError,
                .targetAlreadyExists
            )
        }

        XCTAssertTrue(inspector.sdkPaths.isEmpty)
        XCTAssertTrue(runner.requests.isEmpty)
    }
}

private extension FlutterProjectMaterializerTests {
    func assertFailureDoesNotPublish(
        step: FlutterMaterializationStep
    ) throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent(
            "failed_app",
            isDirectory: true
        )
        let fixture = try makeGenerationFixture()
        let runner = MaterializationToolchainRunner(
            failingStep: step
        )

        XCTAssertThrowsError(
            try MaterializeFlutterProjectUseCase(
                inspector: RecordingFlutterInspector(),
                runner: runner
            )(makeInput(fixture, targetURL: targetURL))
        ) { error in
            XCTAssertEqual(
                error as? FlutterMaterializationError,
                .commandFailed(
                    step: step,
                    exitCode: 2,
                    output: "simulated \(step.rawValue) failure"
                )
            )
        }

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: targetURL.path)
        )
        XCTAssertTrue(stagingDirectories(in: parentURL).isEmpty)
    }

    func assertToolchainContract(
        runner: MaterializationToolchainRunner,
        inspector: RecordingFlutterInspector
    ) {
        XCTAssertEqual(inspector.sdkPaths, ["/selected/flutter"])
        XCTAssertEqual(runner.requests.count, 5)
        assertExecutableContract(runner.requests)
        assertCommandArguments(runner.requests)
    }

    func assertExecutableContract(
        _ requests: [ToolchainCommandRequest]
    ) {
        XCTAssertEqual(
            requests.map(\.executablePath),
            [
                "/validated/flutter/bin/flutter",
                "/validated/flutter/bin/flutter",
                "/validated/flutter/bin/dart",
                "/validated/flutter/bin/flutter",
                "/validated/flutter/bin/flutter"
            ]
        )
        XCTAssertTrue(
            requests.allSatisfy {
                !$0.executablePath.contains("/bin/sh")
            }
        )
        XCTAssertNil(requests[0].environment["GITHUB_TOKEN"])
    }

    func assertCommandArguments(
        _ requests: [ToolchainCommandRequest]
    ) {
        XCTAssertEqual(
            requests[0].arguments,
            [
                "--no-version-check",
                "create",
                "--empty",
                "--no-pub",
                "--project-name",
                "inventory_app",
                "--org",
                "de.example",
                "--platforms",
                "android,ios",
                "project"
            ]
        )
        XCTAssertEqual(
            requests[1].arguments,
            ["--no-version-check", "pub", "get"]
        )
        XCTAssertEqual(
            requests[2].arguments,
            ["format", "lib", "test"]
        )
        XCTAssertEqual(
            requests[3].arguments,
            ["--no-version-check", "analyze"]
        )
        XCTAssertEqual(
            requests[4].arguments,
            ["--no-version-check", "test"]
        )
    }

    func assertMaterializedProject(
        _ targetURL: URL
    ) throws {
        for path in ["ios", "android", "test/app_smoke_test.dart"] {
            XCTAssertTrue(
                FileManager.default.fileExists(
                    atPath: targetURL.appendingPathComponent(path).path
                )
            )
        }

        for path in ["test/widget_test.dart", "analysis_options.yaml"] {
            XCTAssertFalse(
                FileManager.default.fileExists(
                    atPath: targetURL.appendingPathComponent(path).path
                )
            )
        }

        let gitignore = try String(
            contentsOf: targetURL.appendingPathComponent(".gitignore"),
            encoding: .utf8
        )
        XCTAssertFalse(gitignore.contains("pubspec.lock"))
    }

    func assertReceipt(
        _ result: FlutterMaterializationResult,
        targetURL: URL,
        parentURL: URL
    ) throws {
        let receiptURL = targetURL.appendingPathComponent(
            FlutterToolchainReceipt.defaultFileName
        )
        let receiptData = try Data(contentsOf: receiptURL)
        let decoded = try FlutterToolchainReceiptCodec().decode(
            receiptData
        )

        XCTAssertEqual(decoded, result.receipt)
        XCTAssertEqual(decoded.schemaVersion, 3)
        XCTAssertEqual(decoded.flutter.flutterVersion, "3.47.2")
        XCTAssertEqual(decoded.targetPlatforms, [.android, .iOS])
        XCTAssertEqual(decoded.pubspecLockSHA256.count, 64)
        XCTAssertEqual(decoded.executionMode, .directSDK)
        XCTAssertNil(decoded.nixEnvironment)
        XCTAssertEqual(
            decoded.validatedSteps,
            [
                .inspectToolchain,
                .create,
                .pubGet,
                .format,
                .analyze,
                .test
            ]
        )

        let receiptText = String(
            bytes: receiptData,
            encoding: .utf8
        ) ?? ""
        XCTAssertFalse(receiptText.contains(parentURL.path))
        XCTAssertFalse(receiptText.contains("/validated/flutter"))
        XCTAssertTrue(stagingDirectories(in: parentURL).isEmpty)
    }

    func makeInput(
        _ fixture: GenerationFixture,
        targetURL: URL
    ) -> FlutterMaterializationInput {
        FlutterMaterializationInput(
            specification: fixture.specification,
            renderedProduct: FlutterRenderedProduct(
                graph: fixture.graph,
                lockfile: fixture.lockfile,
                plan: fixture.plan
            ),
            flutterSDKPath: "/selected/flutter",
            targetURL: targetURL
        )
    }

    func makeGenerationFixture() throws -> GenerationFixture {
        let specification = makeSpecification()
        let graph = try makeGraph()
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )
        let plan = try DeterministicFlutterProjectRenderer().makePlan(
            specification: specification,
            graph: graph,
            lockfile: lockfile
        )
        return GenerationFixture(
            specification: specification,
            graph: graph,
            lockfile: lockfile,
            plan: plan
        )
    }

    func makeSpecification() -> ProjectSpecification {
        let asset = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: [
                FieldDefinition(
                    identity: DefinitionIdentity(
                        id: "field.asset.name",
                        code: "name",
                        label: "Name"
                    ),
                    dataType: .string,
                    isRequired: true
                )
            ]
        )

        return ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: [asset]
        )
    }

    func makeGraph() throws -> ResolvedProductGraph {
        let version = try XCTUnwrap(ForgeSemanticVersion("1.0.0"))
        let contract = ForgePackageContract(
            id: "foundation.core",
            version: version,
            kind: .foundation,
            supportedFrameworks: [.flutter],
            supportedBackends: [.supabase],
            maturity: .stable,
            source: .bundled
        )
        return ResolvedProductGraph(
            packages: [ResolvedPackage(contract: contract)],
            capabilities: []
        )
    }

    func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "appforge-materializer-tests-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )
        return url
    }

    func stagingDirectories(
        in parentURL: URL
    ) -> [URL] {
        let contents = (
            try? FileManager.default.contentsOfDirectory(
                at: parentURL,
                includingPropertiesForKeys: nil
            )
        ) ?? []

        return contents.filter {
            $0.lastPathComponent.hasPrefix(".appforge-materialize-")
        }
    }
}
