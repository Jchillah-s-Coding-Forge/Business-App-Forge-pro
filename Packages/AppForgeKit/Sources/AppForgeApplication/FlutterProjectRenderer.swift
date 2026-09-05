import AppForgeDomain
import Foundation

public protocol FlutterProjectRendering: Sendable {
    func makePlan(
        specification: ProjectSpecification,
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile
    ) throws -> GenerationPlan
}

public enum FlutterRendererError: Error, Equatable, Sendable {
    case unsupportedFramework(OutputFramework)
    case invalidSpecification([ProjectSpecificationValidationIssue])
    case lockfileMismatch
    case invalidProjectPackageName(String)
    case duplicateGeneratedIdentifier(entityID: String, identifier: String)
    case encodingFailed
}

public struct DeterministicFlutterProjectRenderer: FlutterProjectRendering {
    public static let rendererVersion = 1

    private let specificationValidator: ProjectSpecificationValidator
    private let lockfileBuilder: ForgeLockfileBuilder

    public init(
        specificationValidator: ProjectSpecificationValidator = ProjectSpecificationValidator(),
        lockfileBuilder: ForgeLockfileBuilder = ForgeLockfileBuilder()
    ) {
        self.specificationValidator = specificationValidator
        self.lockfileBuilder = lockfileBuilder
    }

    public func makePlan(
        specification: ProjectSpecification,
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile
    ) throws -> GenerationPlan {
        guard specification.framework == .flutter else {
            throw FlutterRendererError.unsupportedFramework(specification.framework)
        }

        let issues = specificationValidator.validate(specification)
        guard issues.isEmpty else {
            throw FlutterRendererError.invalidSpecification(issues)
        }

        let expectedLockfile = lockfileBuilder.build(
            graph: graph,
            specification: specification
        )
        guard expectedLockfile == lockfile else {
            throw FlutterRendererError.lockfileMismatch
        }

        let packageName = try DartNaming.packageName(from: specification.identity.name)
        var files = try baseFiles(
            specification: specification,
            graph: graph,
            lockfile: lockfile,
            packageName: packageName
        )

        for entity in specification.entities.sorted(by: Self.entitySort) {
            files.append(
                contentsOf: try featureFiles(
                    for: entity,
                    packageName: packageName
                )
            )
        }

        files.append(
            try generationManifestFile(
                specification: specification,
                graph: graph,
                packageName: packageName,
                existingFiles: files
            )
        )

        return try GenerationPlan(files: files)
    }

    private func baseFiles(
        specification: ProjectSpecification,
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile,
        packageName: String
    ) throws -> [GeneratedFile] {
        let lockfileData = try ForgeLockfileCodec().encode(lockfile)
        guard let lockfileText = String(data: lockfileData, encoding: .utf8) else {
            throw FlutterRendererError.encodingFailed
        }

        return [
            GeneratedFile(
                relativePath: ".gitignore",
                contents: gitignore()
            ),
            GeneratedFile(
                relativePath: "README.md",
                contents: readme(
                    specification: specification,
                    graph: graph,
                    packageName: packageName
                )
            ),
            GeneratedFile(
                relativePath: "forge.lock",
                contents: lockfileText
            ),
            GeneratedFile(
                relativePath: "lib/app.dart",
                contents: appDart(specification: specification)
            ),
            GeneratedFile(
                relativePath: "lib/main.dart",
                contents: mainDart(specification: specification)
            ),
            GeneratedFile(
                relativePath: "pubspec.yaml",
                contents: pubspec(
                    specification: specification,
                    packageName: packageName
                )
            ),
            GeneratedFile(
                relativePath: "test/app_smoke_test.dart",
                contents: smokeTest(
                    specification: specification,
                    packageName: packageName
                )
            )
        ] + stateManagementFiles(specification: specification)
    }

