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

    func testSpecificationUsesNormalizedUserProvidedOrganizationIdentifier() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
        viewModel.projectName = "Werkstatt Operations"
        viewModel.organizationIdentifier = "DE.Werkstatt"

        XCTAssertEqual(viewModel.specification.identity.organizationIdentifier, "de.werkstatt")
    }

    func testOrganizationIdentifierMustBePortableAcrossAppleAndAndroidTargets() {
        let viewModel = ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
        viewModel.projectName = "Werkstatt Operations"

        viewModel.organizationIdentifier = "de.meine-firma"
        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.organizationIdentifier = "123.meinefirma"
        XCTAssertFalse(viewModel.canPrepareProject)

        viewModel.organizationIdentifier = "de.meine_firma2"
        XCTAssertTrue(viewModel.canPrepareProject)
    }
}
