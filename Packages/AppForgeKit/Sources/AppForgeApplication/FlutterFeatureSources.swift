import AppForgeDomain

struct FlutterFeatureSources {
    let specification: ProjectSpecification
    let entity: EntityDefinition

    func files() throws -> [GeneratedFile] {
        let featureName = FlutterDartNaming.snakeCase(entity.identity.code)
        let typeName = FlutterDartNaming.typeName(entity.identity.code)
        guard FlutterDartNaming.isUsableIdentifier(featureName),
              FlutterDartNaming.isUsableIdentifier(typeName)
        else {
            throw FlutterRendererError.invalidGeneratedIdentifier(
                definitionID: entity.id,
                code: entity.identity.code
            )
        }

        let fields = entity.fields.sorted(by: Self.fieldSort)
        let relations = specification.relations
            .filter { $0.sourceEntityID == entity.id }
            .sorted(by: Self.relationSort)
        return generatedFiles(
            featureName: featureName,
            typeName: typeName,
            fields: fields,
            relations: relations
        )
    }
}

private extension FlutterFeatureSources {
    func generatedFiles(
        featureName: String,
        typeName: String,
        fields: [FieldDefinition],
        relations: [RelationDefinition]
    ) -> [GeneratedFile] {
        [
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/entities/\(featureName).dart",
                contents: entityDart(
                    typeName: typeName,
                    fields: fields,
                    relations: relations
                )
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/repositories/\(featureName)_repository.dart",
                contents: repositoryDart(
                    featureName: featureName,
                    typeName: typeName
                )
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/use_cases/get_\(featureName)_list.dart",
                contents: useCaseDart(
                    featureName: featureName,
                    typeName: typeName
                )
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/use_cases/save_\(featureName).dart",
                contents: saveUseCaseDart(
                    featureName: featureName,
                    typeName: typeName
                )
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/use_cases/delete_\(featureName).dart",
                contents: deleteUseCaseDart(
                    featureName: featureName,
                    typeName: typeName
                )
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/presentation/view_models/\(featureName)_view_model.dart",
                contents: viewModelDart(
                    featureName: featureName,
                    typeName: typeName
                )
            )
        ]
    }
}

private extension FlutterFeatureSources {
    func entityDart(
        typeName: String,
        fields: [FieldDefinition],
        relations: [RelationDefinition]
    ) -> String {
        let needsDomainImport = fields.contains(
            where: FlutterDartNaming.usesDomainValueObject
        ) || !relations.isEmpty
        guard !fields.isEmpty || !relations.isEmpty else {
            return emptyEntityDart(
                typeName: typeName,
                needsDomainImport: needsDomainImport
            )
        }

        var lines = domainImportLines(when: needsDomainImport)
        lines += ["class \(typeName) {"]
        lines += constructorLines(
            typeName: typeName,
            fields: fields,
            relations: relations
        )
        lines += [""]
        lines += propertyLines(fields: fields, relations: relations)
        lines += ["}", ""]
        return FlutterGeneratedText.lines(lines)
    }

    func emptyEntityDart(
        typeName: String,
        needsDomainImport: Bool
    ) -> String {
        var lines = domainImportLines(when: needsDomainImport)
        lines += [
            "class \(typeName) {",
            "  const \(typeName)();",
            "}",
            ""
        ]
        return FlutterGeneratedText.lines(lines)
    }

    func domainImportLines(when needed: Bool) -> [String] {
        needed
            ? [
                "import '../../../../core/domain/domain_values.dart';",
                ""
            ]
            : []
    }

    func constructorLines(
        typeName: String,
        fields: [FieldDefinition],
        relations: [RelationDefinition]
    ) -> [String] {
        let hasToManyRelation = relations.contains(where: Self.isToMany)
        var lines = [
            "  \(hasToManyRelation ? "" : "const ")\(typeName)({"
        ]
        lines += fields.map(fieldConstructorLine)
        lines += relations.map(relationConstructorLine)
        lines += relationInitializerLines(
            relations: relations,
            hasToManyRelation: hasToManyRelation
        )
        return lines
    }

    func fieldConstructorLine(_ field: FieldDefinition) -> String {
        let identifier = FlutterDartNaming.memberName(field.identity.code)
        return field.isRequired
            ? "    required this.\(identifier),"
            : "    this.\(identifier),"
    }

    func relationConstructorLine(_ relation: RelationDefinition) -> String {
        let identifier = FlutterDartNaming.memberName(relation.identity.code)
        let type = relationBaseType(relation)
        if Self.isToMany(relation) {
            return relation.isRequired
                ? "    required \(type) \(identifier),"
                : "    \(type)? \(identifier),"
        }
        return relation.isRequired
            ? "    required this.\(identifier),"
            : "    this.\(identifier),"
    }

