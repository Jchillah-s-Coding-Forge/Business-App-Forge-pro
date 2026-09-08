import AppForgeDomain

struct FlutterDomainContractSources {
    let specification: ProjectSpecification

    func files() -> [GeneratedFile] {
        [
            GeneratedFile(
                relativePath: "lib/core/domain/domain_values.dart",
                contents: domainValuesDart()
            ),
            GeneratedFile(
                relativePath: "lib/core/domain/domain_schema.dart",
                contents: domainSchemaDart()
            )
        ]
    }
}

private extension FlutterDomainContractSources {
    func domainValuesDart() -> String {
        FlutterGeneratedText.lines(
            domainReferenceLines
                + domainFileValueLines
                + domainImageValueLines
                + domainColorValueLines
                + domainLocationValueLines
        )
    }

    private var domainReferenceLines: [String] {
        [
            "class DomainReference {",
            "  const DomainReference({",
            "    required this.entityId,",
            "    required this.recordId,",
            "  });",
            "",
            "  final String entityId;",
            "  final String recordId;",
            "}",
            ""
        ]
    }

    private var domainFileValueLines: [String] {
        uriValueLines(
            typeName: "DomainFileValue",
            label: "File",
            privateConstructor: "DomainFileValue._"
        )
    }

    private var domainImageValueLines: [String] {
        uriValueLines(
            typeName: "DomainImageValue",
            label: "Image",
            privateConstructor: "DomainImageValue._"
        )
    }

    private func uriValueLines(
        typeName: String,
        label: String,
        privateConstructor: String
    ) -> [String] {
        [
            "class \(typeName) {",
            "  factory \(typeName)(Uri uri) {",
            "    if (uri.toString().trim().isEmpty) {",
            "      throw const FormatException('\(label) URI must not be empty.');",
            "    }",
            "    return \(privateConstructor)(uri);",
            "  }",
            "",
            "  const \(privateConstructor)(this.uri);",
            "  final Uri uri;",
            "",
            "  factory \(typeName).fromStorageString(String value) {",
            "    if (value.trim().isEmpty) {",
            "      throw const FormatException('\(label) URI must not be empty.');",
            "    }",
            "    final uri = Uri.tryParse(value);",
            "    if (uri == null) {",
            "      throw FormatException('Invalid \(label.lowercased()) URI: $value');",
            "    }",
            "    return \(typeName)(uri);",
            "  }",
            "",
            "  String toStorageString() => uri.toString();",
            "}",
            ""
        ]
    }

    private var domainColorValueLines: [String] {
        [
            "class DomainColorValue {",
            "  factory DomainColorValue(String value) {",
            "    final normalized = value.trim().toUpperCase();",
            "    if (!RegExp(r'^#[0-9A-F]{6}(?:[0-9A-F]{2})?$').hasMatch(normalized)) {",
            "      throw FormatException(",
            "        'Color must use #RRGGBB or #RRGGBBAA: $value',",
            "      );",
            "    }",
            "    return DomainColorValue._(normalized);",
            "  }",
            "",
            "  const DomainColorValue._(this.hex);",
            "  final String hex;",
            "",
            "  factory DomainColorValue.fromStorageString(String value) =>",
            "      DomainColorValue(value);",
            "",
            "  String toStorageString() => hex;",
            "}",
            ""
        ]
    }

    private var domainLocationValueLines: [String] {
        [
            "class DomainLocationValue {",
            "  factory DomainLocationValue({",
            "    required num latitude,",
            "    required num longitude,",
            "  }) {",
            "    final lat = latitude.toDouble();",
            "    final lon = longitude.toDouble();",
            "    if (!lat.isFinite || lat < -90 || lat > 90) {",
            "      throw FormatException(",
            "        'Latitude must be finite and between -90 and 90: $latitude',",
            "      );",
            "    }",
            "    if (!lon.isFinite || lon < -180 || lon > 180) {",
            "      throw FormatException(",
            "        'Longitude must be finite and between -180 and 180: $longitude',",
            "      );",
            "    }",
            "    return DomainLocationValue._(latitude: lat, longitude: lon);",
            "  }",
            "",
            "  const DomainLocationValue._({",
            "    required this.latitude,",
            "    required this.longitude,",
            "  });",
            "",
            "  final double latitude;",
            "  final double longitude;",
            "",
            "  factory DomainLocationValue.fromStorageString(String value) {",
            "    final parts = value.split(',');",
            "    if (parts.length != 2) {",
            "      throw FormatException('Invalid location value: $value');",
            "    }",
            "    final latitude = double.tryParse(parts[0]);",
            "    final longitude = double.tryParse(parts[1]);",
            "    if (latitude == null || longitude == null) {",
            "      throw FormatException('Invalid location value: $value');",
            "    }",
            "    return DomainLocationValue(",
            "      latitude: latitude,",
            "      longitude: longitude,",
            "    );",
            "  }",
            "",
            "  String toStorageString() => '$latitude,$longitude';",
            "}",
            ""
        ]
    }
}

