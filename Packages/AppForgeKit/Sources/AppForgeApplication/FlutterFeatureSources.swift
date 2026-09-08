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
        try validateMemberIdentifiers(fields: fields, relations: relations)

        return [
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
                contents: repositoryDart(featureName: featureName, typeName: typeName)
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/use_cases/get_\(featureName)_list.dart",
                contents: useCaseDart(featureName: featureName, typeName: typeName)
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/use_cases/save_\(featureName).dart",
                contents: saveUseCaseDart(featureName: featureName, typeName: typeName)
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/use_cases/delete_\(featureName).dart",
                contents: deleteUseCaseDart(featureName: featureName, typeName: typeName)
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/presentation/view_models/\(featureName)_view_model.dart",
                contents: viewModelDart(featureName: featureName, typeName: typeName)
            )
        ]
    }

    private func validateMemberIdentifiers(
        fields: [FieldDefinition],
        relations: [RelationDefinition]
    ) throws {
        var generatedNames = Set<String>()

        for field in fields {
            let identifier = FlutterDartNaming.memberName(field.identity.code)
            guard FlutterDartNaming.isUsableIdentifier(identifier) else {
                throw FlutterRendererError.invalidGeneratedIdentifier(
                    definitionID: field.id,
                    code: field.identity.code
                )
            }
            guard generatedNames.insert(identifier).inserted else {
                throw FlutterRendererError.duplicateGeneratedIdentifier(
                    entityID: entity.id,
                    identifier: identifier
                )
            }
        }

        for relation in relations {
            let identifier = FlutterDartNaming.memberName(relation.identity.code)
            guard FlutterDartNaming.isUsableIdentifier(identifier) else {
                throw FlutterRendererError.invalidGeneratedIdentifier(
                    definitionID: relation.id,
                    code: relation.identity.code
                )
            }
            guard generatedNames.insert(identifier).inserted else {
                throw FlutterRendererError.duplicateGeneratedIdentifier(
                    entityID: entity.id,
                    identifier: identifier
                )
            }
        }
    }

    private func entityDart(
        typeName: String,
        fields: [FieldDefinition],
        relations: [RelationDefinition]
    ) -> String {
        let needsDomainImport = fields.contains(where: FlutterDartNaming.usesDomainValueObject)
            || !relations.isEmpty
        let hasToManyRelation = relations.contains(where: Self.isToMany)

        var lines: [String] = []
        if needsDomainImport {
            lines += [
                "import '../../../../core/domain/domain_values.dart';",
                ""
            ]
        }

        guard !fields.isEmpty || !relations.isEmpty else {
            lines += [
                "class \(typeName) {",
                "  const \(typeName)();",
                "}",
                ""
            ]
            return FlutterGeneratedText.lines(lines)
        }

        lines += [
            "class \(typeName) {",
            "  \(hasToManyRelation ? "" : "const ")\(typeName)({"
        ]

        for field in fields {
            let identifier = FlutterDartNaming.memberName(field.identity.code)
            lines.append(
                field.isRequired
                    ? "    required this.\(identifier),"
                    : "    this.\(identifier),"
            )
        }

        for relation in relations {
            let identifier = FlutterDartNaming.memberName(relation.identity.code)
            let type = relationBaseType(relation)
            if Self.isToMany(relation) {
                lines.append(
                    relation.isRequired
                        ? "    required \(type) \(identifier),"
                        : "    \(type)? \(identifier),"
                )
            } else {
                lines.append(
                    relation.isRequired
                        ? "    required this.\(identifier),"
                        : "    this.\(identifier),"
                )
            }
        }

        if hasToManyRelation {
            let initializers = relations
                .filter(Self.isToMany)
                .map { relation -> String in
                    let identifier = FlutterDartNaming.memberName(
                        relation.identity.code
                    )
                    if relation.isRequired {
                        return "\(identifier) = List<DomainReference>.unmodifiable(\(identifier))"
                    }
                    return "\(identifier) = \(identifier) == null ? null : List<DomainReference>.unmodifiable(\(identifier))"
                }
            lines.append("  })")
            for (index, initializer) in initializers.enumerated() {
                let prefix = index == 0 ? "      : " : "        "
                let suffix = index == initializers.count - 1 ? ";" : ","
                lines.append("\(prefix)\(initializer)\(suffix)")
            }
        } else {
            lines.append("  });")
        }

        lines.append("")
        for field in fields {
            let identifier = FlutterDartNaming.memberName(field.identity.code)
            let type = FlutterDartNaming.dartType(for: field)
            lines.append("  final \(type) \(identifier);")
        }
        for relation in relations {
            let identifier = FlutterDartNaming.memberName(relation.identity.code)
            let type = relationBaseType(relation)
            lines.append(
                "  final \(type)\(relation.isRequired ? "" : "?") \(identifier);"
            )
        }
        lines += [
            "}",
            ""
        ]

        return FlutterGeneratedText.lines(lines)
    }

    private func relationBaseType(_ relation: RelationDefinition) -> String {
        Self.isToMany(relation)
            ? "List<DomainReference>"
            : "DomainReference"
    }

    private func repositoryDart(
        featureName: String,
        typeName: String
    ) -> String {
        FlutterGeneratedText.lines([
            "import '../entities/\(featureName).dart';",
            "",
            "abstract interface class \(typeName)Repository {",
            "  Future<List<\(typeName)>> fetchAll();",
            "  Future<void> save({",
            "    required String recordId,",
            "    required \(typeName) value,",
            "  });",
            "  Future<void> delete(String recordId);",
            "}",
            ""
        ])
    }

    private func useCaseDart(
        featureName: String,
        typeName: String
    ) -> String {
        FlutterGeneratedText.lines([
            "import '../entities/\(featureName).dart';",
            "import '../repositories/\(featureName)_repository.dart';",
            "",
            "class Get\(typeName)List {",
            "  const Get\(typeName)List(this._repository);",
            "",
            "  final \(typeName)Repository _repository;",
            "",
            "  Future<List<\(typeName)>> call() => _repository.fetchAll();",
            "}",
            ""
        ])
    }

    private func saveUseCaseDart(
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

    private func deleteUseCaseDart(
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

    private func viewModelDart(
        featureName: String,
        typeName: String
    ) -> String {
        FlutterGeneratedText.lines([
            "import '../../domain/entities/\(featureName).dart';",
            "import '../../domain/use_cases/get_\(featureName)_list.dart';",
            "",
            "class \(typeName)ViewModel {",
            "  const \(typeName)ViewModel(this._get\(typeName)List);",
            "",
            "  final Get\(typeName)List _get\(typeName)List;",
            "",
            "  Future<List<\(typeName)>> load() => _get\(typeName)List();",
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

    private static func relationSort(
        _ lhs: RelationDefinition,
        _ rhs: RelationDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }

    private static func isToMany(_ relation: RelationDefinition) -> Bool {
        switch relation.cardinality {
        case .oneToMany, .manyToMany:
            true
        case .oneToOne, .manyToOne:
            false
        }
    }
}
