import Foundation

struct WorkflowValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let entities = entityMap(specification.entities)
        let fields = fieldMap(specification.entities)
        let roles = Set(specification.roles.map(\.id))
        var issues = validateRolePermissions(specification.roles, entities: entities)

        for machine in specification.stateMachines {
            issues += validateMachine(machine, entities: entities, fields: fields, roleIDs: roles)
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
                guard let entityID = permission.entityID, entities[entityID] == nil else { continue }
                issues.append(.missingPermissionEntity(roleID: role.id, entityID: entityID))
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
        guard let entity = entities[machine.entityID] else {
            return [.missingStateMachineEntity(machineID: machine.id, entityID: machine.entityID)]
        }

        var issues = validateStateField(machine, entity: entity, fields: fields)
        issues += validateStates(machine, stateField: fields[machine.stateFieldID])
        issues += validateTransitions(machine, entity: entity, fields: fields, roleIDs: roleIDs)
        return issues
    }

    private func validateStateField(
        _ machine: BusinessStateMachineDefinition,
        entity: EntityDefinition,
        fields: [String: FieldDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        guard entity.fields.contains(where: { $0.id == machine.stateFieldID }) else {
            return [.invalidStateField(machineID: machine.id, fieldID: machine.stateFieldID)]
        }
        guard fields[machine.stateFieldID]?.dataType == .enumeration else {
            return [.stateFieldMustBeEnumeration(machineID: machine.id, fieldID: machine.stateFieldID)]
        }
        return []
    }

    private func validateStates(
        _ machine: BusinessStateMachineDefinition,
        stateField: FieldDefinition?
    ) -> [ProjectSpecificationValidationIssue] {
        var issues = duplicateStateIssues(machine)
        let initialCount = machine.states.filter(\.isInitial).count

        if initialCount != 1 {
            issues.append(.invalidInitialStateCount(machineID: machine.id, count: initialCount))
        }
        for state in machine.states {
            issues += validateIdentity(state.identity, kind: .state)
        }

        guard let stateField, stateField.dataType == .enumeration else { return issues }
        for state in machine.states where !stateField.options.contains(where: { $0.value == state.identity.code }) {
            issues.append(
                .stateNotRepresentedInFieldOptions(
                    machineID: machine.id,
                    stateID: state.id,
                    value: state.identity.code
                )
            )
        }

        return issues
    }

    private func duplicateStateIssues(
        _ machine: BusinessStateMachineDefinition
    ) -> [ProjectSpecificationValidationIssue] {
        var issues = duplicateValues(machine.states.map(\.id)).map {
            ProjectSpecificationValidationIssue.duplicateStateID(machineID: machine.id, stateID: $0)
        }
        issues += duplicateValues(machine.states.map(\.identity.code)).map {
            ProjectSpecificationValidationIssue.duplicateStateCode(machineID: machine.id, code: $0)
        }
        return issues
    }

    private func validateTransitions(
        _ machine: BusinessStateMachineDefinition,
        entity: EntityDefinition,
        fields: [String: FieldDefinition],
        roleIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        var issues = duplicateTransitionIssues(machine)
        let stateIDs = Set(machine.states.map(\.id))
        let entityFieldIDs = Set(entity.fields.map(\.id))

        for transition in machine.transitions {
            issues += validateTransition(transition, stateIDs: stateIDs, roleIDs: roleIDs)
            issues += validateWorkflowFields(
                transition,
                machineID: machine.id,
                fields: fields,
                entityFieldIDs: entityFieldIDs
            )
        }

        return issues
    }

    private func duplicateTransitionIssues(
        _ machine: BusinessStateMachineDefinition
    ) -> [ProjectSpecificationValidationIssue] {
        var issues = duplicateValues(machine.transitions.map(\.id)).map {
            ProjectSpecificationValidationIssue.duplicateTransitionID(
                machineID: machine.id,
                transitionID: $0
            )
        }
        issues += duplicateValues(machine.transitions.map(\.identity.code)).map {
            ProjectSpecificationValidationIssue.duplicateTransitionCode(machineID: machine.id, code: $0)
        }
        return issues
    }

    private func validateTransition(
        _ transition: BusinessTransitionDefinition,
        stateIDs: Set<String>,
        roleIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        var issues = validateIdentity(transition.identity, kind: .transition)

        if !transition.trigger.isPortableCodeIdentifier {
            issues.append(.invalidTransitionTrigger(transitionID: transition.id, trigger: transition.trigger))
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
        var issues: [ProjectSpecificationValidationIssue] = []

        for reference in transition.guards.flatMap(\.fieldReferences) {
            issues += validateWorkflowReference(
                reference,
                machineID: machineID,
                fields: fields,
                entityFieldIDs: entityFieldIDs
            )
        }
        for reference in transition.sideEffects.compactMap(\.fieldAssignment) {
            issues += validateWorkflowReference(
                reference,
                machineID: machineID,
                fields: fields,
                entityFieldIDs: entityFieldIDs
            )
        }

        return issues
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

private struct WorkflowFieldReference {
    let fieldID: String
    let value: FieldDefaultValue?
}

private extension BusinessPredicate {
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

private extension BusinessSideEffect {
    var fieldAssignment: WorkflowFieldReference? {
        guard case let .setField(fieldID, value) = self else { return nil }
        return WorkflowFieldReference(fieldID: fieldID, value: value)
    }
}
