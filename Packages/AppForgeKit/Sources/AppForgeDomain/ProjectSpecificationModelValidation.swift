import Foundation

struct ProjectModelValidator {
    let controlValidator: ControlCompatibilityValidator

    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        FieldDefinitionValidator().validate(specification)
            + RelationDefinitionValidator().validate(specification)
            + PresentationDefinitionValidator(controlValidator: controlValidator).validate(specification)
    }
}

private struct FieldDefinitionValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        var issues: [ProjectSpecificationValidationIssue] = []
        var globalFieldIDs = Set<String>()

        for entity in specification.entities {
            issues += validateFields(
                entity.fields,
                entityID: entity.id,
                globalIDs: &globalFieldIDs
            )
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
            issues += validateDefinitionIdentity(field.identity, kind: .field)
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
        if !validationRulesAreCompatible(field.validationRules, with: field.dataType) {
            issues.append(.invalidValidationRule(fieldID: field.id))
        }
        if !validationRulesHaveCoherentBounds(field.validationRules) {
            issues.append(.invalidValidationRule(fieldID: field.id))
        }
        return issues
    }

    private func validateOptions(_ field: FieldDefinition) -> [ProjectSpecificationValidationIssue] {
        var issues = duplicateValues(field.options.map(\.id)).map {
            ProjectSpecificationValidationIssue.duplicateFieldOptionID(
                fieldID: field.id,
                optionID: $0
            )
        }
        issues += duplicateValues(field.options.map(\.value)).map {
            ProjectSpecificationValidationIssue.duplicateFieldOptionValue(
                fieldID: field.id,
                value: $0
            )
        }
        return issues
    }
}

private struct RelationDefinitionValidator {
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
            issues.append(
                .missingSourceEntity(
                    relationID: relation.id,
                    entityID: relation.sourceEntityID
                )
            )
        }
        if entities[relation.targetEntityID] == nil {
            issues.append(
                .missingTargetEntity(
                    relationID: relation.id,
                    entityID: relation.targetEntityID
                )
            )
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

private struct PresentationDefinitionValidator {
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
                return [
                    .missingPresentationField(
                        presentationID: presentation.id,
                        fieldID: fieldID
                    )
                ]
            }
            return wrap(
                controlValidator.validate(presentation, field: field),
                presentationID: presentation.id
            )
        case let .relation(relationID):
            guard let relation = relations[relationID] else {
                return [
                    .missingPresentationRelation(
                        presentationID: presentation.id,
                        relationID: relationID
                    )
                ]
            }
            return wrap(
                controlValidator.validate(presentation, relation: relation),
                presentationID: presentation.id
            )
        }
    }

    private func wrap(
        _ controlIssues: [ControlCompatibilityIssue],
        presentationID: String
    ) -> [ProjectSpecificationValidationIssue] {
        guard !controlIssues.isEmpty else { return [] }
        return [
            .incompatiblePresentation(
                presentationID: presentationID,
                issues: controlIssues
            )
        ]
    }
}

func validationRulesAreCompatible(
    _ rules: [FieldValidationRule],
    with dataType: FieldDataType
) -> Bool {
    rules.allSatisfy { $0.isCompatible(with: dataType) }
}

func validationRulesHaveCoherentBounds(_ rules: [FieldValidationRule]) -> Bool {
    coherentBounds(
        minima: rules.compactMap(\.minimumLengthValue).map(Double.init),
        maxima: rules.compactMap(\.maximumLengthValue).map(Double.init)
    ) && coherentBounds(
        minima: rules.compactMap(\.minimumNumericValue),
        maxima: rules.compactMap(\.maximumNumericValue)
    )
}

private func coherentBounds(minima: [Double], maxima: [Double]) -> Bool {
    guard let minimum = minima.max(), let maximum = maxima.min() else {
        return true
    }
    return minimum <= maximum
}

extension FieldDefaultValue {
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
