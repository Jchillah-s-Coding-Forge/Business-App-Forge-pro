import AppForgeDomain

struct FlutterOfflineFeatureSources {
    let specification: ProjectSpecification
    let entity: EntityDefinition

    func files() throws -> [GeneratedFile] {
        guard specification.offline.isEnabled else {
            return []
        }

        let featureName = FlutterDartNaming.snakeCase(entity.identity.code)
        let typeName = FlutterDartNaming.typeName(entity.identity.code)
        let tableName = try FlutterOfflineStorageNaming.tableName(for: entity)
        let columnNames = try FlutterOfflineStorageNaming.columnNames(
            for: entity
        )

        return [
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/data/local/\(featureName)_local_data_source.dart",
                contents: FlutterOfflineLocalDataSourceSource(
                    specification: specification,
                    entity: entity,
                    featureName: featureName,
                    typeName: typeName,
                    tableName: tableName,
                    columnNames: columnNames
                ).content()
            ),
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/data/repositories/\(featureName)_repository_impl.dart",
                contents: FlutterOfflineRepositorySource(
                    featureName: featureName,
                    typeName: typeName
                ).content()
            )
        ]
    }
}
