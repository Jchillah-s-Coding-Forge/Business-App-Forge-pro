import Foundation

struct IdentityValidator {
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

struct FieldValidator {
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

struct RelationValidator {
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

struct PresentationValidator {
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
