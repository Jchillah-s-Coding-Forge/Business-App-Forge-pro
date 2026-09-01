import AppForgeApplication
import AppForgeDomain
import Foundation
import Observation

@MainActor
@Observable
final class ProjectSetupViewModel {
    private let createProjectDraft: CreateProjectDraftUseCase

    var projectName: String
    var organizationIdentifier: String
    var framework: OutputFramework
    var targetPlatforms: Set<TargetPlatform>
    var backend: BackendProvider
    var flutterStateManagement: FlutterStateManagement
    private(set) var summaryMessage: String?

    let architecture = ArchitectureContract.standard

    init(createProjectDraft: CreateProjectDraftUseCase) {
        self.createProjectDraft = createProjectDraft
        let draft = createProjectDraft()
        projectName = draft.identity.name
        organizationIdentifier = draft.identity.organizationIdentifier
        framework = draft.framework
        targetPlatforms = draft.targetPlatforms
        backend = draft.backend
        flutterStateManagement = draft.flutterStateManagement ?? .riverpod
    }

    var availableFrameworks: [OutputFramework] {
        OutputFramework.allCases.filter(\.isAvailable)
    }

    var availablePlatforms: [TargetPlatform] {
        TargetPlatform.allCases.filter { framework.supportedPlatforms.contains($0) }
    }

    var canPrepareProject: Bool {
        !normalizedProjectName.isEmpty
            && isOrganizationIdentifierValid
            && framework.isAvailable
            && !targetPlatforms.isEmpty
            && targetPlatforms.isSubset(of: framework.supportedPlatforms)
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
            flutterStateManagement: framework == .flutter ? flutterStateManagement : nil
        )
    }

    func setTarget(_ platform: TargetPlatform, enabled: Bool) {
        guard framework.supportedPlatforms.contains(platform) else {
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
        guard !normalizedProjectName.isEmpty else {
            summaryMessage = "Bitte geben Sie einen Projektnamen ein."
            return
        }

        guard isOrganizationIdentifierValid else {
            summaryMessage = "Bitte verwenden Sie eine portable Organisationskennung wie de.meinefirma."
            return
        }

        guard framework.isAvailable else {
            summaryMessage = "Dieser Renderer ist noch nicht produktionsbereit. Bitte verwenden Sie Flutter."
            return
        }

        guard !targetPlatforms.isEmpty,
              targetPlatforms.isSubset(of: framework.supportedPlatforms)
        else {
            summaryMessage = "Bitte wählen Sie mindestens eine vom Framework unterstützte Zielplattform."
            return
        }

        summaryMessage = "Projektentwurf bereit. Generator und Preview folgen in den nächsten Meilensteinen."
    }

    private var normalizedProjectName: String {
        projectName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedOrganizationIdentifier: String {
        organizationIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isOrganizationIdentifierValid: Bool {
        let components = normalizedOrganizationIdentifier.split(separator: ".", omittingEmptySubsequences: false)
        guard components.count >= 2 else {
            return false
        }

        return components.allSatisfy { component in
            guard let first = component.first, first.isLowercase else {
                return false
            }

            return component.allSatisfy { character in
                character.isLowercase || character.isNumber
            }
        }
    }
}
