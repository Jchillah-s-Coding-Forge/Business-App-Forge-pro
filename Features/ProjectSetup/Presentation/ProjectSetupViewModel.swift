import AppForgeApplication
import AppForgeDomain
import Foundation
import Observation

@MainActor
@Observable
final class ProjectSetupViewModel {
    private let createProjectDraft: CreateProjectDraftUseCase
    private static let organizationIdentifierPattern = #"^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$"#

    var projectName: String
    var organizationIdentifier: String
    var framework: OutputFramework {
        didSet {
            targetPlatforms.formIntersection(compatibleTargetPlatforms)
            summaryMessage = nil
        }
    }

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

    var canPrepareProject: Bool {
        preparationGuidance == nil
    }

    var compatibleTargetPlatforms: Set<TargetPlatform> {
        switch framework {
        case .flutter:
            [.iOS, .android]
        case .swiftUI:
            [.iOS]
        case .compose:
            [.android]
        }
    }

    var isRendererAvailable: Bool {
        framework == .flutter
    }

    var isOrganizationIdentifierValid: Bool {
        organizationIdentifier.range(
            of: Self.organizationIdentifierPattern,
            options: .regularExpression
        ) != nil
    }

    var preparationGuidance: String? {
        if projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Geben Sie einen App-Namen ein."
        }

        if !isOrganizationIdentifierValid {
            return "Geben Sie eine gültige Organisations-ID ein, zum Beispiel de.meinefirma."
        }

        if !isRendererAvailable {
            return "Der ausgewählte Renderer ist geplant, aber noch nicht für Generierungen freigegeben."
        }

        if targetPlatforms.isEmpty {
            return "Wählen Sie mindestens eine kompatible Zielplattform."
        }

        if !targetPlatforms.isSubset(of: compatibleTargetPlatforms) {
            return "Die gewählten Zielplattformen sind mit dem Framework nicht kompatibel."
        }

        return nil
    }

    var specification: ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: projectName.trimmingCharacters(in: .whitespacesAndNewlines),
                organizationIdentifier: organizationIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            framework: framework,
            targetPlatforms: targetPlatforms,
            backend: backend,
            flutterStateManagement: framework == .flutter ? flutterStateManagement : nil
        )
    }

    func setTarget(_ platform: TargetPlatform, enabled: Bool) {
        guard compatibleTargetPlatforms.contains(platform) else {
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
        if let preparationGuidance {
            summaryMessage = preparationGuidance
            return
        }

        summaryMessage = "Projektentwurf bereit. Generator und Preview folgen in den nächsten Meilensteinen."
    }
}
