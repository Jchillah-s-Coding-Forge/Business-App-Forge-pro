import AppForgeApplication
import AppForgeDomain
@testable import AppForgePro
import Foundation
import XCTest

@MainActor
final class ProjectSetupViewModelTests: XCTestCase {
    func testDefaultDraftUsesRiverpodWithoutOptionalMVVMChoice() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.flutterStateManagement, .riverpod)
        XCTAssertEqual(
            viewModel.architecture.presentationPattern,
            "MVVM"
        )
        XCTAssertEqual(viewModel.architecture, .standard)
    }

    func testProjectNeedsNameOrganizationAndTargetBeforePreview() {
        let viewModel = makeViewModel()

        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.projectName = "Werkstatt Operations"
        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.organizationIdentifier = "de.werkstatt"
        XCTAssertTrue(viewModel.canPrepareProject)
    }

    func testUnsupportedRendererCannotPrepareProject() {
        let viewModel = makeViewModel()
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "de.werkstatt"
        viewModel.framework = .swiftUI
        viewModel.targetPlatforms = [.android]

        XCTAssertFalse(viewModel.canPrepareProject)
    }

    func testSpecificationUsesNormalizedOrganizationIdentifier() {
        let viewModel = makeViewModel()
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "DE.Werkstatt"

        XCTAssertEqual(
            viewModel.specification.identity
                .organizationIdentifier,
            "de.werkstatt"
        )
    }

    func testOrganizationIdentifierMustBePortable() {
        let viewModel = makeViewModel()
        viewModel.projectName = "Werkstatt Operations"

        viewModel.organizationIdentifier = "de.meine-firma"
        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.organizationIdentifier = "de.meine_firma"
        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.organizationIdentifier = "123.meinefirma"
        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.organizationIdentifier = "de.meinefirma2"
        XCTAssertTrue(viewModel.canPrepareProject)
    }

    func testManagedModeUsesExplicitFlutterSDKOffMainThread() async {
        let builder = RecordingFlutterProjectBuilder()
        let preferences = ProjectSetupPreferenceStore(
            initial: ToolchainPreferences(
                flutterSDKPath: " /selected/flutter ",
                developmentEnvironmentMode: .appForgeManaged
            )
        )
        let viewModel = makeViewModel(
            preferences: preferences,
            builder: builder
        )
        configureValidProject(viewModel)

        XCTAssertTrue(viewModel.canGenerateProject)

        let targetURL = generationTarget("managed")
        await viewModel.generateProject(at: targetURL)

        XCTAssertEqual(
            builder.lastToolchain,
            .directSDK(path: "/selected/flutter")
        )
        XCTAssertEqual(builder.lastTargetURL, targetURL)
        XCTAssertEqual(builder.wasMainThread, false)
        XCTAssertEqual(
            viewModel.generatedProjectPath,
            targetURL.path
        )
        XCTAssertEqual(
            viewModel.generatedToolchainReceipt?
                .executionMode,
            .directSDK
        )
    }

    func testExistingToolchainUsesExplicitFlutterSDK() async {
        let builder = RecordingFlutterProjectBuilder()
        let viewModel = makeViewModel(
            preferences: ProjectSetupPreferenceStore(
                initial: ToolchainPreferences(
                    flutterSDKPath: "/existing/flutter",
                    developmentEnvironmentMode:
                        .existingToolchain
                )
            ),
            builder: builder
        )
        configureValidProject(viewModel)

        await viewModel.generateProject(
            at: generationTarget("existing")
        )

        XCTAssertEqual(
            builder.lastToolchain,
            .directSDK(path: "/existing/flutter")
        )
    }

    func testNixModeUsesPersistedEnvironmentAndExecutable() async {
        let builder = RecordingFlutterProjectBuilder()
        let viewModel = makeViewModel(
            preferences: ProjectSetupPreferenceStore(
                initial: ToolchainPreferences(
                    developmentEnvironmentMode:
                        .nixReproducible,
                    nixEnvironmentPath:
                        " /tmp/appforge-nix ",
                    nixExecutablePath:
                        " /nix/bin/nix "
                )
            ),
            builder: builder
        )
        configureValidProject(viewModel)

        XCTAssertTrue(viewModel.canGenerateProject)

        await viewModel.generateProject(
            at: generationTarget("nix")
        )

        XCTAssertEqual(
            builder.lastToolchain,
            .nixEnvironment(
                environmentPath: "/tmp/appforge-nix",
                nixExecutablePath: "/nix/bin/nix"
            )
        )
    }

    func testMissingToolchainBlocksGenerationWithoutFallback() async {
        let builder = RecordingFlutterProjectBuilder()
        let viewModel = makeViewModel(
            preferences: ProjectSetupPreferenceStore(
                initial: ToolchainPreferences(
                    developmentEnvironmentMode:
                        .nixReproducible
                )
            ),
            builder: builder
        )
        configureValidProject(viewModel)

        XCTAssertFalse(viewModel.canGenerateProject)

        await viewModel.generateProject(
            at: generationTarget("blocked")
        )

        XCTAssertEqual(builder.callCount, 0)
        XCTAssertNil(viewModel.generatedProjectPath)
        XCTAssertTrue(
            viewModel.summaryMessage?
                .contains("Nix-Environment") == true
        )
    }

    func testRefreshPicksUpEnvironmentDoctorChanges() {
        let preferences = ProjectSetupPreferenceStore(
            initial: ToolchainPreferences(
                developmentEnvironmentMode:
                    .appForgeManaged
            )
        )
        let viewModel = makeViewModel(
            preferences: preferences
        )
        configureValidProject(viewModel)

        XCTAssertFalse(viewModel.canGenerateProject)

        preferences.save(
            ToolchainPreferences(
                flutterSDKPath: "/new/flutter",
                preferredIDE: .androidStudio,
                developmentEnvironmentMode:
                    .appForgeManaged
            )
        )
        viewModel.refreshToolchainPreferences()

        XCTAssertTrue(viewModel.canGenerateProject)
        XCTAssertEqual(
            viewModel.preferredIDE,
            .androidStudio
        )
    }

    func testGenerationFailureLeavesNoSuccessfulProjectState() async {
        let builder = RecordingFlutterProjectBuilder(
            shouldFail: true
        )
        let viewModel = makeViewModel(
            preferences: directPreferences,
            builder: builder
        )
        configureValidProject(viewModel)

        await viewModel.generateProject(
            at: generationTarget("failed")
        )

        XCTAssertEqual(builder.callCount, 1)
        XCTAssertNil(viewModel.generatedProjectPath)
        XCTAssertNil(viewModel.generatedToolchainReceipt)
        XCTAssertNotNil(viewModel.summaryMessage)
        XCTAssertFalse(viewModel.isGeneratingProject)
    }

    func testGeneratedProjectOpensInPreferredIDE() async {
        let opener = RecordingGeneratedProjectOpener()
        let viewModel = makeViewModel(
            preferences: ProjectSetupPreferenceStore(
                initial: ToolchainPreferences(
                    flutterSDKPath: "/selected/flutter",
                    preferredIDE: .androidStudio,
                    developmentEnvironmentMode:
                        .appForgeManaged
                )
            ),
            opener: opener
        )
        configureValidProject(viewModel)
        let targetURL = generationTarget("open")

        await viewModel.generateProject(at: targetURL)
        viewModel.openGeneratedProject()

        XCTAssertEqual(opener.projectURL, targetURL)
        XCTAssertEqual(
            opener.preferredIDE,
            .androidStudio
        )
    }

    private var directPreferences: ProjectSetupPreferenceStore {
        ProjectSetupPreferenceStore(
            initial: ToolchainPreferences(
                flutterSDKPath: "/selected/flutter",
                developmentEnvironmentMode: .appForgeManaged
            )
        )
    }

    private func makeViewModel(
        preferences: ProjectSetupPreferenceStore =
            ProjectSetupPreferenceStore(),
        builder: RecordingFlutterProjectBuilder =
            RecordingFlutterProjectBuilder(),
        opener: RecordingGeneratedProjectOpener =
            RecordingGeneratedProjectOpener()
    ) -> ProjectSetupViewModel {
        ProjectSetupViewModel(
            createProjectDraft: CreateProjectDraftUseCase(),
            preferencesStore: preferences,
            projectBuilder: builder,
            projectOpener: opener
        )
    }

    private func configureValidProject(
        _ viewModel: ProjectSetupViewModel
    ) {
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "de.werkstatt"
    }

    private func generationTarget(
        _ suffix: String
    ) -> URL {
        URL(
            fileURLWithPath: "/tmp/appforge-\(suffix)",
            isDirectory: true
        )
    }
}

