import AppForgeDomain
import XCTest

final class ProjectSpecificationTests: XCTestCase {
    func testArchitectureContractIsFixedAndNotAUserChoice() {
        let contract = ArchitectureContract.standard

        XCTAssertEqual(contract.presentationPattern, "MVVM")
        XCTAssertEqual(contract.projectStructure, "Feature-First")
        XCTAssertEqual(contract.dataAccess, "Repository Pattern")
        XCTAssertEqual(contract.localDataPolicy, "Single Source of Truth")
    }

    func testSpecificationCanBeEncodedAndDecoded() throws {
        let original = ProjectSpecification(
            identity: ProjectIdentity(name: "Field Service", organizationIdentifier: "de.example"),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProjectSpecification.self, from: data)

        XCTAssertEqual(decoded, original)
    }
}
