import Observation

@MainActor
@Observable
final class WorkspaceHomeViewModel {
    var isPresentingProjectSetup = false

    func startProjectSetup() {
        isPresentingProjectSetup = true
    }

    func dismissProjectSetup() {
        isPresentingProjectSetup = false
    }
}
