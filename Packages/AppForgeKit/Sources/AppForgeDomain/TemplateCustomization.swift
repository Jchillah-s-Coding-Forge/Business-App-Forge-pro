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
        diff(
            entities: specification.entities,
            relations: specification.relations,
            presentations: specification.fieldPresentations,
            roles: specification.roles,
            stateMachines: specification.stateMachines,
            screens: specification.screens,
            navigation: specification.navigation,
            baseline: specification.templateBaseline
        )
    }

    public func diff(_ draft: ProjectSpecificationDraft) -> [TemplateDiffEntry] {
        diff(
            entities: draft.entities,
            relations: draft.relations,
            presentations: draft.fieldPresentations,
            roles: draft.roles,
            stateMachines: draft.stateMachines,
            screens: draft.screens,
            navigation: draft.navigation,
            baseline: draft.templateBaseline
        )
    }

    public func resetBusinessModel(_ draft: inout ProjectSpecificationDraft) {
        guard let baseline = draft.templateBaseline else { return }
        draft.entities = baseline.entities
        draft.relations = baseline.relations
        draft.fieldPresentations = baseline.fieldPresentations
        draft.roles = baseline.roles
        draft.stateMachines = baseline.stateMachines
        draft.screens = baseline.screens
        draft.navigation = baseline.navigation
    }

    public func resetEntity(id: String, in draft: inout ProjectSpecificationDraft) {
        guard let baseline = draft.templateBaseline,
              let baselineEntity = baseline.entities.first(where: { $0.id == id })
        else {
            return
        }

        replaceOrAppend(baselineEntity, in: &draft.entities)
    }

    public func resetField(
        entityID: String,
        fieldID: String,
        in draft: inout ProjectSpecificationDraft
    ) {
        guard let baseline = draft.templateBaseline,
              let baselineEntity = baseline.entities.first(where: { $0.id == entityID }),
              let baselineField = baselineEntity.fields.first(where: { $0.id == fieldID })
        else {
            return
        }

        guard let entityIndex = draft.entities.firstIndex(where: { $0.id == entityID }) else {
            draft.entities.append(baselineEntity)
            return
        }

        replaceOrAppend(baselineField, in: &draft.entities[entityIndex].fields)
    }

    public func resetRelation(id: String, in draft: inout ProjectSpecificationDraft) {
        guard let baseline = draft.templateBaseline,
              let value = baseline.relations.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &draft.relations)
    }

    public func resetPresentation(id: String, in draft: inout ProjectSpecificationDraft) {
        guard let baseline = draft.templateBaseline,
              let value = baseline.fieldPresentations.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &draft.fieldPresentations)
    }

    public func resetRole(id: String, in draft: inout ProjectSpecificationDraft) {
        guard let baseline = draft.templateBaseline,
              let value = baseline.roles.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &draft.roles)
    }

    public func resetStateMachine(id: String, in draft: inout ProjectSpecificationDraft) {
        guard let baseline = draft.templateBaseline,
              let value = baseline.stateMachines.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &draft.stateMachines)
    }

    public func resetScreen(id: String, in draft: inout ProjectSpecificationDraft) {
        guard let baseline = draft.templateBaseline,
              let value = baseline.screens.first(where: { $0.id == id })
        else {
            return
        }
        replaceOrAppend(value, in: &draft.screens)
    }

    public func resetNavigation(in draft: inout ProjectSpecificationDraft) {
        guard let baseline = draft.templateBaseline else { return }
        draft.navigation = baseline.navigation
    }

    private func diff(
        entities: [EntityDefinition],
        relations: [RelationDefinition],
        presentations: [FieldPresentationDefinition],
        roles: [RoleDefinition],
        stateMachines: [BusinessStateMachineDefinition],
        screens: [ScreenDefinition],
        navigation: NavigationDefinition,
        baseline: TemplateBaselineDefinition?
    ) -> [TemplateDiffEntry] {
        guard let baseline else { return [] }
        var result: [TemplateDiffEntry] = []

        result += diffIdentified(current: entities, baseline: baseline.entities, kind: .entity)
        result += diffIdentified(current: relations, baseline: baseline.relations, kind: .relation)
        result += diffIdentified(
            current: presentations,
            baseline: baseline.fieldPresentations,
            kind: .presentation
        )
        result += diffIdentified(current: roles, baseline: baseline.roles, kind: .role)
        result += diffIdentified(
            current: stateMachines,
            baseline: baseline.stateMachines,
            kind: .stateMachine
        )
        result += diffIdentified(current: screens, baseline: baseline.screens, kind: .screen)

        if navigation != baseline.navigation {
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
