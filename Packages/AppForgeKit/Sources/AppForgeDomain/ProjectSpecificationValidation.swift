import Foundation

public enum ProjectSpecificationValidationIssue: Equatable, Sendable {
    case unsupportedSchemaVersion(Int)
    case duplicateEntityID(String)
    case duplicateEntityCode(String)
    case duplicateFieldID(String)
    case duplicateFieldCode(entityID: String, code: String)
    case duplicateFieldOptionValue(fieldID: String, value: String)
    case enumerationOptionsRequired(fieldID: String)
    case invalidDefaultValue(fieldID: String)
    case invalidValidationRule(fieldID: String)
    case missingSourceEntity(relationID: String, entityID: String)
    case missingTargetEntity(relationID: String, entityID: String)
    case manyToManyJoinEntityRequired(relationID: String)
    case missingJoinEntity(relationID: String, entityID: String)
    case invalidDisplayField(relationID: String, fieldID: String)
    case missingPresentationField(presentationID: String, fieldID: String)
    case missingPresentationRelation(presentationID: String, relationID: String)
    case incompatiblePresentation(
        presentationID: String,
        issues: [ControlCompatibilityIssue]
    )
    case duplicateRoleID(String)
    case missingPermissionEntity(roleID: String, entityID: String)
    case missingStateMachineEntity(machineID: String, entityID: String)
    case invalidStateField(machineID: String, fieldID: String)
    case invalidInitialStateCount(machineID: String, count: Int)
    case missingTransitionState(transitionID: String, stateID: String)
    case missingTransitionRole(transitionID: String, roleID: String)
    case missingWorkflowField(machineID: String, fieldID: String)
    case missingScreenEntity(screenID: String, entityID: String)
    case missingScreenField(screenID: String, fieldID: String)
    case missingScreenRole(screenID: String, roleID: String)
    case missingNavigationScreen(itemID: String, screenID: String)
    case missingNavigationRole(itemID: String, roleID: String)
    case offlineSingleSourceOfTruthRequired
    case offlineSyncOutboxRequired
    case invalidPrimaryColorHex(String)
}

public struct ProjectSpecificationValidator: Sendable {
    private let controlValidator: ControlCompatibilityValidator

    public init(controlValidator: ControlCompatibilityValidator = ControlCompatibilityValidator()) {
        self.controlValidator = controlValidator
    }

    public func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []

        if specification.schemaVersion != ProjectSpecification.currentSchemaVersion {
            issues.append(.unsupportedSchemaVersion(specification.schemaVersion))
        }

        issues += IdentityValidator().validate(specification)
        issues += FieldValidator().validate(specification)
        issues += RelationValidator().validate(specification)
        issues += PresentationValidator(controlValidator: controlValidator).validate(specification)
        issues += WorkflowValidator().validate(specification)
        issues += ScreenNavigationValidator().validate(specification)
        issues += ConfigurationValidator().validate(specification)

        return issues
    }
}

private struct IdentityValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        var entityIDs = Set<String>()
        var entityCodes = Set<String>()
        var roleIDs = Set<String>()

        for entity in specification.entities {
            if !entityIDs.insert(entity.id).inserted {
                issues.append(.duplicateEntityID(entity.id))
            }
            if !entityCodes.insert(entity.identity.code).inserted {
                issues.append(.duplicateEntityCode(entity.identity.code))
            }
        }

        for role in specification.roles where !roleIDs.insert(role.id).inserted {
            issues.append(.duplicateRoleID(role.id))
        }

        return issues
    }
}

