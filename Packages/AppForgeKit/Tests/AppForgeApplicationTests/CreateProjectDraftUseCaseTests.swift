import AppForgeApplication
import AppForgeDomain
import XCTest

final class CreateProjectDraftUseCaseTests: XCTestCase {
    func testCreatesBusinessReadyDefaultsWithoutMakingMVVMSelectable() {
        let specification = CreateProjectDraftUseCase()(projectName: "Operations")

        XCTAssertEqual(specification.identity.name, "Operations")
        XCTAssertEqual(specification.framework, .flutter)
        XCTAssertEqual(specification.targetPlatforms, [.iOS, .android])
        XCTAssertEqual(specification.backend, .supabase)
        XCTAssertEqual(specification.flutterStateManagement, .riverpod)
        XCTAssertEqual(specification.architecture, .standard)
    }
}
