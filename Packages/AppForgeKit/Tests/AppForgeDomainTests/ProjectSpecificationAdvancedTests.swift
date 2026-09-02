import AppForgeDomain
import XCTest

final class ProjectSpecificationAdvancedTests: XCTestCase {
    private let validator = ProjectSpecificationValidator()

    func testCompleteBusinessWorkflowSpecificationIsValid() {
        let fixture = makeValidOrderWorkflow()
        let project = makeProject(
            entities: [fixture.entity],
            roles: [fixture.role],
            stateMachines: [fixture.machine],
            screens: [fixture.screen],
            navigation: fixture.navigation
        )

        XCTAssertTrue(validator.validate(project).isEmpty)
    }

    func testInvalidWorkflowAndScreenReferencesAreReported() {
        let fixture = makeInvalidTicketWorkflow()
        let issues = validator.validate(
            makeProject(
                entities: [fixture.entity],
                stateMachines: [fixture.machine],
                screens: [fixture.screen],
                navigation: fixture.navigation
            )
        )

        XCTAssertTrue(
            issues.contains(
                .missingTransitionState(
                    transitionID: fixture.transitionID,
                    stateID: "state.missing"
                )
            )
        )
        XCTAssertTrue(
            issues.contains(
                .missingTransitionRole(
                    transitionID: fixture.transitionID,
                    roleID: "role.missing"
                )
            )
        )
        XCTAssertTrue(
            issues.contains(.missingWorkflowField(machineID: fixture.machine.id, fieldID: "field.missing"))
        )
        XCTAssertTrue(
            issues.contains(.missingScreenField(screenID: fixture.screen.id, fieldID: "field.missing"))
        )
        XCTAssertTrue(issues.contains(.missingScreenRole(screenID: fixture.screen.id, roleID: "role.missing")))
    }

    func testWorkflowCannotReferenceFieldFromAnotherEntity() {
        let orderStatus = enumerationField(id: "field.order.status", code: "status", options: ["draft"])
        let customerName = FieldDefinition(
            identity: DefinitionIdentity(id: "field.customer.name", code: "name", label: "Name"),
            dataType: .string
        )
        let order = entity(id: "entity.order", code: "order", fields: [orderStatus])
        let customer = entity(id: "entity.customer", code: "customer", fields: [customerName])
        let state = BusinessStateDefinition(
            identity: DefinitionIdentity(id: "state.draft", code: "draft", label: "Entwurf"),
            isInitial: true
        )
        let transition = BusinessTransitionDefinition(
            identity: DefinitionIdentity(id: "transition.keep", code: "keep", label: "Beibehalten"),
            fromStateID: state.id,
            toStateID: state.id,
            trigger: "keep",
            guards: [.fieldIsSet(fieldID: customerName.id)]
        )
        let machine = stateMachine(entity: order, stateField: orderStatus, states: [state], transitions: [transition])

        let issues = validator.validate(makeProject(entities: [order, customer], stateMachines: [machine]))

        XCTAssertTrue(
            issues.contains(.workflowFieldOutsideEntity(machineID: machine.id, fieldID: customerName.id))
        )
    }

    func testStateMachineRequiresEnumerationStateFieldAndMatchingOptions() {
        let status = enumerationField(id: "field.status", code: "status", options: ["draft"])
        let order = entity(id: "entity.order", code: "order", fields: [status])
        let draft = BusinessStateDefinition(
            identity: DefinitionIdentity(id: "state.draft", code: "draft", label: "Entwurf"),
            isInitial: true
        )
        let approved = BusinessStateDefinition(
            identity: DefinitionIdentity(id: "state.approved", code: "approved", label: "Freigegeben")
        )
        let machine = stateMachine(entity: order, stateField: status, states: [draft, approved])

        let issues = validator.validate(makeProject(entities: [order], stateMachines: [machine]))

        XCTAssertTrue(
            issues.contains(
                .stateNotRepresentedInFieldOptions(
                    machineID: machine.id,
                    stateID: approved.id,
                    value: "approved"
                )
            )
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
            entities: [entity(id: "entity.customer", code: "customer", fields: [field])]
        )
        let codec = ProjectSpecificationJSONCodec()

        let first = try codec.encode(project)
        let second = try codec.encode(project)
        let decoded = try codec.decode(first)

        XCTAssertEqual(first, second)
        XCTAssertEqual(decoded, project)
    }

    func testUnsupportedSchemaVersionIsRejected() {
        XCTAssertEqual(
            validator.validate(makeProject(schemaVersion: 999)),
            [.unsupportedSchemaVersion(999)]
        )
    }

