import AppForgeDomain
import XCTest

final class ProjectSpecificationAdvancedTests: XCTestCase {
    private let validator = ProjectSpecificationValidator()

    func testCompleteBusinessWorkflowSpecificationIsValid() {
        let statusField = FieldDefinition(
            identity: DefinitionIdentity(id: "field.order.status", code: "status", label: "Status"),
            dataType: .enumeration,
            defaultValue: .option("draft"),
            options: [
                FieldOptionDefinition(id: "option.draft", value: "draft", label: "Entwurf"),
                FieldOptionDefinition(id: "option.approved", value: "approved", label: "Freigegeben")
            ]
        )
        let titleField = FieldDefinition(
            identity: DefinitionIdentity(id: "field.order.title", code: "title", label: "Titel"),
            dataType: .string,
            isRequired: true
        )
        let order = EntityDefinition(
            identity: DefinitionIdentity(id: "entity.order", code: "order", label: "Auftrag"),
            fields: [statusField, titleField]
        )
        let manager = RoleDefinition(
            identity: DefinitionIdentity(id: "role.manager", code: "manager", label: "Manager"),
            permissions: [
                BusinessPermissionDefinition(action: .manage, entityID: order.id)
            ]
        )
        let draft = BusinessStateDefinition(
            identity: DefinitionIdentity(id: "state.draft", code: "draft", label: "Entwurf"),
            isInitial: true
        )
        let approved = BusinessStateDefinition(
            identity: DefinitionIdentity(id: "state.approved", code: "approved", label: "Freigegeben"),
            isTerminal: true
        )
        let transition = BusinessTransitionDefinition(
            identity: DefinitionIdentity(id: "transition.approve", code: "approve", label: "Freigeben"),
            fromStateID: draft.id,
            toStateID: approved.id,
            trigger: "approve",
            allowedRoleIDs: [manager.id],
            guards: [.fieldIsSet(fieldID: titleField.id)],
            sideEffects: [.setField(fieldID: statusField.id, value: .option("approved"))],
            requiresAudit: true
        )
        let machine = BusinessStateMachineDefinition(
            identity: DefinitionIdentity(
                id: "machine.order.status",
                code: "orderStatus",
                label: "Auftragsstatus"
            ),
            entityID: order.id,
            stateFieldID: statusField.id,
            states: [draft, approved],
            transitions: [transition]
        )
        let screen = ScreenDefinition(
            identity: DefinitionIdentity(id: "screen.orders", code: "orders", label: "Aufträge"),
            kind: .list,
            entityID: order.id,
            visibleFieldIDs: [titleField.id, statusField.id],
            allowedRoleIDs: [manager.id]
        )
        let navigation = NavigationDefinition(
            items: [
                NavigationItemDefinition(
                    id: "nav.orders",
                    label: "Aufträge",
                    screenID: screen.id,
                    allowedRoleIDs: [manager.id]
                )
            ]
        )
        let project = makeProject(
            entities: [order],
            roles: [manager],
            stateMachines: [machine],
            screens: [screen],
            navigation: navigation
        )

        XCTAssertTrue(validator.validate(project).isEmpty)
    }

