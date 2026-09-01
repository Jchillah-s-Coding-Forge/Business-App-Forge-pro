@testable import AppForgePro
import XCTest

@MainActor
final class WorkspaceHomeViewModelTests: XCTestCase {
    func testStartProjectSetupPresentsWizardEntry() {
        let viewModel = WorkspaceHomeViewModel()

        viewModel.startProjectSetup()

        XCTAssertTrue(viewModel.isPresentingProjectSetup)
    }

    func testDismissProjectSetupClosesWizardEntry() {
        let viewModel = WorkspaceHomeViewModel()
        viewModel.startProjectSetup()

        viewModel.dismissProjectSetup()

        XCTAssertFalse(viewModel.isPresentingProjectSetup)
    }
}
