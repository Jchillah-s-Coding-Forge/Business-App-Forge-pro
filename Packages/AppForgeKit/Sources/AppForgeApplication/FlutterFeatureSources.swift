import AppForgeDomain

struct FlutterFeatureSources {
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
        try validateFieldIdentifiers(fields)

        return [
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/entities/\(featureName).dart",
                contents: entityDart(typeName: typeName, fields: fields)
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
                relativePath: "lib/features/\(featureName)/presentation/view_models/\(featureName)_view_model.dart",
                contents: viewModelDart(featureName: featureName, typeName: typeName)
            )
        ]
    }

    private func validateFieldIdentifiers(
        _ fields: [FieldDefinition]
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
    }

    private func entityDart(
        typeName: String,
        fields: [FieldDefinition]
    ) -> String {
        guard !fields.isEmpty else {
            return FlutterGeneratedText.lines([
                "class \(typeName) {",
                "  const \(typeName)();",
                "}",
                ""
            ])
        }

        let constructorLines = fields.map { field in
            let identifier = FlutterDartNaming.memberName(field.identity.code)
            return field.isRequired
                ? "    required this.\(identifier),"
                : "    this.\(identifier),"
        }
        let propertyLines = fields.map { field in
            let identifier = FlutterDartNaming.memberName(field.identity.code)
            let type = FlutterDartNaming.dartType(for: field)
            return "  final \(type) \(identifier);"
        }

        return FlutterGeneratedText.lines(
            [
                "class \(typeName) {",
                "  const \(typeName)({"
            ]
                + constructorLines
                + [
                    "  });",
                    ""
                ]
                + propertyLines
                + [
                    "}",
                    ""
                ]
        )
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
}
