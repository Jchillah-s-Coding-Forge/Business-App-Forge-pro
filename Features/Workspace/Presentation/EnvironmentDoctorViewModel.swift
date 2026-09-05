import AppForgeApplication
import AppForgeDomain
import Foundation
import Observation

@MainActor
@Observable
final class EnvironmentDoctorViewModel {
    private let doctor: EnvironmentDoctorUseCase
    private let preferencesStore: any ToolchainPreferenceStore
    private let projectOpener: any GeneratedProjectOpening
    private let flutterInstaller: any FlutterSDKInstalling
    private let reportExporter: any ToolchainReportExporting
    private let setupAdvisor: ToolSetupAdvisor
    private let externalURLLauncher: any ExternalURLLaunching
    private let nixBootstrapPreparer: any NixBootstrapPreparing
    private let nixBootstrapLauncher: any NixBootstrapLaunching
    private let nixBootstrapCleaner: any NixBootstrapCleaning
    private let nixEnvironmentProvisioner: any NixEnvironmentProvisioning
    private let nixEnvironmentPlanner: NixEnvironmentPlanner
    private let nixBootstrapWorkspaceParentURL: URL
    private var configurationRevision = 0

    var selectedPlatforms: Set<TargetPlatform> = [.iOS, .android]
    private(set) var developmentEnvironmentMode: DevelopmentEnvironmentMode
    var preferredIDE: PreferredIDE {
        didSet { persistPreferences() }
    }

    var isPresentingFlutterInstallConfirmation = false
    var isNixBootstrapConfirmed = false

    private(set) var flutterSDKPath: String
    private(set) var flutterInstallParentPath = ""
    private(set) var report: ToolchainReport?
    private(set) var isScanning = false
    private(set) var isInstallingFlutter = false
    private(set) var installationPhase: FlutterInstallationPhase?
    private(set) var installationWarnings: [String] = []
    private(set) var errorMessage: String?

    private(set) var preparedNixBootstrap: NixBootstrapPreparedInstaller?
    private(set) var isPreparingNixBootstrap = false
    private(set) var hasLaunchedNixBootstrap = false
    private(set) var isProvisioningNixEnvironment = false
    private(set) var nixProvisioningResult: NixEnvironmentProvisioningResult?
    private(set) var nixProvisionTargetPath = ""

    let availablePlatforms: [TargetPlatform] = [.iOS, .android]
    let nixBootstrapReleaseVersion = NixBootstrapReleasePolicy.current.version

    init(
        doctor: EnvironmentDoctorUseCase,
        preferencesStore: any ToolchainPreferenceStore,
        projectOpener: any GeneratedProjectOpening,
        flutterInstaller: any FlutterSDKInstalling,
        reportExporter: any ToolchainReportExporting = JSONToolchainReportExporter(),
        setupAdvisor: ToolSetupAdvisor = ToolSetupAdvisor(),
        externalURLLauncher: any ExternalURLLaunching = SystemExternalURLLauncher(),
        nixBootstrapPreparer: any NixBootstrapPreparing = PrepareNixBootstrapUseCase(),
        nixBootstrapLauncher: any NixBootstrapLaunching = LaunchNixBootstrapUseCase(),
        nixBootstrapCleaner: any NixBootstrapCleaning = CleanupNixBootstrapUseCase(),
        nixEnvironmentProvisioner: any NixEnvironmentProvisioning = ProvisionNixEnvironmentUseCase(),
        nixEnvironmentPlanner: NixEnvironmentPlanner = NixEnvironmentPlanner(),
        nixBootstrapWorkspaceParentURL: URL = FileManager.default.temporaryDirectory
    ) {
        self.doctor = doctor
        self.preferencesStore = preferencesStore
        self.projectOpener = projectOpener
        self.flutterInstaller = flutterInstaller
        self.reportExporter = reportExporter
        self.setupAdvisor = setupAdvisor
        self.externalURLLauncher = externalURLLauncher
        self.nixBootstrapPreparer = nixBootstrapPreparer
        self.nixBootstrapLauncher = nixBootstrapLauncher
        self.nixBootstrapCleaner = nixBootstrapCleaner
        self.nixEnvironmentProvisioner = nixEnvironmentProvisioner
        self.nixEnvironmentPlanner = nixEnvironmentPlanner
        self.nixBootstrapWorkspaceParentURL = nixBootstrapWorkspaceParentURL

        let preferences = preferencesStore.load()
        flutterSDKPath = preferences.flutterSDKPath ?? ""
        preferredIDE = preferences.preferredIDE
        developmentEnvironmentMode = preferences.developmentEnvironmentMode
            ?? .appForgeManaged
    }

