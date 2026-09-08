import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterDetailRendererValidationTests: XCTestCase {
    func testDetailScreenWithoutEntityFailsClosed() throws {
        let detail = detailScreen(
            id: "screen.orphan",
            code: "orphan",
            entityID: nil
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [],
                    screens: [detail]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .detailScreenRequiresEntity(screenID: detail.id)
            )
        }
    }

    func testNormalizedDetailScreenPathCollisionFailsWithBothDefinitions() throws {
        let asset = entity(id: "entity.asset", code: "asset")
        let camel = detailScreen(
            id: "screen.camel",
            code: "assetOverview",
            entityID: asset.id
        )
        let snake = detailScreen(
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
                    path: "lib/features/asset/presentation/screens/asset_overview_detail_screen.dart"
                )
            )
        }
    }

    func testDetailScreenTypeCollisionWithEntityDerivedTypeFailsClosed() throws {
        let asset = entity(id: "entity.asset", code: "asset")
        let collision = entity(
            id: "entity.assetDetailScreen",
            code: "asset_detail_screen"
        )
        let detail = detailScreen(
            id: "screen.asset",
            code: "asset",
            entityID: asset.id
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [collision, asset],
                    screens: [detail]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .generatedTypeNameCollision(
                    firstDefinitionID: collision.id,
                    secondDefinitionID: detail.id,
                    typeName: "AssetDetailScreen"
                )
            )
        }
    }
}

private extension FlutterDetailRendererValidationTests {
    func specification(
        entities: [EntityDefinition],
        screens: [ScreenDefinition]
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Detail Validation",
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

    func detailScreen(
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
            kind: .detail,
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
