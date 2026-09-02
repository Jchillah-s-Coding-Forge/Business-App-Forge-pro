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
