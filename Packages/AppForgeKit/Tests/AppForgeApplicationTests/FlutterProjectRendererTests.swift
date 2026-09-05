import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterProjectRendererTests: XCTestCase {
    func testSameInputsProduceIdenticalPlanWithCoreArchitectureFiles() throws {
        let specification = makeSpecification()
        let graph = try makeGraph()
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )
        let renderer = DeterministicFlutterProjectRenderer()

        let first = try renderer.makePlan(
            specification: specification,
            graph: graph,
            lockfile: lockfile
        )
        let second = try renderer.makePlan(
            specification: specification,
            graph: graph,
            lockfile: lockfile
        )

        XCTAssertEqual(first, second)
        XCTAssertNotNil(first.file(at: "lib/main.dart"))
        XCTAssertNotNil(first.file(at: "lib/app.dart"))
        XCTAssertNotNil(first.file(at: "pubspec.yaml"))
        XCTAssertNotNil(first.file(at: "forge.lock"))
        XCTAssertNotNil(first.file(at: "appforge.generated.json"))
        XCTAssertEqual(
            first.file(at: "lib/main.dart")?.contents.contains("ProviderScope"),
            true
        )
        XCTAssertEqual(
            first.file(at: "pubspec.yaml")?.contents.contains("flutter_riverpod: ^3.3.2"),
            true
        )
    }

    func testEntityRenderingUsesFeatureFirstLayersAndSafeDartIdentifiers() throws {
        let specification = makeSpecification()
        let graph = try makeGraph()
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )

        let plan = try DeterministicFlutterProjectRenderer().makePlan(
            specification: specification,
            graph: graph,
            lockfile: lockfile
        )

        let entityPath = "lib/features/customer/domain/entities/customer.dart"
        let repositoryPath = "lib/features/customer/domain/repositories/customer_repository.dart"
        let useCasePath = "lib/features/customer/domain/use_cases/get_customer_list.dart"
        let viewModelPath = "lib/features/customer/presentation/view_models/customer_view_model.dart"

        XCTAssertNotNil(plan.file(at: entityPath))
        XCTAssertNotNil(plan.file(at: repositoryPath))
        XCTAssertNotNil(plan.file(at: useCasePath))
        XCTAssertNotNil(plan.file(at: viewModelPath))

        let entitySource = try XCTUnwrap(plan.file(at: entityPath)?.contents)
        XCTAssertTrue(entitySource.contains("final String name;"))
        XCTAssertTrue(entitySource.contains("final int? age;"))
        XCTAssertTrue(entitySource.contains("final bool classValue;"))
    }

    func testRendererRejectsLockfileThatDoesNotMatchGraphAndSpecification() throws {
        let specification = makeSpecification()
        let graph = try makeGraph()
        let valid = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )
        let mismatched = ForgeLockfile(
            projectSchemaVersion: valid.projectSchemaVersion,
            framework: valid.framework,
            backend: .firebase,
            packages: valid.packages,
            capabilities: valid.capabilities
        )

        XCTAssertThrowsError(
            try DeterministicFlutterProjectRenderer().makePlan(
                specification: specification,
                graph: graph,
                lockfile: mismatched
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .lockfileMismatch
            )
        }
    }

    func testRendererRejectsIdentifierThatCannotBeEmittedAsDart() throws {
        let entity = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.placeholder",
                code: "_",
                label: "Placeholder"
            )
        )
        let specification = ProjectSpecification(
            identity: ProjectIdentity(
                name: "Identifier Test",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: [entity]
        )
        let graph = try makeGraph()
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )

        XCTAssertThrowsError(
            try DeterministicFlutterProjectRenderer().makePlan(
                specification: specification,
                graph: graph,
                lockfile: lockfile
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .invalidGeneratedIdentifier(
                    definitionID: entity.id,
                    code: entity.identity.code
                )
            )
        }
    }

    func testBlocConfigurationProducesBlocDependencyAndCubitBootstrap() throws {
        let specification = makeSpecification(stateManagement: .blocCubit)
        let graph = try makeGraph()
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )

        let plan = try DeterministicFlutterProjectRenderer().makePlan(
            specification: specification,
            graph: graph,
            lockfile: lockfile
        )

        XCTAssertEqual(
            plan.file(at: "pubspec.yaml")?.contents.contains("flutter_bloc: ^9.1.1"),
            true
        )
        XCTAssertNotNil(plan.file(at: "lib/core/state/app_cubit.dart"))
        XCTAssertEqual(
            plan.file(at: "lib/main.dart")?.contents.contains("BlocProvider"),
            true
        )
    }

    private func makeSpecification(
        stateManagement: FlutterStateManagement = .riverpod
    ) -> ProjectSpecification {
        let customer = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.customer",
                code: "customer",
                label: "Customer"
            ),
            fields: [
                FieldDefinition(
                    identity: DefinitionIdentity(
                        id: "field.customer.name",
                        code: "name",
                        label: "Name"
                    ),
                    dataType: .string,
                    isRequired: true
                ),
                FieldDefinition(
                    identity: DefinitionIdentity(
                        id: "field.customer.age",
                        code: "age",
                        label: "Age"
                    ),
                    dataType: .integer
                ),
                FieldDefinition(
                    identity: DefinitionIdentity(
                        id: "field.customer.class",
                        code: "class",
                        label: "Class"
                    ),
                    dataType: .boolean,
                    isRequired: true
                )
            ]
        )

        return ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory Operations",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: stateManagement,
            entities: [customer]
        )
    }

    private func makeGraph() throws -> ResolvedProductGraph {
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
        return ResolvedProductGraph(
            packages: [ResolvedPackage(contract: contract)],
            capabilities: []
        )
    }
}
