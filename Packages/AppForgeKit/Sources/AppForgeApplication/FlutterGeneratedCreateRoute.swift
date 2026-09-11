import AppForgeDomain

struct FlutterGeneratedCreateRoute {
    let screen: ScreenDefinition
    let entity: EntityDefinition
    let label: String

    var propertyName: String {
        FlutterDartNaming.memberName(screen.identity.code) + "Create"
    }
}

enum FlutterGeneratedCreateRoutes {
    static func make(
        specification: ProjectSpecification
    ) throws -> [FlutterGeneratedCreateRoute] {
        let screens = FlutterFormRenderingSupport.formScreens(
            in: specification
        )
        let screensByID = Dictionary(
            uniqueKeysWithValues: screens.map { ($0.id, $0) }
        )
        var routedScreenIDs = Set<String>()
        var result = try explicitRoutes(
            specification: specification,
            screensByID: screensByID,
            routedScreenIDs: &routedScreenIDs
        )
        result += try automaticRoutes(
            specification: specification,
            screens: screens,
            routedScreenIDs: &routedScreenIDs
        )
        return result
    }

    private static func explicitRoutes(
        specification: ProjectSpecification,
        screensByID: [String: ScreenDefinition],
        routedScreenIDs: inout Set<String>
    ) throws -> [FlutterGeneratedCreateRoute] {
        var result: [FlutterGeneratedCreateRoute] = []
        for item in specification.navigation.items {
            guard let screen = screensByID[item.screenID],
                  routedScreenIDs.insert(screen.id).inserted
            else {
                continue
            }
            let entity = try FlutterFormRenderingSupport.entity(
                for: screen,
                in: specification
            )
            try FlutterCreateFlowPrerequisites.validate(
                screen: screen,
                entity: entity,
                navigationRoleIDs: item.allowedRoleIDs,
                specification: specification
            )
            result.append(
                FlutterGeneratedCreateRoute(
                    screen: screen,
                    entity: entity,
                    label: normalized(
                        item.label,
                        fallback: screen.identity.label
                    )
                )
            )
        }
        return result
    }

    private static func automaticRoutes(
        specification: ProjectSpecification,
        screens: [ScreenDefinition],
        routedScreenIDs: inout Set<String>
    ) throws -> [FlutterGeneratedCreateRoute] {
        var result: [FlutterGeneratedCreateRoute] = []
        for screen in screens where routedScreenIDs.insert(screen.id).inserted {
            let entity = try FlutterFormRenderingSupport.entity(
                for: screen,
                in: specification
            )
            guard FlutterCreateFlowPrerequisites.canAutoMaterialize(
                screen: screen,
                entity: entity,
                specification: specification
            ) else {
                continue
            }
            result.append(
                FlutterGeneratedCreateRoute(
                    screen: screen,
                    entity: entity,
                    label: screen.identity.label
                )
            )
        }
        return result
    }

    private static func normalized(
        _ value: String,
        fallback: String
    ) -> String {
        let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? fallback : result
    }
}

enum FlutterCreateFlowPrerequisites {
    static func validate(
        screen: ScreenDefinition,
        entity: EntityDefinition,
        navigationRoleIDs: Set<String> = [],
        specification: ProjectSpecification
    ) throws {
        guard specification.offline.isEnabled else {
            throw FlutterRendererError.formCreateRequiresOfflinePersistence(
                screenID: screen.id
            )
        }
        guard screen.allowedRoleIDs.isEmpty,
              navigationRoleIDs.isEmpty
        else {
            throw FlutterRendererError.formCreateRequiresRoleEvaluation(
                screenID: screen.id
            )
        }

        try validateFields(
            screen: screen,
            entity: entity
        )
        try validateRelations(
            screen: screen,
            entity: entity,
            specification: specification
        )
    }

    static func canAutoMaterialize(
        screen: ScreenDefinition,
        entity: EntityDefinition,
        specification: ProjectSpecification
    ) -> Bool {
        do {
            try validate(
                screen: screen,
                entity: entity,
                specification: specification
            )
            return true
        } catch {
            return false
        }
    }

    private static func validateFields(
        screen: ScreenDefinition,
        entity: EntityDefinition
    ) throws {
        let visibleFieldIDs = Set(screen.visibleFieldIDs)
        for field in entity.fields {
            if field.isRequired {
                if field.defaultValue == nil,
                   !visibleFieldIDs.contains(field.id)
                {
                    throw FlutterRendererError.formCreateMissingRequiredField(
                        screenID: screen.id,
                        fieldID: field.id
                    )
                }
                if visibleFieldIDs.contains(field.id),
                   usesExternalValuePicker(field)
                {
                    throw FlutterRendererError.formCreateRequiresExternalValuePicker(
                        screenID: screen.id,
                        fieldID: field.id
                    )
                }
            }
        }
    }

    private static func validateRelations(
        screen: ScreenDefinition,
        entity: EntityDefinition,
        specification: ProjectSpecification
    ) throws {
        let requiredRelations = specification.relations.filter {
            $0.sourceEntityID == entity.id && $0.isRequired
        }
        if let relation = requiredRelations.first {
            throw FlutterRendererError.formCreateRequiresRelationInput(
                screenID: screen.id,
                relationID: relation.id
            )
        }
    }

    private static func usesExternalValuePicker(
        _ field: FieldDefinition
    ) -> Bool {
        switch field.dataType {
        case .file, .image, .color, .location:
            true
        default:
            false
        }
    }
}
