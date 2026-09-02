import Foundation

public enum ProjectDefinitionKind: String, Equatable, Sendable {
    case entity
    case field
    case relation
    case role
    case stateMachine
    case state
    case transition
    case screen
}

public enum ProjectSpecificationValidationIssue: Equatable, Sendable {
    case unsupportedSchemaVersion(Int)
    case invalidStableID(kind: ProjectDefinitionKind, id: String)
    case invalidCode(kind: ProjectDefinitionKind, id: String, code: String)
    case emptyLabel(kind: ProjectDefinitionKind, id: String)
    case duplicateEntityID(String)
    case duplicateEntityCode(String)
    case duplicateFieldID(String)
    case duplicateFieldCode(entityID: String, code: String)
    case duplicateFieldOptionID(fieldID: String, optionID: String)
    case duplicateFieldOptionValue(fieldID: String, value: String)
    case enumerationOptionsRequired(fieldID: String)
    case invalidDefaultValue(fieldID: String)
    case invalidValidationRule(fieldID: String)
    case duplicateRelationID(String)
    case duplicateRelationCode(String)
    case missingSourceEntity(relationID: String, entityID: String)
    case missingTargetEntity(relationID: String, entityID: String)
    case manyToManyJoinEntityRequired(relationID: String)
    case missingJoinEntity(relationID: String, entityID: String)
    case joinEntityMustBeDistinct(relationID: String, entityID: String)
    case invalidDisplayField(relationID: String, fieldID: String)
    case duplicatePresentationID(String)
    case missingPresentationField(presentationID: String, fieldID: String)
    case missingPresentationRelation(presentationID: String, relationID: String)
    case incompatiblePresentation(
        presentationID: String,
        issues: [ControlCompatibilityIssue]
    )
    case duplicateRoleID(String)
    case duplicateRoleCode(String)
    case missingPermissionEntity(roleID: String, entityID: String)
    case duplicateStateMachineID(String)
    case duplicateStateMachineCode(String)
    case missingStateMachineEntity(machineID: String, entityID: String)
    case invalidStateField(machineID: String, fieldID: String)
    case stateFieldMustBeEnumeration(machineID: String, fieldID: String)
    case invalidInitialStateCount(machineID: String, count: Int)
    case duplicateStateID(machineID: String, stateID: String)
    case duplicateStateCode(machineID: String, code: String)
    case stateNotRepresentedInFieldOptions(machineID: String, stateID: String, value: String)
    case duplicateTransitionID(machineID: String, transitionID: String)
    case duplicateTransitionCode(machineID: String, code: String)
    case invalidTransitionTrigger(transitionID: String, trigger: String)
    case missingTransitionState(transitionID: String, stateID: String)
    case missingTransitionRole(transitionID: String, roleID: String)
    case missingWorkflowField(machineID: String, fieldID: String)
    case workflowFieldOutsideEntity(machineID: String, fieldID: String)
    case invalidWorkflowValue(machineID: String, fieldID: String)
    case duplicateScreenID(String)
    case duplicateScreenCode(String)
    case missingScreenEntity(screenID: String, entityID: String)
    case missingScreenField(screenID: String, fieldID: String)
    case screenFieldOutsideEntity(screenID: String, fieldID: String)
    case missingScreenRole(screenID: String, roleID: String)
    case duplicateNavigationItemID(String)
    case missingNavigationScreen(itemID: String, screenID: String)
    case missingNavigationRole(itemID: String, roleID: String)
    case offlineSingleSourceOfTruthRequired
    case offlineSyncOutboxRequired
    case invalidPrimaryColorHex(String)
}

public struct ProjectSpecificationValidationReport: Equatable, Sendable {
    public let issues: [ProjectSpecificationValidationIssue]

    public var isValid: Bool {
        issues.isEmpty
    }

    public init(issues: [ProjectSpecificationValidationIssue]) {
        self.issues = issues
    }
}

public struct ProjectSpecificationValidator: Sendable {
    private let controlValidator: ControlCompatibilityValidator

    public init(controlValidator: ControlCompatibilityValidator = ControlCompatibilityValidator()) {
        self.controlValidator = controlValidator
    }

    public func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        report(specification).issues
    }

    public func report(_ specification: ProjectSpecification) -> ProjectSpecificationValidationReport {
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

        return ProjectSpecificationValidationReport(issues: issues)
    }
}

