import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class GenerateMaterializedFlutterProjectUseCaseTests: XCTestCase {
    func testBundledGenerationPassesResolvedProductToDirectMaterializer() throws {
        let recorder = RecordingProjectMaterializer()
        let useCase = GenerateMaterializedFlutterProjectUseCase(
            materializer: recorder
        )
        let targetURL = URL(
            fileURLWithPath: "/tmp/appforge-generated",
            isDirectory: true
        )
        let specification = makeSpecification()

        let result = try useCase(
            specification: specification,
            toolchain: .directSDK(
                path: "/selected/flutter"
            ),
            targetURL: targetURL
        )

        let input = try XCTUnwrap(recorder.lastInput)
        XCTAssertEqual(
            input.specification,
            specification
        )
        XCTAssertEqual(
            input.toolchain,
            .directSDK(path: "/selected/flutter")
        )
        XCTAssertEqual(
            input.targetURL,
            targetURL
        )
        XCTAssertEqual(
            input.renderedProduct.graph,
            result.graph
        )
        XCTAssertEqual(
            input.renderedProduct.lockfile,
            result.lockfile
        )
        XCTAssertEqual(
            input.renderedProduct.plan,
            result.plan
        )
        XCTAssertEqual(
            result.graph.packages.map(\.contract.id),
            [BundledPackageRegistry.foundationCoreID]
        )
        XCTAssertEqual(
            result.projectPath,
            targetURL.path
        )
        XCTAssertEqual(
            result.toolchainReceipt.executionMode,
            .directSDK
        )
    }

    func testBundledGenerationPreservesNixToolchainSelection() throws {
        let recorder = RecordingProjectMaterializer()
        let useCase = GenerateMaterializedFlutterProjectUseCase(
            materializer: recorder
        )
        let toolchain = FlutterMaterializationToolchain
            .nixEnvironment(
                environmentPath: "/tmp/appforge-nix-environment",
                nixExecutablePath: "/nix/bin/nix"
            )

        _ = try useCase(
            specification: makeSpecification(),
            toolchain: toolchain,
            targetURL: URL(
                fileURLWithPath: "/tmp/appforge-nix-generated",
                isDirectory: true
            )
        )

        XCTAssertEqual(
            recorder.lastInput?.toolchain,
            toolchain
        )
    }

    func testResolutionFailureDoesNotStartMaterializer() throws {
        let recorder = RecordingProjectMaterializer()
        let useCase = GenerateMaterializedFlutterProjectUseCase(
            materializer: recorder
        )
        let registry = try InMemoryPackageRegistry(
            contracts: []
        )

        XCTAssertThrowsError(
            try useCase(
                specification: makeSpecification(),
                requests: [
                    ForgePackageRequirement(
                        packageID: "feature.missing"
                    )
                ],
                registry: registry,
                toolchain: .directSDK(
                    path: "/selected/flutter"
                ),
                targetURL: URL(
                    fileURLWithPath: "/tmp/never-generated",
                    isDirectory: true
                )
            )
        )

        XCTAssertNil(recorder.lastInput)
    }

    func testRendererFailureDoesNotStartMaterializer() throws {
        let recorder = RecordingProjectMaterializer()
        let useCase = GenerateMaterializedFlutterProjectUseCase(
            renderer: FailingProjectRenderer(),
            materializer: recorder
        )

        XCTAssertThrowsError(
            try useCase(
                specification: makeSpecification(),
                toolchain: .directSDK(
                    path: "/selected/flutter"
                ),
                targetURL: URL(
                    fileURLWithPath: "/tmp/never-rendered",
                    isDirectory: true
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .encodingFailed
            )
        }

        XCTAssertNil(recorder.lastInput)
    }

    private func makeSpecification() -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )
    }
}

private final class RecordingProjectMaterializer:
    FlutterProjectMaterializing,
    @unchecked Sendable
{
    private let lock = NSLock()
    private var storedInput: FlutterMaterializationInput?

    var lastInput: FlutterMaterializationInput? {
        lock.lock()
        defer { lock.unlock() }
        return storedInput
    }

    func materialize(
        _ input: FlutterMaterializationInput
    ) throws -> FlutterMaterializationResult {
        lock.lock()
        storedInput = input
        lock.unlock()

        return FlutterMaterializationResult(
            projectPath: input.targetURL.path,
            receipt: testReceipt(
                specification: input.specification,
                toolchain: input.toolchain
            )
        )
    }

    private func testReceipt(
        specification: ProjectSpecification,
        toolchain: FlutterMaterializationToolchain
    ) -> FlutterToolchainReceipt {
        let mode: FlutterToolchainExecutionMode = switch toolchain {
        case .directSDK:
            .directSDK
        case .nixEnvironment:
            .nixEnvironment
        }

        return FlutterToolchainReceipt(
            flutter: FlutterToolchainIdentity(
                flutterVersion: "3.47.2",
                channel: "stable",
                frameworkRevision: String(
                    repeating: "a",
                    count: 40
                ),
                engineRevision: String(
                    repeating: "b",
                    count: 40
                ),
                dartSDKVersion: "3.11.0"
            ),
            projectPackageName: "inventory_app",
            organizationIdentifier: specification.identity.organizationIdentifier,
            targetPlatforms: specification.targetPlatforms.sorted {
                $0.rawValue < $1.rawValue
            },
            pubspecLockSHA256: String(
                repeating: "c",
                count: 64
            ),
            validatedSteps: [
                .inspectToolchain,
                .create,
                .pubGet,
                .analyze,
                .test
            ],
            executionMode: mode
        )
    }
}

private struct FailingProjectRenderer: FlutterProjectRendering {
    func makePlan(
        specification: ProjectSpecification,
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile
    ) throws -> GenerationPlan {
        throw FlutterRendererError.encodingFailed
    }
}
