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
        )(
            specification: fixture.specification,
            graph: fixture.graph,
            lockfile: fixture.lockfile,
            plan: fixture.plan,
            flutterSDKPath: "/selected/flutter",
            targetURL: targetURL
        )

        XCTAssertEqual(
            result.projectPath,
            targetURL.standardizedFileURL.path
        )
        XCTAssertEqual(inspector.sdkPaths, ["/selected/flutter"])
        XCTAssertEqual(runner.requests.count, 4)
        XCTAssertTrue(
            runner.requests.allSatisfy {
                $0.executablePath == "/validated/flutter/bin/flutter"
            }
        )
        XCTAssertTrue(
            runner.requests.allSatisfy {
                !$0.executablePath.contains("/bin/sh")
            }
        )

        let createRequest = runner.requests[0]
        XCTAssertEqual(
            createRequest.arguments,
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
        XCTAssertNil(createRequest.environment["GITHUB_TOKEN"])

        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: targetURL.appendingPathComponent("ios").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: targetURL.appendingPathComponent("android").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: targetURL.appendingPathComponent(
                    "test/app_smoke_test.dart"
                ).path
            )
        )
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: targetURL.appendingPathComponent(
                    "test/widget_test.dart"
                ).path
            )
        )
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: targetURL.appendingPathComponent(
                    "analysis_options.yaml"
                ).path
            )
        )

        let gitignore = try String(
            contentsOf: targetURL.appendingPathComponent(".gitignore"),
            encoding: .utf8
        )
        XCTAssertFalse(gitignore.contains("pubspec.lock"))

        let receiptURL = targetURL.appendingPathComponent(
            FlutterToolchainReceipt.defaultFileName
        )
        let receiptData = try Data(contentsOf: receiptURL)
        let decodedReceipt = try FlutterToolchainReceiptCodec().decode(
            receiptData
        )

        XCTAssertEqual(decodedReceipt, result.receipt)
        XCTAssertEqual(decodedReceipt.flutter.flutterVersion, "3.47.2")
        XCTAssertEqual(
            decodedReceipt.targetPlatforms,
            [.android, .iOS]
        )
        XCTAssertEqual(decodedReceipt.pubspecLockSHA256.count, 64)

        let receiptText = String(decoding: receiptData, as: UTF8.self)
        XCTAssertFalse(receiptText.contains(parentURL.path))
        XCTAssertFalse(receiptText.contains("/validated/flutter"))
        XCTAssertTrue(stagingDirectories(in: parentURL).isEmpty)
    }

    func testAnalyzeFailureDoesNotPublishOrLeaveStaging() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent(
            "failed_app",
            isDirectory: true
        )
        let fixture = try makeGenerationFixture()
        let runner = MaterializationToolchainRunner(
            failingStep: .analyze
        )

        XCTAssertThrowsError(
            try MaterializeFlutterProjectUseCase(
                inspector: RecordingFlutterInspector(),
                runner: runner
            )(
                specification: fixture.specification,
                graph: fixture.graph,
                lockfile: fixture.lockfile,
                plan: fixture.plan,
                flutterSDKPath: "/selected/flutter",
                targetURL: targetURL
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterMaterializationError,
                .commandFailed(
                    step: .analyze,
                    exitCode: 2,
                    output: "simulated analyze failure"
                )
            )
        }

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: targetURL.path)
        )
        XCTAssertTrue(stagingDirectories(in: parentURL).isEmpty)
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
            )(
                specification: fixture.specification,
                graph: fixture.graph,
                lockfile: fixture.lockfile,
                plan: fixture.plan,
                flutterSDKPath: "/selected/flutter",
                targetURL: targetURL
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterMaterializationError,
                .targetAlreadyExists
            )
        }

        XCTAssertTrue(inspector.sdkPaths.isEmpty)
        XCTAssertTrue(runner.requests.isEmpty)
    }

    private func makeGenerationFixture() throws -> GenerationFixture {
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
        let specification = ProjectSpecification(
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
        let graph = ResolvedProductGraph(
            packages: [ResolvedPackage(contract: contract)],
            capabilities: []
        )
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

    private func makeTemporaryDirectory() throws -> URL {
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
            $0.lastPathComponent.hasPrefix(".appforge-materialize-")
        }
    }
}

