import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterCreateFlowRendererTests: XCTestCase {
    func testCreateFlowMaterializesNavigationCompositionAndTypedSave() throws {
        let fixture = makeFixture()
        let plan = try render(fixture.specification)

        let app = try contents(plan, at: "lib/app.dart")
        let dependencies = try contents(
            plan,
            at: "lib/core/bootstrap/app_dependencies.dart"
        )
        let viewModel = try contents(
            plan,
            at: "lib/features/asset/presentation/view_models/asset_create_form_create_view_model.dart"
        )
        let mapper = try contents(
            plan,
            at: "lib/features/asset/presentation/mappers/asset_create_form_create_mapper.dart"
        )

        XCTAssertTrue(app.contains("title: 'Create asset'"))
        XCTAssertTrue(app.contains("required String? recordId"))
        XCTAssertTrue(app.contains("if (recordId != null)"))
        XCTAssertTrue(
            app.contains("_dependencies.assetCreateCreate.create(values)")
        )
        XCTAssertTrue(dependencies.contains("AssetRepositoryImpl("))
        XCTAssertTrue(dependencies.contains("AssetLocalDataSource(database)"))
        XCTAssertTrue(dependencies.contains("save: SaveAsset(assetRepository)"))
        XCTAssertFalse(viewModel.contains("final AssetCreateFormCreateMapper"))
        XCTAssertTrue(
            viewModel.contains("AssetCreateFormCreateMapper.apply(values)")
        )
        XCTAssertTrue(viewModel.contains("recordId: recordId"))
        XCTAssertTrue(
            mapper.contains(
                "name: GeneratedFormCreateMapping.requiredValue<String>"
            )
        )
        XCTAssertTrue(mapper.contains("priority: 3"))
        XCTAssertFalse(mapper.contains("internalNote:"))
    }

    func testCreateFlowUsesSecureUuidBoundaryAndRealOfflineSavePath() throws {
        let plan = try render(makeFixture().specification)
        let ids = try contents(
            plan,
            at: "lib/core/domain/record_id_generator.dart"
        )
        let viewModel = try contents(
            plan,
            at: "lib/features/asset/presentation/view_models/asset_create_form_create_view_model.dart"
        )
        let repository = try contents(
            plan,
            at: "lib/features/asset/data/repositories/asset_repository_impl.dart"
        )

        XCTAssertTrue(ids.contains("Random.secure()"))
        XCTAssertTrue(ids.contains("bytes[6] = (bytes[6] & 0x0f) | 0x40"))
        XCTAssertTrue(ids.contains("bytes[8] = (bytes[8] & 0x3f) | 0x80"))
        XCTAssertFalse(ids.contains("DateTime.now"))
        XCTAssertTrue(viewModel.contains("final recordId = _recordIds.next();"))
        XCTAssertTrue(viewModel.contains("await _save(recordId: recordId, value: value);"))
        XCTAssertTrue(repository.contains("_local.save(recordId: recordId, value: value)"))
    }

    func testDefaultsLayerBelowRecordAndExplicitInitialValues() throws {
        let plan = try render(makeFixture().specification)
        let form = try contents(
            plan,
            at: "lib/features/asset/presentation/screens/asset_create_form_screen.dart"
        )

        let defaults = try XCTUnwrap(
            form.range(of: "..._defaultValues")?.lowerBound
        )
        let record = try XCTUnwrap(
            form.range(of: "...recordValues")?.lowerBound
        )
        let explicit = try XCTUnwrap(
            form.range(of: "...initialValues")?.lowerBound
        )
        XCTAssertLessThan(defaults, record)
        XCTAssertLessThan(record, explicit)
        XCTAssertTrue(form.contains("'field.asset.active': true"))
    }

    func testCreateAndEditMappersCoexistWithoutContractRegression() throws {
        let plan = try render(makeFixture().specification)
        let createMapper = try contents(
            plan,
            at: "lib/features/asset/presentation/mappers/asset_create_form_create_mapper.dart"
        )
        let editMapper = try contents(
            plan,
            at: "lib/features/asset/presentation/mappers/asset_create_form_edit_mapper.dart"
        )

        XCTAssertTrue(createMapper.contains("abstract final class AssetCreateFormCreateMapper"))
        XCTAssertTrue(editMapper.contains("abstract final class AssetCreateFormEditMapper"))
        XCTAssertTrue(editMapper.contains("internalNote: record.value.internalNote"))
        XCTAssertTrue(editMapper.contains("priority: record.value.priority"))
        XCTAssertFalse(createMapper.contains("record.value"))
    }

    func testGeneratedHomeProvidesNativeNavigationAndUsefulEmptyStateContract() throws {
        let plan = try render(makeFixture().specification)
        let home = try contents(
            plan,
            at: "lib/core/presentation/generated_app_home.dart"
        )
        let smoke = try contents(plan, at: "test/app_smoke_test.dart")

        XCTAssertTrue(home.contains("Navigator.of(context).push<bool>"))
        XCTAssertTrue(home.contains("Saved successfully."))
        XCTAssertTrue(home.contains("No create flows are configured."))
        XCTAssertTrue(smoke.contains("opens the generated create flow"))
        XCTAssertTrue(smoke.contains("find.byType(BackButton)"))
        XCTAssertFalse(smoke.contains("Generated with AppForge Pro'))"))
    }

    func testCurrentCreateFlowRenderingIsDeterministic() throws {
        let fixture = makeFixture()

        XCTAssertEqual(
            try render(fixture.specification),
            try render(fixture.specification)
        )
    }
}

private extension FlutterCreateFlowRendererTests {
    struct Fixture {
        let specification: ProjectSpecification
    }

    func makeFixture() -> Fixture {
        let asset = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: [
                field(
                    id: "field.asset.name",
                    code: "name",
                    type: .string,
                    required: true
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
                    required: true,
                    defaultValue: .integer(3)
                ),
                field(
                    id: "field.asset.internal_note",
                    code: "internal_note",
                    type: .string
                )
            ]
        )
        let screen = ScreenDefinition(
            identity: DefinitionIdentity(
                id: "screen.asset.create",
                code: "asset_create",
                label: "Asset create"
            ),
            kind: .form,
            entityID: asset.id,
            visibleFieldIDs: [
                "field.asset.name",
                "field.asset.active"
            ]
        )
        let navigation = NavigationDefinition(
            items: [
                NavigationItemDefinition(
                    id: "nav.asset.create",
                    label: "Create asset",
                    screenID: screen.id
                )
            ]
        )

        return Fixture(
            specification: ProjectSpecification(
                identity: ProjectIdentity(
                    name: "Inventory App",
                    organizationIdentifier: "de.example"
                ),
                framework: .flutter,
                targetPlatforms: [.iOS, .android],
                backend: .localOnly,
                flutterStateManagement: .riverpod,
                entities: [asset],
                screens: [screen],
                navigation: navigation,
                offline: .businessDefault
            )
        )
    }

    func field(
        id: String,
        code: String,
        type: FieldDataType,
        required: Bool = false,
        defaultValue: FieldDefaultValue? = nil
    ) -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            dataType: type,
            isRequired: required,
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
