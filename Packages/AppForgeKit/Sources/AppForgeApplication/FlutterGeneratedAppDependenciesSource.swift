import AppForgeDomain

struct FlutterGeneratedAppDependenciesSource {
    let routes: [FlutterGeneratedCreateRoute]

    func file() throws -> GeneratedFile {
        try GeneratedFile(
            relativePath: "lib/core/bootstrap/app_dependencies.dart",
            contents: content()
        )
    }
}

private extension FlutterGeneratedAppDependenciesSource {
    func content() throws -> String {
        let entities = uniqueEntities
        var lines = importLines(entities: entities) + [
            "",
            "class AppDependencies {",
            "  AppDependencies._({",
            "    required this.database,"
        ]
        lines += routes.map {
            "    required this.\($0.propertyName),"
        }
        lines += [
            "  });",
            "",
            "  factory AppDependencies.production() {"
        ]
        lines += try productionFactoryLines(entities: entities)
        lines += [
            "  }",
            "",
            "  final AppDatabase database;"
        ]
        lines += try routes.map { route in
            let typeName = try FlutterFormCreateMappingSupport.viewModelTypeName(
                for: route.screen
            )
            return "  final \(typeName) \(route.propertyName);"
        }
        lines += [
            "",
            "  Future<void> close() => database.close();",
            "}",
            ""
        ]
        return FlutterGeneratedText.lines(lines)
    }

    func importLines(
        entities: [EntityDefinition]
    ) -> [String] {
        var imports = [
            "import '../domain/record_id_generator.dart';",
            "import '../storage/app_database.dart';"
        ]
        for entity in entities {
            let feature = FlutterDartNaming.snakeCase(entity.identity.code)
            imports += [
                "import '../../features/\(feature)/data/local/\(feature)_local_data_source.dart';",
                "import '../../features/\(feature)/data/repositories/\(feature)_repository_impl.dart';",
                "import '../../features/\(feature)/domain/use_cases/save_\(feature).dart';"
            ]
        }
        for route in routes {
            let feature = FlutterDartNaming.snakeCase(
                route.entity.identity.code
            )
            let screen = FlutterDartNaming.snakeCase(
                route.screen.identity.code
            )
            imports.append(
                "import '../../features/\(feature)/presentation/view_models/\(screen)_form_create_view_model.dart';"
            )
        }
        return imports.sorted()
    }

    func productionFactoryLines(
        entities: [EntityDefinition]
    ) throws -> [String] {
        var lines = [
            "    final database = AppDatabase();",
            "    final recordIds = SecureUuidV4Generator();"
        ]
        for entity in entities {
            let typeName = FlutterDartNaming.typeName(entity.identity.code)
            let variable = FlutterDartNaming.memberName(entity.identity.code)
            lines += [
                "    final \(variable)Repository = \(typeName)RepositoryImpl(",
                "      \(typeName)LocalDataSource(database),",
                "    );"
            ]
        }
        lines += [
            "    return AppDependencies._(",
            "      database: database,"
        ]
        for route in routes {
            let entityType = FlutterDartNaming.typeName(
                route.entity.identity.code
            )
            let repository = FlutterDartNaming.memberName(
                route.entity.identity.code
            )
            let viewModel = try FlutterFormCreateMappingSupport.viewModelTypeName(
                for: route.screen
            )
            lines += [
                "      \(route.propertyName): \(viewModel)(",
                "        save: Save\(entityType)(\(repository)Repository),",
                "        recordIds: recordIds,",
                "      ),"
            ]
        }
        lines += ["    );"]
        return lines
    }

    var uniqueEntities: [EntityDefinition] {
        var entityIDs = Set<String>()
        return routes
            .map(\.entity)
            .filter { entityIDs.insert($0.id).inserted }
            .sorted(by: Self.entitySort)
    }

    static func entitySort(
        _ lhs: EntityDefinition,
        _ rhs: EntityDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}