    private func featureFiles(
        for entity: EntityDefinition,
        packageName: String
    ) throws -> [GeneratedFile] {
        let featureName = DartNaming.snakeCase(entity.identity.code)
        let typeName = DartNaming.typeName(entity.identity.code)
        let fields = entity.fields.sorted(by: Self.fieldSort)
        var generatedNames = Set<String>()

        for field in fields {
            let identifier = DartNaming.memberName(field.identity.code)
            guard generatedNames.insert(identifier).inserted else {
                throw FlutterRendererError.duplicateGeneratedIdentifier(
                    entityID: entity.id,
                    identifier: identifier
                )
            }
        }

        return [
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/domain/entities/\(featureName).dart",
                contents: entityDart(typeName: typeName, fields: fields)
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
                relativePath: "lib/features/\(featureName)/presentation/view_models/\(featureName)_view_model.dart",
                contents: viewModelDart(
                    featureName: featureName,
                    typeName: typeName
                )
            )
        ]
    }

    private func stateManagementFiles(
        specification: ProjectSpecification
    ) -> [GeneratedFile] {
        switch specification.flutterStateManagement {
        case .riverpod:
            []
        case .blocCubit:
            [
                GeneratedFile(
                    relativePath: "lib/core/state/app_cubit.dart",
                    contents: """
                    import 'package:flutter_bloc/flutter_bloc.dart';

                    class AppCubit extends Cubit<bool> {
                      AppCubit() : super(true);
                    }

                    """
                )
            ]
        case nil:
            []
        }
    }

    private func pubspec(
        specification: ProjectSpecification,
        packageName: String
    ) -> String {
        let stateDependency: String
        switch specification.flutterStateManagement {
        case .riverpod:
            stateDependency = "  flutter_riverpod: ^3.3.2"
        case .blocCubit:
            stateDependency = "  flutter_bloc: ^9.1.1"
        case nil:
            stateDependency = ""
        }

        return """
        name: \(packageName)
        description: \(DartEscaping.yamlQuoted("Generated by AppForge Pro for \(specification.identity.name)."))
        publish_to: "none"
        version: 0.1.0+1

        environment:
          sdk: ">=3.10.0 <4.0.0"
          flutter: ">=3.44.0"

        dependencies:
          flutter:
            sdk: flutter
        \(stateDependency)

        dev_dependencies:
          flutter_test:
            sdk: flutter

        flutter:
          uses-material-design: true

        """
    }

    private func mainDart(specification: ProjectSpecification) -> String {
        switch specification.flutterStateManagement {
        case .riverpod:
            """
            import 'package:flutter/material.dart';
            import 'package:flutter_riverpod/flutter_riverpod.dart';

            import 'app.dart';

            void main() {
              runApp(
                const ProviderScope(
                  child: App(),
                ),
              );
            }

            """
        case .blocCubit:
            """
            import 'package:flutter/material.dart';
            import 'package:flutter_bloc/flutter_bloc.dart';

            import 'app.dart';
            import 'core/state/app_cubit.dart';

            void main() {
              runApp(
                BlocProvider(
                  create: (_) => AppCubit(),
                  child: const App(),
                ),
              );
            }

            """
        case nil:
            """
            import 'package:flutter/material.dart';

            import 'app.dart';

            void main() {
              runApp(const App());
            }

            """
        }
    }

    private func appDart(specification: ProjectSpecification) -> String {
        let displayName = specification.design.appDisplayName ?? specification.identity.name
        let escapedName = DartEscaping.singleQuoted(displayName)

        return """
        import 'package:flutter/material.dart';

        class App extends StatelessWidget {
          const App({super.key});

          @override
          Widget build(BuildContext context) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: '\(escapedName)',
              home: const _AppHome(),
            );
          }
        }

        class _AppHome extends StatelessWidget {
          const _AppHome();

          @override
          Widget build(BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('\(escapedName)'),
              ),
              body: const Center(
                child: Text('Generated with AppForge Pro'),
              ),
            );
          }
        }

        """
    }

    private func entityDart(
        typeName: String,
        fields: [FieldDefinition]
    ) -> String {
        guard !fields.isEmpty else {
            return """
            class \(typeName) {
              const \(typeName)();
            }

            """
        }

        let constructorLines = fields.map { field in
            let identifier = DartNaming.memberName(field.identity.code)
            return field.isRequired ? "    required this.\(identifier)," : "    this.\(identifier),"
        }.joined(separator: "\n")

        let propertyLines = fields.map { field in
            let identifier = DartNaming.memberName(field.identity.code)
            let type = DartNaming.dartType(for: field)
            return "  final \(type) \(identifier);"
        }.joined(separator: "\n")

        return """
        class \(typeName) {
          const \(typeName)({
        \(constructorLines)
          });

        \(propertyLines)
        }

        """
    }

    private func repositoryDart(
        featureName: String,
        typeName: String
    ) -> String {
        """
        import '../entities/\(featureName).dart';

        abstract interface class \(typeName)Repository {
          Future<List<\(typeName)>> fetchAll();
        }

        """
    }

    private func useCaseDart(
        featureName: String,
        typeName: String
    ) -> String {
        """
        import '../entities/\(featureName).dart';
        import '../repositories/\(featureName)_repository.dart';

        class Get\(typeName)List {
          const Get\(typeName)List(this._repository);

          final \(typeName)Repository _repository;

          Future<List<\(typeName)>> call() => _repository.fetchAll();
        }

        """
    }

    private func viewModelDart(
        featureName: String,
        typeName: String
    ) -> String {
        """
        import '../../domain/entities/\(featureName).dart';
        import '../../domain/use_cases/get_\(featureName)_list.dart';

        class \(typeName)ViewModel {
          const \(typeName)ViewModel(this._get\(typeName)List);

          final Get\(typeName)List _get\(typeName)List;

          Future<List<\(typeName)>> load() => _get\(typeName)List();
        }

        """
    }

    private func smokeTest(
        specification: ProjectSpecification,
        packageName: String
    ) -> String {
        let displayName = specification.design.appDisplayName ?? specification.identity.name

        return """
        import 'package:flutter_test/flutter_test.dart';
        import 'package:\(packageName)/app.dart';

        void main() {
          testWidgets('renders the generated app shell', (tester) async {
            await tester.pumpWidget(const App());

            expect(find.text('\(DartEscaping.singleQuoted(displayName))'), findsOneWidget);
          });
        }

        """
    }

    private func gitignore() -> String {
        """
        .dart_tool/
        .flutter-plugins
        .flutter-plugins-dependencies
        .packages
        build/
        coverage/
        pubspec.lock
        .idea/
        .vscode/

        """
    }

    private func readme(
        specification: ProjectSpecification,
        graph: ResolvedProductGraph,
        packageName: String
    ) -> String {
        let packageList = graph.packages
            .map { "- \($0.contract.id.rawValue) @ \($0.contract.version.description)" }
            .joined(separator: "\n")

        return """
        # \(DartEscaping.singleLine(specification.identity.name))

        Generated by AppForge Pro.

        ## Architecture

        - MVVM
        - Feature-First
        - Repository Pattern
        - Use Cases
        - Single Source of Truth

        ## Generated package

        `\(packageName)`

        ## Resolved Forge packages

        \(packageList.isEmpty ? "- none" : packageList)

        The generated application is normal editable Flutter source code and has no runtime dependency on AppForge Pro.

        """
    }

    private func generationManifestFile(
        specification: ProjectSpecification,
        graph: ResolvedProductGraph,
        packageName: String,
        existingFiles: [GeneratedFile]
    ) throws -> GeneratedFile {
        let manifestPath = "appforge.generated.json"
        let paths = (existingFiles.map(\.relativePath) + [manifestPath]).sorted()
        let manifest = GenerationManifest(
            rendererVersion: Self.rendererVersion,
            projectSchemaVersion: specification.schemaVersion,
            packageName: packageName,
            forgePackages: graph.packages.map { $0.contract.id.rawValue },
            files: paths
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(manifest)
        guard let text = String(data: data, encoding: .utf8) else {
            throw FlutterRendererError.encodingFailed
        }
        return GeneratedFile(relativePath: manifestPath, contents: text)
    }

    private static func entitySort(_ lhs: EntityDefinition, _ rhs: EntityDefinition) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }

    private static func fieldSort(_ lhs: FieldDefinition, _ rhs: FieldDefinition) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}

