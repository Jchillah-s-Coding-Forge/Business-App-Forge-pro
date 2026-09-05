import AppForgeApplication
import AppForgeDomain
import XCTest

enum FlutterOfflineTestFixture {
    static func render(
        _ specification: ProjectSpecification
    ) throws -> GenerationPlan {
        let graph = try makeGraph(for: specification.backend)
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )
        return try DeterministicFlutterProjectRenderer().makePlan(
            specification: specification,
            graph: graph,
            lockfile: lockfile
        )
    }

    static func contents(
        _ path: String,
        in plan: GenerationPlan
    ) throws -> String {
        try XCTUnwrap(plan.file(at: path)?.contents)
    }

    static func makeSpecification(
        backend: BackendProvider,
        offline: OfflineConfiguration,
        additionalFields: [FieldDefinition] = []
    ) -> ProjectSpecification {
        let customer = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.customer",
                code: "customer",
                label: "Customer"
            ),
            fields: baseFields + additionalFields
        )

        return ProjectSpecification(
            identity: ProjectIdentity(
                name: "Offline Business",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: backend,
            flutterStateManagement: .riverpod,
            entities: [customer],
            offline: offline
        )
    }

    private static var baseFields: [FieldDefinition] {
        [
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
                    id: "field.customer.price",
                    code: "price",
                    label: "Price"
                ),
                dataType: .currency
            ),
            FieldDefinition(
                identity: DefinitionIdentity(
                    id: "field.customer.active",
                    code: "active",
                    label: "Active"
                ),
                dataType: .boolean,
                isRequired: true
            ),
            FieldDefinition(
                identity: DefinitionIdentity(
                    id: "field.customer.scheduledAt",
                    code: "scheduledAt",
                    label: "Scheduled At"
                ),
                dataType: .dateTime
            )
        ]
    }

    static func makeGraph(
        for backend: BackendProvider
    ) throws -> ResolvedProductGraph {
        let version = try XCTUnwrap(ForgeSemanticVersion("1.0.0"))
        let contract = ForgePackageContract(
            id: "foundation.core",
            version: version,
            kind: .foundation,
            supportedFrameworks: [.flutter],
            supportedBackends: [backend],
            maturity: .stable,
            source: .bundled
        )
        return ResolvedProductGraph(
            packages: [ResolvedPackage(contract: contract)],
            capabilities: []
        )
    }
}