    func relationInitializerLines(
        relations: [RelationDefinition],
        hasToManyRelation: Bool
    ) -> [String] {
        guard hasToManyRelation else {
            return ["  });"]
        }

        let initializers = relations
            .filter(Self.isToMany)
            .map(relationInitializer)
        var lines = ["  })"]
        for (index, initializer) in initializers.enumerated() {
            let prefix = index == 0 ? "      : " : "        "
            let suffix = index == initializers.count - 1 ? ";" : ","
            lines.append("\(prefix)\(initializer)\(suffix)")
        }
        return lines
    }

    func relationInitializer(_ relation: RelationDefinition) -> String {
        let identifier = FlutterDartNaming.memberName(relation.identity.code)
        if relation.isRequired {
            return "\(identifier) = "
                + "List<DomainReference>.unmodifiable(\(identifier))"
        }
        return "\(identifier) = \(identifier) == null ? null : "
            + "List<DomainReference>.unmodifiable(\(identifier))"
    }

    func propertyLines(
        fields: [FieldDefinition],
        relations: [RelationDefinition]
    ) -> [String] {
        let fieldLines = fields.map { field in
            let identifier = FlutterDartNaming.memberName(field.identity.code)
            let type = FlutterDartNaming.dartType(for: field)
            return "  final \(type) \(identifier);"
        }
        let relationLines = relations.map { relation in
            let identifier = FlutterDartNaming.memberName(
                relation.identity.code
            )
            let type = relationBaseType(relation)
            return "  final \(type)\(relation.isRequired ? "" : "?") "
                + "\(identifier);"
        }
        return fieldLines + relationLines
    }

    func relationBaseType(_ relation: RelationDefinition) -> String {
        Self.isToMany(relation)
            ? "List<DomainReference>"
            : "DomainReference"
    }
}

private extension FlutterFeatureSources {
    func repositoryDart(
        featureName: String,
        typeName: String
    ) -> String {
        FlutterGeneratedText.lines([
            "import '../../../../core/domain/domain_values.dart';",
            "",
            "import '../entities/\(featureName).dart';",
            "",
            "abstract interface class \(typeName)Repository {",
            "  Future<List<DomainRecord<\(typeName)>>> fetchAll();",
            "  Future<void> save({",
            "    required String recordId,",
            "    required \(typeName) value,",
            "  });",
            "  Future<void> delete(String recordId);",
            "}",
            ""
        ])
    }

    func useCaseDart(
        featureName: String,
        typeName: String
    ) -> String {
        FlutterGeneratedText.lines([
            "import '../../../../core/domain/domain_values.dart';",
            "",
            "import '../entities/\(featureName).dart';",
            "import '../repositories/\(featureName)_repository.dart';",
            "",
            "class Get\(typeName)List {",
            "  const Get\(typeName)List(this._repository);",
            "",
            "  final \(typeName)Repository _repository;",
            "",
            "  Future<List<DomainRecord<\(typeName)>>> call() =>",
            "      _repository.fetchAll();",
            "}",
            ""
        ])
    }

    func saveUseCaseDart(
        featureName: String,
        typeName: String
    ) -> String {
        FlutterGeneratedText.lines([
            "import '../entities/\(featureName).dart';",
            "import '../repositories/\(featureName)_repository.dart';",
            "",
            "class Save\(typeName) {",
            "  const Save\(typeName)(this._repository);",
            "",
            "  final \(typeName)Repository _repository;",
            "",
            "  Future<void> call({",
            "    required String recordId,",
            "    required \(typeName) value,",
            "  }) =>",
            "      _repository.save(recordId: recordId, value: value);",
            "}",
            ""
        ])
    }

    func deleteUseCaseDart(
        featureName: String,
        typeName: String
    ) -> String {
        FlutterGeneratedText.lines([
            "import '../repositories/\(featureName)_repository.dart';",
            "",
            "class Delete\(typeName) {",
            "  const Delete\(typeName)(this._repository);",
            "",
            "  final \(typeName)Repository _repository;",
            "",
            "  Future<void> call(String recordId) => _repository.delete(recordId);",
            "}",
            ""
        ])
    }

    func viewModelDart(
        featureName: String,
        typeName: String
    ) -> String {
        FlutterGeneratedText.lines([
            "import '../../../../core/domain/domain_values.dart';",
            "",
            "import '../../domain/entities/\(featureName).dart';",
            "import '../../domain/use_cases/get_\(featureName)_list.dart';",
            "",
            "class \(typeName)ViewModel {",
            "  const \(typeName)ViewModel(this._get\(typeName)List);",
            "",
            "  final Get\(typeName)List _get\(typeName)List;",
            "",
            "  Future<List<DomainRecord<\(typeName)>>> load() =>",
            "      _get\(typeName)List();",
            "}",
            ""
        ])
    }
}

private extension FlutterFeatureSources {
    static func fieldSort(
        _ lhs: FieldDefinition,
        _ rhs: FieldDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }

    static func relationSort(
        _ lhs: RelationDefinition,
        _ rhs: RelationDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }

    static func isToMany(_ relation: RelationDefinition) -> Bool {
        switch relation.cardinality {
        case .oneToMany, .manyToMany:
            true
        case .oneToOne, .manyToOne:
            false
        }
    }
}
