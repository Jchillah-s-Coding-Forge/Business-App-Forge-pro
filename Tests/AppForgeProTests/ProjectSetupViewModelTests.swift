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

    func testProjectNeedsNameOrganizationAndTargetBeforePreview() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())

        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.projectName = "Werkstatt Operations"
        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.organizationIdentifier = "de.werkstatt"
        XCTAssertTrue(viewModel.canPrepareProject)
    }

    func testUnsupportedRendererCannotPrepareProject() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "de.werkstatt"
        viewModel.framework = .swiftUI
        viewModel.targetPlatforms = [.android]

        XCTAssertFalse(viewModel.canPrepareProject)
    }

    func testSpecificationUsesUserProvidedOrganizationIdentifier() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "de.werkstatt"

        XCTAssertEqual(viewModel.specification.identity.organizationIdentifier, "de.werkstatt")
    }
}
