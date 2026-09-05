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

    func testValidatorRejectsInvalidProjectRootConfiguration() {
        let specification = ProjectSpecification(
            identity: ProjectIdentity(name: "   ", organizationIdentifier: "invalid"),
            framework: .flutter,
            targetPlatforms: [],
            backend: .supabase,
            flutterStateManagement: nil
        )

        let issues = ProjectSpecificationValidator().validate(specification)

        XCTAssertTrue(issues.contains(.emptyProjectName))
        XCTAssertTrue(issues.contains(.invalidOrganizationIdentifier("invalid")))
        XCTAssertTrue(issues.contains(.unsupportedTargetConfiguration))
        XCTAssertTrue(issues.contains(.flutterStateManagementRequired))
    }

    func testOnlyAvailableRendererWithSupportedPlatformsIsValid() {
        let flutter = ProjectSpecification(
            identity: ProjectIdentity(name: "Field Service", organizationIdentifier: "de.example"),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )
        let plannedSwiftUI = ProjectSpecification(
            identity: ProjectIdentity(name: "Field Service", organizationIdentifier: "de.example"),
            framework: .swiftUI,
            targetPlatforms: [.iOS],
            backend: .supabase,
            flutterStateManagement: nil
        )
        let invalidFlutter = ProjectSpecification(
            identity: ProjectIdentity(name: "Field Service", organizationIdentifier: "de.example"),
            framework: .flutter,
            targetPlatforms: [.macOS],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )

        XCTAssertTrue(flutter.hasSupportedTargetConfiguration)
        XCTAssertFalse(plannedSwiftUI.hasSupportedTargetConfiguration)
        XCTAssertFalse(invalidFlutter.hasSupportedTargetConfiguration)
    }
}