private struct FieldValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        var globalFieldIDs = Set<String>()

        for entity in specification.entities {
            var fieldCodes = Set<String>()
            for field in entity.fields {
                if !globalFieldIDs.insert(field.id).inserted {
                    issues.append(.duplicateFieldID(field.id))
                }
                if !fieldCodes.insert(field.identity.code).inserted {
                    issues.append(
                        .duplicateFieldCode(entityID: entity.id, code: field.identity.code)
                    )
                }
                issues += validateDefinition(field)
            }
        }

        return issues
    }

    private func validateDefinition(_ field: FieldDefinition) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []

        if field.dataType == .enumeration, field.options.isEmpty {
            issues.append(.enumerationOptionsRequired(fieldID: field.id))
        }

        var optionValues = Set<String>()
        for option in field.options where !optionValues.insert(option.value).inserted {
            issues.append(.duplicateFieldOptionValue(fieldID: field.id, value: option.value))
        }

        if let defaultValue = field.defaultValue, !defaultValue.isCompatible(with: field) {
            issues.append(.invalidDefaultValue(fieldID: field.id))
        }
        if field.validationRules.contains(where: { !$0.isCompatible(with: field.dataType) }) {
            issues.append(.invalidValidationRule(fieldID: field.id))
        }

        return issues
    }
}

private struct RelationValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let entitiesByID = entityMap(specification.entities)
        var issues: [ProjectSpecificationValidationIssue] = []

        for relation in specification.relations {
            let target = entitiesByID[relation.targetEntityID]
            if entitiesByID[relation.sourceEntityID] == nil {
                issues.append(
                    .missingSourceEntity(relationID: relation.id, entityID: relation.sourceEntityID)
                )
            }
            if target == nil {
                issues.append(
                    .missingTargetEntity(relationID: relation.id, entityID: relation.targetEntityID)
                )
            }
            issues += validateJoinEntity(relation, entitiesByID: entitiesByID)
            issues += validateDisplayField(relation, target: target)
        }

        return issues
    }

    private func validateJoinEntity(
        _ relation: RelationDefinition,
        entitiesByID: [String: EntityDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        if relation.cardinality == .manyToMany, relation.joinEntityID == nil {
            return [.manyToManyJoinEntityRequired(relationID: relation.id)]
        }
        if let joinEntityID = relation.joinEntityID, entitiesByID[joinEntityID] == nil {
            return [.missingJoinEntity(relationID: relation.id, entityID: joinEntityID)]
        }
        return []
    }

    private func validateDisplayField(
        _ relation: RelationDefinition,
        target: EntityDefinition?
    ) -> [ProjectSpecificationValidationIssue] {
        guard let displayFieldID = relation.displayFieldID else { return [] }
        guard target?.fields.contains(where: { $0.id == displayFieldID }) == true else {
            return [.invalidDisplayField(relationID: relation.id, fieldID: displayFieldID)]
        }
        return []
    }
}

private struct PresentationValidator {
    let controlValidator: ControlCompatibilityValidator

    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let fieldsByID = fieldMap(specification.entities)
        let relationsByID = relationMap(specification.relations)
        var issues: [ProjectSpecificationValidationIssue] = []

        for presentation in specification.fieldPresentations {
            switch presentation.target {
            case let .field(fieldID):
                issues += validateFieldPresentation(
                    presentation,
                    fieldID: fieldID,
                    fieldsByID: fieldsByID
                )
            case let .relation(relationID):
                issues += validateRelationPresentation(
                    presentation,
                    relationID: relationID,
                    relationsByID: relationsByID
                )
            }
        }

