import AppForgeApplication
import AppForgeDomain
import Foundation
import Observation

@MainActor
@Observable
final class ProjectSetupViewModel {
    private let createProjectDraft: CreateProjectDraftUseCase
    private let preferencesStore: any ToolchainPreferenceStore
    private let toolchainResolver: ResolveProjectGenerationToolchainUseCase
    private let projectBuilder: any MaterializedFlutterProjectBuilding
    private let projectOpener: any GeneratedProjectOpening
    private let ideHandoffDetector: any IDEHandoffDetecting
    private let generationPreferences: ToolchainPreferences

    var projectName: String
    var organizationIdentifier: String
    var framework: OutputFramework
    var targetPlatforms: Set<TargetPlatform>
    var backend: BackendProvider
    var flutterStateManagement: FlutterStateManagement

    private(set) var summaryMessage: String?
    private(set) var isGenerating = false
    private(set) var generatedProjectPath: String?
    private(set) var generatedToolchainReceipt: FlutterToolchainReceipt?
    private(set) var generationErrorMessage: String?
    private(set) var ideHandoffs: [IDEHandoffAvailability]

    let architecture = ArchitectureContract.standard

    init(
        createProjectDraft: CreateProjectDraftUseCase,
        preferencesStore: any ToolchainPreferenceStore =
            UserDefaultsToolchainPreferenceStore(),
        toolchainResolver: ResolveProjectGenerationToolchainUseCase =
            ResolveProjectGenerationToolchainUseCase(),
        projectBuilder: any MaterializedFlutterProjectBuilding =
            BuildFlutterProjectUseCase(),
        projectOpener: any GeneratedProjectOpening =
            SystemGeneratedProjectOpener(),
        ideHandoffDetector: any IDEHandoffDetecting =
            SystemIDEHandoffDetector()
    ) {
        self.createProjectDraft = createProjectDraft
        self.preferencesStore = preferencesStore
        self.toolchainResolver = toolchainResolver
        self.projectBuilder = projectBuilder
        self.projectOpener = projectOpener
        self.ideHandoffDetector = ideHandoffDetector
        ideHandoffs = ideHandoffDetector.detect()

        let draft = createProjectDraft()
        let preferences = preferencesStore.load()
        generationPreferences = preferences

        projectName = draft.identity.name
        organizationIdentifier = draft.identity.organizationIdentifier
        framework = draft.framework
        targetPlatforms = draft.targetPlatforms
        backend = draft.backend
        flutterStateManagement = draft.flutterStateManagement
            ?? .riverpod
    }

    var availableFrameworks: [OutputFramework] {
        OutputFramework.allCases.filter(\.isAvailable)
    }

    var availablePlatforms: [TargetPlatform] {
        TargetPlatform.allCases.filter {
            framework.supportedPlatforms.contains($0)
        }
    }

    var canPrepareProject: Bool {
        !normalizedProjectName.isEmpty
            && isOrganizationIdentifierValid
            && framework.isAvailable
            && !targetPlatforms.isEmpty
            && targetPlatforms.isSubset(
                of: framework.supportedPlatforms
            )
    }

    var isGenerationToolchainReady: Bool {
        resolvedGenerationToolchain != nil
    }

    var canGenerateProject: Bool {
        canPrepareProject
            && isGenerationToolchainReady
            && !isGenerating
    }

    var developmentEnvironmentMode: DevelopmentEnvironmentMode {
        generationPreferences.developmentEnvironmentMode
            ?? .appForgeManaged
    }

    var preferredIDE: PreferredIDE {
        generationPreferences.preferredIDE
    }


    var availableIDEHandoffs: [IDEHandoffAvailability] {
        ideHandoffs.filter(\.isAvailable)
    }

    var isPreferredIDEAvailable: Bool {
        handoffAvailability(
            for: preferredIDE
        )?.isAvailable == true
    }


    var alternateIDEHandoffs: [IDEHandoffAvailability] {
        availableIDEHandoffs.filter {
            $0.ide != preferredIDE
        }
    }

    var preferredIDEReadinessMessage: String {
        if isPreferredIDEAvailable {
            return "\(preferredIDE.rawValue) ist für den Projekt-Handoff verfügbar."
        }
        return "\(preferredIDE.rawValue) wurde nicht gefunden. Wählen Sie eine verfügbare Alternative."
    }

    var toolchainReadinessMessage: String {
        do {
            _ = try toolchainResolver(
                preferences: generationPreferences
            )
            return "Toolchain für die produktive Flutter-Generierung ist bereit."
        } catch {
            return error.localizedDescription
        }
    }

    var toolchainSummary: String {
        guard let toolchain = resolvedGenerationToolchain else {
            return "Nicht bereit"
        }

        switch toolchain {
        case .directSDK:
            return "Explizites Flutter SDK"
        case .nixEnvironment:
            return "Verifiziertes Nix Environment"
        }
    }

