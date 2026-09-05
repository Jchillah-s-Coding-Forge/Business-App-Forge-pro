import AppForgeDomain
import Foundation

struct FlutterSourceBuilder {
    let specification: ProjectSpecification
    let graph: ResolvedProductGraph
    let lockfile: ForgeLockfile
    let packageName: String
    let rendererVersion: Int

    func build() throws -> [GeneratedFile] {
        var files = try baseFiles()

        for entity in specification.entities.sorted(by: Self.entitySort) {
            files.append(contentsOf: try featureFiles(for: entity))
        }

        files.append(try generationManifestFile(existingFiles: files))
        return files
    }

    private func baseFiles() throws -> [GeneratedFile] {
        let lockfileData = try ForgeLockfileCodec().encode(lockfile)
        guard let lockfileText = String(data: lockfileData, encoding: .utf8) else {
            throw FlutterRendererError.encodingFailed
        }

        return [
            GeneratedFile(relativePath: ".gitignore", contents: gitignore()),
            GeneratedFile(
                relativePath: "README.md",
                contents: readme()
            ),
            GeneratedFile(
                relativePath: "forge.lock",
                contents: lockfileText
            ),
            GeneratedFile(
                relativePath: "lib/app.dart",
                contents: appDart()
            ),
            GeneratedFile(
                relativePath: "lib/main.dart",
                contents: mainDart()
            ),
            GeneratedFile(
                relativePath: "pubspec.yaml",
                contents: pubspec()
            ),
            GeneratedFile(
                relativePath: "test/app_smoke_test.dart",
                contents: smokeTest()
            )
        ] + stateManagementFiles()
    }

    private func featureFiles(
        for entity: EntityDefinition
    ) throws -> [GeneratedFile] {
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

    private func stateManagementFiles() -> [GeneratedFile] {
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

    private func pubspec() -> String {
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
        description: \(FlutterDartEscaping.yamlQuoted("Generated by AppForge Pro for \(specification.identity.name)."))
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

    private func mainDart() -> String {
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

    private func appDart() -> String {
        let displayName = specification.design.appDisplayName ?? specification.identity.name
        let escapedName = FlutterDartEscaping.singleQuoted(displayName)

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
            let identifier = FlutterDartNaming.memberName(field.identity.code)
            return field.isRequired
                ? "    required this.\(identifier),"
                : "    this.\(identifier),"
        }.joined(separator: "\n")

        let propertyLines = fields.map { field in
            let identifier = FlutterDartNaming.memberName(field.identity.code)
            let type = FlutterDartNaming.dartType(for: field)
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

    private func smokeTest() -> String {
        let displayName = specification.design.appDisplayName ?? specification.identity.name

        return """
        import 'package:flutter_test/flutter_test.dart';
        import 'package:\(packageName)/app.dart';

        void main() {
          testWidgets('renders the generated app shell', (tester) async {
            await tester.pumpWidget(const App());

            expect(find.text('\(FlutterDartEscaping.singleQuoted(displayName))'), findsOneWidget);
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

    private func readme() -> String {
        let packageList = graph.packages
            .map { "- \($0.contract.id.rawValue) @ \($0.contract.version.description)" }
            .joined(separator: "\n")

        return """
        # \(FlutterDartEscaping.singleLine(specification.identity.name))

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
        existingFiles: [GeneratedFile]
    ) throws -> GeneratedFile {
        let manifestPath = "appforge.generated.json"
        let paths = (existingFiles.map(\.relativePath) + [manifestPath]).sorted()
        let manifest = GenerationManifest(
            rendererVersion: rendererVersion,
            projectSchemaVersion: specification.schemaVersion,
            packageName: packageName,
            forgePackages: graph.packages
                .map { $0.contract.id.rawValue }
                .sorted(),
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

private struct GenerationManifest: Codable {
    let rendererVersion: Int
    let projectSchemaVersion: Int
    let packageName: String
    let forgePackages: [String]
    let files: [String]
}
