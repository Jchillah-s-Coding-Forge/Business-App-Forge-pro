import AppForgeDomain

struct FlutterOfflineOutboxCoreSources {
    func files() -> [GeneratedFile] {
        [
            GeneratedFile(
                relativePath: "lib/core/sync/sync_operation.dart",
                contents: FlutterGeneratedText.lines(Self.operationLines)
            ),
            GeneratedFile(
                relativePath: "lib/core/sync/sync_outbox_entry.dart",
                contents: FlutterGeneratedText.lines(Self.entryLines)
            ),
            GeneratedFile(
                relativePath: "lib/core/sync/sync_outbox_repository.dart",
                contents: FlutterGeneratedText.lines(Self.repositoryLines)
            )
        ]
    }

    private static let operationLines = [
        "enum SyncOperation {",
        "  create,",
        "  update,",
        "  delete,",
        "}",
        ""
    ]

    private static let entryLines = [
        "import 'sync_operation.dart';",
        "",
        "class SyncOutboxEntry {",
        "  const SyncOutboxEntry({",
        "    required this.id,",
        "    required this.entityCode,",
        "    required this.recordId,",
        "    required this.operation,",
        "    required this.idempotencyKey,",
        "    required this.createdAt,",
        "    this.payloadJson,",
        "    this.attemptCount = 0,",
        "    this.lastError,",
        "  });",
        "",
        "  final String id;",
        "  final String entityCode;",
        "  final String recordId;",
        "  final SyncOperation operation;",
        "  final String? payloadJson;",
        "  final String idempotencyKey;",
        "  final DateTime createdAt;",
        "  final int attemptCount;",
        "  final String? lastError;",
        "",
        "  Map<String, Object?> toMap() => <String, Object?>{",
        "        'id': id,",
        "        'entity_code': entityCode,",
        "        'record_id': recordId,",
        "        'operation': operation.name,",
        "        'payload_json': payloadJson,",
        "        'idempotency_key': idempotencyKey,",
        "        'created_at': createdAt.toUtc().toIso8601String(),",
        "        'attempt_count': attemptCount,",
        "        'last_error': lastError,",
        "      };",
        "",
        "  factory SyncOutboxEntry.fromMap(Map<String, Object?> map) {",
        "    return SyncOutboxEntry(",
        "      id: map['id']! as String,",
        "      entityCode: map['entity_code']! as String,",
        "      recordId: map['record_id']! as String,",
        "      operation: SyncOperation.values.byName(",
        "        map['operation']! as String,",
        "      ),",
        "      payloadJson: map['payload_json'] as String?,",
        "      idempotencyKey: map['idempotency_key']! as String,",
        "      createdAt: DateTime.parse(map['created_at']! as String),",
        "      attemptCount: map['attempt_count']! as int,",
        "      lastError: map['last_error'] as String?,",
        "    );",
        "  }",
        "}",
        ""
    ]

    private static let repositoryLines = [
        "import 'package:sqflite/sqflite.dart';",
        "",
        "import '../storage/app_database.dart';",
        "import 'sync_outbox_entry.dart';",
        "",
        "abstract interface class SyncOutboxRepository {",
        "  Future<List<SyncOutboxEntry>> fetchPending({int limit = 100});",
        "  Future<void> markFailure(String id, String error);",
        "  Future<void> remove(String id);",
        "}",
        "",
        "class SqfliteSyncOutboxRepository implements SyncOutboxRepository {",
        "  const SqfliteSyncOutboxRepository(this._database);",
        "",
        "  final AppDatabase _database;",
        "",
        "  @override",
        "  Future<List<SyncOutboxEntry>> fetchPending({int limit = 100}) async {",
        "    final db = await _database.database;",
        "    final rows = await db.query(",
        "      '_sync_outbox',",
        "      orderBy: 'created_at ASC',",
        "      limit: limit,",
        "    );",
        "    return rows.map(SyncOutboxEntry.fromMap).toList(growable: false);",
        "  }",
        "",
        "  @override",
        "  Future<void> markFailure(String id, String error) async {",
        "    final db = await _database.database;",
        "    await db.rawUpdate(",
        "      'UPDATE \"_sync_outbox\" '",
        "      'SET \"attempt_count\" = \"attempt_count\" + 1, '",
        "      '\"last_error\" = ? WHERE \"id\" = ?',",
        "      <Object?>[error, id],",
        "    );",
        "  }",
        "",
        "  @override",
        "  Future<void> remove(String id) async {",
        "    final db = await _database.database;",
        "    await db.delete(",
        "      '_sync_outbox',",
        "      where: '\"id\" = ?',",
        "      whereArgs: <Object?>[id],",
        "    );",
        "  }",
        "}",
        ""
    ]
}
