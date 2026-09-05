import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class GenerateFlutterProjectUseCaseTests: XCTestCase {
    func testUseCaseResolvesRendersAndWritesStandaloneFlutterSource() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent("inventory_app", isDirectory: true)
        let registry = try makeRegistry()
        let specification = makeSpecification()

        let result = try GenerateFlutterProjectUseCase()(
            specification: specification,
            requests: [ForgePackageRequirement(packageID: "foundation.core")],
            registry: registry,
            targetURL: targetURL
        )

        XCTAssertEqual(result.projectPath, targetURL.standardizedFileURL.path)
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: targetURL.appendingPathComponent("pubspec.yaml").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: targetURL.appendingPathComponent("lib/main.dart").path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: targetURL.appendingPathComponent(
                    "lib/features/asset/domain/entities/asset.dart"
                ).path
            )
        )

        let lockData = try Data(
            contentsOf: targetURL.appendingPathComponent("forge.lock")
        )
        XCTAssertEqual(
            try ForgeLockfileCodec().decode(lockData),
            result.lockfile
        )
    }

    func testInvalidSpecificationDoesNotCreateTargetDirectory() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent("invalid_app", isDirectory: true)
        let invalidSpecification = ProjectSpecification(
            identity: ProjectIdentity(
                name: "",
                organizationIdentifier: "invalid"
            ),
            framework: .flutter,
            targetPlatforms: [],
            backend: .supabase,
            flutterStateManagement: .riverpod
        )
        let registry = try InMemoryPackageRegistry(contracts: [])

        XCTAssertThrowsError(
            try GenerateFlutterProjectUseCase()(
                specification: invalidSpecification,
                requests: [],
                registry: registry,
                targetURL: targetURL
            )
        )

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: targetURL.path)
        )
    }

    private func makeSpecification() -> ProjectSpecification {
        let asset = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: [
                FieldDefinition(
                    identity: DefinitionIdentity(
                        id: "field.asset.name",
                        code: "name",
                        label: "Name"
                    ),
                    dataType: .string,
                    isRequired: true
                )
            ]
        )

        return ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: [asset]
        )
    }

    private func makeRegistry() throws -> InMemoryPackageRegistry {
        let version = try XCTUnwrap(ForgeSemanticVersion("1.0.0"))
        let contract = ForgePackageContract(
            id: "foundation.core",
            version: version,
            kind: .foundation,
            supportedFrameworks: [.flutter],
            supportedBackends: [.supabase],
            maturity: .stable,
            source: .bundled
        )
        return try InMemoryPackageRegistry(contracts: [contract])
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "appforge-generation-tests-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )
        return url
    }
}
