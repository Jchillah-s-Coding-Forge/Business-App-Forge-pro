import AppForgeDomain

enum FlutterOfflineStorageNaming {
    static let outboxTable = "_sync_outbox"
    static let recordIDColumn = "_record_id"
    static let revisionColumn = "_sync_revision"
    static let statusColumn = "_sync_status"
    static let updatedAtColumn = "_updated_at"
    static let deletedAtColumn = "_deleted_at"

    static func tableName(
        for entity: EntityDefinition
    ) throws -> String {
        let identifier = FlutterDartNaming.snakeCase(entity.identity.code)
        try validateBusinessIdentifier(
            identifier,
            definitionID: entity.id
        )
        return identifier
    }

    static func columnNames(
        for entity: EntityDefinition
    ) throws -> [String: String] {
        var result: [String: String] = [:]
        var seen = Set<String>()

        for field in entity.fields.sorted(by: fieldSort) {
            let identifier = FlutterDartNaming.snakeCase(
                field.identity.code
            )
            try validateBusinessIdentifier(
                identifier,
                definitionID: field.id
            )
            guard seen.insert(identifier.lowercased()).inserted else {
                throw FlutterRendererError.duplicateGeneratedStorageIdentifier(
                    entityID: entity.id,
                    identifier: identifier
                )
            }
            result[field.id] = identifier
        }

        return result
    }

    private static func validateBusinessIdentifier(
        _ identifier: String,
        definitionID: String
    ) throws {
        guard FlutterDartNaming.isUsableIdentifier(identifier),
              !identifier.hasPrefix("_")
        else {
            throw FlutterRendererError.reservedGeneratedStorageIdentifier(
                definitionID: definitionID,
                identifier: identifier
            )
        }
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
