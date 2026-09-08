import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterListRendererValidationTests: XCTestCase {
    func testListScreenWithoutEntityFailsClosed() throws {
        let screen = listScreen(
            id: "screen.orphan",
            code: "orphan",
            entityID: nil
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [],
                    screens: [screen]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .listScreenRequiresEntity(screenID: screen.id)
            )
        }
    }

    func testNormalizedListScreenPathCollisionFailsWithBothDefinitions() throws {
        let asset = entity(id: "entity.asset", code: "asset")
        let camel = listScreen(
            id: "screen.camel",
            code: "assetOverview",
            entityID: asset.id
        )
        let snake = listScreen(
            id: "screen.snake",
            code: "asset_overview",
            entityID: asset.id
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [asset],
                    screens: [snake, camel]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .generatedOutputPathCollision(
                    firstDefinitionID: camel.id,
                    secondDefinitionID: snake.id,
                    path: "lib/features/asset/presentation/screens/asset_overview_list_screen.dart"
                )
            )
        }
    }

    func testListScreenTypeCollisionWithEntityDerivedTypeFailsClosed() throws {
        let asset = entity(id: "entity.asset", code: "asset")
        let collision = entity(
            id: "entity.assetListScreen",
            code: "asset_list_screen"
        )
        let screen = listScreen(
            id: "screen.asset",
            code: "asset",
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
                    typeName: "AssetListScreen"
                )
            )
        }
    }
}

private extension FlutterListRendererValidationTests {
    func specification(
        entities: [EntityDefinition],
        screens: [ScreenDefinition]
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "List Validation",
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

    func listScreen(
        id: String,
        code: String,
        entityID: String?
    ) -> ScreenDefinition {
        ScreenDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            kind: .list,
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
