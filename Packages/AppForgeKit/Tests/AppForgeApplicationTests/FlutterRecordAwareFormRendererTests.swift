import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterRecordAwareFormRendererTests: XCTestCase {
    func testFormWrapperAcceptsOptionalIdentifiedRecordAndPreservesSubmitIdentity() throws {
        let fixture = makeFixture()
        let plan = try render(fixture.specification)
        let source = try formSource(in: plan)

        XCTAssertTrue(
            source.contains("final DomainRecord<Asset>? record;")
        )
        XCTAssertTrue(
            source.contains("final GeneratedIdentifiedFormSubmit onSubmit;")
        )
        XCTAssertTrue(
            source.contains("recordId: record?.recordId")
        )
        XCTAssertTrue(
            source.contains("values: values")
        )
        XCTAssertTrue(
            source.contains("Map<String, Object?>.unmodifiable(")
        )
        XCTAssertTrue(source.contains("...recordValues"))
        XCTAssertTrue(source.contains("...initialValues"))
    }

    func testRecordPrefillUsesExactlyVisibleFieldsInOrder() throws {
        let fixture = makeFixture()
        let source = try formSource(
            in: render(fixture.specification)
        )

        let markers = fixture.visibleMappings.map {
            "'\($0.fieldID)': value.\($0.member)"
        }
        let offsets = try markers.map { marker in
            try XCTUnwrap(source.range(of: marker)).lowerBound
        }
        for pair in zip(offsets, offsets.dropFirst()) {
            XCTAssertLessThan(pair.0, pair.1)
        }

        XCTAssertFalse(
            source.contains(
                "'field.asset.internal_note': value.internalNote"
            )
        )
    }

    func testRecordPrefillPreservesRichDomainValuesWithoutSerialization() throws {
        let source = try formSource(
            in: render(makeFixture().specification)
        )

        XCTAssertTrue(
            source.contains(
                "'field.asset.attachment': value.attachment"
            )
        )
        XCTAssertTrue(
            source.contains(
                "'field.asset.image': value.image"
            )
        )
        XCTAssertTrue(
            source.contains(
                "'field.asset.color': value.color"
            )
        )
        XCTAssertTrue(
            source.contains(
                "'field.asset.location': value.location"
            )
        )
        XCTAssertFalse(source.contains("value.attachment.toString()"))
        XCTAssertFalse(source.contains("value.location.toString()"))
    }

    func testIdentifiedSubmitContractKeepsRecordIdNullableForCreate() throws {
        let plan = try render(makeFixture().specification)
        let contract = try XCTUnwrap(
            plan.file(
                at: "lib/core/presentation/generated_form_contract.dart"
            )?.contents
        )
        let source = try formSource(in: plan)

        XCTAssertTrue(
            contract.contains(
                "typedef GeneratedIdentifiedFormSubmit"
            )
        )
        XCTAssertTrue(contract.contains("required String? recordId"))
        XCTAssertTrue(source.contains("this.record"))
        XCTAssertTrue(
            source.contains(
                "? const <String, Object?>{}"
            )
        )
        XCTAssertFalse(source.contains("Uuid"))
        XCTAssertFalse(source.contains("random"))
    }

    func testRecordAwareFormBridgeHasNoRepositoryOrProviderCoupling() throws {
        let plan = try render(makeFixture().specification)
        let source = try formSource(in: plan)

        XCTAssertFalse(source.contains("package:appforge"))
        XCTAssertFalse(source.contains("supabase"))
        XCTAssertFalse(source.contains("firebase"))
        XCTAssertFalse(source.contains("stripe"))
        XCTAssertFalse(source.contains("sqflite"))
        XCTAssertFalse(source.contains("Repository"))
    }

    func testRecordAwareFormRenderingIsDeterministic() throws {
        let fixture = makeFixture()

        XCTAssertEqual(
            try render(fixture.specification),
            try render(fixture.specification)
        )
    }
}

private extension FlutterRecordAwareFormRendererTests {
    struct VisibleMapping {
        let fieldID: String
        let member: String
    }

    struct Fixture {
        let specification: ProjectSpecification
        let visibleMappings: [VisibleMapping]
    }

    func makeFixture() -> Fixture {
        let fields = fixtureFields()
        let mappings = fixtureMappings()
        let asset = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: fields
        )
        let screen = ScreenDefinition(
            identity: DefinitionIdentity(
                id: "screen.asset.editor",
                code: "asset_editor",
                label: "Edit asset"
            ),
            kind: .form,
            entityID: asset.id,
            visibleFieldIDs: mappings.map(\.fieldID)
        )

        return Fixture(
            specification: specification(
                entities: [asset],
                screens: [screen]
            ),
            visibleMappings: mappings
        )
    }

    func fixtureMappings() -> [VisibleMapping] {
        [
            VisibleMapping(fieldID: "field.asset.name", member: "name"),
            VisibleMapping(
                fieldID: "field.asset.quantity",
                member: "quantity"
            ),
            VisibleMapping(fieldID: "field.asset.active", member: "active"),
            VisibleMapping(
                fieldID: "field.asset.scheduled_at",
                member: "scheduledAt"
            ),
            VisibleMapping(
                fieldID: "field.asset.attachment",
                member: "attachment"
            ),
            VisibleMapping(fieldID: "field.asset.image", member: "image"),
            VisibleMapping(fieldID: "field.asset.color", member: "color"),
            VisibleMapping(
                fieldID: "field.asset.location",
                member: "location"
            )
        ]
    }

    func fixtureFields() -> [FieldDefinition] {
        [
            field(id: "field.asset.name", code: "name", type: .string),
            field(id: "field.asset.quantity", code: "quantity", type: .integer),
            field(id: "field.asset.active", code: "active", type: .boolean),
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
            field(id: "field.asset.image", code: "image", type: .image),
            field(id: "field.asset.color", code: "color", type: .color),
            field(
                id: "field.asset.location",
                code: "location",
                type: .location
            ),
            field(
                id: "field.asset.internal_note",
                code: "internal_note",
                type: .string
            )
        ]
    }

    func field(
        id: String,
        code: String,
        type: FieldDataType
    ) -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            dataType: type
        )
    }

    func specification(
        entities: [EntityDefinition],
        screens: [ScreenDefinition]
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Record Form Bridge",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: entities,
            screens: screens,
            offline: .businessDefault
        )
    }

    func formSource(
        in plan: GenerationPlan
    ) throws -> String {
        try XCTUnwrap(
            plan.file(
                at: "lib/features/asset/presentation/screens/asset_editor_form_screen.dart"
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
