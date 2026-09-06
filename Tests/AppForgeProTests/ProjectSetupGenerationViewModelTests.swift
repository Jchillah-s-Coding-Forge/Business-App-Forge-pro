import AppForgeApplication
import AppForgeDomain
@testable import AppForgePro
import Foundation
import XCTest

@MainActor
final class ProjectSetupGenerationViewModelTests: XCTestCase {
    func testMissingManagedSDKBlocksGeneration() {
        let viewModel = makeViewModel(
            preferences: ToolchainPreferences(
                developmentEnvironmentMode: .appForgeManaged
            )
        )
        makeProjectValid(viewModel)

        XCTAssertTrue(viewModel.canPrepareProject)
        XCTAssertFalse(viewModel.canGenerateProject)
        XCTAssertEqual(
            viewModel.toolchainSummary,
            "Nicht bereit"
        )
        XCTAssertTrue(
            viewModel.toolchainReadinessMessage
                .contains("Environment Doctor")
        )
    }

    func testManagedGenerationRunsOffMainActorAndStoresSuccess() async {
        let builder = RecordingStudioProjectBuilder()
        let viewModel = makeViewModel(
            preferences: ToolchainPreferences(
                flutterSDKPath: "/opt/flutter",
                preferredIDE: .vsCode,
                developmentEnvironmentMode: .appForgeManaged
            ),
            builder: builder
        )
        makeProjectValid(viewModel)
        let target = URL(
            fileURLWithPath: "/tmp/appforge-studio-output",
            isDirectory: true
        )

        await viewModel.generateProject(to: target)

        XCTAssertEqual(
            builder.lastToolchain,
            .directSDK(path: "/opt/flutter")
        )
        XCTAssertEqual(
            builder.lastTargetURL,
            target
        )
        XCTAssertEqual(builder.lastBuildWasOnMainThread, false)
        XCTAssertEqual(
            viewModel.generatedProjectPath,
            target.path
        )
        XCTAssertEqual(
            viewModel.generatedToolchainReceipt?.executionMode,
            .directSDK
        )
        XCTAssertNil(viewModel.generationErrorMessage)
        XCTAssertFalse(viewModel.isGenerating)
    }

    func testNixGenerationPassesExactStoredNixToolchain() async {
        let builder = RecordingStudioProjectBuilder()
        let viewModel = makeViewModel(
            preferences: ToolchainPreferences(
                flutterSDKPath: "/must/not/be/used",
                preferredIDE: .terminal,
                developmentEnvironmentMode: .nixReproducible,
                nixEnvironmentPath: "/tmp/verified-nix",
                nixExecutablePath: "/nix/bin/nix"
            ),
            builder: builder
        )
        makeProjectValid(viewModel)

        await viewModel.generateProject(
            to: URL(
                fileURLWithPath: "/tmp/nix-generated",
                isDirectory: true
            )
        )

        XCTAssertEqual(
            builder.lastToolchain,
            .nixEnvironment(
                environmentPath: "/tmp/verified-nix",
                nixExecutablePath: "/nix/bin/nix"
            )
        )
        XCTAssertEqual(
            viewModel.generatedToolchainReceipt?.executionMode,
            .nixEnvironment
        )
    }

    func testGenerationFailureLeavesNoSuccessPath() async {
        let builder = RecordingStudioProjectBuilder(
            shouldFail: true
        )
        let viewModel = makeViewModel(
            preferences: readyManagedPreferences,
            builder: builder
        )
        makeProjectValid(viewModel)

        await viewModel.generateProject(
            to: URL(
                fileURLWithPath: "/tmp/failed-output",
                isDirectory: true
            )
        )

        XCTAssertNil(viewModel.generatedProjectPath)
        XCTAssertNil(viewModel.generatedToolchainReceipt)
        XCTAssertNotNil(viewModel.generationErrorMessage)
        XCTAssertFalse(viewModel.isGenerating)
    }

    func testOpenGeneratedProjectUsesPreferredIDE() async {
        let builder = RecordingStudioProjectBuilder()
        let opener = RecordingStudioProjectOpener()
        let viewModel = makeViewModel(
            preferences: ToolchainPreferences(
                flutterSDKPath: "/opt/flutter",
                preferredIDE: .androidStudio,
                developmentEnvironmentMode: .existingToolchain
            ),
            builder: builder,
            opener: opener
        )
        makeProjectValid(viewModel)
        let target = URL(
            fileURLWithPath: "/tmp/open-generated",
            isDirectory: true
        )

        await viewModel.generateProject(to: target)
        viewModel.openGeneratedProject()

        XCTAssertEqual(
            opener.lastProjectURL?.path,
            target.path
        )
        XCTAssertEqual(
            opener.lastPreferredIDE,
            .androidStudio
        )
    }

    func testUnavailablePreferredIDEDoesNotSilentlyFallback() async {
        let opener = RecordingStudioProjectOpener()
        let viewModel = makeViewModel(
            preferences: ToolchainPreferences(
                flutterSDKPath: "/opt/flutter",
                preferredIDE: .androidStudio,
                developmentEnvironmentMode: .existingToolchain
            ),
            opener: opener,
            ideDetector: StudioIDEHandoffDetector(
                available: [.finder, .systemDefault]
            )
        )
        makeProjectValid(viewModel)
        let target = URL(
            fileURLWithPath: "/tmp/no-ide-fallback",
            isDirectory: true
        )

        await viewModel.generateProject(to: target)
        viewModel.openGeneratedProject()

        XCTAssertNil(opener.lastPreferredIDE)
        XCTAssertNotNil(viewModel.generationErrorMessage)

        viewModel.openGeneratedProject(in: .finder)

        XCTAssertEqual(opener.lastPreferredIDE, .finder)
        XCTAssertEqual(opener.lastProjectURL?.path, target.path)
    }

