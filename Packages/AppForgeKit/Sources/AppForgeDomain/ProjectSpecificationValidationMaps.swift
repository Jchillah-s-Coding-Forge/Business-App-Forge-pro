import Foundation

protocol DefinitionIdentified {
    var identity: DefinitionIdentity { get }
}

extension RelationDefinition: DefinitionIdentified {}
extension RoleDefinition: DefinitionIdentified {}
extension BusinessStateMachineDefinition: DefinitionIdentified {}
extension ScreenDefinition: DefinitionIdentified {}

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
