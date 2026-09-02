import Foundation

struct ProjectWorkflowValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let entities = entityMap(specification.entities)
        let fields = fieldMap(specification.entities)
        let roleIDs = Set(specification.roles.map(\.id))
        var issues = validateRolePermissions(specification.roles, entities: entities)

        for machine in specification.stateMachines {
            issues += validateMachine(
                machine,
                entities: entities,
                fields: fields,
                roleIDs: roleIDs
            )
        }
        return issues
    }

    private func validateRolePermissions(
        _ roles: [RoleDefinition],
        entities: [String: EntityDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []

        for role in roles {
            for permission in role.permissions {
                guard let entityID = permission.entityID else { continue }
                if entities[entityID] == nil {
                    issues.append(.missingPermissionEntity(roleID: role.id, entityID: entityID))
                }
            }
        }
        return issues
    }

    private func validateMachine(
        _ machine: BusinessStateMachineDefinition,
        entities: [String: EntityDefinition],
        fields: [String: FieldDefinition],
        roleIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        var issues = validateStateIdentities(machine)
        issues += validateTransitionIdentities(machine)

        guard let entity = entities[machine.entityID] else {
            issues.append(
                .missingStateMachineEntity(
                    machineID: machine.id,
                    entityID: machine.entityID
                )
            )
            return issues
        }

        let stateField = entity.fields.first(where: { $0.id == machine.stateFieldID })
        issues += validateStateField(machine, stateField: stateField)
        issues += validateStates(machine, stateField: stateField)
        issues += validateTransitions(
            machine,
            entity: entity,
            fields: fields,
            roleIDs: roleIDs
        )
        return issues
    }

    private func validateStateField(
        _ machine: BusinessStateMachineDefinition,
        stateField: FieldDefinition?
    ) -> [ProjectSpecificationValidationIssue] {
        guard let stateField else {
            return [.invalidStateField(machineID: machine.id, fieldID: machine.stateFieldID)]
        }
        guard stateField.dataType == .enumeration else {
            return [
                .stateFieldMustBeEnumeration(
                    machineID: machine.id,
                    fieldID: stateField.id
                )
            ]
        }
        return []
    }

    private func validateStates(
        _ machine: BusinessStateMachineDefinition,
        stateField: FieldDefinition?
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        let initialCount = machine.states.filter(\.isInitial).count

        if initialCount != 1 {
            issues.append(.invalidInitialStateCount(machineID: machine.id, count: initialCount))
        }
        guard let stateField, stateField.dataType == .enumeration else {
            return issues
        }

        for state in machine.states {
            let isRepresented = stateField.options.contains { option in
                option.value == state.identity.code
            }
            if !isRepresented {
                issues.append(
                    .stateNotRepresentedInFieldOptions(
                        machineID: machine.id,
                        stateID: state.id,
                        value: state.identity.code
                    )
                )
            }
        }
        return issues
    }

    private func validateStateIdentities(
        _ machine: BusinessStateMachineDefinition
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []

        for state in machine.states {
            issues += validateDefinitionIdentity(state.identity, kind: .state)
        }
        issues += duplicateValues(machine.states.map(\.id)).map {
            .duplicateStateID(machineID: machine.id, stateID: $0)
        }
        issues += duplicateValues(machine.states.map(\.identity.code)).map {
            .duplicateStateCode(machineID: machine.id, code: $0)
        }
        return issues
    }

    private func validateTransitionIdentities(
        _ machine: BusinessStateMachineDefinition
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []

        for transition in machine.transitions {
            issues += validateDefinitionIdentity(transition.identity, kind: .transition)
        }
        issues += duplicateValues(machine.transitions.map(\.id)).map {
            .duplicateTransitionID(machineID: machine.id, transitionID: $0)
        }
        issues += duplicateValues(machine.transitions.map(\.identity.code)).map {
            .duplicateTransitionCode(machineID: machine.id, code: $0)
        }
        return issues
    }

    private func validateTransitions(
        _ machine: BusinessStateMachineDefinition,
        entity: EntityDefinition,
        fields: [String: FieldDefinition],
        roleIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        let stateIDs = Set(machine.states.map(\.id))
        let entityFieldIDs = Set(entity.fields.map(\.id))
        var issues: [ProjectSpecificationValidationIssue] = []

        for transition in machine.transitions {
            issues += validateTransitionReferences(
                transition,
                stateIDs: stateIDs,
                roleIDs: roleIDs
            )
            issues += validateWorkflowFields(
                transition,
                machineID: machine.id,
                fields: fields,
                entityFieldIDs: entityFieldIDs
            )
        }
        return issues
    }

    private func validateTransitionReferences(
        _ transition: BusinessTransitionDefinition,
        stateIDs: Set<String>,
        roleIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []

        if !transition.trigger.isPortableCodeIdentifier {
            issues.append(
                .invalidTransitionTrigger(
                    transitionID: transition.id,
                    trigger: transition.trigger
                )
            )
        }
        for stateID in [transition.fromStateID, transition.toStateID] where !stateIDs.contains(stateID) {
            issues.append(.missingTransitionState(transitionID: transition.id, stateID: stateID))
        }
        for roleID in transition.allowedRoleIDs where !roleIDs.contains(roleID) {
            issues.append(.missingTransitionRole(transitionID: transition.id, roleID: roleID))
        }
        return issues
    }

    private func validateWorkflowFields(
        _ transition: BusinessTransitionDefinition,
        machineID: String,
        fields: [String: FieldDefinition],
        entityFieldIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        var references = transition.guards.flatMap(\.fieldReferences)
        references += transition.sideEffects.compactMap(\.fieldAssignment)

        return references.flatMap { reference in
            validateWorkflowReference(
                reference,
                machineID: machineID,
                fields: fields,
                entityFieldIDs: entityFieldIDs
            )
        }
    }

    private func validateWorkflowReference(
        _ reference: WorkflowFieldReference,
        machineID: String,
        fields: [String: FieldDefinition],
        entityFieldIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        guard let field = fields[reference.fieldID] else {
            return [.missingWorkflowField(machineID: machineID, fieldID: reference.fieldID)]
        }
        guard entityFieldIDs.contains(reference.fieldID) else {
            return [.workflowFieldOutsideEntity(machineID: machineID, fieldID: reference.fieldID)]
        }
        if let value = reference.value, !value.isCompatible(with: field) {
            return [.invalidWorkflowValue(machineID: machineID, fieldID: reference.fieldID)]
        }
        return []
    }
}

struct WorkflowFieldReference {
    let fieldID: String
    let value: FieldDefaultValue?
}

extension BusinessPredicate {
    var fieldReferences: [WorkflowFieldReference] {
        switch self {
        case let .fieldEquals(fieldID, value):
            [WorkflowFieldReference(fieldID: fieldID, value: value)]
        case let .fieldIsSet(fieldID):
            [WorkflowFieldReference(fieldID: fieldID, value: nil)]
        case let .all(predicates), let .any(predicates):
            predicates.flatMap(\.fieldReferences)
        case let .not(predicate):
            predicate.fieldReferences
        }
    }
}

extension BusinessSideEffect {
    var fieldAssignment: WorkflowFieldReference? {
        guard case let .setField(fieldID, value) = self else { return nil }
        return WorkflowFieldReference(fieldID: fieldID, value: value)
    }
}
