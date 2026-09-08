import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterTypedEditMapperRendererTests: XCTestCase {
    func testMapperReplacesVisibleFieldsAndPreservesHiddenState() throws {
        let source = try formSource(
            in: render(makeSpecification())
        )

        XCTAssertTrue(
            source.contains("static Asset applyEditValues({")
        )
        XCTAssertTrue(source.contains("final current = record.value;"))
        XCTAssertTrue(source.contains("return Asset("))
        XCTAssertTrue(
            source.contains("internalNote: current.internalNote")
        )
        XCTAssertTrue(source.contains("members: current.members"))
        XCTAssertTrue(source.contains("owner: current.owner"))
    }

    func testMapperUsesTypedNormalizedValues() throws {
        let source = try formSource(
            in: render(makeSpecification())
        )

        let expected = [
            "active: _requiredEditValue<bool>(",
            "attachment: _optionalEditValue<DomainFileValue>(",
            "brandColor: _requiredEditValue<DomainColorValue>(",
            "image: _requiredEditValue<DomainImageValue>(",
            "location: _requiredEditValue<DomainLocationValue>(",
            "name: _requiredEditValue<String>(",
            "price: _requiredEditValue<double>(",
            "quantity: _optionalEditValue<int>(",
            "scheduledAt: _requiredEditValue<DateTime>("
        ]
        for marker in expected {
            XCTAssertTrue(source.contains(marker), marker)
        }
    }

    func testMapperFailsClosedForMissingOrInvalidVisibleValues() throws {
        let source = try formSource(
            in: render(makeSpecification())
        )

        XCTAssertTrue(
            source.contains("if (!values.containsKey(fieldId))")
        )
        XCTAssertTrue(
            source.contains(
                "Missing normalized edit value for $fieldId."
            )
        )
        XCTAssertTrue(
            source.contains(
                "Invalid normalized edit value for $fieldId."
            )
        )
        XCTAssertTrue(source.contains("if (value == null) {"))
        XCTAssertTrue(source.contains("if (value is T) {"))
        XCTAssertFalse(source.contains("?? current."))
    }

    func testMapperIsProviderNeutralAndDeterministic() throws {
        let specification = makeSpecification()
        let first = try render(specification)
        let second = try render(specification)
        let source = try formSource(in: first)

        XCTAssertEqual(first, second)
        XCTAssertFalse(source.contains("Repository"))
        XCTAssertFalse(source.contains("supabase"))
        XCTAssertFalse(source.contains("firebase"))
        XCTAssertFalse(source.contains("sqflite"))
        XCTAssertFalse(source.contains("package:appforge"))
    }
}

private extension FlutterTypedEditMapperRendererTests {
    func makeSpecification() -> ProjectSpecification {
        let asset = makeAsset()
        let user = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.user",
                code: "user",
                label: "User"
            )
        )
        let relations = makeRelations(
            asset: asset,
            user: user
        )
        let form = ScreenDefinition(
            identity: DefinitionIdentity(
                id: "screen.asset.editor",
                code: "asset_editor",
                label: "Edit asset"
            ),
            kind: .form,
            entityID: asset.id,
            visibleFieldIDs: visibleFieldIDs
        )

        return ProjectSpecification(
            identity: ProjectIdentity(
                name: "Typed Edit Mapper",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: [asset, user],
            relations: relations,
            screens: [form],
            offline: .businessDefault
        )
    }

    var visibleFieldIDs: [String] {
        [
            "field.asset.scheduled_at",
            "field.asset.name",
            "field.asset.active",
            "field.asset.price",
            "field.asset.quantity",
            "field.asset.attachment",
            "field.asset.image",
            "field.asset.brand_color",
            "field.asset.location"
        ]
    }

    func makeAsset() -> EntityDefinition {
        EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: [
                field(
                    id: "field.asset.active",
                    code: "active",
                    type: .boolean,
                    isRequired: true
                ),
                field(
                    id: "field.asset.attachment",
                    code: "attachment",
                    type: .file
                ),
                field(
                    id: "field.asset.brand_color",
                    code: "brand_color",
                    type: .color,
                    isRequired: true
                ),
                field(
                    id: "field.asset.image",
                    code: "image",
                    type: .image,
                    isRequired: true
                ),
                field(
                    id: "field.asset.internal_note",
                    code: "internal_note",
                    type: .string
                ),
                field(
                    id: "field.asset.location",
                    code: "location",
                    type: .location,
                    isRequired: true
                ),
                field(
                    id: "field.asset.name",
                    code: "name",
                    type: .string,
                    isRequired: true
                ),
                field(
                    id: "field.asset.price",
                    code: "price",
                    type: .decimal,
                    isRequired: true
                ),
                field(
                    id: "field.asset.quantity",
                    code: "quantity",
                    type: .integer
                ),
                field(
                    id: "field.asset.scheduled_at",
                    code: "scheduled_at",
                    type: .dateTime,
                    isRequired: true
                )
            ]
        )
    }

    func field(
        id: String,
        code: String,
        type: FieldDataType,
        isRequired: Bool = false
    ) -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            dataType: type,
            isRequired: isRequired
        )
    }

    func makeRelations(
        asset: EntityDefinition,
        user: EntityDefinition
    ) -> [RelationDefinition] {
        [
            RelationDefinition(
                identity: DefinitionIdentity(
                    id: "relation.asset.members",
                    code: "members",
                    label: "Members"
                ),
                sourceEntityID: asset.id,
                targetEntityID: user.id,
                cardinality: .oneToMany,
                isRequired: true
            ),
            RelationDefinition(
                identity: DefinitionIdentity(
                    id: "relation.asset.owner",
                    code: "owner",
                    label: "Owner"
                ),
                sourceEntityID: asset.id,
                targetEntityID: user.id,
                cardinality: .manyToOne,
                isRequired: true
            )
        ]
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