    var canScan: Bool {
        !selectedPlatforms.isEmpty
    }

    var canInstallFlutter: Bool {
        !flutterInstallParentPath.isEmpty && !isInstallingFlutter
    }

    func setTarget(
        _ platform: TargetPlatform,
        enabled: Bool
    ) {
        if enabled {
            selectedPlatforms.insert(platform)
        } else {
            selectedPlatforms.remove(platform)
        }
        configurationDidChange()
    }

    func setFlutterSDKPath(_ path: String) {
        flutterSDKPath = path.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        persistPreferences()
        configurationDidChange()
    }

    func clearFlutterSDKPath() {
        flutterSDKPath = ""
        persistPreferences()
        configurationDidChange()
    }

    func requestFlutterInstallation(
        into parentDirectoryPath: String
    ) {
        let path = parentDirectoryPath.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
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
        guard canInstallFlutter else {
            return
        }

        beginFlutterInstallation()
        defer { isInstallingFlutter = false }

        do {
            let result = try await flutterInstaller.install(
                into: flutterInstallParentPath
            ) { phase in
                await MainActor.run {
                    self.installationPhase = phase
                }
            }
            await completeFlutterInstallation(result)
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
        let sdkPath = flutterSDKPath.isEmpty
            ? nil
            : flutterSDKPath

        isScanning = true
        errorMessage = nil

        let newReport = await doctor.run(
            framework: .flutter,
            targetPlatforms: platforms,
            flutterSDKPath: sdkPath
        )

        guard revision == configurationRevision else {
            return
        }

        report = newReport
        isScanning = false
        handleNixReadinessAfterScan()
    }

    func exportReport(to url: URL) {
        guard let report else {
            errorMessage = "Es gibt noch keinen Toolchain-Report zum Speichern."
            return
        }

        do {
            try reportExporter.export(report, to: url)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setupRecommendation(
        for result: ToolDetectionResult
    ) -> ToolSetupRecommendation? {
        guard result.availability != .ready else {
            return nil
        }
        return setupAdvisor.recommendation(for: result.id)
    }

    func openSetup(for result: ToolDetectionResult) {
        guard let recommendation = setupRecommendation(
            for: result
        ) else {
            return
        }

        do {
            try externalURLLauncher.open(
                urlString: recommendation.urlString
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openGeneratedProject(at url: URL) {
        do {
            try projectOpener.open(
                projectURL: url,
                preferredIDE: preferredIDE
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func beginFlutterInstallation() {
        isPresentingFlutterInstallConfirmation = false
        isInstallingFlutter = true
        installationPhase = .resolvingRelease
        installationWarnings = []
        errorMessage = nil
    }

    private func completeFlutterInstallation(
        _ result: FlutterInstallationResult
    ) async {
        flutterSDKPath = result.sdkPath
        installationWarnings = result.warnings
        persistPreferences()
        configurationRevision += 1
        report = nil
        await scan()
    }

    private func configurationDidChange() {
        configurationRevision += 1
        report = nil
        isScanning = false

        guard canScan else {
            return
        }
        Task { await scan() }
    }

    private func persistPreferences() {
        preferencesStore.save(
            ToolchainPreferences(
                flutterSDKPath: flutterSDKPath.isEmpty
                    ? nil
                    : flutterSDKPath,
                preferredIDE: preferredIDE,
                developmentEnvironmentMode: developmentEnvironmentMode
            )
        )
    }
}

extension EnvironmentDoctorViewModel {
    var nixResult: ToolDetectionResult? {
        report?.results.first { $0.id == .nix }
    }

    var isNixReady: Bool {
        nixResult?.availability == .ready
    }

    var shouldOfferNixBootstrap: Bool {
        developmentEnvironmentMode == .nixReproducible
            && !isNixReady
    }

    var canPrepareNixBootstrap: Bool {
        shouldOfferNixBootstrap
            && preparedNixBootstrap == nil
            && !isPreparingNixBootstrap
    }

    var canLaunchNixBootstrap: Bool {
        developmentEnvironmentMode == .nixReproducible
            && preparedNixBootstrap != nil
            && isNixBootstrapConfirmed
            && !hasLaunchedNixBootstrap
    }

    var canProvisionNixEnvironment: Bool {
        developmentEnvironmentMode == .nixReproducible
            && isNixReady
            && !isProvisioningNixEnvironment
    }

    func setDevelopmentEnvironmentMode(
        _ mode: DevelopmentEnvironmentMode
    ) {
        guard developmentEnvironmentMode != mode else {
            return
        }

        let leavingNix = developmentEnvironmentMode == .nixReproducible
            && mode != .nixReproducible
        if leavingNix {
            cleanupPreparedNixBootstrap()
            nixProvisioningResult = nil
            nixProvisionTargetPath = ""
        }

        developmentEnvironmentMode = mode
        persistPreferences()
        configurationDidChange()
    }

    func prepareNixBootstrap() async {
        guard canPrepareNixBootstrap else {
            return
        }

        isPreparingNixBootstrap = true
        isNixBootstrapConfirmed = false
        hasLaunchedNixBootstrap = false
        errorMessage = nil
        defer { isPreparingNixBootstrap = false }

        do {
            preparedNixBootstrap = try await nixBootstrapPreparer.prepare(
                workspaceParentURL: nixBootstrapWorkspaceParentURL
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func launchNixBootstrap() {
        guard canLaunchNixBootstrap,
              let preparedNixBootstrap
        else {
            return
        }

        do {
            try nixBootstrapLauncher.launch(
                prepared: preparedNixBootstrap,
                confirmation: NixBootstrapConfirmation(
                    approvedInstallerSHA256:
                    preparedNixBootstrap.installerSHA256
                )
            )
            hasLaunchedNixBootstrap = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelNixBootstrapPreparation() {
        cleanupPreparedNixBootstrap()
    }

    func provisionNixEnvironment(
        to targetURL: URL
    ) async {
        guard canProvisionNixEnvironment,
              let nixExecutablePath = nixResult?.path
        else {
            return
        }

        do {
            let plan = try nixEnvironmentPlanner.plan(
                framework: .flutter,
                targetPlatforms: selectedPlatforms
            )
            let input = NixEnvironmentProvisioningInput(
                plan: plan,
                nixExecutablePath: nixExecutablePath,
                targetURL: targetURL
            )
            try await runNixProvisioning(input)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func runNixProvisioning(
        _ input: NixEnvironmentProvisioningInput
    ) async throws {
        isProvisioningNixEnvironment = true
        nixProvisionTargetPath = input.targetURL.path
        nixProvisioningResult = nil
        errorMessage = nil
        defer { isProvisioningNixEnvironment = false }

        let provisioner = nixEnvironmentProvisioner
        let result = try await Task.detached(
            priority: .userInitiated
        ) {
            try provisioner.provision(input)
        }.value

        nixProvisioningResult = result
    }

    private func handleNixReadinessAfterScan() {
        guard isNixReady,
              preparedNixBootstrap != nil
        else {
            return
        }
        cleanupPreparedNixBootstrap()
    }

    private func cleanupPreparedNixBootstrap() {
        guard let preparedNixBootstrap else {
            isNixBootstrapConfirmed = false
            hasLaunchedNixBootstrap = false
            return
        }

        do {
            try nixBootstrapCleaner.cleanup(
                prepared: preparedNixBootstrap
            )
            self.preparedNixBootstrap = nil
            isNixBootstrapConfirmed = false
            hasLaunchedNixBootstrap = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
