import AppForgeDomain

struct FlutterOfflineCoreSources {
    let specification: ProjectSpecification
    let packageName: String

    func files() throws -> [GeneratedFile] {
        guard specification.offline.isEnabled else {
            return []
        }

        let statements = try FlutterSQLiteSchema(
            specification: specification
        ).createStatements()

        var files = [
            GeneratedFile(
                relativePath: "lib/core/storage/app_database.dart",
                contents: appDatabase()
            ),
            GeneratedFile(
                relativePath: "lib/core/storage/database_migrations.dart",
                contents: databaseMigrations(statements: statements)
            ),
            GeneratedFile(
                relativePath: "lib/core/sync/sync_status.dart",
                contents: syncStatus()
            ),
            GeneratedFile(
                relativePath: "lib/core/sync/sync_policy.dart",
                contents: syncPolicy()
            )
        ]

        if specification.offline.usesSyncOutbox {
            files += [
                GeneratedFile(
                    relativePath: "lib/core/sync/sync_operation.dart",
                    contents: syncOperation()
                ),
                GeneratedFile(
                    relativePath: "lib/core/sync/sync_outbox_entry.dart",
                    contents: syncOutboxEntry()
                ),
                GeneratedFile(
                    relativePath: "lib/core/sync/sync_outbox_repository.dart",
                    contents: syncOutboxRepository()
                )
            ]
        }

        return files
    }

    private func appDatabase() -> String {
        FlutterGeneratedText.lines([
            "import 'package:path/path.dart' as p;",
            "import 'package:sqflite/sqflite.dart';",
            "",
            "import 'database_migrations.dart';",
            "",
            "class AppDatabase {",
            "  AppDatabase({this.databaseName = '\(packageName).db'});",
            "",
            "  final String databaseName;",
            "  Database? _database;",
            "",
            "  Future<Database> get database async {",
            "    return _database ??= await _open();",
            "  }",
            "",
            "  Future<Database> _open() async {",
            "    final root = await getDatabasesPath();",
            "    return openDatabase(",
            "      p.join(root, databaseName),",
            "      version: DatabaseMigrations.schemaVersion,",
            "      onCreate: (db, _) => DatabaseMigrations.create(db),",
            "      onUpgrade: (db, oldVersion, newVersion) =>",
            "          DatabaseMigrations.upgrade(",
            "        db,",
            "        fromVersion: oldVersion,",
            "        toVersion: newVersion,",
            "      ),",
            "    );",
            "  }",
            "",
            "  Future<void> close() async {",
            "    final current = _database;",
            "    _database = null;",
            "    await current?.close();",
            "  }",
            "}",
            ""
        ])
    }

    private func databaseMigrations(
        statements: [String]
    ) -> String {
        let statementLines = statements.map { statement in
            "    '\(FlutterDartEscaping.singleQuoted(statement))',"
        }

        return FlutterGeneratedText.lines(
            [
                "import 'package:sqflite/sqflite.dart';",
                "",
                "abstract final class DatabaseMigrations {",
                "  static const schemaVersion = 1;",
                "",
                "  static const createStatements = <String>["
            ]
                + statementLines
                + [
                    "  ];",
                    "",
                    "  static Future<void> create(DatabaseExecutor db) async {",
                    "    for (final statement in createStatements) {",
                    "      await db.execute(statement);",
                    "    }",
                    "  }",
                    "",
                    "  static Future<void> upgrade(",
                    "    DatabaseExecutor db, {",
                    "    required int fromVersion,",
                    "    required int toVersion,",
                    "  }) async {",
                    "    if (toVersion > schemaVersion) {",
                    "      throw StateError('Unsupported database schema version');",
                    "    }",
                    "    if (fromVersion < 1 && toVersion >= 1) {",
                    "      await create(db);",
                    "    }",
                    "  }",
                    "}",
                    ""
                ]
        )
    }

    private func syncOperation() -> String {
        FlutterGeneratedText.lines([
            "enum SyncOperation {",
            "  create,",
            "  update,",
            "  delete,",
            "}",
            ""
        ])
    }

    private func syncStatus() -> String {
        FlutterGeneratedText.lines([
            "enum SyncStatus {",
            "  clean,",
            "  pending,",
            "  syncing,",
            "  conflict,",
            "  failed,",
            "  deleted,",
            "}",
            ""
        ])
    }

    private func syncPolicy() -> String {
        let strategy = switch specification.offline.conflictResolution {
        case .latestWriteWins:
            "latestWriteWins"
        case .serverWins:
            "serverWins"
        case .clientWins:
            "clientWins"
        case .manualReview:
            "manualReview"
        }
        let reconnect = specification.offline.syncsOnReconnect
            ? "true"
            : "false"

        return FlutterGeneratedText.lines([
            "enum SyncConflictStrategy {",
            "  latestWriteWins,",
            "  serverWins,",
            "  clientWins,",
            "  manualReview,",
            "}",
            "",
            "class SyncPolicy {",
            "  const SyncPolicy({",
            "    required this.strategy,",
            "    required this.syncsOnReconnect,",
            "  });",
            "",
            "  final SyncConflictStrategy strategy;",
            "  final bool syncsOnReconnect;",
            "",
            "  static const current = SyncPolicy(",
            "    strategy: SyncConflictStrategy.\(strategy),",
            "    syncsOnReconnect: \(reconnect),",
            "  );",
            "}",
            ""
        ])
    }

    private func syncOutboxEntry() -> String {
        FlutterGeneratedText.lines([
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
        ])
    }

    private func syncOutboxRepository() -> String {
        FlutterGeneratedText.lines([
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
        ])
    }
}