private struct IdentityValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        issues += validateEntities(specification.entities)
        issues += validateRelations(specification.relations)
        issues += validateRoles(specification.roles)
        issues += validateStateMachines(specification.stateMachines)
        issues += validateScreens(specification.screens)
        issues += duplicatePresentationIssues(specification.fieldPresentations)
        return issues
    }

    private func validateEntities(_ entities: [EntityDefinition]) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        var ids = Set<String>()
        var codes = Set<String>()

        for entity in entities {
            issues += validateIdentity(entity.identity, kind: .entity)
            if !ids.insert(entity.id).inserted {
                issues.append(.duplicateEntityID(entity.id))
            }
            if !codes.insert(entity.identity.code).inserted {
                issues.append(.duplicateEntityCode(entity.identity.code))
            }
        }
        return issues
    }

    private func validateRelations(_ relations: [RelationDefinition]) -> [ProjectSpecificationValidationIssue] {
        duplicateIdentityIssues(
            relations,
            kind: .relation,
            duplicateID: ProjectSpecificationValidationIssue.duplicateRelationID,
            duplicateCode: ProjectSpecificationValidationIssue.duplicateRelationCode
        )
    }

    private func validateRoles(_ roles: [RoleDefinition]) -> [ProjectSpecificationValidationIssue] {
        duplicateIdentityIssues(
            roles,
            kind: .role,
            duplicateID: ProjectSpecificationValidationIssue.duplicateRoleID,
            duplicateCode: ProjectSpecificationValidationIssue.duplicateRoleCode
        )
    }

    private func validateStateMachines(
        _ machines: [BusinessStateMachineDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        duplicateIdentityIssues(
            machines,
            kind: .stateMachine,
            duplicateID: ProjectSpecificationValidationIssue.duplicateStateMachineID,
            duplicateCode: ProjectSpecificationValidationIssue.duplicateStateMachineCode
        )
    }

    private func validateScreens(_ screens: [ScreenDefinition]) -> [ProjectSpecificationValidationIssue] {
        duplicateIdentityIssues(
            screens,
            kind: .screen,
            duplicateID: ProjectSpecificationValidationIssue.duplicateScreenID,
            duplicateCode: ProjectSpecificationValidationIssue.duplicateScreenCode
        )
    }

    private func duplicatePresentationIssues(
        _ presentations: [FieldPresentationDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        duplicateValues(presentations.map(\.id)).map(
            ProjectSpecificationValidationIssue.duplicatePresentationID
        )
    }
}

private struct FieldValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        var globalFieldIDs = Set<String>()

        for entity in specification.entities {
            issues += validateFields(entity.fields, entityID: entity.id, globalIDs: &globalFieldIDs)
        }
        return issues
    }

    private func validateFields(
        _ fields: [FieldDefinition],
        entityID: String,
        globalIDs: inout Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        var codes = Set<String>()

        for field in fields {
            issues += validateIdentity(field.identity, kind: .field)
            if !globalIDs.insert(field.id).inserted {
                issues.append(.duplicateFieldID(field.id))
            }
            if !codes.insert(field.identity.code).inserted {
                issues.append(.duplicateFieldCode(entityID: entityID, code: field.identity.code))
            }
            issues += validateDefinition(field)
        }
        return issues
    }

    private func validateDefinition(_ field: FieldDefinition) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []

        if field.dataType == .enumeration, field.options.isEmpty {
            issues.append(.enumerationOptionsRequired(fieldID: field.id))
        }
        issues += validateOptions(field)

        if let defaultValue = field.defaultValue, !defaultValue.isCompatible(with: field) {
            issues.append(.invalidDefaultValue(fieldID: field.id))
        }
        if !field.validationRules.areCompatible(with: field.dataType) {
            issues.append(.invalidValidationRule(fieldID: field.id))
        }
        if !field.validationRules.haveCoherentBounds {
            issues.append(.invalidValidationRule(fieldID: field.id))
        }
        return issues
    }

    private func validateOptions(_ field: FieldDefinition) -> [ProjectSpecificationValidationIssue] {
        var issues = duplicateValues(field.options.map(\.id)).map {
            ProjectSpecificationValidationIssue.duplicateFieldOptionID(fieldID: field.id, optionID: $0)
        }
        issues += duplicateValues(field.options.map(\.value)).map {
            ProjectSpecificationValidationIssue.duplicateFieldOptionValue(fieldID: field.id, value: $0)
        }
        return issues
    }
}

