import Foundation

struct ProjectScreenNavigationValidator {
    func validate(_ specification: ProjectSpecification) -> [ProjectSpecificationValidationIssue] {
        let entities = entityMap(specification.entities)
        let fields = fieldMap(specification.entities)
        let roleIDs = Set(specification.roles.map(\.id))
        var issues: [ProjectSpecificationValidationIssue] = []

        for screen in specification.screens {
            issues += validateScreen(
                screen,
                entities: entities,
                fields: fields,
                roleIDs: roleIDs
            )
        }
        issues += validateNavigation(
            specification.navigation,
            screens: specification.screens,
            roleIDs: roleIDs
        )
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
            issues += validateScreenField(
                screen,
                fieldID: fieldID,
                entity: entity,
                fields: fields
            )
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
