import AppForgeApplication
import AppForgeDomain
@testable import AppForgePro
import XCTest

@MainActor
final class ProjectSetupViewModelTests: XCTestCase {
    func testDefaultDraftUsesRiverpodWithoutOptionalMVVMChoice() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())

        XCTAssertEqual(viewModel.flutterStateManagement, .riverpod)
        XCTAssertEqual(viewModel.architecture.presentationPattern, "MVVM")
        XCTAssertEqual(viewModel.architecture, .standard)
    }

    func testProjectNeedsNameAndTargetBeforePreview() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())

        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.projectName = "Werkstatt Operations"

        XCTAssertTrue(viewModel.canPrepareProject)
    }
}
