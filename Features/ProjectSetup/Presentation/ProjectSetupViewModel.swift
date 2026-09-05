import AppForgeApplication
import AppForgeDomain
import Foundation
import Observation

@MainActor
@Observable
final class ProjectSetupViewModel {
    private let createProjectDraft: CreateProjectDraftUseCase
    private let preferencesStore: any ToolchainPreferenceStore
    private let projectBuilder: any FlutterProjectBuilding
    private let projectOpener: any GeneratedProjectOpening

    var projectName: String
    var organizationIdentifier: String
    var framework: OutputFramework
    var targetPlatforms: Set<TargetPlatform>
    var backend: BackendProvider
    var flutterStateManagement: FlutterStateManagement

    private(set) var summaryMessage: String?
    private(set) var toolchainPreferences: ToolchainPreferences
    private(set) var isGeneratingProject = false
    private(set) var generatedProjectPath: String?
    private(set) var generatedToolchainReceipt: FlutterToolchainReceipt?

    let architecture = ArchitectureContract.standard

    init(
        createProjectDraft: CreateProjectDraftUseCase,
        preferencesStore: any ToolchainPreferenceStore,
        projectBuilder: any FlutterProjectBuilding,
        projectOpener: any GeneratedProjectOpening
    ) {
        self.createProjectDraft = createProjectDraft
        self.preferencesStore = preferencesStore
        self.projectBuilder = projectBuilder
        self.projectOpener = projectOpener

        let draft = createProjectDraft()
        projectName = draft.identity.name
        organizationIdentifier = draft.identity.organizationIdentifier
        framework = draft.framework
        targetPlatforms = draft.targetPlatforms
        backend = draft.backend
        flutterStateManagement = draft.flutterStateManagement ?? .riverpod
        toolchainPreferences = preferencesStore.load()
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

    var canGenerateProject: Bool {
        canPrepareProject
            && resolvedToolchain != nil
            && !isGeneratingProject
    }

    var developmentEnvironmentMode: DevelopmentEnvironmentMode {
        toolchainPreferences.developmentEnvironmentMode
            ?? .appForgeManaged
    }

    var preferredIDE: PreferredIDE {
        toolchainPreferences.preferredIDE
    }

    var toolchainSummary: String {
        switch developmentEnvironmentMode {
        case .appForgeManaged:
            directToolchainSummary(
                prefix: "AppForge Managed"
            )
        case .existingToolchain:
            directToolchainSummary(
                prefix: "Existing Toolchain"
            )
        case .nixReproducible:
            nixToolchainSummary
        }
    }

    var specification: ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: normalizedProjectName,
                organizationIdentifier:
                    normalizedOrganizationIdentifier
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

    func refreshToolchainPreferences() {
        toolchainPreferences = preferencesStore.load()
    }

    func prepareProject() {
        guard validateProjectForAction() else {
            return
        }

        summaryMessage = canGenerateProject
            ? "Projektentwurf und Build-Umgebung sind bereit."
            : toolchainMissingMessage
    }

    func generateProject(
        at targetURL: URL
    ) async {
        refreshToolchainPreferences()
        guard validateProjectForAction() else {
            return
        }
        guard let toolchain = resolvedToolchain else {
            summaryMessage = toolchainMissingMessage
            return
        }

        isGeneratingProject = true
        generatedProjectPath = nil
        generatedToolchainReceipt = nil
        summaryMessage = "Flutter-Projekt wird erzeugt …"
        defer { isGeneratingProject = false }

        let builder = projectBuilder
        let currentSpecification = specification

        do {
            let result = try await Task.detached(
                priority: .userInitiated
            ) {
                try builder.build(
                    specification: currentSpecification,
                    toolchain: toolchain,
                    targetURL: targetURL
                )
            }.value

            generatedProjectPath = result.projectPath
            generatedToolchainReceipt =
                result.toolchainReceipt
            summaryMessage =
                "Flutter-Projekt erfolgreich erzeugt."
        } catch {
            summaryMessage = error.localizedDescription
        }
    }

    func openGeneratedProject() {
        guard let generatedProjectPath else {
            summaryMessage =
                "Es wurde noch kein Projekt erzeugt."
            return
        }

        do {
            try projectOpener.open(
                projectURL: URL(
                    fileURLWithPath: generatedProjectPath,
                    isDirectory: true
                ),
                preferredIDE: preferredIDE
            )
        } catch {
            summaryMessage = error.localizedDescription
        }
    }

    private var resolvedToolchain: FlutterMaterializationToolchain? {
        switch developmentEnvironmentMode {
        case .appForgeManaged, .existingToolchain:
            guard let flutterSDKPath = normalizedPreference(
                toolchainPreferences.flutterSDKPath
            ) else {
                return nil
            }
            return .directSDK(path: flutterSDKPath)

        case .nixReproducible:
            guard let environmentPath = normalizedPreference(
                toolchainPreferences.nixEnvironmentPath
            ),
            let executablePath = normalizedPreference(
                toolchainPreferences.nixExecutablePath
            ) else {
                return nil
            }
            return .nixEnvironment(
                environmentPath: environmentPath,
                nixExecutablePath: executablePath
            )
        }
    }

    private func directToolchainSummary(
        prefix: String
    ) -> String {
        guard let flutterSDKPath = normalizedPreference(
            toolchainPreferences.flutterSDKPath
        ) else {
            return "\(prefix): Flutter SDK im Environment Doctor auswählen."
        }
        return "\(prefix): \(flutterSDKPath)"
    }

    private var nixToolchainSummary: String {
        guard let environmentPath = normalizedPreference(
            toolchainPreferences.nixEnvironmentPath
        ),
        normalizedPreference(
            toolchainPreferences.nixExecutablePath
        ) != nil
        else {
            return "Nix Reproducible: Environment im Environment Doctor erzeugen."
        }
        return "Nix Reproducible: \(environmentPath)"
    }

    private var toolchainMissingMessage: String {
        switch developmentEnvironmentMode {
        case .appForgeManaged, .existingToolchain:
            "Bitte wählen oder installieren Sie im Environment Doctor ein Flutter SDK."
        case .nixReproducible:
            "Bitte erzeugen Sie im Environment Doctor zuerst ein verifiziertes Nix-Environment."
        }
    }

    private func validateProjectForAction() -> Bool {
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

    private func normalizedPreference(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }
        let normalized = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return normalized.isEmpty ? nil : normalized
    }

    private var normalizedProjectName: String {
        projectName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var normalizedOrganizationIdentifier: String {
        organizationIdentifier.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()
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
}