        return issues
    }

    private func validateFieldPresentation(
        _ presentation: FieldPresentationDefinition,
        fieldID: String,
        fieldsByID: [String: FieldDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        guard let field = fieldsByID[fieldID] else {
            return [.missingPresentationField(presentationID: presentation.id, fieldID: fieldID)]
        }
        return wrap(controlValidator.validate(presentation, field: field), id: presentation.id)
    }

    private func validateRelationPresentation(
        _ presentation: FieldPresentationDefinition,
        relationID: String,
        relationsByID: [String: RelationDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        guard let relation = relationsByID[relationID] else {
            return [
                .missingPresentationRelation(
                    presentationID: presentation.id,
                    relationID: relationID
                )
            ]
        }
        return wrap(controlValidator.validate(presentation, relation: relation), id: presentation.id)
    }

    private func wrap(
        _ controlIssues: [ControlCompatibilityIssue],
        id: String
    ) -> [ProjectSpecificationValidationIssue] {
        guard !controlIssues.isEmpty else { return [] }
        return [.incompatiblePresentation(presentationID: id, issues: controlIssues)]
    }
}

private struct WorkflowValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let entitiesByID = entityMap(specification.entities)
        let fieldsByID = fieldMap(specification.entities)
        let roleIDs = Set(specification.roles.map(\.id))
        var issues = validateRolePermissions(specification.roles, entitiesByID: entitiesByID)

        for machine in specification.stateMachines {
            issues += validateMachine(
                machine,
                entitiesByID: entitiesByID,
                fieldsByID: fieldsByID,
                roleIDs: roleIDs
            )
        }

        return issues
    }

    private func validateRolePermissions(
        _ roles: [RoleDefinition],
        entitiesByID: [String: EntityDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        for role in roles {
            for permission in role.permissions {
                guard let entityID = permission.entityID else { continue }
                if entitiesByID[entityID] == nil {
                    issues.append(.missingPermissionEntity(roleID: role.id, entityID: entityID))
                }
            }
        }
        return issues
    }

    private func validateMachine(
        _ machine: BusinessStateMachineDefinition,
        entitiesByID: [String: EntityDefinition],
        fieldsByID: [String: FieldDefinition],
        roleIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        let entity = entitiesByID[machine.entityID]
        let stateIDs = Set(machine.states.map(\.id))
        let initialCount = machine.states.filter(\.isInitial).count

        if entity == nil {
            issues.append(.missingStateMachineEntity(machineID: machine.id, entityID: machine.entityID))
        }
        if entity?.fields.contains(where: { $0.id == machine.stateFieldID }) != true {
            issues.append(.invalidStateField(machineID: machine.id, fieldID: machine.stateFieldID))
        }
        if initialCount != 1 {
            issues.append(.invalidInitialStateCount(machineID: machine.id, count: initialCount))
        }

        for transition in machine.transitions {
            issues += validateTransition(transition, machineID: machine.id, stateIDs: stateIDs, roleIDs: roleIDs)
            issues += validateWorkflowReferences(transition, machineID: machine.id, fieldsByID: fieldsByID)
        }

        return issues
    }

    private func validateTransition(
        _ transition: BusinessTransitionDefinition,
        machineID _: String,
        stateIDs: Set<String>,
        roleIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        for stateID in [transition.fromStateID, transition.toStateID] where !stateIDs.contains(stateID) {
            issues.append(.missingTransitionState(transitionID: transition.id, stateID: stateID))
        }
        for roleID in transition.allowedRoleIDs where !roleIDs.contains(roleID) {
            issues.append(.missingTransitionRole(transitionID: transition.id, roleID: roleID))
        }
        return issues
    }

    private func validateWorkflowReferences(
        _ transition: BusinessTransitionDefinition,
        machineID: String,
        fieldsByID: [String: FieldDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        var referencedFieldIDs = transition.guards.flatMap(\.referencedFieldIDs)
        referencedFieldIDs += transition.sideEffects.compactMap(\.referencedFieldID)
        return referencedFieldIDs.compactMap { fieldID in
            guard fieldsByID[fieldID] == nil else { return nil }
            return .missingWorkflowField(machineID: machineID, fieldID: fieldID)
        }
    }
}

private struct ScreenNavigationValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let entitiesByID = entityMap(specification.entities)
        let fieldsByID = fieldMap(specification.entities)
        let roleIDs = Set(specification.roles.map(\.id))
        let screenIDs = Set(specification.screens.map(\.id))
        var issues: [ProjectSpecificationValidationIssue] = []

        for screen in specification.screens {
            if let entityID = screen.entityID, entitiesByID[entityID] == nil {
                issues.append(.missingScreenEntity(screenID: screen.id, entityID: entityID))
            }
            for fieldID in screen.visibleFieldIDs where fieldsByID[fieldID] == nil {
                issues.append(.missingScreenField(screenID: screen.id, fieldID: fieldID))
            }
            for roleID in screen.allowedRoleIDs where !roleIDs.contains(roleID) {
                issues.append(.missingScreenRole(screenID: screen.id, roleID: roleID))
            }
        }

        for item in specification.navigation.items {
            if !screenIDs.contains(item.screenID) {
                issues.append(.missingNavigationScreen(itemID: item.id, screenID: item.screenID))
            }
            for roleID in item.allowedRoleIDs where !roleIDs.contains(roleID) {
                issues.append(.missingNavigationRole(itemID: item.id, roleID: roleID))
            }
        }

        return issues
    }
}