private extension FlutterDomainContractSources {
    func domainSchemaDart() -> String {
        FlutterGeneratedText.lines(
            relationSchemaTypeLines
                + relationSchemaValueLines()
                + presentationSchemaTypeLines
                + presentationSchemaValueLines()
        )
    }

    private var relationSchemaTypeLines: [String] {
        [
            "class GeneratedRelationSchema {",
            "  const GeneratedRelationSchema({",
            "    required this.id,",
            "    required this.sourceEntityId,",
            "    required this.targetEntityId,",
            "    required this.cardinality,",
            "    required this.ownership,",
            "    required this.isRequired,",
            "    required this.deleteRule,",
            "    this.joinEntityId,",
            "  });",
            "",
            "  final String id;",
            "  final String sourceEntityId;",
            "  final String targetEntityId;",
            "  final String cardinality;",
            "  final String ownership;",
            "  final bool isRequired;",
            "  final String deleteRule;",
            "  final String? joinEntityId;",
            "}",
            "",
            "const List<GeneratedRelationSchema> generatedRelations =",
            "    <GeneratedRelationSchema>["
        ]
    }

    private func relationSchemaValueLines() -> [String] {
        var lines: [String] = []
        for relation in specification.relations.sorted(by: Self.relationSort) {
            lines += relationSchemaLines(relation)
        }
        lines += ["];", ""]
        return lines
    }

    private func relationSchemaLines(
        _ relation: RelationDefinition
    ) -> [String] {
        [
            "  GeneratedRelationSchema(",
            "    id: '\(FlutterDartEscaping.singleQuoted(relation.id))',",
            "    sourceEntityId: '\(FlutterDartEscaping.singleQuoted(relation.sourceEntityID))',",
            "    targetEntityId: '\(FlutterDartEscaping.singleQuoted(relation.targetEntityID))',",
            "    cardinality: '\(relation.cardinality.rawValue)',",
            "    ownership: '\(relation.ownership.rawValue)',",
            "    isRequired: \(relation.isRequired),",
            "    deleteRule: '\(relation.deleteRule.rawValue)',",
            relation.joinEntityID.map {
                "    joinEntityId: '\(FlutterDartEscaping.singleQuoted($0))',"
            } ?? "    joinEntityId: null,",
            "  ),"
        ]
    }

    private var presentationSchemaTypeLines: [String] {
        [
            "class GeneratedFieldPresentationSchema {",
            "  const GeneratedFieldPresentationSchema({",
            "    required this.id,",
            "    required this.targetKind,",
            "    required this.targetId,",
            "    required this.control,",
            "    this.minimum,",
            "    this.maximum,",
            "  });",
            "",
            "  final String id;",
            "  final String targetKind;",
            "  final String targetId;",
            "  final String control;",
            "  final double? minimum;",
            "  final double? maximum;",
            "}",
            "",
            "const List<GeneratedFieldPresentationSchema> generatedFieldPresentations =",
            "    <GeneratedFieldPresentationSchema>["
        ]
    }

    private func presentationSchemaValueLines() -> [String] {
        var lines: [String] = []
        for presentation in specification.fieldPresentations.sorted(
            by: Self.presentationSort
        ) {
            lines += presentationSchemaLines(presentation)
        }
        lines += ["];", ""]
        return lines
    }

    private func presentationSchemaLines(
        _ presentation: FieldPresentationDefinition
    ) -> [String] {
        let target = presentationTarget(presentation.target)
        return [
            "  GeneratedFieldPresentationSchema(",
            "    id: '\(FlutterDartEscaping.singleQuoted(presentation.id))',",
            "    targetKind: '\(target.kind)',",
            "    targetId: '\(FlutterDartEscaping.singleQuoted(target.id))',",
            "    control: '\(presentation.control.rawValue)',",
            presentation.numericRange.map { "    minimum: \($0.minimum)," } ?? "    minimum: null,",
            presentation.numericRange.map { "    maximum: \($0.maximum)," } ?? "    maximum: null,",
            "  ),"
        ]
    }

    private func presentationTarget(
        _ target: PresentationTarget
    ) -> (kind: String, id: String) {
        switch target {
        case let .field(id):
            ("field", id)
        case let .relation(id):
            ("relation", id)
        }
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

    private static func presentationSort(
        _ lhs: FieldPresentationDefinition,
        _ rhs: FieldPresentationDefinition
    ) -> Bool {
        lhs.id < rhs.id
    }
}
