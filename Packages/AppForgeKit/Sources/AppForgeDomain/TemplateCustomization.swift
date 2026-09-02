import Foundation

public enum TemplateObjectKind: String, CaseIterable, Codable, Sendable {
    case entity
    case relation
    case presentation
    case role
    case stateMachine
    case screen
    case navigation
}

public enum TemplateChangeKind: String, CaseIterable, Codable, Sendable {
    case added
    case removed
    case modified
}

public struct TemplateDiffEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let objectKind: TemplateObjectKind
    public let changeKind: TemplateChangeKind
    public let definitionID: String

    public init(
        objectKind: TemplateObjectKind,
        changeKind: TemplateChangeKind,
        definitionID: String
    ) {
        id = "\(objectKind.rawValue):\(changeKind.rawValue):\(definitionID)"
        self.objectKind = objectKind
        self.changeKind = changeKind
        self.definitionID = definitionID
    }
}

public struct TemplateCustomizationService: Sendable {
    public init() {}

    public func diff(_ specification: ProjectSpecification) -> [TemplateDiffEntry] {
        guard let baseline = specification.templateBaseline else { return [] }
        var result: [TemplateDiffEntry] = []

        result += diffIdentified(
            current: specification.entities,
            baseline: baseline.entities,
            kind: .entity
        )
        result += diffIdentified(
            current: specification.relations,
            baseline: baseline.relations,
            kind: .relation
        )
        result += diffIdentified(
            current: specification.fieldPresentations,
            baseline: baseline.fieldPresentations,
            kind: .presentation
        )
        result += diffIdentified(
            current: specification.roles,
            baseline: baseline.roles,
            kind: .role
        )
        result += diffIdentified(
            current: specification.stateMachines,
            baseline: baseline.stateMachines,
            kind: .stateMachine
        )
        result += diffIdentified(
            current: specification.screens,
            baseline: baseline.screens,
            kind: .screen
        )

        if specification.navigation != baseline.navigation {
            result.append(
                TemplateDiffEntry(
                    objectKind: .navigation,
                    changeKind: .modified,
                    definitionID: "navigation"
                )
            )
        }

        return result
    }

    public func resetBusinessModel(_ specification: inout ProjectSpecification) {
        guard let baseline = specification.templateBaseline else { return }
        specification.entities = baseline.entities
        specification.relations = baseline.relations
        specification.fieldPresentations = baseline.fieldPresentations
        specification.roles = baseline.roles
        specification.stateMachines = baseline.stateMachines
        specification.screens = baseline.screens
        specification.navigation = baseline.navigation
    }

    public func resetEntity(id: String, in specification: inout ProjectSpecification) {
        guard let baseline = specification.templateBaseline,
              let baselineEntity = baseline.entities.first(where: { $0.id == id })
        else {
            return
        }

        replaceOrAppend(baselineEntity, in: &specification.entities)
    }

    public func resetField(
        entityID: String,
        fieldID: String,
        in specification: inout ProjectSpecification
    ) {
        guard let baseline = specification.templateBaseline,
              let baselineEntity = baseline.entities.first(where: { $0.id == entityID }),
              let baselineField = baselineEntity.fields.first(where: { $0.id == fieldID })
        else {
            return
        }

        guard let entityIndex = specification.entities.firstIndex(where: { $0.id == entityID }) else {
            specification.entities.append(baselineEntity)
            return
        }

        replaceOrAppend(baselineField, in: &specification.entities[entityIndex].fields)
    }

    public func resetRelation(id: String, in specification: inout ProjectSpecification) {
        guard let baseline = specification.templateBaseline,
              let value = baseline.relations.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &specification.relations)
    }

    public func resetPresentation(id: String, in specification: inout ProjectSpecification) {
        guard let baseline = specification.templateBaseline,
              let value = baseline.fieldPresentations.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &specification.fieldPresentations)
    }

    public func resetRole(id: String, in specification: inout ProjectSpecification) {
        guard let baseline = specification.templateBaseline,
              let value = baseline.roles.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &specification.roles)
    }

    public func resetStateMachine(id: String, in specification: inout ProjectSpecification) {
        guard let baseline = specification.templateBaseline,
              let value = baseline.stateMachines.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &specification.stateMachines)
    }

    public func resetScreen(id: String, in specification: inout ProjectSpecification) {
        guard let baseline = specification.templateBaseline,
              let value = baseline.screens.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &specification.screens)
    }

    public func resetNavigation(in specification: inout ProjectSpecification) {
        guard let baseline = specification.templateBaseline else { return }
        specification.navigation = baseline.navigation
    }

    private func diffIdentified<Value>(
        current: [Value],
        baseline: [Value],
        kind: TemplateObjectKind
    ) -> [TemplateDiffEntry] where Value: Identifiable & Equatable, Value.ID == String {
        let currentMap = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        let baselineMap = Dictionary(uniqueKeysWithValues: baseline.map { ($0.id, $0) })
        let allIDs = Set(currentMap.keys).union(baselineMap.keys).sorted()

        return allIDs.compactMap { id in
            switch (baselineMap[id], currentMap[id]) {
            case (nil, .some):
                TemplateDiffEntry(objectKind: kind, changeKind: .added, definitionID: id)
            case (.some, nil):
                TemplateDiffEntry(objectKind: kind, changeKind: .removed, definitionID: id)
            case let (.some(baselineValue), .some(currentValue)) where baselineValue != currentValue:
                TemplateDiffEntry(objectKind: kind, changeKind: .modified, definitionID: id)
            default:
                nil
            }
        }
    }

    private func replaceOrAppend<Value>(
        _ value: Value,
        in values: inout [Value]
    ) where Value: Identifiable, Value.ID == String {
        if let index = values.firstIndex(where: { $0.id == value.id }) {
            values[index] = value
        } else {
            values.append(value)
        }
    }
}