private struct ConfigurationValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []

        if specification.offline.isEnabled,
           !specification.offline.usesLocalSingleSourceOfTruth
        {
            issues.append(.offlineSingleSourceOfTruthRequired)
        }
        if specification.offline.isEnabled,
           specification.backend != .localOnly,
           !specification.offline.usesSyncOutbox
        {
            issues.append(.offlineSyncOutboxRequired)
        }
        if let color = specification.design.primaryColorHex, !color.isHexColor {
            issues.append(.invalidPrimaryColorHex(color))
        }

        return issues
    }
}

private func entityMap(_ entities: [EntityDefinition]) -> [String: EntityDefinition] {
    uniqueMap(entities, id: \.id)
}

private func fieldMap(_ entities: [EntityDefinition]) -> [String: FieldDefinition] {
    uniqueMap(entities.flatMap(\.fields), id: \.id)
}

private func relationMap(_ relations: [RelationDefinition]) -> [String: RelationDefinition] {
    uniqueMap(relations, id: \.id)
}

private func uniqueMap<Value>(
    _ values: [Value],
    id: KeyPath<Value, String>
) -> [String: Value] {
    var result: [String: Value] = [:]
    for value in values where result[value[keyPath: id]] == nil {
        result[value[keyPath: id]] = value
    }
    return result
}

private extension FieldDefaultValue {
    func isCompatible(with field: FieldDefinition) -> Bool {
        switch (self, field.dataType) {
        case (.string, .string), (.string, .email), (.string, .phone), (.string, .url),
             (.string, .color), (.string, .location):
            true
        case (.integer, .integer):
            true
        case (.integer, .decimal), (.integer, .currency), (.integer, .percentage):
            true
        case (.decimal, .decimal), (.decimal, .currency), (.decimal, .percentage):
            true
        case (.boolean, .boolean):
            true
        case (.date, .date), (.dateTime, .dateTime), (.time, .time):
            true
        case let (.option(value), .enumeration):
            field.options.contains(where: { $0.value == value })
        default:
            false
        }
    }
}

private extension FieldValidationRule {
    func isCompatible(with dataType: FieldDataType) -> Bool {
        switch self {
        case .minimumLength, .maximumLength, .pattern:
            [.string, .email, .phone, .url, .location].contains(dataType)
        case .minimumValue, .maximumValue:
            [.integer, .decimal, .currency, .percentage].contains(dataType)
        }
    }
}

private extension BusinessPredicate {
    var referencedFieldIDs: [String] {
        switch self {
        case let .fieldEquals(fieldID, _), let .fieldIsSet(fieldID):
            [fieldID]
        case let .all(predicates), let .any(predicates):
            predicates.flatMap(\.referencedFieldIDs)
        case let .not(predicate):
            predicate.referencedFieldIDs
        }
    }
}

private extension BusinessSideEffect {
    var referencedFieldID: String? {
        switch self {
        case let .setField(fieldID, _):
            fieldID
        case .appendAuditEntry, .enqueueNotification:
            nil
        }
    }
}

private extension String {
    var isHexColor: Bool {
        let value = hasPrefix("#") ? String(dropFirst()) : self
        guard value.count == 6 || value.count == 8 else { return false }
        return value.allSatisfy(\.isHexDigit)
    }
}
