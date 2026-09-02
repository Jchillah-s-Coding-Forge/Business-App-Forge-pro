import AppForgeApplication

@MainActor
struct AppEnvironment {
    let makeProjectSetupViewModel: () -> ProjectSetupViewModel

    static let live = AppEnvironment {
        ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
    }

    static let test = AppEnvironment {
        ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
    }
}
