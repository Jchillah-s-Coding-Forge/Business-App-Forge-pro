import AppForgeApplication
import AppForgeDomain
import Foundation
import Observation

@MainActor
@Observable
final class ProjectSetupViewModel {
    private let createProjectDraft: CreateProjectDraftUseCase

    var projectName: String
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
        framework = draft.framework
        targetPlatforms = draft.targetPlatforms
        backend = draft.backend
        flutterStateManagement = draft.flutterStateManagement ?? .riverpod
    }

    var canPrepareProject: Bool {
        !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !targetPlatforms.isEmpty
    }

    var specification: ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: projectName.trimmingCharacters(in: .whitespacesAndNewlines),
                organizationIdentifier: "com.example"
            ),
            framework: framework,
            targetPlatforms: targetPlatforms,
            backend: backend,
            flutterStateManagement: framework == .flutter ? flutterStateManagement : nil
        )
    }

    func setTarget(_ platform: TargetPlatform, enabled: Bool) {
        if enabled {
            targetPlatforms.insert(platform)
        } else {
            targetPlatforms.remove(platform)
        }
    }

    func prepareProject() {
        guard canPrepareProject else {
            summaryMessage = "Bitte geben Sie einen Projektnamen ein und wählen Sie mindestens eine Zielplattform."
            return
        }

        summaryMessage = "Projektentwurf bereit. Generator und Preview folgen in den nächsten Meilensteinen."
    }
}
