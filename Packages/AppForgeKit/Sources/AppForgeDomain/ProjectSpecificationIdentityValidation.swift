import Foundation

struct ProjectIdentityValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        issues += validateEntities(specification.entities)
        issues += duplicateIdentityIssues(
            specification.relations,
            kind: .relation,
            duplicateID: ProjectSpecificationValidationIssue.duplicateRelationID,
            duplicateCode: ProjectSpecificationValidationIssue.duplicateRelationCode
        )
        issues += duplicateIdentityIssues(
            specification.roles,
            kind: .role,
            duplicateID: ProjectSpecificationValidationIssue.duplicateRoleID,
            duplicateCode: ProjectSpecificationValidationIssue.duplicateRoleCode
        )
        issues += duplicateIdentityIssues(
            specification.stateMachines,
            kind: .stateMachine,
            duplicateID: ProjectSpecificationValidationIssue.duplicateStateMachineID,
            duplicateCode: ProjectSpecificationValidationIssue.duplicateStateMachineCode
        )
        issues += duplicateIdentityIssues(
            specification.screens,
            kind: .screen,
            duplicateID: ProjectSpecificationValidationIssue.duplicateScreenID,
            duplicateCode: ProjectSpecificationValidationIssue.duplicateScreenCode
        )
        issues += duplicateValues(specification.fieldPresentations.map(\.id)).map(
            ProjectSpecificationValidationIssue.duplicatePresentationID
        )
        return issues
    }

    private func validateEntities(_ entities: [EntityDefinition]) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        var ids = Set<String>()
        var codes = Set<String>()

        for entity in entities {
            issues += validateDefinitionIdentity(entity.identity, kind: .entity)
            if !ids.insert(entity.id).inserted {
                issues.append(.duplicateEntityID(entity.id))
            }
            if !codes.insert(entity.identity.code).inserted {
                issues.append(.duplicateEntityCode(entity.identity.code))
            }
        }
        return issues
    }
}

func validateDefinitionIdentity(
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

func duplicateIdentityIssues<Value: DefinitionIdentified & Identifiable>(
    _ values: [Value],
    kind: ProjectDefinitionKind,
    duplicateID: (String) -> ProjectSpecificationValidationIssue,
    duplicateCode: (String) -> ProjectSpecificationValidationIssue
) -> [ProjectSpecificationValidationIssue] where Value.ID == String {
    var issues: [ProjectSpecificationValidationIssue] = []
    var ids = Set<String>()
    var codes = Set<String>()

    for value in values {
        issues += validateDefinitionIdentity(value.identity, kind: kind)
        if !ids.insert(value.id).inserted {
            issues.append(duplicateID(value.id))
        }
        if !codes.insert(value.identity.code).inserted {
            issues.append(duplicateCode(value.identity.code))
        }
    }
    return issues
}

extension String {
    var isStableDefinitionID: Bool {
        range(of: "^[A-Za-z0-9._-]+$", options: .regularExpression) != nil
    }

    var isPortableCodeIdentifier: Bool {
        range(of: "^[A-Za-z_][A-Za-z0-9_]*$", options: .regularExpression) != nil
    }
}
