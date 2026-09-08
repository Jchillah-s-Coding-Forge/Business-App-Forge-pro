import AppForgeDomain

struct FlutterOfflineLocalDataSourceSource {
    let specification: ProjectSpecification
    let entity: EntityDefinition
    let relations: [RelationDefinition]
    let featureName: String
    let typeName: String
    let tableName: String
    let columnNames: [String: String]
    let relationColumnNames: [String: String]

    func content() -> String {
        let mapping = FlutterOfflineRowMappingSource(
            entity: entity,
            relations: relations,
            typeName: typeName,
            columnNames: columnNames,
            relationColumnNames: relationColumnNames
        )
        let mutations = FlutterOfflineMutationSource(
            specification: specification,
            entity: entity,
            typeName: typeName
        )

        var lines = importLines + classPreambleLines
        lines += mutations.saveLines()
        lines += [""]
        lines += mutations.deleteLines()
        lines += mappingLines(mapping)

        let enqueue = mutations.enqueueLines()
        if !enqueue.isEmpty {
            lines += [""]
            lines += enqueue
        }

        lines += ["}", ""]
        return FlutterGeneratedText.lines(lines)
    }

    private var classPreambleLines: [String] {
        [
            "",
            "class \(typeName)LocalDataSource {",
            "  const \(typeName)LocalDataSource(this._database);",
            "",
            "  static const _table = '\(tableName)';",
            "  final AppDatabase _database;",
            "",
            "  Future<List<\(typeName)>> fetchAll() async {",
            "    final db = await _database.database;",
            "    final rows = await db.query(",
            "      _table,",
            "      where: '\"_deleted_at\" IS NULL',",
            "      orderBy: '\"_updated_at\" DESC',",
            "    );",
            "    return rows.map(_fromRow).toList(growable: false);",
            "  }",
            ""
        ]
    }

    private func mappingLines(
        _ mapping: FlutterOfflineRowMappingSource
    ) -> [String] {
        var lines = [
            "",
            "  \(typeName) _fromRow(Map<String, Object?> row) {"
        ]
        lines += mapping.fromRowLines()
        lines += [
            "  }",
            "",
            "  Map<String, Object?> _toRow(\(typeName) value) {"
        ]
        lines += mapping.toRowLines()
        lines += ["  }"]
        return lines
    }

    private var importLines: [String] {
        var imports: [String] = []
        let usesRelationJSON = relations.contains {
            $0.cardinality == .oneToMany || $0.cardinality == .manyToMany
        }
        if specification.offline.usesSyncOutbox || usesRelationJSON {
            imports.append("import 'dart:convert';")
        }

        imports += [
            "",
            "import 'package:sqflite/sqflite.dart';",
            "",
            "import '../../../../core/storage/app_database.dart';",
            "import '../../../../core/sync/sync_status.dart';"
        ]

        if entity.fields.contains(where: FlutterDartNaming.usesDomainValueObject)
            || !relations.isEmpty {
            imports.append(
                "import '../../../../core/domain/domain_values.dart';"
            )
        }

        if specification.offline.usesSyncOutbox {
            imports.append(
                "import '../../../../core/sync/sync_operation.dart';"
            )
        }

        imports.append(
            "import '../../domain/entities/\(featureName).dart';"
        )
        return imports
    }
}
