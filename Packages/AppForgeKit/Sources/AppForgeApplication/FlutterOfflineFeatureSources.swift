import AppForgeDomain

struct FlutterOfflineFeatureSources {
    let specification: ProjectSpecification
    let entity: EntityDefinition

    func files() throws -> [GeneratedFile] {
        guard specification.offline.isEnabled else {
            return []
        }

        let featureName = FlutterDartNaming.snakeCase(entity.identity.code)
        let typeName = FlutterDartNaming.typeName(entity.identity.code)
        let tableName = try FlutterOfflineStorageNaming.tableName(for: entity)
        let columnNames = try FlutterOfflineStorageNaming.columnNames(
            for: entity
        )

        return [
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/data/local/\(featureName)_local_data_source.dart",
                contents: localDataSource(
                    featureName: featureName,
                    typeName: typeName,
                    tableName: tableName,
                    columnNames: columnNames
                )
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/data/repositories/\(featureName)_repository_impl.dart",
                contents: repositoryImplementation(
                    featureName: featureName,
                    typeName: typeName
                )
            )
        ]
    }

    private func localDataSource(
        featureName: String,
        typeName: String,
        tableName: String,
        columnNames: [String: String]
    ) -> String {
        let fields = entity.fields.sorted(by: Self.fieldSort)
        var lines = importLines(featureName: featureName)
        lines += [
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
            "",
            "  Future<void> save({",
            "    required String recordId,",
            "    required \(typeName) value,",
            "  }) async {",
            "    final db = await _database.database;",
            "    await db.transaction((txn) async {",
            "      final current = await txn.query(",
            "        _table,",
            "        columns: const ['_sync_revision'],",
            "        where: '\"_record_id\" = ?',",
            "        whereArgs: <Object?>[recordId],",
            "        limit: 1,",
            "      );",
            "      final revision = current.isEmpty",
            "          ? 1",
            "          : (current.first['_sync_revision']! as int) + 1;",
            "      final now = DateTime.now().toUtc().toIso8601String();",
            "      final row = <String, Object?>{",
            "        ..._toRow(value),",
            "        '_record_id': recordId,",
            "        '_sync_revision': revision,",
            "        '_sync_status': SyncStatus.\(saveSyncStatus).name,",
            "        '_updated_at': now,",
            "        '_deleted_at': null,",
            "      };",
            "",
            "      await txn.insert(",
            "        _table,",
            "        row,",
            "        conflictAlgorithm: ConflictAlgorithm.replace,",
            "      );"
        ]

        if specification.offline.usesSyncOutbox {
            lines += [
                "",
                "      final operation = current.isEmpty",
                "          ? SyncOperation.create",
                "          : SyncOperation.update;",
                "      await _enqueue(",
                "        txn,",
                "        recordId: recordId,",
                "        revision: revision,",
                "        operation: operation,",
                "        payloadJson: jsonEncode(row),",
                "        createdAt: now,",
                "      );"
            ]
        }

        lines += [
            "    });",
            "  }",
            ""
        ]
        lines += deleteMethod()
        lines += [
            "",
            "  \(typeName) _fromRow(Map<String, Object?> row) {"
        ]
        lines += fromRowLines(
            typeName: typeName,
            fields: fields,
            columnNames: columnNames
        )
        lines += [
            "  }",
            "",
            "  Map<String, Object?> _toRow(\(typeName) value) {"
        ]
        lines += toRowLines(
            fields: fields,
            columnNames: columnNames
        )
        lines += [
            "  }"
        ]

        if specification.offline.usesSyncOutbox {
            lines += [""]
            lines += enqueueMethod()
        }

        lines += [
            "}",
            ""
        ]

        return FlutterGeneratedText.lines(lines)
    }

    private var saveSyncStatus: String {
        specification.offline.usesSyncOutbox
            ? "pending"
            : "clean"
    }

    private func importLines(
        featureName: String
    ) -> [String] {
        var imports: [String] = []
        if specification.offline.usesSyncOutbox {
            imports.append("import 'dart:convert';")
        }

        imports += [
            "",
            "import 'package:sqflite/sqflite.dart';",
            "",
            "import '../../../../core/storage/app_database.dart';",
            "import '../../../../core/sync/sync_status.dart';"
        ]

        if specification.offline.usesSyncOutbox {
            imports.append(
                "import '../../../../core/sync/sync_operation.dart';"
            )
        }

        imports += [
            "import '../../domain/entities/\(featureName).dart';"
        ]
        return imports
    }

    private func deleteMethod() -> [String] {
        if specification.offline.usesSyncOutbox {
            return [
                "  Future<void> delete(String recordId) async {",
                "    final db = await _database.database;",
                "    await db.transaction((txn) async {",
                "      final current = await txn.query(",
                "        _table,",
                "        columns: const ['_sync_revision'],",
                "        where: '\"_record_id\" = ?',",
                "        whereArgs: <Object?>[recordId],",
                "        limit: 1,",
                "      );",
                "      if (current.isEmpty) {",
                "        return;",
                "      }",
                "",
                "      final revision =",
                "          (current.first['_sync_revision']! as int) + 1;",
                "      final now = DateTime.now().toUtc().toIso8601String();",
                "      await txn.update(",
                "        _table,",
                "        <String, Object?>{",
                "          '_sync_revision': revision,",
                "          '_sync_status': SyncStatus.deleted.name,",
                "          '_updated_at': now,",
                "          '_deleted_at': now,",
                "        },",
                "        where: '\"_record_id\" = ?',",
                "        whereArgs: <Object?>[recordId],",
                "      );",
                "",
                "      await _enqueue(",
                "        txn,",
                "        recordId: recordId,",
                "        revision: revision,",
                "        operation: SyncOperation.delete,",
                "        payloadJson: null,",
                "        createdAt: now,",
                "      );",
                "    });",
                "  }"
            ]
        }

        return [
            "  Future<void> delete(String recordId) async {",
            "    final db = await _database.database;",
            "    await db.delete(",
            "      _table,",
            "      where: '\"_record_id\" = ?',",
            "      whereArgs: <Object?>[recordId],",
            "    );",
            "  }"
        ]
    }

    private func enqueueMethod() -> [String] {
        [
            "  Future<void> _enqueue(",
            "    DatabaseExecutor txn, {",
            "    required String recordId,",
            "    required int revision,",
            "    required SyncOperation operation,",
            "    required String? payloadJson,",
            "    required String createdAt,",
            "  }) async {",
            "    final idempotencyKey =",
            "        '\(entity.identity.code):$recordId:$revision:\${operation.name}';",
            "    await txn.insert(",
            "      '_sync_outbox',",
            "      <String, Object?>{",
            "        'id': idempotencyKey,",
            "        'entity_code': '\(entity.identity.code)',",
            "        'record_id': recordId,",
            "        'operation': operation.name,",
            "        'payload_json': payloadJson,",
            "        'idempotency_key': idempotencyKey,",
            "        'created_at': createdAt,",
            "        'attempt_count': 0,",
            "        'last_error': null,",
            "      },",
            "      conflictAlgorithm: ConflictAlgorithm.abort,",
            "    );",
            "  }"
        ]
    }

    private func fromRowLines(
        typeName: String,
        fields: [FieldDefinition],
        columnNames: [String: String]
    ) -> [String] {
        guard !fields.isEmpty else {
            return [
                "    return const \(typeName)();"
            ]
        }

        var lines = [
            "    return \(typeName)("
        ]
        for field in fields {
            guard let columnName = columnNames[field.id] else {
                continue
            }
            let memberName = FlutterDartNaming.memberName(
                field.identity.code
            )
            lines.append(
                "      \(memberName): \(fromRowExpression(field, columnName: columnName)),"
            )
        }
        lines += [
            "    );"
        ]
        return lines
    }

    private func toRowLines(
        fields: [FieldDefinition],
        columnNames: [String: String]
    ) -> [String] {
        guard !fields.isEmpty else {
            return [
                "    return <String, Object?>{};"
            ]
        }

        var lines = [
            "    return <String, Object?>{"
        ]
        for field in fields {
            guard let columnName = columnNames[field.id] else {
                continue
            }
            let memberName = FlutterDartNaming.memberName(
                field.identity.code
            )
            lines.append(
                "      '\(columnName)': \(toRowExpression(field, memberName: memberName)),"
            )
        }
        lines += [
            "    };"
        ]
        return lines
    }

    private func fromRowExpression(
        _ field: FieldDefinition,
        columnName: String
    ) -> String {
        let lookup = "row['\(columnName)']"

        switch field.dataType {
        case .integer:
            return field.isRequired
                ? "\(lookup)! as int"
                : "\(lookup) as int?"
        case .decimal, .currency, .percentage:
            return field.isRequired
                ? "(\(lookup)! as num).toDouble()"
                : "\(lookup) == null ? null : (\(lookup)! as num).toDouble()"
        case .boolean:
            return field.isRequired
                ? "(\(lookup)! as int) != 0"
                : "\(lookup) == null ? null : (\(lookup)! as int) != 0"
        case .date, .dateTime, .time:
            return field.isRequired
                ? "DateTime.parse(\(lookup)! as String)"
                : "\(lookup) == null ? null : DateTime.parse(\(lookup)! as String)"
        case .string, .email, .phone, .url, .enumeration, .file, .image, .color, .location:
            return field.isRequired
                ? "\(lookup)! as String"
                : "\(lookup) as String?"
        }
    }

    private func toRowExpression(
        _ field: FieldDefinition,
        memberName: String
    ) -> String {
        let access = "value.\(memberName)"

        switch field.dataType {
        case .boolean:
            return field.isRequired
                ? "\(access) ? 1 : 0"
                : "\(access) == null ? null : (\(access)! ? 1 : 0)"
        case .date, .dateTime, .time:
            return field.isRequired
                ? "\(access).toUtc().toIso8601String()"
                : "\(access)?.toUtc().toIso8601String()"
        case .integer, .decimal, .currency, .percentage,
             .string, .email, .phone, .url, .enumeration,
             .file, .image, .color, .location:
            return access
        }
    }

    private func repositoryImplementation(
        featureName: String,
        typeName: String
    ) -> String {
        FlutterGeneratedText.lines([
            "import '../../domain/entities/\(featureName).dart';",
            "import '../../domain/repositories/\(featureName)_repository.dart';",
            "import '../local/\(featureName)_local_data_source.dart';",
            "",
            "class \(typeName)RepositoryImpl implements \(typeName)Repository {",
            "  const \(typeName)RepositoryImpl(this._local);",
            "",
            "  final \(typeName)LocalDataSource _local;",
            "",
            "  @override",
            "  Future<List<\(typeName)>> fetchAll() => _local.fetchAll();",
            "",
            "  @override",
            "  Future<void> save({",
            "    required String recordId,",
            "    required \(typeName) value,",
            "  }) =>",
            "      _local.save(recordId: recordId, value: value);",
            "",
            "  @override",
            "  Future<void> delete(String recordId) => _local.delete(recordId);",
            "}",
            ""
        ])
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
