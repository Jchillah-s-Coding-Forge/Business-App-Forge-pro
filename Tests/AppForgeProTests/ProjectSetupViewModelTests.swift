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
        XCTAssertEqual(viewModel.organizationIdentifier, "")
    }

    func testProjectNeedsNameOrganizationIdentifierAndTargetBeforePreview() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())

        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.projectName = "Werkstatt Operations"

        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.organizationIdentifier = "de.werkstatt"

        XCTAssertTrue(viewModel.canPrepareProject)
    }

    func testRejectsInvalidOrganizationIdentifier() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "com example"

        XCTAssertFalse(viewModel.canPrepareProject)
    }

    func testPlannedRendererCannotBePreparedAndRemovesIncompatibleTargets() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "de.werkstatt"

        viewModel.framework = .compose

        XCTAssertEqual(viewModel.targetPlatforms, [.android])
        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.setTarget(.iOS, enabled: true)

        XCTAssertEqual(viewModel.targetPlatforms, [.android])
    }

    func testSpecificationUsesExplicitOrganizationIdentifier() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "de.werkstatt"

        XCTAssertEqual(viewModel.specification.identity.organizationIdentifier, "de.werkstatt")
    }
}
