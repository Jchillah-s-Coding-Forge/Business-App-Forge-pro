import AppForgeApplication
import AppForgeDomain
@testable import AppForgePro
import Foundation
import XCTest

@MainActor
final class EnvironmentDoctorNixViewModelTests: XCTestCase {
    func testLegacyPreferencesDefaultToManagedAndModePersists() {
        let preferences = NixTestPreferenceStore(
            initial: ToolchainPreferences(
                flutterSDKPath: "/existing/flutter",
                preferredIDE: .vsCode
            )
        )
        let viewModel = makeViewModel(
            preferences: preferences
        )

        XCTAssertEqual(
            viewModel.developmentEnvironmentMode,
            .appForgeManaged
        )

        viewModel.setDevelopmentEnvironmentMode(
            .nixReproducible
        )

        XCTAssertEqual(
            preferences.saved.developmentEnvironmentMode,
            .nixReproducible
        )
        XCTAssertEqual(
            preferences.saved.flutterSDKPath,
            "/existing/flutter"
        )
    }

    func testMissingNixOffersVerifiedBootstrap() async {
        let detector = MutableNixToolDetector(nixReady: false)
        let viewModel = makeViewModel(detector: detector)

        viewModel.setDevelopmentEnvironmentMode(
            .nixReproducible
        )
        await viewModel.scan()

        XCTAssertFalse(viewModel.isNixReady)
        XCTAssertTrue(viewModel.shouldOfferNixBootstrap)
        XCTAssertTrue(viewModel.canPrepareNixBootstrap)
        XCTAssertEqual(
            viewModel.nixBootstrapReleaseVersion,
            "2.35.2"
        )
    }

    func testBootstrapCannotLaunchUntilDigestIsConfirmed() async {
        let detector = MutableNixToolDetector(nixReady: false)
        let preparer = RecordingNixBootstrapPreparer()
        let launcher = RecordingNixBootstrapLauncher()
        let viewModel = makeViewModel(
            detector: detector,
            preparer: preparer,
            launcher: launcher
        )

        viewModel.setDevelopmentEnvironmentMode(
            .nixReproducible
        )
        await viewModel.scan()
        await viewModel.prepareNixBootstrap()

        XCTAssertNotNil(viewModel.preparedNixBootstrap)
        XCTAssertFalse(viewModel.isNixBootstrapConfirmed)
        XCTAssertFalse(viewModel.canLaunchNixBootstrap)

        viewModel.launchNixBootstrap()
        XCTAssertEqual(launcher.launchCount, 0)

        viewModel.isNixBootstrapConfirmed = true
        XCTAssertTrue(viewModel.canLaunchNixBootstrap)

        viewModel.launchNixBootstrap()

        XCTAssertEqual(launcher.launchCount, 1)
        XCTAssertTrue(viewModel.hasLaunchedNixBootstrap)
    }

    func testReadyRescanCleansPreparedBootstrapState() async {
        let detector = MutableNixToolDetector(nixReady: false)
        let cleaner = RecordingNixBootstrapCleaner()
        let viewModel = makeViewModel(
            detector: detector,
            cleaner: cleaner
        )

        viewModel.setDevelopmentEnvironmentMode(
            .nixReproducible
        )
        await viewModel.scan()
        await viewModel.prepareNixBootstrap()
        viewModel.isNixBootstrapConfirmed = true

        await detector.setNixReady(true)
        await viewModel.scan()

        XCTAssertTrue(viewModel.isNixReady)
        XCTAssertNil(viewModel.preparedNixBootstrap)
        XCTAssertFalse(viewModel.isNixBootstrapConfirmed)
        XCTAssertEqual(cleaner.cleanupCount, 1)
    }