    func testAvailableHandoffsIncludeDetectedIDEAndSafeFallbacks() {
        let viewModel = makeViewModel(
            preferences: readyManagedPreferences,
            ideDetector: StudioIDEHandoffDetector(
                available: [
                    .vsCode,
                    .finder,
                    .systemDefault
                ]
            )
        )

        XCTAssertEqual(
            Set(viewModel.availableIDEHandoffs.map(\.ide)),
            [.vsCode, .finder, .systemDefault]
        )
    }

    private var readyManagedPreferences: ToolchainPreferences {
        ToolchainPreferences(
            flutterSDKPath: "/opt/flutter",
            preferredIDE: .vsCode,
            developmentEnvironmentMode: .appForgeManaged
        )
    }

    private func makeViewModel(
        preferences: ToolchainPreferences,
        builder: RecordingStudioProjectBuilder =
            RecordingStudioProjectBuilder(),
        opener: RecordingStudioProjectOpener =
            RecordingStudioProjectOpener(),
        ideDetector: any IDEHandoffDetecting =
            StudioIDEHandoffDetector()
    ) -> ProjectSetupViewModel {
        ProjectSetupViewModel(
            createProjectDraft: CreateProjectDraftUseCase(),
            preferencesStore: StudioPreferenceStore(
                preferences
            ),
            projectBuilder: builder,
            projectOpener: opener,
            ideHandoffDetector: ideDetector
        )
    }

    private func makeProjectValid(
        _ viewModel: ProjectSetupViewModel
    ) {
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "de.werkstatt"
    }
}

private final class StudioPreferenceStore: ToolchainPreferenceStore {
    private var preferences: ToolchainPreferences

    init(_ preferences: ToolchainPreferences) {
        self.preferences = preferences
    }

    func load() -> ToolchainPreferences {
        preferences
    }

    func save(_ preferences: ToolchainPreferences) {
        self.preferences = preferences
    }
}

private final class RecordingStudioProjectBuilder: MaterializedFlutterProjectBuilding, @unchecked Sendable {
    private let lock = NSLock()
    private let shouldFail: Bool
    private var storedToolchain: FlutterMaterializationToolchain?
    private var storedTargetURL: URL?
    private var storedBuildWasOnMainThread: Bool?

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    var lastToolchain: FlutterMaterializationToolchain? {
        locked { storedToolchain }
    }

    var lastTargetURL: URL? {
        locked { storedTargetURL }
    }

    var lastBuildWasOnMainThread: Bool? {
        locked { storedBuildWasOnMainThread }
    }

    func build(
        specification: ProjectSpecification,
        toolchain: FlutterMaterializationToolchain,
        targetURL: URL
    ) throws -> MaterializedFlutterGenerationResult {
        lock.lock()
        storedToolchain = toolchain
        storedTargetURL = targetURL
        storedBuildWasOnMainThread = Thread.isMainThread
        lock.unlock()

        if shouldFail {
            throw StudioGenerationTestError.failed
        }

        return try makeResult(
            specification: specification,
            toolchain: toolchain,
            targetURL: targetURL
        )
    }

    private func makeResult(
        specification: ProjectSpecification,
        toolchain: FlutterMaterializationToolchain,
        targetURL: URL
    ) throws -> MaterializedFlutterGenerationResult {
        let graph = ResolvedProductGraph(
            packages: [],
            capabilities: []
        )
        let lockfile = ForgeLockfile(
            projectSchemaVersion: specification.schemaVersion,
            framework: specification.framework,
            backend: specification.backend,
            packages: [],
            capabilities: []
        )
        let plan = try GenerationPlan(files: [])
        let mode: FlutterToolchainExecutionMode = switch toolchain {
        case .directSDK:
            .directSDK
        case .nixEnvironment:
            .nixEnvironment
        }

        return MaterializedFlutterGenerationResult(
            projectPath: targetURL.path,
            graph: graph,
            lockfile: lockfile,
            plan: plan,
            toolchainReceipt: makeReceipt(
                specification: specification,
                mode: mode
            )
        )
    }

    private func makeReceipt(
        specification: ProjectSpecification,
        mode: FlutterToolchainExecutionMode
    ) -> FlutterToolchainReceipt {
        FlutterToolchainReceipt(
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
            projectPackageName: "werkstatt_operations",
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

    private func locked<T>(
        _ operation: () -> T
    ) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}

private final class RecordingStudioProjectOpener: GeneratedProjectOpening {
    private(set) var lastProjectURL: URL?
    private(set) var lastPreferredIDE: PreferredIDE?

    func open(
        projectURL: URL,
        preferredIDE: PreferredIDE
    ) throws {
        lastProjectURL = projectURL
        lastPreferredIDE = preferredIDE
    }
}

private enum StudioGenerationTestError: Error {
    case failed
}

private struct StudioIDEHandoffDetector: IDEHandoffDetecting {
    let available: Set<PreferredIDE>

    init(
        available: Set<PreferredIDE> = Set(
            PreferredIDE.allCases
        )
    ) {
        self.available = available
    }

    func detect() -> [IDEHandoffAvailability] {
        PreferredIDE.allCases.map { ide in
            IDEHandoffAvailability(
                ide: ide,
                applicationPath: applicationPath(
                    for: ide
                )
            )
        }
    }

    private func applicationPath(
        for ide: PreferredIDE
    ) -> String? {
        guard available.contains(ide) else {
            return nil
        }

        switch ide {
        case .finder, .systemDefault:
            nil
        default:
            "/Applications/\(ide.rawValue).app"
        }
    }
}
