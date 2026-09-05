import AppForgeDomain

struct FlutterOfflineRowMappingSource {
    let entity: EntityDefinition
    let typeName: String
    let columnNames: [String: String]

    func fromRowLines() -> [String] {
        let fields = sortedFields
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

    func toRowLines() -> [String] {
        let fields = sortedFields
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

    private var sortedFields: [FieldDefinition] {
        entity.fields.sorted(by: Self.fieldSort)
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
