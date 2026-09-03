import AppForgeApplication
import AppForgeDomain
import XCTest

final class PackageResolverTests: XCTestCase {
    func testResolvesTransitiveDependenciesWithBacktrackingAndStableOrder() throws {
        let core = try package(
            "foundation.core",
            "2.0.0",
            provides: ["identity.current_user"]
        )
        let inventoryV1 = try package(
            "feature.inventory",
            "1.5.0",
            dependencies: [requirement("foundation.core", from: "2.0.0", to: "3.0.0")],
            requires: ["identity.current_user"]
        )
        let inventoryV2 = try package(
            "feature.inventory",
            "2.5.0",
            dependencies: [requirement("foundation.core", from: "2.0.0", to: "3.0.0")],
            requires: ["identity.current_user"]
        )
        let policy = try package(
            "policy.legacy",
            "1.0.0",
            dependencies: [requirement("feature.inventory", from: "1.0.0", to: "2.0.0")]
        )
        let registry = try InMemoryPackageRegistry(contracts: [inventoryV2, policy, core, inventoryV1])

        let graph = try PackageResolver().resolve(
            requests: [requirement("feature.inventory"), requirement("policy.legacy")],
            specification: projectSpecification(),
            registry: registry
        )

        XCTAssertEqual(
            graph.packages.map(\.contract.id.rawValue),
            ["foundation.core", "feature.inventory", "policy.legacy"]
        )
        XCTAssertEqual(
            graph.packages.first { $0.contract.id.rawValue == "feature.inventory" }?.contract.version,
            try version("1.5.0")
        )
    }

    func testReportsMissingCapabilities() throws {
        let contract = try package(
            "feature.orders",
            "1.0.0",
            requires: ["identity.current_user"]
        )
        let registry = try InMemoryPackageRegistry(contracts: [contract])

        XCTAssertThrowsError(
            try PackageResolver().resolve(
                requests: [requirement("feature.orders")],
                specification: projectSpecification(),
                registry: registry
            )
        ) { error in
            XCTAssertEqual(
                error as? PackageResolutionError,
                .missingCapabilities([ForgeCapabilityID("identity.current_user")])
            )
        }
    }

    func testReportsDependencyCyclesWithClosedPath() throws {
        let first = try package(
            "feature.first",
            "1.0.0",
            dependencies: [requirement("feature.second")]
        )
        let second = try package(
            "feature.second",
            "1.0.0",
            dependencies: [requirement("feature.first")]
        )
        let registry = try InMemoryPackageRegistry(contracts: [first, second])

        XCTAssertThrowsError(
            try PackageResolver().resolve(
                requests: [requirement("feature.first")],
                specification: projectSpecification(),
                registry: registry
            )
        ) { error in
            guard case let PackageResolutionError.dependencyCycle(cycle) = error else {
                return XCTFail("Expected dependencyCycle, got \(error)")
            }
            XCTAssertEqual(cycle.first, cycle.last)
        }
    }

    func testReportsConflictsDeterministically() throws {
        let first = try package(
            "feature.first",
            "1.0.0",
            conflicts: ["feature.second"]
        )
        let second = try package("feature.second", "1.0.0")
        let registry = try InMemoryPackageRegistry(contracts: [second, first])

        XCTAssertThrowsError(
            try PackageResolver().resolve(
                requests: [requirement("feature.second"), requirement("feature.first")],
                specification: projectSpecification(),
                registry: registry
            )
        ) { error in
            XCTAssertEqual(
                error as? PackageResolutionError,
                .packageConflict(ForgePackageID("feature.first"), ForgePackageID("feature.second"))
            )
        }
    }

    func testRejectsPackagesIncompatibleWithBackend() throws {
        let contract = try package(
            "integration.firebase",
            "1.0.0",
            backends: [.firebase]
        )
        let registry = try InMemoryPackageRegistry(contracts: [contract])

        XCTAssertThrowsError(
            try PackageResolver().resolve(
                requests: [requirement("integration.firebase")],
                specification: projectSpecification(),
                registry: registry
            )
        ) { error in
            XCTAssertEqual(
                error as? PackageResolutionError,
                .incompatibleBackend(packageID: "integration.firebase", backend: .supabase)
            )
        }
    }
}

private func projectSpecification() -> ProjectSpecification {
    ProjectSpecification(
        identity: ProjectIdentity(name: "Inventory Operations", organizationIdentifier: "de.example"),
        framework: .flutter,
        targetPlatforms: [.iOS, .android],
        backend: .supabase,
        flutterStateManagement: .riverpod
    )
}

private func version(_ value: String) throws -> ForgeSemanticVersion {
    try XCTUnwrap(ForgeSemanticVersion(value))
}

private func requirement(_ packageID: String) -> ForgePackageRequirement {
    ForgePackageRequirement(packageID: ForgePackageID(packageID))
}

private func requirement(
    _ packageID: String,
    from minimum: String,
    to maximum: String
) throws -> ForgePackageRequirement {
    try ForgePackageRequirement(
        packageID: ForgePackageID(packageID),
        versionConstraint: .range(from: version(minimum), to: version(maximum))
    )
}

private func package(
    _ packageID: String,
    _ versionValue: String,
    dependencies: [ForgePackageRequirement] = [],
    requires: [ForgeCapabilityID] = [],
    provides: [ForgeCapabilityID] = [],
    conflicts: [ForgePackageID] = [],
    frameworks: [OutputFramework] = [.flutter],
    backends: [BackendProvider] = [.supabase]
) throws -> ForgePackageContract {
    try ForgePackageContract(
        id: ForgePackageID(packageID),
        version: version(versionValue),
        kind: .feature,
        dependencies: dependencies,
        requiredCapabilities: requires,
        providedCapabilities: provides,
        conflicts: conflicts,
        supportedFrameworks: frameworks,
        supportedBackends: backends,
        maturity: .stable,
        source: .bundled
    )
}
