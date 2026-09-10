import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterFormEditMapperValidationTests: XCTestCase {
    func testEditMapperTypeCollisionWithEntityFailsClosed() throws {
        let asset = entity(
            id: "entity.asset",
            code: "asset"
        )
        let collision = entity(
            id: "entity.mapper_collision",
            code: "asset_editor_form_edit_mapper"
        )
        let screen = formScreen(
            id: "screen.asset.editor",
            code: "asset_editor",
            entityID: asset.id
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [collision, asset],
                    screens: [screen]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .generatedTypeNameCollision(
                    firstDefinitionID: collision.id,
                    secondDefinitionID: screen.id,
                    typeName: "AssetEditorFormEditMapper"
                )
            )
        }
    }

    func testGeneratedFormEditMappingCoreTypeIsReserved() throws {
        let collision = entity(
            id: "entity.generated_mapping",
            code: "generated_form_edit_mapping"
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
                    typeName: "GeneratedFormEditMapping"
                )
            )
        }
    }
}

private extension FlutterFormEditMapperValidationTests {
    func specification(
        entities: [EntityDefinition],
        screens: [ScreenDefinition]
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Edit Mapper Validation",
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

    func formScreen(
        id: String,
        code: String,
        entityID: String
    ) -> ScreenDefinition {
        ScreenDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            kind: .form,
            entityID: entityID
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
