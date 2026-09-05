import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterOfflineRendererValidationTests: XCTestCase {
    func testOfflineRendererRejectsReservedSystemColumnCode() throws {
        let reservedField = FieldDefinition(
            identity: DefinitionIdentity(
                id: "field.customer.system",
                code: "_sync_status",
                label: "System Status"
            ),
            dataType: .string
        )
        let specification = FlutterOfflineTestFixture.makeSpecification(
            backend: .supabase,
            offline: .businessDefault,
            additionalFields: [reservedField]
        )
        let graph = try FlutterOfflineTestFixture.makeGraph(
            for: specification.backend
        )
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )

        XCTAssertThrowsError(
            try DeterministicFlutterProjectRenderer().makePlan(
                specification: specification,
                graph: graph,
                lockfile: lockfile
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .reservedGeneratedStorageIdentifier(
                    definitionID: reservedField.id,
                    identifier: "_sync_status"
                )
            )
        }
    }

    func testOfflineRenderingRemainsDeterministic() throws {
        let specification = FlutterOfflineTestFixture.makeSpecification(
            backend: .supabase,
            offline: .businessDefault
        )
        let first = try FlutterOfflineTestFixture.render(specification)
        let second = try FlutterOfflineTestFixture.render(specification)

        XCTAssertEqual(first, second)
        XCTAssertEqual(
            first.files.map(\.relativePath),
            second.files.map(\.relativePath)
        )
    }
}
