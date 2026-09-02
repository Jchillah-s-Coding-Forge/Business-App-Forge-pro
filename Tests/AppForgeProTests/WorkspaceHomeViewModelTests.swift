import AppForgeApplication
import AppForgeCore
import AppForgeDomain
@testable import AppForgePro
import Foundation
import XCTest

@MainActor
final class WorkspaceHomeViewModelTests: XCTestCase {
    func testStartProjectSetupCreatesOneDraftAndPresentsWizard() {
        let viewModel = WorkspaceHomeViewModel(environment: .test)

        viewModel.startProjectSetup()

        XCTAssertTrue(viewModel.isPresentingProjectSetup)
        XCTAssertNotNil(viewModel.projectSetupViewModel)
    }

    func testDismissProjectSetupClearsTransientDraft() {
        let viewModel = WorkspaceHomeViewModel(environment: .test)
        viewModel.startProjectSetup()

        viewModel.dismissProjectSetup()

        XCTAssertFalse(viewModel.isPresentingProjectSetup)
        XCTAssertNil(viewModel.projectSetupViewModel)
    }

    func testRequestingFlutterInstallationDoesNotStartDownloadBeforeConfirmation() async {
        let recorder = InstallerInvocationRecorder()
        let viewModel = makeEnvironmentDoctorViewModel(
            installer: StubFlutterInstaller(recorder: recorder)
        )

        viewModel.requestFlutterInstallation(into: "/tmp/appforge-sdk")
        let callCount = await recorder.callCount

        XCTAssertTrue(viewModel.isPresentingFlutterInstallConfirmation)
        XCTAssertEqual(viewModel.flutterInstallParentPath, "/tmp/appforge-sdk")
        XCTAssertEqual(callCount, 0)
    }

    func testSuccessfulFlutterInstallationPersistsSDKAndRefreshesDoctor() async {
        let recorder = InstallerInvocationRecorder()
        let preferences = InMemoryToolchainPreferenceStore()
        let viewModel = makeEnvironmentDoctorViewModel(
            preferences: preferences,
            installer: StubFlutterInstaller(
                recorder: recorder,
                result: FlutterInstallationResult(
                    sdkPath: "/tmp/appforge-sdk/flutter",
                    version: "3.47.0",
                    warnings: ["Temporäres Testartefakt konnte nicht entfernt werden."]
                )
            )
        )

        viewModel.requestFlutterInstallation(into: "/tmp/appforge-sdk")
        await viewModel.installFlutter()
        let callCount = await recorder.callCount

        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(viewModel.flutterSDKPath, "/tmp/appforge-sdk/flutter")
        XCTAssertEqual(preferences.saved.flutterSDKPath, "/tmp/appforge-sdk/flutter")
        XCTAssertEqual(viewModel.installationPhase, .completed)
        XCTAssertEqual(viewModel.installationWarnings.count, 1)
        XCTAssertNotNil(viewModel.report)
        XCTAssertFalse(viewModel.isInstallingFlutter)
    }

    func testFailedFlutterInstallationKeepsExistingSDKConfiguration() async {
        let preferences = InMemoryToolchainPreferenceStore(
            initial: ToolchainPreferences(
                flutterSDKPath: "/existing/flutter",
                preferredIDE: .vsCode
            )
        )
        let viewModel = makeEnvironmentDoctorViewModel(
            preferences: preferences,
            installer: StubFlutterInstaller(shouldFail: true)
        )

        viewModel.requestFlutterInstallation(into: "/tmp/appforge-sdk")
        await viewModel.installFlutter()

        XCTAssertEqual(viewModel.flutterSDKPath, "/existing/flutter")
        XCTAssertEqual(preferences.saved.flutterSDKPath, "/existing/flutter")
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isInstallingFlutter)
    }

    private func makeEnvironmentDoctorViewModel(
        preferences: InMemoryToolchainPreferenceStore = InMemoryToolchainPreferenceStore(),
        installer: any FlutterSDKInstalling
    ) -> EnvironmentDoctorViewModel {
        EnvironmentDoctorViewModel(
            doctor: EnvironmentDoctorUseCase(detector: AlwaysReadyToolDetector()),
            preferencesStore: preferences,
            projectOpener: NoopProjectOpener(),
            flutterInstaller: installer
        )
    }
}

private struct AlwaysReadyToolDetector: ToolDetector {
    func detect(
        requirement: ToolRequirement,
        flutterSDKPath: String?
    ) async -> ToolDetectionResult {
        ToolDetectionResult(
            requirement: requirement,
            availability: .ready,
            version: SemanticVersion(major: 99, minor: 0),
            path: requirement.id == .flutter ? flutterSDKPath : "/usr/bin/test-tool",
            detail: "Bereit"
        )
    }
}

private final class InMemoryToolchainPreferenceStore: ToolchainPreferenceStore {
    private(set) var saved: ToolchainPreferences

    init(initial: ToolchainPreferences = ToolchainPreferences()) {
        saved = initial
    }

    func load() -> ToolchainPreferences {
        saved
    }

    func save(_ preferences: ToolchainPreferences) {
        saved = preferences
    }
}

private struct NoopProjectOpener: GeneratedProjectOpening {
    func open(projectURL: URL, preferredIDE: PreferredIDE) throws {}
}

private struct StubFlutterInstaller: FlutterSDKInstalling {
    let recorder: InstallerInvocationRecorder?
    let result: FlutterInstallationResult
    let shouldFail: Bool

    init(
        recorder: InstallerInvocationRecorder? = nil,
        result: FlutterInstallationResult = FlutterInstallationResult(
            sdkPath: "/tmp/appforge-sdk/flutter",
            version: "3.47.0"
        ),
        shouldFail: Bool = false
    ) {
        self.recorder = recorder
        self.result = result
        self.shouldFail = shouldFail
    }

    func install(
        into parentDirectoryPath: String,
        progress: @escaping @Sendable (FlutterInstallationPhase) async -> Void
    ) async throws -> FlutterInstallationResult {
        await recorder?.recordCall()
        await progress(.resolvingRelease)

        if shouldFail {
            throw AppForgeError.configuration(message: "Testinstallation fehlgeschlagen")
        }

        await progress(.downloading)
        await progress(.verifying)
        await progress(.extracting)
        await progress(.validating)
        await progress(.completed)
        return result
    }
}

private actor InstallerInvocationRecorder {
    private(set) var callCount = 0

    func recordCall() {
        callCount += 1
    }
}