    private func makeValidOrderWorkflow() -> WorkflowFixture {
        let status = enumerationField(
            id: "field.order.status",
            code: "status",
            options: ["draft", "approved"]
        )
        let title = FieldDefinition(
            identity: DefinitionIdentity(id: "field.order.title", code: "title", label: "Titel"),
            dataType: .string,
            isRequired: true
        )
        let order = entity(id: "entity.order", code: "order", fields: [status, title])
        let manager = RoleDefinition(
            identity: DefinitionIdentity(id: "role.manager", code: "manager", label: "Manager"),
            permissions: [BusinessPermissionDefinition(action: .manage, entityID: order.id)]
        )
        let draft = state(id: "state.draft", code: "draft", label: "Entwurf", isInitial: true)
        let approved = state(id: "state.approved", code: "approved", label: "Freigegeben")
        let transition = BusinessTransitionDefinition(
            identity: DefinitionIdentity(id: "transition.approve", code: "approve", label: "Freigeben"),
            fromStateID: draft.id,
            toStateID: approved.id,
            trigger: "approve",
            allowedRoleIDs: [manager.id],
            guards: [.fieldIsSet(fieldID: title.id)],
            sideEffects: [.setField(fieldID: status.id, value: .option("approved"))],
            requiresAudit: true
        )
        let machine = stateMachine(
            entity: order,
            stateField: status,
            states: [draft, approved],
            transitions: [transition]
        )
        let screen = ScreenDefinition(
            identity: DefinitionIdentity(id: "screen.orders", code: "orders", label: "Aufträge"),
            kind: .list,
            entityID: order.id,
            visibleFieldIDs: [title.id, status.id],
            allowedRoleIDs: [manager.id]
        )
        return WorkflowFixture(
            entity: order,
            role: manager,
            machine: machine,
            screen: screen,
            navigation: navigation(to: screen, roles: [manager.id]),
            transitionID: transition.id
        )
    }

    private func makeInvalidTicketWorkflow() -> WorkflowFixture {
        let status = enumerationField(id: "field.status", code: "status", options: ["open"])
        let ticket = entity(id: "entity.ticket", code: "ticket", fields: [status])
        let open = state(id: "state.open", code: "open", label: "Offen", isInitial: true)
        let transition = BusinessTransitionDefinition(
            identity: DefinitionIdentity(id: "transition.close", code: "close", label: "Schließen"),
            fromStateID: open.id,
            toStateID: "state.missing",
            trigger: "close",
            allowedRoleIDs: ["role.missing"],
            guards: [.fieldIsSet(fieldID: "field.missing")]
        )
        let machine = stateMachine(
            entity: ticket,
            stateField: status,
            states: [open],
            transitions: [transition]
        )
        let screen = ScreenDefinition(
            identity: DefinitionIdentity(id: "screen.ticket", code: "ticket", label: "Ticket"),
            kind: .detail,
            entityID: ticket.id,
            visibleFieldIDs: ["field.missing"],
            allowedRoleIDs: ["role.missing"]
        )
        return WorkflowFixture(
            entity: ticket,
            role: RoleDefinition(
                identity: DefinitionIdentity(id: "role.placeholder", code: "placeholder", label: "Placeholder")
            ),
            machine: machine,
            screen: screen,
            navigation: NavigationDefinition(
                items: [
                    NavigationItemDefinition(
                        id: "nav.missing",
                        label: "Fehlt",
                        screenID: "screen.missing",
                        allowedRoleIDs: ["role.missing"]
                    )
                ]
            ),
            transitionID: transition.id
        )
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

    private func enumerationField(id: String, code: String, options: [String]) -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(id: id, code: code, label: "Status"),
            dataType: .enumeration,
            defaultValue: options.first.map(FieldDefaultValue.option),
            options: options.map {
                FieldOptionDefinition(id: "option.\($0)", value: $0, label: $0)
            }
        )
    }

    private func entity(id: String, code: String, fields: [FieldDefinition]) -> EntityDefinition {
        EntityDefinition(
            identity: DefinitionIdentity(id: id, code: code, label: code.capitalized),
            fields: fields
        )
    }

    private func state(
        id: String,
        code: String,
        label: String,
        isInitial: Bool = false
    ) -> BusinessStateDefinition {
        BusinessStateDefinition(
            identity: DefinitionIdentity(id: id, code: code, label: label),
            isInitial: isInitial
        )
    }

    private func stateMachine(
        entity: EntityDefinition,
        stateField: FieldDefinition,
        states: [BusinessStateDefinition],
        transitions: [BusinessTransitionDefinition] = []
    ) -> BusinessStateMachineDefinition {
        BusinessStateMachineDefinition(
            identity: DefinitionIdentity(id: "machine.\(entity.id)", code: "statusFlow", label: "Status"),
            entityID: entity.id,
            stateFieldID: stateField.id,
            states: states,
            transitions: transitions
        )
    }

    private func navigation(to screen: ScreenDefinition, roles: Set<String>) -> NavigationDefinition {
        NavigationDefinition(
            items: [
                NavigationItemDefinition(
                    id: "nav.\(screen.id)",
                    label: screen.identity.label,
                    screenID: screen.id,
                    allowedRoleIDs: roles
                )
            ]
        )
    }
}

private struct WorkflowFixture {
    let entity: EntityDefinition
    let role: RoleDefinition
    let machine: BusinessStateMachineDefinition
    let screen: ScreenDefinition
    let navigation: NavigationDefinition
    let transitionID: String
}
