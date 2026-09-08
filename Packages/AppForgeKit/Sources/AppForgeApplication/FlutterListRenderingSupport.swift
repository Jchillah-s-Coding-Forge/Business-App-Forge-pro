import AppForgeDomain

enum FlutterListRenderingSupport {
    static func listScreens(
        in specification: ProjectSpecification
    ) -> [ScreenDefinition] {
        specification.screens
            .filter { $0.kind == .list }
            .sorted(by: screenSort)
    }

    static func entity(
        for screen: ScreenDefinition,
        in specification: ProjectSpecification
    ) throws -> EntityDefinition {
        guard let entityID = screen.entityID,
              let entity = specification.entities.first(where: { $0.id == entityID })
        else {
            throw FlutterRendererError.listScreenRequiresEntity(
                screenID: screen.id
            )
        }
        return entity
    }

    static func typeName(for screen: ScreenDefinition) throws -> String {
        let typeName = FlutterDartNaming.typeName(
            screen.identity.code
        ) + "ListScreen"
        guard FlutterDartNaming.isUsableIdentifier(typeName) else {
            throw FlutterRendererError.invalidGeneratedIdentifier(
                definitionID: screen.id,
                code: screen.identity.code
            )
        }
        return typeName
    }

    static func outputPath(
        for screen: ScreenDefinition,
        entity: EntityDefinition
    ) throws -> String {
        let featureName = FlutterDartNaming.snakeCase(
            entity.identity.code
        )
        let screenName = FlutterDartNaming.snakeCase(
            screen.identity.code
        )
        guard FlutterDartNaming.isUsableIdentifier(featureName),
              FlutterDartNaming.isUsableIdentifier(screenName)
        else {
            throw FlutterRendererError.invalidGeneratedIdentifier(
                definitionID: screen.id,
                code: screen.identity.code
            )
        }

        return "lib/features/\(featureName)"
            + "/presentation/screens/"
            + "\(screenName)_list_screen.dart"
    }

    private static func screenSort(
        _ lhs: ScreenDefinition,
        _ rhs: ScreenDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}
