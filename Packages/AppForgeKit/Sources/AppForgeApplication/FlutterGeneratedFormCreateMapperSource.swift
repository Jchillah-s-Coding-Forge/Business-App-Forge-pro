import AppForgeDomain

struct FlutterGeneratedFormCreateMapperSource {
    let screen: ScreenDefinition
    let entity: EntityDefinition

    func file() throws -> GeneratedFile {
        try GeneratedFile(
            relativePath: FlutterFormCreateMappingSupport.outputPath(
                for: screen,
                entity: entity
            ),
            contents: content()
        )
    }
}

private extension FlutterGeneratedFormCreateMapperSource {
    func content() throws -> String {
        let mapperType = try FlutterFormCreateMappingSupport.typeName(
            for: screen
        )
        let featureName = FlutterDartNaming.snakeCase(
            entity.identity.code
        )
        let entityType = FlutterDartNaming.typeName(
            entity.identity.code
        )
        var imports = [
            "import '../../../../core/presentation/generated_form_create_mapping.dart';",
            "import '../../domain/entities/\(featureName).dart';"
        ]
        if usesDomainValues {
            imports.append(
                "import '../../../../core/domain/domain_values.dart';"
            )
        }

        return FlutterGeneratedText.lines(
            imports.sorted() + [
                "",
                "abstract final class \(mapperType) {",
                "  static \(entityType) apply(",
                "    Map<String, Object?> values,",
                "  ) {",
                "    return \(entityType)("
            ] + entityArgumentLines() + [
                "    );",
                "  }",
                "}",
                ""
            ]
        )
    }

    func entityArgumentLines() -> [String] {
        let visibleFieldIDs = Set(screen.visibleFieldIDs)
        return FlutterFormCreateMappingSupport.fields(for: entity).compactMap { field in
            let member = FlutterDartNaming.memberName(
                field.identity.code
            )
            if visibleFieldIDs.contains(field.id) {
                return "      \(member): \(mappedValueExpression(for: field)),"
            }
            guard let defaultExpression = FlutterDartDefaultValue.expression(
                for: field
            ) else {
                return nil
            }
            return "      \(member): \(defaultExpression),"
        }
    }

    func mappedValueExpression(
        for field: FieldDefinition
    ) -> String {
        let reader = field.isRequired
            ? "requiredValue"
            : "optionalValue"
        let type = baseDartType(for: field)
        let fieldID = FlutterDartEscaping.singleQuoted(field.id)
        return "GeneratedFormCreateMapping.\(reader)<\(type)>("
            + "values, '\(fieldID)')"
    }

    func baseDartType(
        for field: FieldDefinition
    ) -> String {
        let type = FlutterDartNaming.dartType(for: field)
        if field.isRequired {
            return type
        }
        return String(type.dropLast())
    }

    var usesDomainValues: Bool {
        FlutterFormCreateMappingSupport.fields(for: entity).contains { field in
            let visible = screen.visibleFieldIDs.contains(field.id)
            let hasDefault = field.defaultValue != nil
            return (visible || hasDefault)
                && FlutterDartNaming.usesDomainValueObject(field)
        }
    }
}
