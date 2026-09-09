import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterCreateFlowRendererTests: XCTestCase {
    func testFormGeneratesTypedCreateViewModelSecureIDsAndDefaults() throws {
        let fixture = makeFixture()
        let plan = try render(fixture.specification)
        let viewModel = try contents(
            plan,
            at: "lib/features/asset/presentation/view_models/asset_create_form_view_model.dart"
        )
        let form = try contents(
            plan,
            at: "lib/features/asset/presentation/screens/asset_create_form_screen.dart"
        )
        let recordIDs = try contents(
            plan,
            at: "lib/core/domain/record_id_generator.dart"
        )
        let app = try contents(plan, at: "lib/app.dart")
        let dependencies = try contents(
            plan,
            at: "lib/core/bootstrap/app_dependencies.dart"
        )
        let home = try contents(
            plan,
            at: "lib/core/presentation/generated_app_home.dart"
        )
        let smokeTest = try contents(plan, at: "test/app_smoke_test.dart")

        XCTAssertTrue(viewModel.contains("class AssetCreateFormViewModel"))
        XCTAssertTrue(viewModel.contains("final SaveAsset _save;"))
        XCTAssertTrue(
            viewModel.contains(
                "name: values['field.asset.name'] as String"
            )
        )
        XCTAssertTrue(viewModel.contains("priority: 3"))
        XCTAssertTrue(viewModel.contains("recordId: _recordIds.next()"))
        XCTAssertTrue(form.contains("..._defaultValues"))
        XCTAssertTrue(form.contains("'field.asset.active': true"))
        XCTAssertTrue(recordIDs.contains("Random.secure()"))
        XCTAssertTrue(recordIDs.contains("bytes[6] = (bytes[6] & 0x0f) | 0x40"))
        XCTAssertFalse(recordIDs.contains("DateTime.now"))
        XCTAssertTrue(app.contains("title: 'Asset erfassen'"))
        XCTAssertTrue(app.contains("_dependencies.assetCreateForm.create(values)"))
        XCTAssertFalse(app.contains("Generated with AppForge Pro"))
        XCTAssertTrue(dependencies.contains("AssetRepositoryImpl("))
        XCTAssertTrue(dependencies.contains("AssetLocalDataSource(database)"))
        XCTAssertTrue(dependencies.contains("save: SaveAsset(assetRepository)"))
        XCTAssertTrue(home.contains("Navigator.of(context).push<bool>"))
        XCTAssertTrue(home.contains("Saved successfully."))
        XCTAssertTrue(smokeTest.contains("opens the generated create flow"))
        XCTAssertTrue(smokeTest.contains("find.byType(BackButton)"))
    }

    func testRequiredHiddenFieldFailsClosed() throws {
        var fixture = makeFixture()
        fixture.screen.visibleFieldIDs = ["field.asset.active"]
        let specification = makeSpecification(
            entities: [fixture.entity],
            screens: [fixture.screen]
        )

        XCTAssertThrowsError(try render(specification)) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .formScreenMissingRequiredField(
                    screenID: fixture.screen.id,
                    fieldID: "field.asset.name"
                )
            )
        }
    }

    func testRequiredRelationFailsUntilRelationPickerIsMaterialized() throws {
        let fixture = makeFixture()
        let location = entity(id: "entity.location", code: "location")
        let relations = [
            RelationDefinition(
                identity: DefinitionIdentity(
                    id: "relation.asset.location",
                    code: "location",
                    label: "Location"
                ),
                sourceEntityID: fixture.entity.id,
                targetEntityID: "entity.location",
                cardinality: .manyToOne,
                isRequired: true
            )
        ]
        let specification = makeSpecification(
            entities: [fixture.entity, location],
            relations: relations,
            screens: [fixture.screen]
        )

        XCTAssertThrowsError(try render(specification)) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .formScreenRequiresRelationPicker(
                    screenID: fixture.screen.id,
                    relationID: "relation.asset.location"
                )
            )
        }
    }

    func testFormWithoutOfflineRepositoryFailsClosed() throws {
        let fixture = makeFixture()
        let offline = OfflineConfiguration(
            isEnabled: false,
            usesLocalSingleSourceOfTruth: false,
            usesSyncOutbox: false,
            syncsOnReconnect: false,
            conflictResolution: .manualReview
        )
        let specification = makeSpecification(
            entities: [fixture.entity],
            screens: [fixture.screen],
            offline: offline
        )

        XCTAssertThrowsError(try render(specification)) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .formScreenRequiresOfflinePersistence(
                    screenID: fixture.screen.id
                )
            )
        }
    }

    func testRoleProtectedFormFailsUntilRoleEvaluationIsMaterialized() throws {
        let fixture = makeFixture()
        var screen = fixture.screen
        screen.allowedRoleIDs = ["role.owner"]
        let specification = ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS],
            backend: .localOnly,
            flutterStateManagement: .riverpod,
            entities: [fixture.entity],
            roles: [
                RoleDefinition(
                    identity: DefinitionIdentity(
                        id: "role.owner",
                        code: "owner",
                        label: "Owner"
                    )
                )
            ],
            screens: [screen]
        )

        XCTAssertThrowsError(try render(specification)) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .formScreenRequiresRoleEvaluation(screenID: screen.id)
            )
        }
    }
}

private extension FlutterCreateFlowRendererTests {
    struct Fixture {
        var specification: ProjectSpecification
        let entity: EntityDefinition
        var screen: ScreenDefinition
    }

    func makeFixture() -> Fixture {
        let asset = entity(
            id: "entity.asset",
            code: "asset",
            fields: [
                field(
                    id: "field.asset.name",
                    code: "name",
                    type: .string,
                    isRequired: true
                ),
                field(
                    id: "field.asset.active",
                    code: "active",
                    type: .boolean,
                    defaultValue: .boolean(true)
                ),
                field(
                    id: "field.asset.priority",
                    code: "priority",
                    type: .integer,
                    isRequired: true,
                    defaultValue: .integer(3)
                )
            ]
        )
        let screen = ScreenDefinition(
            identity: DefinitionIdentity(
                id: "screen.asset.create",
                code: "asset_create",
                label: "Asset erfassen"
            ),
            kind: .form,
            entityID: asset.id,
            visibleFieldIDs: [
                "field.asset.name",
                "field.asset.active"
            ]
        )
        let specification = makeSpecification(
            entities: [asset],
            screens: [screen]
        )
        return Fixture(
            specification: specification,
            entity: asset,
            screen: screen
        )
    }

    func makeSpecification(
        entities: [EntityDefinition],
        relations: [RelationDefinition] = [],
        screens: [ScreenDefinition],
        offline: OfflineConfiguration = .businessDefault
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS],
            backend: .localOnly,
            flutterStateManagement: .riverpod,
            entities: entities,
            relations: relations,
            screens: screens,
            offline: offline
        )
    }

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
        code: String,
        type: FieldDataType,
        isRequired: Bool = false,
        defaultValue: FieldDefaultValue? = nil
    ) -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            dataType: type,
            isRequired: isRequired,
            defaultValue: defaultValue
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
