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

    var selectedPlatforms: Set<TargetPlatform> = [.iOS, .android]
    var preferredIDE: PreferredIDE {
        didSet { persistPreferences() }
    }

    private(set) var flutterSDKPath: String
    private(set) var report: ToolchainReport?
    private(set) var isScanning = false
    private(set) var errorMessage: String?

    let availablePlatforms: [TargetPlatform] = [.iOS, .android]

    init(
        doctor: EnvironmentDoctorUseCase,
        preferencesStore: any ToolchainPreferenceStore,
        projectOpener: any GeneratedProjectOpening
    ) {
        self.doctor = doctor
        self.preferencesStore = preferencesStore
        self.projectOpener = projectOpener

        let preferences = preferencesStore.load()
        flutterSDKPath = preferences.flutterSDKPath ?? ""
        preferredIDE = preferences.preferredIDE
    }

    var canScan: Bool {
        !selectedPlatforms.isEmpty && !isScanning
    }

    func setTarget(_ platform: TargetPlatform, enabled: Bool) {
        if enabled {
            selectedPlatforms.insert(platform)
        } else {
            selectedPlatforms.remove(platform)
        }
    }

    func setFlutterSDKPath(_ path: String) {
        flutterSDKPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        persistPreferences()
    }

    func clearFlutterSDKPath() {
        flutterSDKPath = ""
        persistPreferences()
    }

    func scan() async {
        guard canScan else { return }
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }

        report = await doctor.run(
            framework: .flutter,
            targetPlatforms: selectedPlatforms,
            flutterSDKPath: flutterSDKPath.isEmpty ? nil : flutterSDKPath
        )
    }

    func openGeneratedProject(at url: URL) {
        do {
            try projectOpener.open(projectURL: url, preferredIDE: preferredIDE)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
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
