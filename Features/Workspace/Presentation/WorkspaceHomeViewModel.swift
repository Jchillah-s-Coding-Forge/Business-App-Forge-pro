import Observation

@MainActor
@Observable
final class WorkspaceHomeViewModel {
    private let environment: AppEnvironment

    var isPresentingProjectSetup = false
    private(set) var projectSetupViewModel: ProjectSetupViewModel?

    init(environment: AppEnvironment) {
        self.environment = environment
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
