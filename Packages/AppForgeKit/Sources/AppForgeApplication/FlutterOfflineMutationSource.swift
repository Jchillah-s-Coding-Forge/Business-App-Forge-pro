import AppForgeDomain

struct FlutterOfflineMutationSource {
    let specification: ProjectSpecification
    let entity: EntityDefinition
    let typeName: String

    func saveLines() -> [String] {
        var lines = savePreludeLines
        if specification.offline.usesSyncOutbox {
            lines += saveOutboxLines
        }
        lines += [
            "    });",
            "  }"
        ]
        return lines
    }

    func deleteLines() -> [String] {
        specification.offline.usesSyncOutbox
            ? tombstoneDeleteLines
            : hardDeleteLines
    }

    func enqueueLines() -> [String] {
        guard specification.offline.usesSyncOutbox else {
            return []
        }

        return [
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

    private var savePreludeLines: [String] {
        [
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
    }

    private var saveOutboxLines: [String] {
        [
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

    private var hardDeleteLines: [String] {
        [
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

    private var tombstoneDeleteLines: [String] {
        [
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

    private var saveSyncStatus: String {
        specification.offline.usesSyncOutbox
            ? "pending"
            : "clean"
    }
}
