import Foundation

public enum ProjectSpecificationValidationIssue: Equatable, Sendable {
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
}

public struct ProjectSpecificationValidator: Sendable {
    private let controlValidator: ControlCompatibilityValidator

    public init(controlValidator: ControlCompatibilityValidator = ControlCompatibilityValidator()) {
        self.controlValidator = controlValidator
    }

    public func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        let entitiesByID = Dictionary(uniqueKeysWithValues: uniqueEntities(specification.entities))
        let fieldsByID = allFieldsByID(specification.entities)
        let relationsByID = Dictionary(uniqueKeysWithValues: uniqueRelations(specification.relations))

        validateEntityIdentity(specification.entities, issues: &issues)
        validateFields(specification.entities, issues: &issues)
        validateRelations(
            specification.relations,
            entitiesByID: entitiesByID,
            issues: &issues
        )
        validatePresentations(
            specification.fieldPresentations,
            fieldsByID: fieldsByID,
            relationsByID: relationsByID,
            issues: &issues
        )

        return issues
    }

    private func validateEntityIdentity(
        _ entities: [EntityDefinition],
        issues: inout [ProjectSpecificationValidationIssue]
    ) {
        var ids = Set<String>()
        var codes = Set<String>()

        for entity in entities {
            if !ids.insert(entity.id).inserted {
                issues.append(.duplicateEntityID(entity.id))
            }
            if !codes.insert(entity.identity.code).inserted {
                issues.append(.duplicateEntityCode(entity.identity.code))
            }
        }
    }

    private func validateFields(
        _ entities: [EntityDefinition],
        issues: inout [ProjectSpecificationValidationIssue]
    ) {
        var globalFieldIDs = Set<String>()

        for entity in entities {
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

                validateFieldDefinition(field, issues: &issues)
            }
        }
    }

    private func validateFieldDefinition(
        _ field: FieldDefinition,
        issues: inout [ProjectSpecificationValidationIssue]
    ) {
        if field.dataType == .enumeration, field.options.isEmpty {
            issues.append(.enumerationOptionsRequired(fieldID: field.id))
        }

        var optionValues = Set<String>()
        for option in field.options where !optionValues.insert(option.value).inserted {
            issues.append(.duplicateFieldOptionValue(fieldID: field.id, value: option.value))
        }

        if let defaultValue = field.defaultValue,
           !defaultValue.isCompatible(with: field)
        {
            issues.append(.invalidDefaultValue(fieldID: field.id))
        }

        if field.validationRules.contains(where: { !$0.isCompatible(with: field.dataType) }) {
            issues.append(.invalidValidationRule(fieldID: field.id))
        }
    }

    private func validateRelations(
        _ relations: [RelationDefinition],
        entitiesByID: [String: EntityDefinition],
        issues: inout [ProjectSpecificationValidationIssue]
    ) {
        for relation in relations {
            let source = entitiesByID[relation.sourceEntityID]
            let target = entitiesByID[relation.targetEntityID]

            if source == nil {
                issues.append(
                    .missingSourceEntity(relationID: relation.id, entityID: relation.sourceEntityID)
                )
            }
            if target == nil {
                issues.append(
                    .missingTargetEntity(relationID: relation.id, entityID: relation.targetEntityID)
                )
            }

            validateJoinEntity(relation, entitiesByID: entitiesByID, issues: &issues)
            validateDisplayField(relation, target: target, issues: &issues)
        }
    }

    private func validateJoinEntity(
        _ relation: RelationDefinition,
        entitiesByID: [String: EntityDefinition],
        issues: inout [ProjectSpecificationValidationIssue]
    ) {
        if relation.cardinality == .manyToMany, relation.joinEntityID == nil {
            issues.append(.manyToManyJoinEntityRequired(relationID: relation.id))
        }

        if let joinEntityID = relation.joinEntityID, entitiesByID[joinEntityID] == nil {
            issues.append(.missingJoinEntity(relationID: relation.id, entityID: joinEntityID))
        }
    }

    private func validateDisplayField(
        _ relation: RelationDefinition,
        target: EntityDefinition?,
        issues: inout [ProjectSpecificationValidationIssue]
    ) {
        guard let displayFieldID = relation.displayFieldID else { return }
        guard target?.fields.contains(where: { $0.id == displayFieldID }) == true else {
            issues.append(.invalidDisplayField(relationID: relation.id, fieldID: displayFieldID))
            return
        }
    }

    private func validatePresentations(
        _ presentations: [FieldPresentationDefinition],
        fieldsByID: [String: FieldDefinition],
        relationsByID: [String: RelationDefinition],
        issues: inout [ProjectSpecificationValidationIssue]
    ) {
        for presentation in presentations {
            switch presentation.target {
            case let .field(fieldID):
                guard let field = fieldsByID[fieldID] else {
                    issues.append(
                        .missingPresentationField(presentationID: presentation.id, fieldID: fieldID)
                    )
                    continue
                }
                appendControlIssues(
                    controlValidator.validate(presentation, field: field),
                    presentationID: presentation.id,
                    issues: &issues
                )
            case let .relation(relationID):
                guard let relation = relationsByID[relationID] else {
                    issues.append(
                        .missingPresentationRelation(
                            presentationID: presentation.id,
                            relationID: relationID
                        )
                    )
                    continue
                }
                appendControlIssues(
                    controlValidator.validate(presentation, relation: relation),
                    presentationID: presentation.id,
                    issues: &issues
                )
            }
        }
    }

    private func appendControlIssues(
        _ controlIssues: [ControlCompatibilityIssue],
        presentationID: String,
        issues: inout [ProjectSpecificationValidationIssue]
    ) {
        guard !controlIssues.isEmpty else { return }
        issues.append(
            .incompatiblePresentation(
                presentationID: presentationID,
                issues: controlIssues
            )
        )
    }

    private func uniqueEntities(_ entities: [EntityDefinition]) -> [(String, EntityDefinition)] {
        var seen = Set<String>()
        return entities.compactMap { entity in
            guard seen.insert(entity.id).inserted else { return nil }
            return (entity.id, entity)
        }
    }

    private func uniqueRelations(_ relations: [RelationDefinition]) -> [(String, RelationDefinition)] {
        var seen = Set<String>()
        return relations.compactMap { relation in
            guard seen.insert(relation.id).inserted else { return nil }
            return (relation.id, relation)
        }
    }

    private func allFieldsByID(_ entities: [EntityDefinition]) -> [String: FieldDefinition] {
        var fields: [String: FieldDefinition] = [:]
        for field in entities.flatMap(\.fields) where fields[field.id] == nil {
            fields[field.id] = field
        }
        return fields
    }
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
            switch dataType {
            case .string, .email, .phone, .url, .location:
                true
            default:
                false
            }
        case .minimumValue, .maximumValue:
            switch dataType {
            case .integer, .decimal, .currency, .percentage:
                true
            default:
                false
            }
        }
    }
}