    func testInvalidWorkflowAndScreenReferencesAreReported() {
        let statusField = FieldDefinition(
            identity: DefinitionIdentity(id: "field.status", code: "status", label: "Status"),
            dataType: .enumeration,
            options: [FieldOptionDefinition(id: "option.open", value: "open", label: "Offen")]
        )
        let entity = EntityDefinition(
            identity: DefinitionIdentity(id: "entity.ticket", code: "ticket", label: "Ticket"),
            fields: [statusField]
        )
        let initial = BusinessStateDefinition(
            identity: DefinitionIdentity(id: "state.open", code: "open", label: "Offen"),
            isInitial: true
        )
        let transition = BusinessTransitionDefinition(
            identity: DefinitionIdentity(id: "transition.close", code: "close", label: "Schließen"),
            fromStateID: initial.id,
            toStateID: "state.missing",
            trigger: "close",
            allowedRoleIDs: ["role.missing"],
            guards: [.fieldIsSet(fieldID: "field.missing")]
        )
        let machine = BusinessStateMachineDefinition(
            identity: DefinitionIdentity(id: "machine.ticket", code: "ticketState", label: "Ticketstatus"),
            entityID: entity.id,
            stateFieldID: statusField.id,
            states: [initial],
            transitions: [transition]
        )
        let screen = ScreenDefinition(
            identity: DefinitionIdentity(id: "screen.ticket", code: "ticket", label: "Ticket"),
            kind: .detail,
            entityID: entity.id,
            visibleFieldIDs: ["field.missing"],
            allowedRoleIDs: ["role.missing"]
        )
        let navigation = NavigationDefinition(
            items: [
                NavigationItemDefinition(
                    id: "nav.missing",
                    label: "Fehlt",
                    screenID: "screen.missing",
                    allowedRoleIDs: ["role.missing"]
                )
            ]
        )

        let issues = validator.validate(
            makeProject(
                entities: [entity],
                stateMachines: [machine],
                screens: [screen],
                navigation: navigation
            )
        )

        XCTAssertTrue(
            issues.contains(.missingTransitionState(transitionID: transition.id, stateID: "state.missing"))
        )
        XCTAssertTrue(
            issues.contains(.missingTransitionRole(transitionID: transition.id, roleID: "role.missing"))
        )
        XCTAssertTrue(
            issues.contains(.missingWorkflowField(machineID: machine.id, fieldID: "field.missing"))
        )
        XCTAssertTrue(issues.contains(.missingScreenField(screenID: screen.id, fieldID: "field.missing")))
        XCTAssertTrue(issues.contains(.missingScreenRole(screenID: screen.id, roleID: "role.missing")))
        XCTAssertTrue(
            issues.contains(.missingNavigationScreen(itemID: "nav.missing", screenID: "screen.missing"))
        )
    }

    func testOfflineArchitectureCannotDisableSSOTOrRequiredOutbox() {
        var draft = ProjectSpecificationDraft(snapshot: makeProject())
        draft.offline = OfflineConfiguration(
            isEnabled: true,
            usesLocalSingleSourceOfTruth: false,
            usesSyncOutbox: false,
            syncsOnReconnect: true,
            conflictResolution: .manualReview
        )

        let issues = validator.validate(draft.snapshot())

        XCTAssertTrue(issues.contains(.offlineSingleSourceOfTruthRequired))
        XCTAssertTrue(issues.contains(.offlineSyncOutboxRequired))
    }

    func testCodecProducesStableBytesAndRoundTripsSpecification() throws {
        let field = FieldDefinition(
            identity: DefinitionIdentity(id: "field.name", code: "name", label: "Name"),
            dataType: .string
        )
        let project = makeProject(
            entities: [
                EntityDefinition(
                    identity: DefinitionIdentity(id: "entity.customer", code: "customer", label: "Kunde"),
                    fields: [field]
                )
            ]
        )
        let codec = ProjectSpecificationJSONCodec()

        let first = try codec.encode(project)
        let second = try codec.encode(project)
        let decoded = try codec.decode(first)

        XCTAssertEqual(first, second)
        XCTAssertEqual(decoded, project)
    }

    func testUnsupportedSchemaVersionIsRejected() {
        let project = makeProject(schemaVersion: 999)

        XCTAssertEqual(validator.validate(project), [.unsupportedSchemaVersion(999)])
    }

    private func makeProject(
        schemaVersion: Int = ProjectSpecification.currentSchemaVersion,
        entities: [EntityDefinition] = [],
        roles: [RoleDefinition] = [],
        stateMachines: [BusinessStateMachineDefinition] = [],
        screens: [ScreenDefinition] = [],
        navigation: NavigationDefinition = NavigationDefinition()
    ) -> ProjectSpecification {
        ProjectSpecification(
            schemaVersion: schemaVersion,
            identity: ProjectIdentity(name: "Business Test", organizationIdentifier: "de.example"),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: entities,
            roles: roles,
            stateMachines: stateMachines,
            screens: screens,
            navigation: navigation
        )
    }
}