private final class ProjectSetupPreferenceStore: ToolchainPreferenceStore {
    private(set) var saved: ToolchainPreferences

    init(
        initial: ToolchainPreferences =
            ToolchainPreferences()
    ) {
        saved = initial
    }

    func load() -> ToolchainPreferences {
        saved
    }

    func save(
        _ preferences: ToolchainPreferences
    ) {
        saved = preferences
    }
}

private final class RecordingFlutterProjectBuilder: FlutterProjectBuilding, @unchecked Sendable {
    private let lock = NSLock()
    private let shouldFail: Bool
    private var storedToolchain: FlutterMaterializationToolchain?
    private var storedTargetURL: URL?
    private var storedCallCount = 0
    private var storedWasMainThread: Bool?

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    var lastToolchain: FlutterMaterializationToolchain? {
        locked { storedToolchain }
    }

    var lastTargetURL: URL? {
        locked { storedTargetURL }
    }

    var callCount: Int {
        locked { storedCallCount }
    }

    var wasMainThread: Bool? {
        locked { storedWasMainThread }
    }

    func build(
        specification: ProjectSpecification,
        toolchain: FlutterMaterializationToolchain,
        targetURL: URL
    ) throws -> MaterializedFlutterGenerationResult {
        lock.lock()
        storedToolchain = toolchain
        storedTargetURL = targetURL
        storedCallCount += 1
        storedWasMainThread = Thread.isMainThread
        lock.unlock()

        if shouldFail {
            throw ProjectSetupBuildTestError.failed
        }

        let graph = ResolvedProductGraph(
            packages: [],
            capabilities: []
        )
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )
        let plan = try GenerationPlan(files: [])
        let receipt = makeReceipt(
            specification: specification,
            toolchain: toolchain
        )

