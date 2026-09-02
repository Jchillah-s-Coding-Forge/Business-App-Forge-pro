import Foundation

protocol DefinitionIdentified {
    var identity: DefinitionIdentity { get }
}

extension RelationDefinition: DefinitionIdentified {}
extension RoleDefinition: DefinitionIdentified {}
extension BusinessStateMachineDefinition: DefinitionIdentified {}
extension ScreenDefinition: DefinitionIdentified {}

func validateIdentity(
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

func duplicateIdentityIssues<Value: Identifiable & DefinitionIdentified>(
    _ values: [Value],
    kind: ProjectDefinitionKind,
    duplicateID: (String) -> ProjectSpecificationValidationIssue,
    duplicateCode: (String) -> ProjectSpecificationValidationIssue
) -> [ProjectSpecificationValidationIssue] where Value.ID == String {
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

func entityMap(_ entities: [EntityDefinition]) -> [String: EntityDefinition] {
    uniqueMap(entities, id: \.id)
}

func fieldMap(_ entities: [EntityDefinition]) -> [String: FieldDefinition] {
    uniqueMap(entities.flatMap(\.fields), id: \.id)
}

func relationMap(_ relations: [RelationDefinition]) -> [String: RelationDefinition] {
    uniqueMap(relations, id: \.id)
}

func uniqueMap<Value>(
    _ values: [Value],
    id: KeyPath<Value, String>
) -> [String: Value] {
    var result: [String: Value] = [:]

    for value in values where result[value[keyPath: id]] == nil {
        result[value[keyPath: id]] = value
    }

    return result
}

func duplicateValues(_ values: [String]) -> [String] {
    var seen = Set<String>()
    var duplicates = Set<String>()

    for value in values where !seen.insert(value).inserted {
        duplicates.insert(value)
    }

    return duplicates.sorted()
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

extension [FieldValidationRule] {
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

extension FieldValidationRule {
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

extension String {
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
