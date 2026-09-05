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