    func testSwitchingBackToManagedCleansTransientBootstrap() async {
        let detector = MutableNixToolDetector(nixReady: false)
        let cleaner = RecordingNixBootstrapCleaner()
        let preferences = NixTestPreferenceStore()
        let viewModel = makeViewModel(
            detector: detector,
            preferences: preferences,
            cleaner: cleaner
        )

        viewModel.setDevelopmentEnvironmentMode(
            .nixReproducible
        )
        await viewModel.scan()
        await viewModel.prepareNixBootstrap()
        viewModel.isNixBootstrapConfirmed = true

        viewModel.setDevelopmentEnvironmentMode(
            .appForgeManaged
        )

        XCTAssertNil(viewModel.preparedNixBootstrap)
        XCTAssertFalse(viewModel.isNixBootstrapConfirmed)
        XCTAssertEqual(cleaner.cleanupCount, 1)
        XCTAssertEqual(
            preferences.saved.developmentEnvironmentMode,
            .appForgeManaged
        )
    }

    func testReadyNixCanProvisionEnvironment() async {
        let detector = MutableNixToolDetector(nixReady: true)
        let provisioner = RecordingNixEnvironmentProvisioner()
        let preferences = NixTestPreferenceStore()
        let viewModel = makeViewModel(
            detector: detector,
            preferences: preferences,
            provisioner: provisioner
        )

        viewModel.setDevelopmentEnvironmentMode(
            .nixReproducible
        )
        await viewModel.scan()

        XCTAssertTrue(viewModel.isNixReady)
        XCTAssertFalse(viewModel.shouldOfferNixBootstrap)
        XCTAssertTrue(viewModel.canProvisionNixEnvironment)

        let target = URL(
            fileURLWithPath: "/tmp/appforge-nix-ui-test",
            isDirectory: true
        )
        await viewModel.provisionNixEnvironment(to: target)

        XCTAssertEqual(
            viewModel.nixProvisioningResult?.environmentPath,
            target.path
        )
        XCTAssertEqual(
            provisioner.lastInput?.nixExecutablePath,
            "/nix/var/nix/profiles/default/bin/nix"
        )
        XCTAssertEqual(
            provisioner.lastInput?.plan.packages,
            [.flutter, .git, .jdk17]
        )
        XCTAssertEqual(
            preferences.saved.nixEnvironmentPath,
            target.path
        )
        XCTAssertEqual(
            preferences.saved.nixExecutablePath,
            "/nix/var/nix/profiles/default/bin/nix"
        )
    }

    private func makeViewModel(
        detector: any ToolDetector = MutableNixToolDetector(
            nixReady: true
        ),
        preferences: NixTestPreferenceStore = NixTestPreferenceStore(),
        preparer: any NixBootstrapPreparing =
            RecordingNixBootstrapPreparer(),
        launcher: any NixBootstrapLaunching =
            RecordingNixBootstrapLauncher(),
        cleaner: any NixBootstrapCleaning =
            RecordingNixBootstrapCleaner(),
        provisioner: any NixEnvironmentProvisioning =
            RecordingNixEnvironmentProvisioner()
    ) -> EnvironmentDoctorViewModel {
        EnvironmentDoctorViewModel(
            doctor: EnvironmentDoctorUseCase(detector: detector),
            preferencesStore: preferences,
            projectOpener: NixNoopProjectOpener(),
            flutterInstaller: NixNoopFlutterInstaller(),
            nixBootstrapPreparer: preparer,
            nixBootstrapLauncher: launcher,
            nixBootstrapCleaner: cleaner,
            nixEnvironmentProvisioner: provisioner,
            nixBootstrapWorkspaceParentURL: URL(
                fileURLWithPath: "/tmp",
                isDirectory: true
            )
        )
    }
}

private actor MutableNixToolDetector: ToolDetector {
    private var nixReady: Bool

    init(nixReady: Bool) {
        self.nixReady = nixReady
    }

    func setNixReady(_ ready: Bool) {
        nixReady = ready
    }

    func detect(
        requirement: ToolRequirement,
        flutterSDKPath: String?
    ) async -> ToolDetectionResult {
        if requirement.id == .nix {
            return ToolDetectionResult(
                requirement: requirement,
                availability: nixReady ? .ready : .missing,
                version: nixReady
                    ? SemanticVersion(major: 2, minor: 35, patch: 2)
                    : nil,
                path: nixReady
                    ? "/nix/var/nix/profiles/default/bin/nix"
                    : nil,
                detail: nixReady ? "Bereit" : "Nicht installiert"
            )
        }

        return ToolDetectionResult(
            requirement: requirement,
            availability: .ready,
            version: SemanticVersion(major: 99, minor: 0),
            path: requirement.id == .flutter
                ? flutterSDKPath
                : "/usr/bin/test-tool",
            detail: "Bereit"
        )
    }
}