        return MaterializedFlutterGenerationResult(
            projectPath: targetURL.path,
            graph: graph,
            lockfile: lockfile,
            plan: plan,
            toolchainReceipt: receipt
        )
    }

    private func makeReceipt(
        specification: ProjectSpecification,
        toolchain: FlutterMaterializationToolchain
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
            targetPlatforms: [.android, .iOS],
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
            executionMode: executionMode(
                for: toolchain
            )
        )
    }

    private func executionMode(
        for toolchain: FlutterMaterializationToolchain
    ) -> FlutterToolchainExecutionMode {
        switch toolchain {
        case .directSDK:
            .directSDK
        case .nixEnvironment:
            .nixEnvironment
        }
    }

    private func locked<T>(
        _ operation: () -> T
    ) -> T {
        lock.lock()
        defer { lock.unlock() }
        return operation()
    }
}

private final class RecordingGeneratedProjectOpener: GeneratedProjectOpening {
    private(set) var projectURL: URL?
    private(set) var preferredIDE: PreferredIDE?

    func open(
        projectURL: URL,
        preferredIDE: PreferredIDE
    ) throws {
        self.projectURL = projectURL
        self.preferredIDE = preferredIDE
    }
}

private enum ProjectSetupBuildTestError: Error {
    case failed
}