    var specification: ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: normalizedProjectName,
                organizationIdentifier: normalizedOrganizationIdentifier
            ),
            framework: framework,
            targetPlatforms: targetPlatforms,
            backend: backend,
            flutterStateManagement: framework == .flutter
                ? flutterStateManagement
                : nil
        )
    }

    func setTarget(
        _ platform: TargetPlatform,
        enabled: Bool
    ) {
        guard framework.supportedPlatforms.contains(
            platform
        ) else {
            targetPlatforms.remove(platform)
            return
        }

        if enabled {
            targetPlatforms.insert(platform)
        } else {
            targetPlatforms.remove(platform)
        }
    }

    func prepareProject() {
        guard validateProjectInputs() else {
            return
        }

        if resolvedGenerationToolchain == nil {
            summaryMessage = toolchainReadinessMessage
            return
        }

        summaryMessage =
            "Projektentwurf und Toolchain sind bereit für die Generierung."
    }

    private var resolvedGenerationToolchain: FlutterMaterializationToolchain? {
        try? toolchainResolver(
            preferences: generationPreferences
        )
    }

    private var normalizedProjectName: String {
        projectName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var normalizedOrganizationIdentifier: String {
        organizationIdentifier
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
    }

    private var isOrganizationIdentifierValid: Bool {
        let components = normalizedOrganizationIdentifier
            .split(
                separator: ".",
                omittingEmptySubsequences: false
            )
        guard components.count >= 2 else {
            return false
        }

        return components.allSatisfy { component in
            guard let first = component.first,
                  first.isLowercase
            else {
                return false
            }

            return component.allSatisfy { character in
                character.isLowercase
                    || character.isNumber
            }
        }
    }

    private func validateProjectInputs() -> Bool {
        guard !normalizedProjectName.isEmpty else {
            summaryMessage =
                "Bitte geben Sie einen Projektnamen ein."
            return false
        }
        guard isOrganizationIdentifierValid else {
            summaryMessage =
                "Bitte verwenden Sie eine portable Organisationskennung wie de.meinefirma."
            return false
        }
        guard framework.isAvailable else {
            summaryMessage =
                "Dieser Renderer ist noch nicht produktionsbereit. Bitte verwenden Sie Flutter."
            return false
        }
        guard !targetPlatforms.isEmpty,
              targetPlatforms.isSubset(
                  of: framework.supportedPlatforms
              )
        else {
            summaryMessage =
                "Bitte wählen Sie mindestens eine vom Framework unterstützte Zielplattform."
            return false
        }
        return true
    }
}

extension ProjectSetupViewModel {
    func generateProject(
        to targetURL: URL
    ) async {
        guard validateProjectInputs() else {
            return
        }

        let toolchain: FlutterMaterializationToolchain
        do {
            toolchain = try toolchainResolver(
                preferences: generationPreferences
            )
        } catch {
            generationErrorMessage = error.localizedDescription
            summaryMessage = error.localizedDescription
            return
        }

        beginGeneration()

        let builder = projectBuilder
        let specification = specification

        do {
            let result = try await Task.detached(
                priority: .userInitiated
            ) {
                try builder.build(
                    specification: specification,
                    toolchain: toolchain,
                    targetURL: targetURL
                )
            }.value
            completeGeneration(result)
        } catch {
            failGeneration(error)
        }
    }

    func openGeneratedProject() {
        openGeneratedProject(in: preferredIDE)
    }

    func openGeneratedProject(
        in ide: PreferredIDE
    ) {
        guard let generatedProjectPath else {
            generationErrorMessage =
                "Es wurde noch kein Projekt erzeugt."
            return
        }
        guard handoffAvailability(for: ide)?.isAvailable == true else {
            generationErrorMessage =
                "(ide.rawValue) wurde auf diesem Mac nicht gefunden."
            return
        }

        do {
            try projectOpener.open(
                projectURL: URL(
                    fileURLWithPath: generatedProjectPath,
                    isDirectory: true
                ),
                preferredIDE: ide
            )
            generationErrorMessage = nil
        } catch {
            generationErrorMessage = error.localizedDescription
        }
    }

    func refreshIDEHandoffs() {
        ideHandoffs = ideHandoffDetector.detect()
    }

    private func handoffAvailability(
        for ide: PreferredIDE
    ) -> IDEHandoffAvailability? {
        ideHandoffs.first { $0.ide == ide }
    }

    private func beginGeneration() {
        isGenerating = true
        generatedProjectPath = nil
        generatedToolchainReceipt = nil
        generationErrorMessage = nil
        summaryMessage =
            "Flutter-Projekt wird erzeugt und validiert …"
    }

    private func completeGeneration(
        _ result: MaterializedFlutterGenerationResult
    ) {
        isGenerating = false
        generatedProjectPath = result.projectPath
        generatedToolchainReceipt = result.toolchainReceipt
        generationErrorMessage = nil
        summaryMessage =
            "Flutter-Projekt wurde vollständig erzeugt und validiert."
    }

    private func failGeneration(
        _ error: Error
    ) {
        isGenerating = false
        generatedProjectPath = nil
        generatedToolchainReceipt = nil
        generationErrorMessage = error.localizedDescription
        summaryMessage = error.localizedDescription
    }
}
