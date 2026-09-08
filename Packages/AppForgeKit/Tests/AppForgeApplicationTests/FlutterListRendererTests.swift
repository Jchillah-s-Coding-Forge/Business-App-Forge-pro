import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterListRendererTests: XCTestCase {
    func testListScreenMaterializesIdentifiedLoaderAndOrderedFields() throws {
        let fixture = makeFixture()
        let plan = try render(fixture.specification)
        let source = try XCTUnwrap(
            plan.file(
                at: "lib/features/asset/presentation/screens/asset_overview_list_screen.dart"
            )?.contents
        )

        XCTAssertTrue(source.contains("class AssetOverviewListScreen"))
        XCTAssertTrue(source.contains("final GeneratedListLoader<Asset> loadRecords;"))
        XCTAssertTrue(
            source.contains(
                "final GeneratedListRecordSelected<Asset>? onRecordSelected;"
            )
        )
        XCTAssertTrue(source.contains("GeneratedEntityListScreen<Asset>"))
        XCTAssertTrue(source.contains("GeneratedListValueKind.location"))
        XCTAssertTrue(source.contains("GeneratedListValueKind.string"))
        XCTAssertTrue(source.contains("GeneratedListValueKind.boolean"))
        XCTAssertTrue(source.contains("GeneratedListValueKind.integer"))
        XCTAssertTrue(source.contains("GeneratedListValueKind.file"))

        let markers = fixture.visibleMembers.map {
            "value: value.\($0)"
        }
        let offsets = try markers.map { marker in
            try XCTUnwrap(source.range(of: marker)).lowerBound
        }
        for pair in zip(offsets, offsets.dropFirst()) {
            XCTAssertLessThan(pair.0, pair.1)
        }
    }

    func testGeneratedListRuntimeKeepsIdentityAndExplicitStates() throws {
        let plan = try render(makeFixture().specification)
        let core = try XCTUnwrap(
            plan.file(
                at: "lib/core/presentation/generated_entity_list_screen.dart"
            )?.contents
        )

        XCTAssertTrue(
            core.contains(
                "Future<List<DomainRecord<T>>> Function()"
            )
        )
        XCTAssertTrue(
            core.contains("ValueKey<String>(record.recordId)")
        )
        XCTAssertTrue(
            core.contains("widget.onRecordSelected!(record)")
        )
        XCTAssertTrue(core.contains("CircularProgressIndicator"))
        XCTAssertTrue(core.contains("snapshot.hasError"))
        XCTAssertTrue(core.contains("'Unable to load records.'"))
        XCTAssertTrue(core.contains("child: const Text('Retry')"))
        XCTAssertTrue(core.contains("records.isEmpty"))
        XCTAssertTrue(core.contains("Text(widget.emptyMessage)"))
        XCTAssertFalse(core.contains("Text(record.recordId)"))
    }

    func testGeneratedListRuntimeFormatsRichValuesDeterministically() throws {
        let plan = try render(makeFixture().specification)
        let core = try XCTUnwrap(
            plan.file(
                at: "lib/core/presentation/generated_entity_list_screen.dart"
            )?.contents
        )

        XCTAssertTrue(core.contains("value as DomainFileValue"))
        XCTAssertTrue(core.contains("value as DomainImageValue"))
        XCTAssertTrue(core.contains("value as DomainColorValue"))
        XCTAssertTrue(core.contains("value as DomainLocationValue"))
        XCTAssertTrue(core.contains(".toUtc()"))
        XCTAssertTrue(core.contains(".toIso8601String()"))
        XCTAssertTrue(
            core.contains(
                "'${location.latitude}, ${location.longitude}'"
            )
        )
    }

    func testGeneratedListSourcesHaveNoAppForgeOrProviderRuntimeCoupling() throws {
        let plan = try render(makeFixture().specification)
        let listFiles = plan.files.filter {
            $0.relativePath.contains("generated_entity_list_screen")
                || $0.relativePath.hasSuffix("_list_screen.dart")
        }

        XCTAssertFalse(listFiles.isEmpty)
        for file in listFiles {
            XCTAssertFalse(file.contents.contains("package:appforge"))
            XCTAssertFalse(file.contents.contains("supabase"))
            XCTAssertFalse(file.contents.contains("firebase"))
            XCTAssertFalse(file.contents.contains("stripe"))
            XCTAssertFalse(file.contents.contains("sqflite"))
        }
    }

    func testListRenderingIsDeterministic() throws {
        let fixture = makeFixture()

        XCTAssertEqual(
            try render(fixture.specification),
            try render(fixture.specification)
        )
    }
}

private extension FlutterListRendererTests {
    struct Fixture {
        let specification: ProjectSpecification
        let visibleMembers: [String]
    }

    func makeFixture() -> Fixture {
        let fields = fixtureFields()
        let asset = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: fields
        )
        let visibleIDs = [
            "field.asset.location",
            "field.asset.name",
            "field.asset.active",
            "field.asset.quantity",
            "field.asset.attachment"
        ]
        let screen = ScreenDefinition(
            identity: DefinitionIdentity(
                id: "screen.asset.overview",
                code: "asset_overview",
                label: "Assets"
            ),
            kind: .list,
            entityID: asset.id,
            visibleFieldIDs: visibleIDs
        )

        return Fixture(
            specification: specification(
                entities: [asset],
                screens: [screen]
            ),
            visibleMembers: [
                "location",
                "name",
                "active",
                "quantity",
                "attachment"
            ]
        )
    }

    func fixtureFields() -> [FieldDefinition] {
        [
            field(
                id: "field.asset.name",
                code: "name",
                type: .string
            ),
            field(
                id: "field.asset.quantity",
                code: "quantity",
                type: .integer
            ),
            field(
                id: "field.asset.active",
                code: "active",
                type: .boolean
            ),
            field(
                id: "field.asset.scheduledAt",
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
                name: "List Contract",
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
