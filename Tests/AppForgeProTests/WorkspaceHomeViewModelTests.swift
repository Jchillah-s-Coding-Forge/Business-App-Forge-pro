@testable import AppForgePro
import XCTest

@MainActor
final class WorkspaceHomeViewModelTests: XCTestCase {
    func testStartProjectSetupCreatesOneDraftAndPresentsWizard() {
        let viewModel = WorkspaceHomeViewModel(environment: .test)

        viewModel.startProjectSetup()

        XCTAssertTrue(viewModel.isPresentingProjectSetup)
        XCTAssertNotNil(viewModel.projectSetupViewModel)
    }

    func testDismissProjectSetupClearsTransientDraft() {
        let viewModel = WorkspaceHomeViewModel(environment: .test)
        viewModel.startProjectSetup()

        viewModel.dismissProjectSetup()

        XCTAssertFalse(viewModel.isPresentingProjectSetup)
        XCTAssertNil(viewModel.projectSetupViewModel)
    }
}
