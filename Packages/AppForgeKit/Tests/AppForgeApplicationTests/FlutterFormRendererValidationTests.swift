import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterFormRendererValidationTests: XCTestCase {
    func testAmbiguousVisibleFieldPresentationFailsClosed() throws {
        let name = field(id: "field.asset.name", code: "name", type: .string)
        let asset = entity(
            id: "entity.asset",
            code: "asset",
            fields: [name]
        )
        let screen = formScreen(
            id: "screen.asset.form",
            code: "asset_form",
            entityID: asset.id,
            fields: [name.id]
        )
        let first = presentation(
            id: "presentation.name.a",
            fieldID: name.id,
            control: .textField
        )
        let second = presentation(
            id: "presentation.name.b",
            fieldID: name.id,
            control: .textArea
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [asset],
                    presentations: [second, first],
                    screens: [screen]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .ambiguousFieldPresentation(
                    screenID: screen.id,
                    fieldID: name.id,
                    firstPresentationID: first.id,
                    secondPresentationID: second.id
                )
            )
        }
    }

    func testLocationTextPresentationFailsClosedInsteadOfEmittingStringValue() throws {
        let location = field(
            id: "field.asset.location",
            code: "location",
            type: .location
        )
        let asset = entity(
            id: "entity.asset",
            code: "asset",
            fields: [location]
        )
        let screen = formScreen(
            id: "screen.asset.form",
            code: "asset_form",
            entityID: asset.id,
            fields: [location.id]
        )

        XCTAssertThrowsError(
            try render(
                specification(
                    entities: [asset],
                    presentations: [
                        presentation(
                            id: "presentation.location.text",
                            fieldID: location.id,
                            control: .textField
                        )
                    ],
                    screens: [screen]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .unsupportedFormControl(
                    screenID: screen.id,
                    fieldID: location.id,
                    control: .textField
                )
            )
        }
    }

    func testNormalizedFormScreenPathCollisionFailsWithBothDefinitions() throws {
        let asset = entity(id: "entity.asset", code: "asset")
        let camel = formScreen(
            id: "screen.camel",
            code: "assetEditor",
            entityID: asset.id
        )
        let snake = formScreen(
            id: "screen.snake",
            code: "asset_editor",
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
                    path: "lib/features/asset/presentation/screens/asset_editor_form_screen.dart"
                )
            )
        }
    }

    func testFormScreenTypeCollisionWithEntityDerivedTypeFailsClosed() throws {
        let asset = entity(id: "entity.asset", code: "asset")
        let collision = entity(
            id: "entity.assetFormScreen",
            code: "asset_form_screen"
        )
        let screen = formScreen(
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
                    typeName: "AssetFormScreen"
                )
            )
        }
    }
}

private extension FlutterFormRendererValidationTests {
    func specification(
        entities: [EntityDefinition],
        presentations: [FieldPresentationDefinition] = [],
        screens: [ScreenDefinition] = []
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Form Validation",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: entities,
            fieldPresentations: presentations,
            screens: screens,
            offline: .businessDefault
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

    func formScreen(
        id: String,
        code: String,
        entityID: String,
        fields: [String] = []
    ) -> ScreenDefinition {
        ScreenDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            kind: .form,
            entityID: entityID,
            visibleFieldIDs: fields
        )
    }

    func presentation(
        id: String,
        fieldID: String,
        control: FieldControl
    ) -> FieldPresentationDefinition {
        FieldPresentationDefinition(
            id: id,
            target: .field(fieldID),
            control: control
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
