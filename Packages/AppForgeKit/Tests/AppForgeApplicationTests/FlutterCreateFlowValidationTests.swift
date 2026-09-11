import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterCreateFlowValidationTests: XCTestCase {
    func testExplicitCreateRouteWithRequiredHiddenFieldFailsClosed() throws {
        let fixture = baseFixture()
        var entity = fixture.entity
        entity.fields.append(
            field(
                id: "field.asset.secret",
                code: "secret",
                type: .string,
                required: true
            )
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [entity],
                    screens: [fixture.screen],
                    navigation: navigation(to: fixture.screen)
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .formCreateMissingRequiredField(
                    screenID: fixture.screen.id,
                    fieldID: "field.asset.secret"
                )
            )
        }
    }

    func testEditOnlyUnsafeFormRemainsGeneratedButIsNotAutoRouted() throws {
        let fixture = baseFixture()
        var entity = fixture.entity
        entity.fields.append(
            field(
                id: "field.asset.secret",
                code: "secret",
                type: .string,
                required: true
            )
        )
        let plan = try render(
            specification(
                entities: [entity],
                screens: [fixture.screen]
            )
        )

        XCTAssertNotNil(
            plan.file(
                at: "lib/features/asset/presentation/screens/asset_form_form_screen.dart"
            )
        )
        XCTAssertNotNil(
            plan.file(
                at: "lib/features/asset/presentation/mappers/asset_form_form_edit_mapper.dart"
            )
        )
        XCTAssertNil(
            plan.file(
                at: "lib/features/asset/presentation/mappers/asset_form_form_create_mapper.dart"
            )
        )
        XCTAssertNil(plan.file(at: "lib/core/bootstrap/app_dependencies.dart"))
        let app = try contents(plan, at: "lib/app.dart")
        XCTAssertTrue(app.contains("destinations: <GeneratedAppDestination>[]"))
    }

    func testExplicitCreateRouteWithRequiredRelationFailsClosed() throws {
        let fixture = baseFixture()
        let category = entity(id: "entity.category", code: "category")
        let relation = RelationDefinition(
            identity: DefinitionIdentity(
                id: "relation.asset.category",
                code: "category",
                label: "Category"
            ),
            sourceEntityID: fixture.entity.id,
            targetEntityID: category.id,
            cardinality: .manyToOne,
            isRequired: true
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [fixture.entity, category],
                    relations: [relation],
                    screens: [fixture.screen],
                    navigation: navigation(to: fixture.screen)
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .formCreateRequiresRelationInput(
                    screenID: fixture.screen.id,
                    relationID: relation.id
                )
            )
        }
    }

    func testExplicitCreateRouteWithoutOfflinePersistenceFailsClosed() throws {
        let fixture = baseFixture()
        let offline = OfflineConfiguration(
            isEnabled: false,
            usesLocalSingleSourceOfTruth: false,
            usesSyncOutbox: false,
            syncsOnReconnect: false,
            conflictResolution: .manualReview
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [fixture.entity],
                    screens: [fixture.screen],
                    navigation: navigation(to: fixture.screen),
                    offline: offline
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .formCreateRequiresOfflinePersistence(
                    screenID: fixture.screen.id
                )
            )
        }
    }

    func testExplicitRoleProtectedCreateRouteFailsClosed() throws {
        let fixture = baseFixture()
        var screen = fixture.screen
        screen.allowedRoleIDs = ["role.owner"]
        let role = RoleDefinition(
            identity: DefinitionIdentity(
                id: "role.owner",
                code: "owner",
                label: "Owner"
            )
        )

        XCTAssertThrowsError(
            try render(
                ProjectSpecification(
                    identity: projectIdentity,
                    framework: .flutter,
                    targetPlatforms: [.iOS],
                    backend: .localOnly,
                    flutterStateManagement: .riverpod,
                    entities: [fixture.entity],
                    roles: [role],
                    screens: [screen],
                    navigation: navigation(to: screen),
                    offline: .businessDefault
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .formCreateRequiresRoleEvaluation(screenID: screen.id)
            )
        }
    }

    func testExplicitRequiredExternalValueCreateRouteFailsClosed() throws {
        let attachment = field(
            id: "field.asset.attachment",
            code: "attachment",
            type: .file,
            required: true
        )
        let entity = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: [attachment]
        )
        let screen = formScreen(
            entityID: entity.id,
            fields: [attachment.id]
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [entity],
                    screens: [screen],
                    navigation: navigation(to: screen)
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .formCreateRequiresExternalValuePicker(
                    screenID: screen.id,
                    fieldID: attachment.id
                )
            )
        }
    }

    func testCreateCoreTypeCollisionFailsClosed() throws {
        let collision = entity(
            id: "entity.generated_home",
            code: "generated_app_home"
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [collision],
                    screens: []
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .reservedGeneratedTypeName(
                    definitionID: collision.id,
                    typeName: "GeneratedAppHome"
                )
            )
        }
    }
}

private extension FlutterCreateFlowValidationTests {
    struct Fixture {
        let entity: EntityDefinition
        let screen: ScreenDefinition
    }

    var projectIdentity: ProjectIdentity {
        ProjectIdentity(
            name: "Create Validation",
            organizationIdentifier: "de.example"
        )
    }

    func baseFixture() -> Fixture {
        let name = field(
            id: "field.asset.name",
            code: "name",
            type: .string,
            required: true
        )
        let asset = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: [name]
        )
        return Fixture(
            entity: asset,
            screen: formScreen(
                entityID: asset.id,
                fields: [name.id]
            )
        )
    }

    func formScreen(
        entityID: String,
        fields: [String]
    ) -> ScreenDefinition {
        ScreenDefinition(
            identity: DefinitionIdentity(
                id: "screen.asset.form",
                code: "asset_form",
                label: "Asset form"
            ),
            kind: .form,
            entityID: entityID,
            visibleFieldIDs: fields
        )
    }

    func navigation(
        to screen: ScreenDefinition
    ) -> NavigationDefinition {
        NavigationDefinition(
            items: [
                NavigationItemDefinition(
                    id: "nav.\(screen.id)",
                    label: "Create asset",
                    screenID: screen.id
                )
            ]
        )
    }

    func specification(
        entities: [EntityDefinition],
        relations: [RelationDefinition] = [],
        screens: [ScreenDefinition],
        navigation: NavigationDefinition = NavigationDefinition(),
        offline: OfflineConfiguration = .businessDefault
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: projectIdentity,
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .localOnly,
            flutterStateManagement: .riverpod,
            entities: entities,
            relations: relations,
            screens: screens,
            navigation: navigation,
            offline: offline
        )
    }

    func entity(
        id: String,
        code: String
    ) -> EntityDefinition {
        EntityDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            )
        )
    }

    func field(
        id: String,
        code: String,
        type: FieldDataType,
        required: Bool = false
    ) -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            dataType: type,
            isRequired: required
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

    func contents(
        _ plan: GenerationPlan,
        at path: String
    ) throws -> String {
        try XCTUnwrap(plan.file(at: path)?.contents)
    }
}
