import AppForgeDomain

struct FlutterGeneratedDetailScreenSource {
    let screen: ScreenDefinition
    let entity: EntityDefinition

    func file() throws -> GeneratedFile {
        try GeneratedFile(
            relativePath: FlutterDetailRenderingSupport.outputPath(
                for: screen,
                entity: entity
            ),
            contents: content()
        )
    }
}

private extension FlutterGeneratedDetailScreenSource {
    func content() throws -> String {
        let typeName = try FlutterDetailRenderingSupport.typeName(for: screen)
        let featureName = FlutterDartNaming.snakeCase(entity.identity.code)
        let entityType = FlutterDartNaming.typeName(entity.identity.code)
        let escapedTitle = FlutterDartEscaping.singleQuoted(screen.identity.label)

        return FlutterGeneratedText.lines([
            "import 'package:flutter/material.dart';",
            "",
            "import '../../../../core/domain/domain_values.dart';",
            "import '../../../../core/presentation/generated_entity_detail_screen.dart';",
            "import '../../../../core/presentation/generated_record_display.dart';",
            "import '../../domain/entities/\(featureName).dart';",
            "",
            "class \(typeName) extends StatelessWidget {",
            "  const \(typeName)({",
            "    super.key,",
            "    required this.record,",
            "    this.onEdit,",
            "    this.emptyMessage = 'No visible fields',",
            "  });",
            "",
            "  final DomainRecord<\(entityType)> record;",
            "  final GeneratedDetailEdit<\(entityType)>? onEdit;",
            "  final String emptyMessage;",
            "",
            "  @override",
            "  Widget build(BuildContext context) {",
            "    return GeneratedEntityDetailScreen<\(entityType)>(",
            "      title: '\(escapedTitle)',",
            "      record: record,",
            "      fieldsFor: _fieldsFor,",
            "      onEdit: onEdit,",
            "      emptyMessage: emptyMessage,",
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
