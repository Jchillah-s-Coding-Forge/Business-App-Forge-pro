import AppForgeDomain

struct FlutterOfflineRowMappingSource {
    let entity: EntityDefinition
    let relations: [RelationDefinition]
    let typeName: String
    let columnNames: [String: String]
    let relationColumnNames: [String: String]

    func fromRowLines() -> [String] {
        let fields = sortedFields
        let sourceRelations = sortedRelations
        guard !fields.isEmpty || !sourceRelations.isEmpty else {
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
        for relation in sourceRelations {
            guard let columnName = relationColumnNames[relation.id] else {
                continue
            }
            let memberName = FlutterDartNaming.memberName(
                relation.identity.code
            )
            lines.append(
                "      \(memberName): \(fromRowExpression(relation, columnName: columnName)),"
            )
        }
        lines += [
            "    );"
        ]
        return lines
    }

    func toRowLines() -> [String] {
        let fields = sortedFields
        let sourceRelations = sortedRelations
        guard !fields.isEmpty || !sourceRelations.isEmpty else {
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
        for relation in sourceRelations {
            guard let columnName = relationColumnNames[relation.id] else {
                continue
            }
            let memberName = FlutterDartNaming.memberName(
                relation.identity.code
            )
            lines.append(
                "      '\(columnName)': \(toRowExpression(relation, memberName: memberName)),"
            )
        }
        lines += [
            "    };"
        ]
        return lines
    }

    private var sortedFields: [FieldDefinition] {
        entity.fields.sorted(by: Self.fieldSort)
    }

    private var sortedRelations: [RelationDefinition] {
        relations.sorted(by: Self.relationSort)
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
        case .file:
            return storageValueExpression(
                lookup: lookup,
                typeName: "DomainFileValue",
                isRequired: field.isRequired
            )
        case .image:
            return storageValueExpression(
                lookup: lookup,
                typeName: "DomainImageValue",
                isRequired: field.isRequired
            )
        case .color:
            return storageValueExpression(
                lookup: lookup,
                typeName: "DomainColorValue",
                isRequired: field.isRequired
            )
        case .location:
            return storageValueExpression(
                lookup: lookup,
                typeName: "DomainLocationValue",
                isRequired: field.isRequired
            )
        case .string, .email, .phone, .url, .enumeration:
            return field.isRequired
                ? "\(lookup)! as String"
                : "\(lookup) as String?"
        }
    }

    private func fromRowExpression(
        _ relation: RelationDefinition,
        columnName: String
    ) -> String {
        let lookup = "row['\(columnName)']"
        let escapedTarget = FlutterDartEscaping.singleQuoted(
            relation.targetEntityID
        )

        switch relation.cardinality {
        case .oneToOne, .manyToOne:
            let decoded = "DomainReference(entityId: '\(escapedTarget)', recordId: \(lookup)! as String)"
            return relation.isRequired
                ? decoded
                : "\(lookup) == null ? null : \(decoded)"
        case .oneToMany, .manyToMany:
            let decoded = "(jsonDecode(\(lookup)! as String) as List<Object?>)"
                + ".map((item) => DomainReference("
                + "entityId: '\(escapedTarget)', recordId: item as String))"
                + ".toList(growable: false)"
            return relation.isRequired
                ? decoded
                : "\(lookup) == null ? null : \(decoded)"
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
        case .file, .image, .color, .location:
            return field.isRequired
                ? "\(access).toStorageString()"
                : "\(access)?.toStorageString()"
        case .integer, .decimal, .currency, .percentage,
             .string, .email, .phone, .url, .enumeration:
            return access
        }
    }

    private func toRowExpression(
        _ relation: RelationDefinition,
        memberName: String
    ) -> String {
        let access = "value.\(memberName)"

        switch relation.cardinality {
        case .oneToOne, .manyToOne:
            return relation.isRequired
                ? "\(access).recordId"
                : "\(access)?.recordId"
        case .oneToMany, .manyToMany:
            let encoded = "jsonEncode(\(access)"
                + ".map((reference) => reference.recordId)"
                + ".toList(growable: false))"
            if relation.isRequired {
                return encoded
            }
            return "\(access) == null ? null : "
                + "jsonEncode(\(access)!"
                + ".map((reference) => reference.recordId)"
                + ".toList(growable: false))"
        }
    }

    private func storageValueExpression(
        lookup: String,
        typeName: String,
        isRequired: Bool
    ) -> String {
        let decoded = "\(typeName).fromStorageString(\(lookup)! as String)"
        return isRequired
            ? decoded
            : "\(lookup) == null ? null : \(decoded)"
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

    private static func relationSort(
        _ lhs: RelationDefinition,
        _ rhs: RelationDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}
