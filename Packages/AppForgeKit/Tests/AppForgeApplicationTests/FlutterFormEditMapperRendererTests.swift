import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterFormEditMapperRendererTests: XCTestCase {
    func testEditMapperRebuildsEntityFromVisibleValues() throws {
        let fixture = makeFixture()
        let plan = try render(fixture.specification)
        let source = try mapperSource(in: plan)

        XCTAssertTrue(
            source.contains("abstract final class AssetEditorFormEditMapper")
        )
        XCTAssertTrue(source.contains("return Asset("))
        XCTAssertTrue(
            source.contains(
                "name: GeneratedFormEditMapping.requiredValue<String>(values, 'field.asset.name')"
            )
        )
        XCTAssertTrue(
            source.contains(
                "quantity: GeneratedFormEditMapping.optionalValue<int>(values, 'field.asset.quantity')"
            )
        )
        XCTAssertTrue(
            source.contains(
                "active: GeneratedFormEditMapping.requiredValue<bool>(values, 'field.asset.active')"
            )
        )
        XCTAssertTrue(
            source.contains(
                "scheduledAt: GeneratedFormEditMapping.optionalValue<DateTime>(values, 'field.asset.scheduled_at')"
            )
        )
    }

    func testEditMapperPreservesHiddenFieldsAndSourceRelations() throws {
        let source = try mapperSource(
            in: render(makeFixture().specification)
        )

        XCTAssertTrue(
            source.contains(
                "internalNote: record.value.internalNote"
            )
        )
        XCTAssertTrue(
            source.contains(
                "secretCode: record.value.secretCode"
            )
        )
        XCTAssertTrue(
            source.contains(
                "category: record.value.category"
            )
        )
        XCTAssertFalse(source.contains("record.value.name"))
        XCTAssertFalse(source.contains("record.value.quantity"))
        XCTAssertFalse(source.contains("record.value.active"))
    }

    func testEditMapperPreservesRichValueTypes() throws {
        let source = try mapperSource(
            in: render(makeFixture().specification)
        )

        assertOptionalMapping(
            type: "DomainFileValue",
            member: "attachment",
            fieldID: "field.asset.attachment",
            in: source
        )
        assertOptionalMapping(
            type: "DomainImageValue",
            member: "image",
            fieldID: "field.asset.image",
            in: source
        )
        assertOptionalMapping(
            type: "DomainColorValue",
            member: "color",
            fieldID: "field.asset.color",
            in: source
        )
        assertOptionalMapping(
            type: "DomainLocationValue",
            member: "location",
            fieldID: "field.asset.location",
            in: source
        )
        XCTAssertFalse(source.contains("toString()"))
    }

    func testEditMappingCoreFailsClosedForMissingAndInvalidValues() throws {
        let plan = try render(makeFixture().specification)
        let core = try XCTUnwrap(
            plan.file(
                at: "lib/core/presentation/generated_form_edit_mapping.dart"
            )?.contents
        )

        XCTAssertTrue(
            core.contains("enum GeneratedFormEditMappingFailure")
        )
        XCTAssertTrue(core.contains("missingValue"))
        XCTAssertTrue(core.contains("invalidType"))
        XCTAssertTrue(core.contains("if (!values.containsKey(fieldId))"))
        XCTAssertTrue(core.contains("if (value is! T)"))
        XCTAssertTrue(core.contains("static T requiredValue<T>("))
        XCTAssertTrue(core.contains("static T? optionalValue<T>("))
    }

    func testEditMapperHasNoRepositoryOrProviderRuntimeCoupling() throws {
        let plan = try render(makeFixture().specification)
        let source = try mapperSource(in: plan)
        let core = try XCTUnwrap(
            plan.file(
                at: "lib/core/presentation/generated_form_edit_mapping.dart"
            )?.contents
        )

        for contents in [source, core] {
            XCTAssertFalse(contents.contains("package:appforge"))
            XCTAssertFalse(contents.contains("Repository"))
            XCTAssertFalse(contents.contains("SaveAsset"))
            XCTAssertFalse(contents.contains("supabase"))
            XCTAssertFalse(contents.contains("firebase"))
            XCTAssertFalse(contents.contains("stripe"))
            XCTAssertFalse(contents.contains("sqflite"))
        }
    }

    func testEditMapperRenderingIsDeterministic() throws {
        let fixture = makeFixture()

        XCTAssertEqual(
            try render(fixture.specification),
            try render(fixture.specification)
        )
    }
}

private extension FlutterFormEditMapperRendererTests {
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
            fields: assetFields()
        )
        let category = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.category",
                code: "category",
                label: "Category"
            )
        )
        let relation = RelationDefinition(
            identity: DefinitionIdentity(
                id: "relation.asset.category",
                code: "category",
                label: "Category"
            ),
            sourceEntityID: asset.id,
            targetEntityID: category.id,
            cardinality: .manyToOne,
            isRequired: true
        )
        let screen = ScreenDefinition(
            identity: DefinitionIdentity(
                id: "screen.asset.editor",
                code: "asset_editor",
                label: "Edit asset"
            ),
            kind: .form,
            entityID: asset.id,
            visibleFieldIDs: visibleFieldIDs()
        )

        return Fixture(
            specification: ProjectSpecification(
                identity: ProjectIdentity(
                    name: "Typed Edit Mapper",
                    organizationIdentifier: "de.example"
                ),
                framework: .flutter,
                targetPlatforms: [.iOS, .android],
                backend: .supabase,
                flutterStateManagement: .riverpod,
                entities: [asset, category],
                relations: [relation],
                screens: [screen],
                offline: .businessDefault
            )
        )
    }

    func visibleFieldIDs() -> [String] {
        [
            "field.asset.name",
            "field.asset.quantity",
            "field.asset.active",
            "field.asset.scheduled_at",
            "field.asset.attachment",
            "field.asset.image",
            "field.asset.color",
            "field.asset.location"
        ]
    }

    func assetFields() -> [FieldDefinition] {
        [
            field(
                id: "field.asset.name",
                code: "name",
                type: .string,
                required: true
            ),
            field(
                id: "field.asset.quantity",
                code: "quantity",
                type: .integer
            ),
            field(
                id: "field.asset.active",
                code: "active",
                type: .boolean,
                required: true
            ),
            field(
                id: "field.asset.scheduled_at",
                code: "scheduled_at",
                type: .dateTime
            ),
            field(
                id: "field.asset.attachment",
                code: "attachment",
                type: .file
            ),
            field(
                id: "field.asset.image",
                code: "image",
                type: .image
            ),
            field(
                id: "field.asset.color",
                code: "color",
                type: .color
            ),
            field(
                id: "field.asset.location",
                code: "location",
                type: .location
            ),
            field(
                id: "field.asset.internal_note",
                code: "internal_note",
                type: .string
            ),
            field(
                id: "field.asset.secret_code",
                code: "secret_code",
                type: .string,
                required: true
            )
        ]
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

    func assertOptionalMapping(
        type: String,
        member: String,
        fieldID: String,
        in source: String
    ) {
        XCTAssertTrue(
            source.contains(
                "\(member): GeneratedFormEditMapping.optionalValue<\(type)>(values, '\(fieldID)')"
            )
        )
    }

    func mapperSource(
        in plan: GenerationPlan
    ) throws -> String {
        try XCTUnwrap(
            plan.file(
                at: "lib/features/asset/presentation/mappers/asset_editor_form_edit_mapper.dart"
            )?.contents
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
