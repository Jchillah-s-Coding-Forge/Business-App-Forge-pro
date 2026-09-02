import AppForgeApplication
import AppForgeDomain
import Foundation
import Observation

@MainActor
@Observable
final class WorkspaceHomeViewModel {
    private let environment: AppEnvironment

    var isPresentingProjectSetup = false
    private(set) var projectSetupViewModel: ProjectSetupViewModel?
    private(set) var environmentDoctorViewModel: EnvironmentDoctorViewModel

    init(environment: AppEnvironment) {
        self.environment = environment
        environmentDoctorViewModel = environment.makeEnvironmentDoctorViewModel()
    }

    func startProjectSetup() {
        projectSetupViewModel = environment.makeProjectSetupViewModel()
        isPresentingProjectSetup = true
    }

    func dismissProjectSetup() {
        isPresentingProjectSetup = false
        projectSetupViewModel = nil
    }
}

@MainActor
@Observable
final class EnvironmentDoctorViewModel {
    private let doctor: EnvironmentDoctorUseCase
    private let preferencesStore: any ToolchainPreferenceStore
    private let projectOpener: any GeneratedProjectOpening
    private let flutterInstaller: any FlutterSDKInstalling
    private var configurationRevision = 0

    var selectedPlatforms: Set<TargetPlatform> = [.iOS, .android]
    var preferredIDE: PreferredIDE {
        didSet { persistPreferences() }
    }
    var isPresentingFlutterInstallConfirmation = false

    private(set) var flutterSDKPath: String
    private(set) var flutterInstallParentPath = ""
    private(set) var report: ToolchainReport?
    private(set) var isScanning = false
    private(set) var isInstallingFlutter = false
    private(set) var installationPhase: FlutterInstallationPhase?
    private(set) var installationWarnings: [String] = []
    private(set) var errorMessage: String?

    let availablePlatforms: [TargetPlatform] = [.iOS, .android]

    init(
        doctor: EnvironmentDoctorUseCase,
        preferencesStore: any ToolchainPreferenceStore,
        projectOpener: any GeneratedProjectOpening,
        flutterInstaller: any FlutterSDKInstalling
    ) {
        self.doctor = doctor
        self.preferencesStore = preferencesStore
        self.projectOpener = projectOpener
        self.flutterInstaller = flutterInstaller

        let preferences = preferencesStore.load()
        flutterSDKPath = preferences.flutterSDKPath ?? ""
        preferredIDE = preferences.preferredIDE
    }

    var canScan: Bool {
        !selectedPlatforms.isEmpty
    }

    var canInstallFlutter: Bool {
        !flutterInstallParentPath.isEmpty && !isInstallingFlutter
    }

    func setTarget(_ platform: TargetPlatform, enabled: Bool) {
        if enabled {
            selectedPlatforms.insert(platform)
        } else {
            selectedPlatforms.remove(platform)
        }
        configurationDidChange()
    }

    func setFlutterSDKPath(_ path: String) {
        flutterSDKPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        persistPreferences()
        configurationDidChange()
    }

    func clearFlutterSDKPath() {
        flutterSDKPath = ""
        persistPreferences()
        configurationDidChange()
    }

    func requestFlutterInstallation(into parentDirectoryPath: String) {
        let path = parentDirectoryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            errorMessage = "Bitte wählen Sie einen Installationsordner für Flutter."
            return
        }

        flutterInstallParentPath = path
        installationWarnings = []
        errorMessage = nil
        isPresentingFlutterInstallConfirmation = true
    }

    func installFlutter() async {
        guard canInstallFlutter else { return }

        isPresentingFlutterInstallConfirmation = false
        isInstallingFlutter = true
        installationPhase = .resolvingRelease
        installationWarnings = []
        errorMessage = nil
        defer { isInstallingFlutter = false }

        do {
            let result = try await flutterInstaller.install(into: flutterInstallParentPath) { phase in
                await MainActor.run {
                    self.installationPhase = phase
                }
            }

            flutterSDKPath = result.sdkPath
            installationWarnings = result.warnings
            persistPreferences()
            configurationRevision += 1
            report = nil
            await scan()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scan() async {
        guard canScan else {
            isScanning = false
            report = nil
            return
        }

        let revision = configurationRevision
        let platforms = selectedPlatforms
        let sdkPath = flutterSDKPath.isEmpty ? nil : flutterSDKPath
        isScanning = true
        errorMessage = nil

        let newReport = await doctor.run(
            framework: .flutter,
            targetPlatforms: platforms,
            flutterSDKPath: sdkPath
        )

        guard revision == configurationRevision else { return }
        report = newReport
        isScanning = false
    }

    func openGeneratedProject(at url: URL) {
        do {
            try projectOpener.open(projectURL: url, preferredIDE: preferredIDE)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func configurationDidChange() {
        configurationRevision += 1
        report = nil
        isScanning = false

        guard canScan else { return }
        Task { await scan() }
    }

    private func persistPreferences() {
        preferencesStore.save(
            ToolchainPreferences(
                flutterSDKPath: flutterSDKPath.isEmpty ? nil : flutterSDKPath,
                preferredIDE: preferredIDE
            )
        )
    }
}
