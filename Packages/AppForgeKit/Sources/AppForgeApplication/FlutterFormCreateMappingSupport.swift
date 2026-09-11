import AppForgeDomain

enum FlutterFormCreateMappingSupport {
    static func typeName(for screen: ScreenDefinition) throws -> String {
        let typeName = FlutterDartNaming.typeName(
            screen.identity.code
        ) + "FormCreateMapper"
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
            + "/presentation/mappers/"
            + "\(screenName)_form_create_mapper.dart"
    }

    static func viewModelTypeName(
        for screen: ScreenDefinition
    ) throws -> String {
        let typeName = FlutterDartNaming.typeName(
            screen.identity.code
        ) + "FormCreateViewModel"
        guard FlutterDartNaming.isUsableIdentifier(typeName) else {
            throw FlutterRendererError.invalidGeneratedIdentifier(
                definitionID: screen.id,
                code: screen.identity.code
            )
        }
        return typeName
    }

    static func viewModelOutputPath(
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
            + "/presentation/view_models/"
            + "\(screenName)_form_create_view_model.dart"
    }

    static func fields(
        for entity: EntityDefinition
    ) -> [FieldDefinition] {
        entity.fields.sorted(by: fieldSort)
    }

    private static func fieldSort(
        _ lhs: FieldDefinition,
        _ rhs: FieldDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}
