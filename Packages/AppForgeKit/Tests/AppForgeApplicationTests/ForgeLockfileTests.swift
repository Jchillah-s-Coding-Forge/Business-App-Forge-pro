import AppForgeApplication
import AppForgeDomain
import XCTest

final class ForgeLockfileTests: XCTestCase {
    func testSameInputsProduceByteIdenticalLockfile() throws {
        let version = try XCTUnwrap(ForgeSemanticVersion("2.0.0"))
        let contract = ForgePackageContract(
            id: "foundation.core",
            version: version,
            kind: .foundation,
            providedCapabilities: ["identity.current_user"],
            supportedFrameworks: [.flutter],
            supportedBackends: [.supabase],
            maturity: .golden,
            source: .github(
                repository: "Jchillah-s-Coding-Forge/forge-core",
                reference: "v2.0.0",
                sha256: String(repeating: "b", count: 64)
            )
        )
        let registry = try InMemoryPackageRegistry(contracts: [contract])
        let specification = ProjectSpecification(
            identity: ProjectIdentity(name: "Operations", organizationIdentifier: "de.example"),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )
        let output = try ResolveProductPackagesUseCase()(
            specification: specification,
            requests: [ForgePackageRequirement(packageID: "foundation.core")],
            registry: registry
        )
        let codec = ForgeLockfileCodec()

        let first = try codec.encode(output.lockfile)
        let second = try codec.encode(output.lockfile)

        XCTAssertEqual(first, second)
        let decoded = try codec.decode(first)
        XCTAssertEqual(decoded, output.lockfile)
        XCTAssertEqual(decoded.packages.first?.source.reference, "v2.0.0")
        XCTAssertEqual(decoded.packages.first?.source.sha256, String(repeating: "b", count: 64))
    }

    func testUseCaseRejectsInvalidProjectBeforeResolution() throws {
        let registry = try InMemoryPackageRegistry(contracts: [])
        let specification = ProjectSpecification(
            identity: ProjectIdentity(name: "", organizationIdentifier: "invalid"),
            framework: .flutter,
            targetPlatforms: [],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )

        XCTAssertThrowsError(
            try ResolveProductPackagesUseCase()(
                specification: specification,
                requests: [],
                registry: registry
            )
        ) { error in
            guard case let PackageResolutionError.invalidProjectSpecification(issues) = error else {
                return XCTFail("Expected invalidProjectSpecification, got \(error)")
            }
            XCTAssertFalse(issues.isEmpty)
        }
    }
}
