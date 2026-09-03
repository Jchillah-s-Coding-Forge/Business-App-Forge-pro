import AppForgeDomain
import XCTest

final class ForgePackageContractValidatorTests: XCTestCase {
    private let validator = ForgePackageContractValidator()

    func testAcceptsPinnedGitHubSource() throws {
        let contract = ForgePackageContract(
            id: "feature.inventory",
            version: try version("2.0.0"),
            kind: .feature,
            providedCapabilities: ["inventory.list"],
            supportedFrameworks: [.flutter],
            supportedBackends: [.supabase],
            maturity: .stable,
            source: .github(
                repository: "Jchillah-s-Coding-Forge/forge-inventory",
                reference: "v2.0.0",
                sha256: String(repeating: "a", count: 64)
            )
        )

        XCTAssertTrue(validator.validate(contract).isEmpty)
    }

    func testRejectsUnpinnedRemoteSourceAndInvalidIdentifiers() throws {
        let contract = ForgePackageContract(
            id: "Inventory",
            version: try version("1.0.0"),
            kind: .feature,
            requiredCapabilities: ["invalid"],
            source: ForgePackageSource(
                kind: .github,
                repository: "owner/repo",
                reference: "main",
                sha256: nil
            )
        )

        let issues = validator.validate(contract)
        XCTAssertTrue(issues.contains(.invalidPackageID("Inventory")))
        XCTAssertTrue(issues.contains(.invalidCapabilityID("invalid")))
        XCTAssertTrue(issues.contains(.invalidSHA256("")))
    }

    func testRejectsSelfDependenciesAndUnsatisfiableRanges() throws {
        let packageID = ForgePackageID("feature.inventory")
        let constraint = ForgeVersionConstraint(
            minimumInclusive: try version("2.0.0"),
            maximumExclusive: try version("2.0.0")
        )
        let contract = ForgePackageContract(
            id: packageID,
            version: try version("1.0.0"),
            kind: .feature,
            dependencies: [ForgePackageRequirement(packageID: packageID, versionConstraint: constraint)]
        )

        let issues = validator.validate(contract)
        XCTAssertTrue(issues.contains(.selfDependency(packageID.rawValue)))
        XCTAssertTrue(issues.contains(.invalidVersionConstraint(packageID: packageID.rawValue)))
    }

    private func version(_ value: String) throws -> ForgeSemanticVersion {
        try XCTUnwrap(ForgeSemanticVersion(value))
    }
}
