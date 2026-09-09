import AppForgeDomain

struct FlutterGeneratedFormViewModelSource {
    let specification: ProjectSpecification
    let screen: ScreenDefinition
    let entity: EntityDefinition

    func file() throws -> GeneratedFile {
        try GeneratedFile(
            relativePath: FlutterFormRenderingSupport.viewModelOutputPath(
                for: screen,
                entity: entity
            ),
            contents: content()
        )
    }
}

private extension FlutterGeneratedFormViewModelSource {
    func content() throws -> String {
        let featureName = FlutterDartNaming.snakeCase(entity.identity.code)
        let entityType = FlutterDartNaming.typeName(entity.identity.code)
        let viewModelType = try FlutterFormRenderingSupport.viewModelTypeName(
            for: screen
        )
        var imports = [
            "import '../../../../core/domain/record_id_generator.dart';"
        ]
        if entity.fields.contains(where: needsDomainValueImport) {
            imports.append(
                "import '../../../../core/domain/domain_values.dart';"
            )
        }
        imports += [
            "import '../../domain/entities/\(featureName).dart';",
            "import '../../domain/use_cases/save_\(featureName).dart';"
        ]

        var lines = imports.sorted() + [
            "",
            "class \(viewModelType) {",
            "  const \(viewModelType)({",
            "    required Save\(entityType) save,",
            "    required RecordIdGenerator recordIds,",
            "  })  : _save = save,",
            "        _recordIds = recordIds;",
            "",
            "  final Save\(entityType) _save;",
            "  final RecordIdGenerator _recordIds;",
            "",
            "  Future<void> create(Map<String, Object?> values) async {"
        ]
        lines += entityCreationLines(entityType: entityType)
        lines += [
            "    await _save(",
            "      recordId: _recordIds.next(),",
            "      value: value,",
            "    );",
            "  }",
            "}",
            ""
        ]
        return FlutterGeneratedText.lines(lines)
    }

    func entityCreationLines(
        entityType: String
    ) -> [String] {
        let arguments = entity.fields
            .sorted(by: Self.fieldSort)
            .compactMap(entityArgument)
        guard !arguments.isEmpty else {
            return ["    const value = \(entityType)();"]
        }

        return ["    final value = \(entityType)("]
            + arguments
            + ["    );"]
    }

    func entityArgument(
        _ field: FieldDefinition
    ) -> String? {
        let memberName = FlutterDartNaming.memberName(field.identity.code)
        let visible = screen.visibleFieldIDs.contains(field.id)
        if visible {
            let type = FlutterDartNaming.dartType(for: field)
            return "      \(memberName): values['\(escaped(field.id))'] as \(type),"
        }
        guard let expression = FlutterDartDefaultValue.expression(for: field) else {
            return nil
        }
        return "      \(memberName): \(expression),"
    }

    func needsDomainValueImport(
        _ field: FieldDefinition
    ) -> Bool {
        FlutterDartNaming.usesDomainValueObject(field)
            && (screen.visibleFieldIDs.contains(field.id)
                || field.defaultValue != nil)
    }

    func escaped(_ value: String) -> String {
        FlutterDartEscaping.singleQuoted(value)
    }

    static func fieldSort(
        _ lhs: FieldDefinition,
        _ rhs: FieldDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}