private final class NixTestPreferenceStore: ToolchainPreferenceStore {
    private(set) var saved: ToolchainPreferences

    init(
        initial: ToolchainPreferences = ToolchainPreferences()
    ) {
        saved = initial
    }

    func load() -> ToolchainPreferences {
        saved
    }

    func save(_ preferences: ToolchainPreferences) {
        saved = preferences
    }
}

private actor RecordingNixBootstrapPreparer: NixBootstrapPreparing {
    private(set) var callCount = 0

    func prepare(
        workspaceParentURL: URL
    ) async throws -> NixBootstrapPreparedInstaller {
        callCount += 1
        return NixBootstrapPreparedInstaller(
            version: "2.35.2",
            installerSHA256: String(repeating: "a", count: 64),
            workspacePath: "/tmp/.appforge-nix-bootstrap-test",
            installerPath: "/tmp/.appforge-nix-bootstrap-test/install.sh",
            commandPath: "/tmp/.appforge-nix-bootstrap-test/install.command"
        )
    }
}

private final class RecordingNixBootstrapLauncher: NixBootstrapLaunching, @unchecked Sendable {
    private let lock = NSLock()
    private var storedLaunchCount = 0

    var launchCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedLaunchCount
    }

    func launch(
        prepared: NixBootstrapPreparedInstaller,
        confirmation: NixBootstrapConfirmation
    ) throws {
        lock.lock()
        storedLaunchCount += 1
        lock.unlock()
    }
}

private final class RecordingNixBootstrapCleaner: NixBootstrapCleaning, @unchecked Sendable {
    private let lock = NSLock()
    private var storedCleanupCount = 0

    var cleanupCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return storedCleanupCount
    }

    func cleanup(
        prepared: NixBootstrapPreparedInstaller
    ) throws {
        lock.lock()
        storedCleanupCount += 1
        lock.unlock()
    }
}

private final class RecordingNixEnvironmentProvisioner: NixEnvironmentProvisioning, @unchecked Sendable {
    private let lock = NSLock()
    private var storedInput: NixEnvironmentProvisioningInput?

    var lastInput: NixEnvironmentProvisioningInput? {
        lock.lock()
        defer { lock.unlock() }
        return storedInput
    }

    func provision(
        _ input: NixEnvironmentProvisioningInput
    ) throws -> NixEnvironmentProvisioningResult {
        lock.lock()
        storedInput = input
        lock.unlock()

        return NixEnvironmentProvisioningResult(
            environmentPath: input.targetURL.path,
            receipt: NixEnvironmentReceipt(
                nixVersion: "2.35.2",
                nixpkgsLockedRevision: String(
                    repeating: "b",
                    count: 40
                ),
                flakeLockSHA256: String(
                    repeating: "c",
                    count: 64
                ),
                systems: input.plan.systems,
                packages: input.plan.packages,
                unmanagedRequirements: input.plan.unmanagedRequirements,
                validationTool: "flutter",
                validationVersion: "3.47.2"
            )
        )
    }
}

private struct NixNoopProjectOpener: GeneratedProjectOpening {
    func open(
        projectURL: URL,
        preferredIDE: PreferredIDE
    ) throws {}
}

private struct NixNoopFlutterInstaller: FlutterSDKInstalling {
    func install(
        into parentDirectoryPath: String,
        progress: @escaping @Sendable (
            FlutterInstallationPhase
        ) async -> Void
    ) async throws -> FlutterInstallationResult {
        FlutterInstallationResult(
            sdkPath: "/tmp/flutter",
            version: "3.47.2"
        )
    }
}