private struct RelationValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let entities = entityMap(specification.entities)
        var issues: [ProjectSpecificationValidationIssue] = []

        for relation in specification.relations {
            issues += validateEndpoints(relation, entities: entities)
            issues += validateJoinEntity(relation, entities: entities)
            issues += validateDisplayField(relation, entities: entities)
        }
        return issues
    }

    private func validateEndpoints(
        _ relation: RelationDefinition,
        entities: [String: EntityDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        if entities[relation.sourceEntityID] == nil {
            issues.append(.missingSourceEntity(relationID: relation.id, entityID: relation.sourceEntityID))
        }
        if entities[relation.targetEntityID] == nil {
            issues.append(.missingTargetEntity(relationID: relation.id, entityID: relation.targetEntityID))
        }
        return issues
    }

    private func validateJoinEntity(
        _ relation: RelationDefinition,
        entities: [String: EntityDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        guard relation.cardinality == .manyToMany else { return [] }
        guard let joinEntityID = relation.joinEntityID else {
            return [.manyToManyJoinEntityRequired(relationID: relation.id)]
        }
        guard entities[joinEntityID] != nil else {
            return [.missingJoinEntity(relationID: relation.id, entityID: joinEntityID)]
        }
        if joinEntityID == relation.sourceEntityID || joinEntityID == relation.targetEntityID {
            return [.joinEntityMustBeDistinct(relationID: relation.id, entityID: joinEntityID)]
        }
        return []
    }

    private func validateDisplayField(
        _ relation: RelationDefinition,
        entities: [String: EntityDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        guard let displayFieldID = relation.displayFieldID else { return [] }
        let target = entities[relation.targetEntityID]
        guard target?.fields.contains(where: { $0.id == displayFieldID }) == true else {
            return [.invalidDisplayField(relationID: relation.id, fieldID: displayFieldID)]
        }
        return []
    }
}

private struct PresentationValidator {
    let controlValidator: ControlCompatibilityValidator

    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let fields = fieldMap(specification.entities)
        let relations = relationMap(specification.relations)
        var issues: [ProjectSpecificationValidationIssue] = []

        for presentation in specification.fieldPresentations {
            issues += validate(presentation, fields: fields, relations: relations)
        }
        return issues
    }

    private func validate(
        _ presentation: FieldPresentationDefinition,
        fields: [String: FieldDefinition],
        relations: [String: RelationDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        switch presentation.target {
        case let .field(fieldID):
            guard let field = fields[fieldID] else {
                return [.missingPresentationField(presentationID: presentation.id, fieldID: fieldID)]
            }
            return wrap(controlValidator.validate(presentation, field: field), id: presentation.id)
        case let .relation(relationID):
            guard let relation = relations[relationID] else {
                return [
                    .missingPresentationRelation(
                        presentationID: presentation.id,
                        relationID: relationID
                    )
                ]
            }
            return wrap(controlValidator.validate(presentation, relation: relation), id: presentation.id)
        }
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
        var issues: [ProjectSpecificationValidationIssue] = []
        let initialCount = machine.states.filter(\.isInitial).count
        if initialCount != 1 {
            issues.append(.invalidInitialStateCount(machineID: machine.id, count: initialCount))
        }
        issues += duplicateStateIssues(machine)
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
        var issues: [ProjectSpecificationValidationIssue] = []
        issues += validateIdentity(transition.identity, kind: .transition)
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

private struct ScreenNavigationValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let entities = entityMap(specification.entities)
        let fields = fieldMap(specification.entities)
        let roleIDs = Set(specification.roles.map(\.id))
        var issues: [ProjectSpecificationValidationIssue] = []

        for screen in specification.screens {
            issues += validateScreen(screen, entities: entities, fields: fields, roleIDs: roleIDs)
        }
        issues += validateNavigation(specification.navigation, screens: specification.screens, roleIDs: roleIDs)
        return issues
    }

    private func validateScreen(
        _ screen: ScreenDefinition,
        entities: [String: EntityDefinition],
        fields: [String: FieldDefinition],
        roleIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        let entity = screen.entityID.flatMap { entities[$0] }

        if let entityID = screen.entityID, entity == nil {
            issues.append(.missingScreenEntity(screenID: screen.id, entityID: entityID))
        }
        for fieldID in screen.visibleFieldIDs {
            issues += validateScreenField(screen, fieldID: fieldID, entity: entity, fields: fields)
        }
        for roleID in screen.allowedRoleIDs where !roleIDs.contains(roleID) {
            issues.append(.missingScreenRole(screenID: screen.id, roleID: roleID))
        }
        return issues
    }

    private func validateScreenField(
        _ screen: ScreenDefinition,
        fieldID: String,
        entity: EntityDefinition?,
        fields: [String: FieldDefinition]
    ) -> [ProjectSpecificationValidationIssue] {
        guard fields[fieldID] != nil else {
            return [.missingScreenField(screenID: screen.id, fieldID: fieldID)]
        }
        guard let entity else {
            return [.screenFieldOutsideEntity(screenID: screen.id, fieldID: fieldID)]
        }
        guard entity.fields.contains(where: { $0.id == fieldID }) else {
            return [.screenFieldOutsideEntity(screenID: screen.id, fieldID: fieldID)]
        }
        return []
    }

    private func validateNavigation(
        _ navigation: NavigationDefinition,
        screens: [ScreenDefinition],
        roleIDs: Set<String>
    ) -> [ProjectSpecificationValidationIssue] {
        let screenIDs = Set(screens.map(\.id))
        var issues = duplicateValues(navigation.items.map(\.id)).map(
            ProjectSpecificationValidationIssue.duplicateNavigationItemID
        )

        for item in navigation.items {
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
           !specification.offline.usesLocalSingleSourceOfTruth {
            issues.append(.offlineSingleSourceOfTruthRequired)
        }
        if specification.offline.isEnabled,
           specification.backend != .localOnly,
           !specification.offline.usesSyncOutbox {
            issues.append(.offlineSyncOutboxRequired)
        }
        if let color = specification.design.primaryColorHex, !color.isHexColor {
            issues.append(.invalidPrimaryColorHex(color))
        }
        return issues
    }
}

private struct WorkflowFieldReference {
    let fieldID: String
    let value: FieldDefaultValue?
}

private func validateIdentity(
    _ identity: DefinitionIdentity,
    kind: ProjectDefinitionKind
) -> [ProjectSpecificationValidationIssue] {
    var issues: [ProjectSpecificationValidationIssue] = []
    if !identity.id.isStableDefinitionID {
        issues.append(.invalidStableID(kind: kind, id: identity.id))
    }
    if !identity.code.isPortableCodeIdentifier {
        issues.append(.invalidCode(kind: kind, id: identity.id, code: identity.code))
    }
    if identity.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        issues.append(.emptyLabel(kind: kind, id: identity.id))
    }
    return issues
}

private func duplicateIdentityIssues<Value: Identifiable>(
    _ values: [Value],
    kind: ProjectDefinitionKind,
    duplicateID: (String) -> ProjectSpecificationValidationIssue,
    duplicateCode: (String) -> ProjectSpecificationValidationIssue
) -> [ProjectSpecificationValidationIssue] where Value.ID == String, Value: DefinitionIdentified {
    var issues: [ProjectSpecificationValidationIssue] = []
    var ids = Set<String>()
    var codes = Set<String>()

    for value in values {
        issues += validateIdentity(value.identity, kind: kind)
        if !ids.insert(value.id).inserted {
            issues.append(duplicateID(value.id))
        }
        if !codes.insert(value.identity.code).inserted {
            issues.append(duplicateCode(value.identity.code))
        }
    }
    return issues
}

private protocol DefinitionIdentified {
    var identity: DefinitionIdentity { get }
}

extension RelationDefinition: DefinitionIdentified {}
extension RoleDefinition: DefinitionIdentified {}
extension BusinessStateMachineDefinition: DefinitionIdentified {}
extension ScreenDefinition: DefinitionIdentified {}

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

private func duplicateValues(_ values: [String]) -> [String] {
    var seen = Set<String>()
    var duplicates = Set<String>()
    for value in values where !seen.insert(value).inserted {
        duplicates.insert(value)
    }
    return duplicates.sorted()
}

private extension FieldDefaultValue {
    func isCompatible(with field: FieldDefinition) -> Bool {
        switch (self, field.dataType) {
        case (.string, .string), (.string, .email), (.string, .phone), (.string, .url):
            true
        case (.string, .color), (.string, .location):
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

private extension Array where Element == FieldValidationRule {
    func areCompatible(with dataType: FieldDataType) -> Bool {
        allSatisfy { $0.isCompatible(with: dataType) }
    }

    var haveCoherentBounds: Bool {
        coherentLengthBounds && coherentNumericBounds
    }

    private var coherentLengthBounds: Bool {
        let minima = compactMap(\.minimumLengthValue)
        let maxima = compactMap(\.maximumLengthValue)
        guard let minimum = minima.max(), let maximum = maxima.min() else { return true }
        return minimum <= maximum
    }

    private var coherentNumericBounds: Bool {
        let minima = compactMap(\.minimumNumericValue)
        let maxima = compactMap(\.maximumNumericValue)
        guard let minimum = minima.max(), let maximum = maxima.min() else { return true }
        return minimum <= maximum
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

    var minimumLengthValue: Int? {
        guard case let .minimumLength(value) = self else { return nil }
        return value
    }

    var maximumLengthValue: Int? {
        guard case let .maximumLength(value) = self else { return nil }
        return value
    }

    var minimumNumericValue: Double? {
        guard case let .minimumValue(value) = self else { return nil }
        return value
    }

    var maximumNumericValue: Double? {
        guard case let .maximumValue(value) = self else { return nil }
        return value
    }
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

private extension String {
    var isStableDefinitionID: Bool {
        guard !isEmpty else { return false }
        return allSatisfy { character in
            character.isLetter || character.isNumber || "._-".contains(character)
        }
    }

    var isPortableCodeIdentifier: Bool {
        guard let first else { return false }
        guard first.isLetter || first == "_" else { return false }
        return allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    var isHexColor: Bool {
        let value = hasPrefix("#") ? String(dropFirst()) : self
        guard value.count == 6 || value.count == 8 else { return false }
        return value.allSatisfy(\.isHexDigit)
    }
}
