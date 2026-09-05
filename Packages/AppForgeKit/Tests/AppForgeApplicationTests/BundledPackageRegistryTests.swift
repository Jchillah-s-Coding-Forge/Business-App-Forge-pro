import AppForgeApplication
import AppForgeDomain
import XCTest

final class BundledPackageRegistryTests: XCTestCase {
    func testFoundationCoreContractIsStableBundledFlutterPackage() throws {
        let registry = try BundledPackageRegistry()
        let contracts = registry.contracts(
            for: BundledPackageRegistry.foundationCoreID
        )

        let contract = try XCTUnwrap(contracts.first)
        XCTAssertEqual(contracts.count, 1)
        XCTAssertEqual(contract.id, "foundation.core")
        XCTAssertEqual(contract.version.description, "1.0.0")
        XCTAssertEqual(contract.kind, .foundation)
        XCTAssertEqual(contract.maturity, .stable)
        XCTAssertEqual(contract.source, .bundled)
        XCTAssertEqual(contract.supportedFrameworks, [.flutter])
        XCTAssertTrue(contract.supportedBackends.isEmpty)
        XCTAssertTrue(contract.dependencies.isEmpty)
        XCTAssertTrue(contract.conflicts.isEmpty)
    }

    func testDefaultRootsResolveForEverySupportedBackend() throws {
        let registry = try BundledPackageRegistry()

        for backend in BackendProvider.allCases {
            let output = try ResolveProductPackagesUseCase()(
                specification: makeSpecification(
                    backend: backend
                ),
                requests: BundledPackageRegistry
                    .defaultRootRequirements,
                registry: registry
            )

            XCTAssertEqual(
                output.graph.packages.map(\.contract.id),
                [BundledPackageRegistry.foundationCoreID]
            )
            XCTAssertEqual(
                output.lockfile.packages.map(\.packageID),
                [BundledPackageRegistry.foundationCoreID]
            )
        }
    }

    func testUnknownPackageIsNotSilentlyProvided() throws {
        let registry = try BundledPackageRegistry()

        XCTAssertTrue(
            registry.contracts(
                for: ForgePackageID("feature.unknown")
            ).isEmpty
        )
    }

    private func makeSpecification(
        backend: BackendProvider
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: backend,
            flutterStateManagement: .riverpod
        )
    }
}
