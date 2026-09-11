import AppForgeDomain

struct FlutterGeneratedFormCreateViewModelSource {
    let screen: ScreenDefinition
    let entity: EntityDefinition

    func file() throws -> GeneratedFile {
        try GeneratedFile(
            relativePath: FlutterFormCreateMappingSupport.viewModelOutputPath(
                for: screen,
                entity: entity
            ),
            contents: content()
        )
    }
}

private extension FlutterGeneratedFormCreateViewModelSource {
    func content() throws -> String {
        let featureName = FlutterDartNaming.snakeCase(
            entity.identity.code
        )
        let entityType = FlutterDartNaming.typeName(
            entity.identity.code
        )
        let screenName = FlutterDartNaming.snakeCase(
            screen.identity.code
        )
        let mapperType = try FlutterFormCreateMappingSupport.typeName(
            for: screen
        )
        let viewModelType = try FlutterFormCreateMappingSupport.viewModelTypeName(
            for: screen
        )

        return FlutterGeneratedText.lines([
            "import '../../../../core/domain/record_id_generator.dart';",
            "import '../../domain/use_cases/save_\(featureName).dart';",
            "import '../mappers/\(screenName)_form_create_mapper.dart';",
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
            "  Future<String> create(Map<String, Object?> values) async {",
            "    final value = \(mapperType).apply(values);",
            "    final recordId = _recordIds.next();",
            "    await _save(recordId: recordId, value: value);",
            "    return recordId;",
            "  }",
            "}",
            ""
        ])
    }
}