private struct GenerationFixture {
    let specification: ProjectSpecification
    let graph: ResolvedProductGraph
    let lockfile: ForgeLockfile
    let plan: GenerationPlan
}

private final class RecordingFlutterInspector: FlutterToolchainInspecting, @unchecked Sendable {
    private(set) var sdkPaths: [String] = []

    func inspect(
        sdkRootPath: String
    ) throws -> FlutterToolchainInspection {
        sdkPaths.append(sdkRootPath)
        return FlutterToolchainInspection(
            sdkRootPath: "/validated/flutter",
            flutterExecutablePath: "/validated/flutter/bin/flutter",
            identity: FlutterToolchainIdentity(
                flutterVersion: "3.47.2",
                channel: "stable",
                frameworkRevision: String(repeating: "a", count: 40),
                engineRevision: String(repeating: "b", count: 40),
                dartSDKVersion: "3.11.0"
            )
        )
    }
}

private final class MaterializationToolchainRunner: ToolchainCommandRunning, @unchecked Sendable {
    private let failingStep: FlutterMaterializationStep?
    private(set) var requests: [ToolchainCommandRequest] = []

    init(failingStep: FlutterMaterializationStep? = nil) {
        self.failingStep = failingStep
    }

    func run(
        _ request: ToolchainCommandRequest
    ) throws -> ToolchainCommandResult {
        requests.append(request)
        let step = step(for: request.arguments)

        if step == .create {
            try createBootstrapProject(
                in: URL(
                    fileURLWithPath: request.workingDirectoryPath,
                    isDirectory: true
                )
            )
        }

        if failingStep == step {
            return ToolchainCommandResult(
                exitCode: 2,
                output: "simulated \(step.rawValue) failure",
                timedOut: false
            )
        }

        if step == .pubGet {
            let lockURL = URL(
                fileURLWithPath: request.workingDirectoryPath,
                isDirectory: true
            ).appendingPathComponent("pubspec.lock")
            try "packages:\n  flutter: sdk\n".write(
                to: lockURL,
                atomically: true,
                encoding: .utf8
            )
        }

        return ToolchainCommandResult(
            exitCode: 0,
            output: "",
            timedOut: false
        )
    }

    private func step(
        for arguments: [String]
    ) -> FlutterMaterializationStep {
        if arguments.contains("create") {
            return .create
        }
        if arguments.contains("analyze") {
            return .analyze
        }
        if arguments.contains("test") {
            return .test
        }
        return .pubGet
    }

    private func createBootstrapProject(
        in stagingRoot: URL
    ) throws {
        let projectURL = stagingRoot.appendingPathComponent(
            "project",
            isDirectory: true
        )
        let paths = [
            "ios/Runner.xcodeproj",
            "android/app",
            "lib",
            "test"
        ]

        for relativePath in paths {
            try FileManager.default.createDirectory(
                at: projectURL.appendingPathComponent(
                    relativePath,
                    isDirectory: true
                ),
                withIntermediateDirectories: true
            )
        }

        try "bootstrap".write(
            to: projectURL.appendingPathComponent("lib/main.dart"),
            atomically: true,
            encoding: .utf8
        )
        try "bootstrap".write(
            to: projectURL.appendingPathComponent("test/widget_test.dart"),
            atomically: true,
            encoding: .utf8
        )
        try "include: package:flutter_lints/flutter.yaml\n".write(
            to: projectURL.appendingPathComponent("analysis_options.yaml"),
            atomically: true,
            encoding: .utf8
        )
        try "bootstrap lock".write(
            to: projectURL.appendingPathComponent("pubspec.lock"),
            atomically: true,
            encoding: .utf8
        )
    }
}
