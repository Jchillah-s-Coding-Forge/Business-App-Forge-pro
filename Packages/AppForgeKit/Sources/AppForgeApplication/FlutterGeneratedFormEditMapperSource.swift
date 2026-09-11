import AppForgeDomain

struct FlutterGeneratedFormEditMapperSource {
    let specification: ProjectSpecification
    let screen: ScreenDefinition
    let entity: EntityDefinition

    func file() throws -> GeneratedFile {
        try GeneratedFile(
            relativePath: FlutterFormEditMappingSupport.outputPath(
                for: screen,
                entity: entity
            ),
            contents: content()
        )
    }
}

private extension FlutterGeneratedFormEditMapperSource {
    func content() throws -> String {
        let mapperType = try FlutterFormEditMappingSupport.typeName(
            for: screen
        )
        let featureName = FlutterDartNaming.snakeCase(
            entity.identity.code
        )
        let entityType = FlutterDartNaming.typeName(
            entity.identity.code
        )

        return FlutterGeneratedText.lines([
            "import '../../../../core/domain/domain_values.dart';",
            "import '../../../../core/presentation/generated_form_edit_mapping.dart';",
            "import '../../domain/entities/\(featureName).dart';",
            "",
            "abstract final class \(mapperType) {",
            "  static \(entityType) apply({",
            "    required DomainRecord<\(entityType)> record,",
            "    required Map<String, Object?> values,",
            "  }) {",
            "    return \(entityType)("
        ] + mappedFieldLines() + preservedRelationLines() + [
            "    );",
            "  }",
            "}",
            ""
        ])
    }

    func mappedFieldLines() -> [String] {
        let visibleFieldIDs = Set(screen.visibleFieldIDs)
        return FlutterFormEditMappingSupport.fields(for: entity).map { field in
            let member = FlutterDartNaming.memberName(
                field.identity.code
            )
            let value = visibleFieldIDs.contains(field.id)
                ? mappedValueExpression(for: field)
                : "record.value.\(member)"
            return "      \(member): \(value),"
        }
    }

    func preservedRelationLines() -> [String] {
        FlutterFormEditMappingSupport.sourceRelations(
            for: entity,
            in: specification
        ).map { relation in
            let member = FlutterDartNaming.memberName(
                relation.identity.code
            )
            return "      \(member): record.value.\(member),"
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
        return "GeneratedFormEditMapping.\(reader)<\(type)>("
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
}
