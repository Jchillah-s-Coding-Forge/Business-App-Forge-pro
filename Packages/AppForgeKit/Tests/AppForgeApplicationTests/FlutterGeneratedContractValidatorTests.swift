import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterGeneratedContractValidatorTests: XCTestCase {
    func testNormalizedFeaturePathCollisionFailsWithBothDefinitions() throws {
        let camel = entity(
            id: "entity.camel",
            code: "salesOrder"
        )
        let snake = entity(
            id: "entity.snake",
            code: "sales_order"
        )

        XCTAssertThrowsError(
            try render(specification(entities: [snake, camel]))
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .generatedOutputPathCollision(
                    firstDefinitionID: camel.id,
                    secondDefinitionID: snake.id,
                    path: "lib/features/sales_order"
                )
            )
        }
    }

    func testReservedGeneratedMemberFailsBeforeRendering() throws {
        let item = entity(
            id: "entity.item",
            code: "item",
            fields: [
                field(
                    id: "field.item.copyWith",
                    code: "copy_with"
                )
            ]
        )

        XCTAssertThrowsError(
            try render(specification(entities: [item]))
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .reservedGeneratedMember(
                    definitionID: "field.item.copyWith",
                    identifier: "copyWith"
                )
            )
        }
    }

    func testNormalizedFieldRelationCollisionReportsBothDefinitions() throws {
        let user = entity(
            id: "entity.user",
            code: "user"
        )
        let asset = entity(
            id: "entity.asset",
            code: "asset",
            fields: [
                field(
                    id: "field.asset.owner",
                    code: "owner_name"
                )
            ]
        )
        let relation = RelationDefinition(
            identity: DefinitionIdentity(
                id: "relation.asset.owner",
                code: "ownerName",
                label: "Owner"
            ),
            sourceEntityID: asset.id,
            targetEntityID: user.id,
            cardinality: .manyToOne
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [asset, user],
                    relations: [relation]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .generatedMemberCollision(
                    entityID: asset.id,
                    firstDefinitionID: "field.asset.owner",
                    secondDefinitionID: relation.id,
                    identifier: "ownerName"
                )
            )
        }
    }

    func testEntityCanNotReuseReservedCoreTypeName() throws {
        let entity = entity(
            id: "entity.domainReference",
            code: "domain_reference"
        )

        XCTAssertThrowsError(
            try render(specification(entities: [entity]))
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .reservedGeneratedTypeName(
                    definitionID: entity.id,
                    typeName: "DomainReference"
                )
            )
        }
    }

    func testGeneratedRepositoryTypeCanNotCollideWithAnotherEntityType() throws {
        let customer = entity(
            id: "entity.customer",
            code: "customer"
        )
        let repository = entity(
            id: "entity.customerRepository",
            code: "customer_repository"
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [repository, customer]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .generatedTypeNameCollision(
                    firstDefinitionID: customer.id,
                    secondDefinitionID: repository.id,
                    typeName: "CustomerRepository"
                )
            )
        }
    }

    func testValidSpecificationRemainsDeterministic() throws {
        let first = try render(
            specification(
                entities: [
                    entity(id: "entity.asset", code: "asset"),
                    entity(id: "entity.user", code: "user")
                ]
            )
        )
        let second = try render(
            specification(
                entities: [
                    entity(id: "entity.user", code: "user"),
                    entity(id: "entity.asset", code: "asset")
                ]
            )
        )

        XCTAssertEqual(first, second)
    }
}

private extension FlutterGeneratedContractValidatorTests {
    func entity(
        id: String,
        code: String,
        fields: [FieldDefinition] = []
    ) -> EntityDefinition {
        EntityDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            fields: fields
        )
    }

    func field(
        id: String,
        code: String
    ) -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            dataType: .string
        )
    }

    func specification(
        entities: [EntityDefinition],
        relations: [RelationDefinition] = []
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Collision Contract",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: entities,
            relations: relations,
            offline: .businessDefault
        )
    }

    func render(
        _ specification: ProjectSpecification
    ) throws -> GenerationPlan {
        let graph = try FlutterOfflineTestFixture.makeGraph(
            for: specification.backend
        )
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
}
