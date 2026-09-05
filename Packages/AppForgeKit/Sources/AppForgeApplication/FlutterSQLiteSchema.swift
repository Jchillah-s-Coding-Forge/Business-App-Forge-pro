import AppForgeDomain

struct FlutterSQLiteSchema {
    let specification: ProjectSpecification

    func createStatements() throws -> [String] {
        var statements: [String] = []
        if specification.offline.usesSyncOutbox {
            statements += [
                outboxTableStatement(),
                outboxCreatedAtIndexStatement()
            ]
        }

        for entity in specification.entities.sorted(by: Self.entitySort) {
            statements.append(try entityTableStatement(entity))
            statements += try entityIndexStatements(entity)
        }

        return statements
    }

    private func outboxTableStatement() -> String {
        """
        CREATE TABLE IF NOT EXISTS "_sync_outbox" (\
        "id" TEXT PRIMARY KEY, \
        "entity_code" TEXT NOT NULL, \
        "record_id" TEXT NOT NULL, \
        "operation" TEXT NOT NULL, \
        "payload_json" TEXT, \
        "idempotency_key" TEXT NOT NULL UNIQUE, \
        "created_at" TEXT NOT NULL, \
        "attempt_count" INTEGER NOT NULL DEFAULT 0, \
        "last_error" TEXT\
        )
        """
    }

    private func outboxCreatedAtIndexStatement() -> String {
        """
        CREATE INDEX IF NOT EXISTS "idx_sync_outbox_created_at" \
        ON "_sync_outbox" ("created_at")
        """
    }

    private func entityTableStatement(
        _ entity: EntityDefinition
    ) throws -> String {
        let tableName = try FlutterOfflineStorageNaming.tableName(
            for: entity
        )
        let columns = try FlutterOfflineStorageNaming.columnNames(
            for: entity
        )

        var definitions = [
            "\"_record_id\" TEXT PRIMARY KEY",
            "\"_sync_revision\" INTEGER NOT NULL DEFAULT 0",
            "\"_sync_status\" TEXT NOT NULL",
            "\"_updated_at\" TEXT NOT NULL",
            "\"_deleted_at\" TEXT"
        ]

        for field in entity.fields.sorted(by: Self.fieldSort) {
            guard let columnName = columns[field.id] else {
                continue
            }
            var definition = "\"\(columnName)\" \(sqliteType(field.dataType))"
            if field.isRequired {
                definition += " NOT NULL"
            }
            if field.isUnique {
                definition += " UNIQUE"
            }
            definitions.append(definition)
        }

        return "CREATE TABLE IF NOT EXISTS \"\(tableName)\" ("
            + definitions.joined(separator: ", ")
            + ")"
    }

    private func entityIndexStatements(
        _ entity: EntityDefinition
    ) throws -> [String] {
        let tableName = try FlutterOfflineStorageNaming.tableName(
            for: entity
        )
        let columns = try FlutterOfflineStorageNaming.columnNames(
            for: entity
        )

        return entity.fields
            .filter(\.isIndexed)
            .sorted(by: Self.fieldSort)
            .compactMap { field in
                guard let columnName = columns[field.id] else {
                    return nil
                }
                return "CREATE INDEX IF NOT EXISTS "
                    + "\"idx_\(tableName)_\(columnName)\" "
                    + "ON \"\(tableName)\" (\"\(columnName)\")"
            }
    }

    private func sqliteType(
        _ dataType: FieldDataType
    ) -> String {
        switch dataType {
        case .integer, .boolean:
            "INTEGER"
        case .decimal, .currency, .percentage:
            "REAL"
        case .string, .date, .dateTime, .time, .email, .phone, .url,
             .enumeration, .file, .image, .color, .location:
            "TEXT"
        }
    }

    private static func entitySort(
        _ lhs: EntityDefinition,
        _ rhs: EntityDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
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
