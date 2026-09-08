import AppForgeDomain

struct FlutterGeneratedListScreenSource {
    let screen: ScreenDefinition
    let entity: EntityDefinition

    func file() throws -> GeneratedFile {
        try GeneratedFile(
            relativePath: FlutterListRenderingSupport.outputPath(
                for: screen,
                entity: entity
            ),
            contents: content()
        )
    }
}

private extension FlutterGeneratedListScreenSource {
    func content() throws -> String {
        let typeName = try FlutterListRenderingSupport.typeName(for: screen)
        let featureName = FlutterDartNaming.snakeCase(entity.identity.code)
        let entityType = FlutterDartNaming.typeName(entity.identity.code)
        let escapedTitle = FlutterDartEscaping.singleQuoted(screen.identity.label)

        return FlutterGeneratedText.lines([
            "import 'package:flutter/material.dart';",
            "",
            "import '../../../../core/presentation/generated_entity_list_screen.dart';",
            "import '../../../../core/presentation/generated_record_display.dart';",
            "import '../../domain/entities/\(featureName).dart';",
            "",
            "class \(typeName) extends StatelessWidget {",
            "  const \(typeName)({",
            "    super.key,",
            "    required this.loadRecords,",
            "    this.onRecordSelected,",
            "    this.emptyMessage = 'No records available.',",
            "    this.errorMessageBuilder,",
            "  });",
            "",
            "  final GeneratedListLoader<\(entityType)> loadRecords;",
            "  final GeneratedListRecordSelected<\(entityType)>? onRecordSelected;",
            "  final String emptyMessage;",
            "  final GeneratedListErrorMessageBuilder? errorMessageBuilder;",
            "",
            "  @override",
            "  Widget build(BuildContext context) {",
            "    return GeneratedEntityListScreen<\(entityType)>(",
            "      title: '\(escapedTitle)',",
            "      loadRecords: loadRecords,",
            "      fieldsFor: _fieldsFor,",
            "      onRecordSelected: onRecordSelected,",
            "      emptyMessage: emptyMessage,",
            "      errorMessageBuilder: errorMessageBuilder,",
            "    );",
            "  }",
            "",
            "  static List<GeneratedRecordFieldValue> _fieldsFor(",
            "    \(entityType) value,",
            "  ) {",
            "    return <GeneratedRecordFieldValue>["
        ] + fieldLines() + [
            "    ];",
            "  }",
            "}",
            ""
        ])
    }

    func fieldLines() -> [String] {
        let fields = Dictionary(
            uniqueKeysWithValues: entity.fields.map { ($0.id, $0) }
        )
        return screen.visibleFieldIDs.flatMap { fieldID -> [String] in
            guard let field = fields[fieldID] else {
                return []
            }
            let label = FlutterDartEscaping.singleQuoted(
                field.identity.label
            )
            let member = FlutterDartNaming.memberName(
                field.identity.code
            )
            return [
                "      GeneratedRecordFieldValue(",
                "        label: '\(label)',",
                "        valueKind: GeneratedRecordValueKind.\(field.dataType.rawValue),",
                "        value: value.\(member),",
                "      ),"
            ]
        }
    }
}
