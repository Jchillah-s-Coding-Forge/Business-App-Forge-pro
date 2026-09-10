import AppForgeDomain

enum FlutterFormEditMappingSupport {
    static func typeName(for screen: ScreenDefinition) throws -> String {
        let typeName = FlutterDartNaming.typeName(
            screen.identity.code
        ) + "FormEditMapper"
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
            + "\(screenName)_form_edit_mapper.dart"
    }

    static func fields(
        for entity: EntityDefinition
    ) -> [FieldDefinition] {
        entity.fields.sorted(by: fieldSort)
    }

    static func sourceRelations(
        for entity: EntityDefinition,
        in specification: ProjectSpecification
    ) -> [RelationDefinition] {
        specification.relations
            .filter { $0.sourceEntityID == entity.id }
            .sorted(by: relationSort)
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

    private static func relationSort(
        _ lhs: RelationDefinition,
        _ rhs: RelationDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}