private struct GenerationManifest: Codable {
    let rendererVersion: Int
    let projectSchemaVersion: Int
    let packageName: String
    let forgePackages: [String]
    let files: [String]
}

private enum DartNaming {
    private static let reservedWords: Set<String> = [
        "abstract", "as", "assert", "async", "await", "base", "break", "case", "catch",
        "class", "const", "continue", "covariant", "default", "deferred", "do", "dynamic",
        "else", "enum", "export", "extends", "extension", "external", "factory", "false",
        "final", "finally", "for", "function", "get", "hide", "if", "implements", "import",
        "in", "interface", "is", "late", "library", "mixin", "new", "null", "of", "on",
        "operator", "part", "required", "rethrow", "return", "sealed", "set", "show",
        "static", "super", "switch", "sync", "this", "throw", "true", "try", "typedef",
        "var", "void", "when", "while", "with", "yield"
    ]

    static func packageName(from projectName: String) throws -> String {
        var value = projectName
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: "_",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        if value.first?.isNumber == true {
            value = "app_\(value)"
        }
        guard !value.isEmpty else {
            throw FlutterRendererError.invalidProjectPackageName(projectName)
        }
        return value
    }

    static func snakeCase(_ code: String) -> String {
        code
            .replacingOccurrences(
                of: "([a-z0-9])([A-Z])",
                with: "$1_$2",
                options: .regularExpression
            )
            .lowercased()
    }

    static func typeName(_ code: String) -> String {
        snakeCase(code)
            .split(separator: "_")
            .map { part in
                part.prefix(1).uppercased() + part.dropFirst()
            }
            .joined()
    }

    static func memberName(_ code: String) -> String {
        let parts = snakeCase(code).split(separator: "_").map(String.init)
        guard let first = parts.first else {
            return code
        }

        let camelCase = first + parts.dropFirst().map { part in
            part.prefix(1).uppercased() + part.dropFirst()
        }.joined()

        return reservedWords.contains(camelCase) ? "\(camelCase)Value" : camelCase
    }

    static func dartType(for field: FieldDefinition) -> String {
        let baseType: String
        switch field.dataType {
        case .integer:
            baseType = "int"
        case .decimal, .currency, .percentage:
            baseType = "double"
        case .boolean:
            baseType = "bool"
        case .date, .dateTime, .time:
            baseType = "DateTime"
        case .string, .email, .phone, .url, .enumeration, .file, .image, .color, .location:
            baseType = "String"
        }

        return field.isRequired ? baseType : "\(baseType)?"
    }
}

private enum DartEscaping {
    static func singleQuoted(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    static func yamlQuoted(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: """, with: "\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
        return ""\(escaped)""
    }

    static func singleLine(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
