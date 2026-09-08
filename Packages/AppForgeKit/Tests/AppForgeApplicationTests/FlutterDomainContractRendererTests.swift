import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterDomainContractRendererTests: XCTestCase {
    func testRichDomainValuesRelationsAndPresentationMetadataAreGenerated() throws {
        let specification = makeSpecification()
        let plan = try render(specification)

        let values = try contents(
            "lib/core/domain/domain_values.dart",
            in: plan
        )
        XCTAssertTrue(values.contains("class DomainFileValue"))
        XCTAssertTrue(values.contains("class DomainImageValue"))
        XCTAssertTrue(values.contains("class DomainColorValue"))
        XCTAssertTrue(values.contains("class DomainLocationValue"))
        XCTAssertTrue(values.contains("lat < -90 || lat > 90"))
        XCTAssertTrue(values.contains("lon < -180 || lon > 180"))
        XCTAssertFalse(values.contains("package:appforge"))

        let asset = try contents(
            "lib/features/asset/domain/entities/asset.dart",
            in: plan
        )
        XCTAssertTrue(
            asset.contains(
                "import '../../../../core/domain/domain_values.dart';"
            )
        )
        XCTAssertTrue(asset.contains("final DomainFileValue? attachment;"))
        XCTAssertTrue(asset.contains("final DomainImageValue image;"))
        XCTAssertTrue(asset.contains("final DomainColorValue brandColor;"))
        XCTAssertTrue(asset.contains("final DomainLocationValue position;"))
        XCTAssertTrue(asset.contains("final DomainReference owner;"))
        XCTAssertTrue(
            asset.contains("final List<DomainReference> members;")
        )
        XCTAssertTrue(
            asset.contains(
                "members = List<DomainReference>.unmodifiable(members)"
            )
        )

        let schema = try contents(
            "lib/core/domain/domain_schema.dart",
            in: plan
        )
        XCTAssertTrue(schema.contains("generatedRelations"))
        XCTAssertTrue(schema.contains("cardinality: 'manyToOne'"))
        XCTAssertTrue(schema.contains("cardinality: 'oneToMany'"))
        XCTAssertTrue(schema.contains("ownership: 'source'"))
        XCTAssertTrue(schema.contains("deleteRule: 'restrict'"))
        XCTAssertTrue(schema.contains("generatedFieldPresentations"))
        XCTAssertTrue(schema.contains("control: 'colorPicker'"))
        XCTAssertTrue(schema.contains("control: 'select'"))
        XCTAssertTrue(schema.contains("control: 'chips'"))
        XCTAssertTrue(schema.contains("minimum: 0.0"))
        XCTAssertTrue(schema.contains("maximum: 100.0"))
    }

    func testOfflineMappingPersistsRichValuesAndSourceRelations() throws {
        let plan = try render(makeSpecification())

        let migration = try contents(
            "lib/core/storage/database_migrations.dart",
            in: plan
        )
        XCTAssertTrue(migration.contains("\"_rel_members\" TEXT NOT NULL"))
        XCTAssertTrue(migration.contains("\"_rel_owner\" TEXT NOT NULL"))

        let local = try contents(
            "lib/features/asset/data/local/asset_local_data_source.dart",
            in: plan
        )
        XCTAssertTrue(
            local.contains(
                "import '../../../../core/domain/domain_values.dart';"
            )
        )
        XCTAssertTrue(local.contains("import 'dart:convert';"))
        XCTAssertTrue(
            local.contains("DomainFileValue.fromStorageString")
        )
        XCTAssertTrue(
            local.contains("DomainLocationValue.fromStorageString")
        )
        XCTAssertTrue(local.contains("value.brandColor.toStorageString()"))
        XCTAssertTrue(local.contains("value.image.toStorageString()"))
        XCTAssertTrue(local.contains("'_rel_owner': value.owner.recordId"))
        XCTAssertTrue(
            local.contains(
                "'_rel_members': jsonEncode(value.members"
            )
        )
        XCTAssertTrue(
            local.contains(
                "entityId: 'entity.user', recordId: item as String"
            )
        )
    }

    func testFieldAndRelationGeneratedMemberCollisionFailsClosed() throws {
        let user = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.user",
                code: "user",
                label: "User"
            )
        )
        let asset = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: [
                FieldDefinition(
                    identity: DefinitionIdentity(
                        id: "field.asset.owner",
                        code: "owner",
                        label: "Owner text"
                    ),
                    dataType: .string
                )
            ]
        )
        let relation = RelationDefinition(
            identity: DefinitionIdentity(
                id: "relation.asset.owner",
                code: "owner",
                label: "Owner"
            ),
            sourceEntityID: asset.id,
            targetEntityID: user.id,
            cardinality: .manyToOne
        )
        let specification = baseSpecification(
            entities: [asset, user],
            relations: [relation]
        )

        XCTAssertThrowsError(try render(specification)) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .duplicateGeneratedIdentifier(
                    entityID: asset.id,
                    identifier: "owner"
                )
            )
        }
    }

    private func makeSpecification() -> ProjectSpecification {
        let asset = makeAsset()
        let user = makeUser()
        let relations = makeRelations(asset: asset, user: user)
        let presentations = makePresentations(
            owner: relations.owner,
            members: relations.members
        )
        return baseSpecification(
            entities: [asset, user],
            relations: [relations.owner, relations.members],
            fieldPresentations: presentations
        )
    }

    private func makeAsset() -> EntityDefinition {
        EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: assetFields
        )
    }

    private var assetFields: [FieldDefinition] {
        [
            makeField(
                id: "field.asset.attachment",
                code: "attachment",
                label: "Attachment",
                dataType: .file
            ),
            makeField(
                id: "field.asset.brandColor",
                code: "brandColor",
                label: "Brand Color",
                dataType: .color,
                isRequired: true
            ),
            makeField(
                id: "field.asset.image",
                code: "image",
                label: "Image",
                dataType: .image,
                isRequired: true
            ),
            makeField(
                id: "field.asset.position",
                code: "position",
                label: "Position",
                dataType: .location,
                isRequired: true
            ),
            makeField(
                id: "field.asset.quantity",
                code: "quantity",
                label: "Quantity",
                dataType: .integer
            )
        ]
    }

    private func makeField(
        id: String,
        code: String,
        label: String,
        dataType: FieldDataType,
        isRequired: Bool = false
    ) -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: label
            ),
            dataType: dataType,
            isRequired: isRequired
        )
    }

    private func makeUser() -> EntityDefinition {
        EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.user",
                code: "user",
                label: "User"
            )
        )
    }

    private func makeRelations(
        asset: EntityDefinition,
        user: EntityDefinition
    ) -> (owner: RelationDefinition, members: RelationDefinition) {
        let owner = RelationDefinition(
            identity: DefinitionIdentity(
                id: "relation.asset.owner",
                code: "owner",
                label: "Owner"
            ),
            sourceEntityID: asset.id,
            targetEntityID: user.id,
            cardinality: .manyToOne,
            isRequired: true,
            ownership: .source,
            deleteRule: .restrict
        )
        let members = RelationDefinition(
            identity: DefinitionIdentity(
                id: "relation.asset.members",
                code: "members",
                label: "Members"
            ),
            sourceEntityID: asset.id,
            targetEntityID: user.id,
            cardinality: .oneToMany,
            isRequired: true,
            ownership: .source,
            deleteRule: .restrict
        )
        return (owner, members)
    }

    private func makePresentations(
        owner: RelationDefinition,
        members: RelationDefinition
    ) -> [FieldPresentationDefinition] {
        [
            FieldPresentationDefinition(
                id: "presentation.asset.brandColor",
                target: .field("field.asset.brandColor"),
                control: .colorPicker
            ),
            FieldPresentationDefinition(
                id: "presentation.asset.members",
                target: .relation(members.id),
                control: .chips
            ),
            FieldPresentationDefinition(
                id: "presentation.asset.owner",
                target: .relation(owner.id),
                control: .select
            ),
            FieldPresentationDefinition(
                id: "presentation.asset.quantity",
                target: .field("field.asset.quantity"),
                control: .slider,
                numericRange: NumericRange(
                    minimum: 0,
                    maximum: 100
                )
            )
        ]
    }

    private func baseSpecification(
        entities: [EntityDefinition],
        relations: [RelationDefinition] = [],
        fieldPresentations: [FieldPresentationDefinition] = []
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Domain Contracts",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: entities,
            relations: relations,
            fieldPresentations: fieldPresentations,
            offline: .businessDefault
        )
    }

    private func render(
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

    private func contents(
        _ path: String,
        in plan: GenerationPlan
    ) throws -> String {
        try XCTUnwrap(plan.file(at: path)?.contents)
    }
}
