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
        let relations = specification.relations
            .filter { $0.sourceEntityID == entity.id }
        let relationColumnNames = try FlutterOfflineStorageNaming.relationColumnNames(
            for: relations
        )

        return [
            GeneratedFile(
                relativePath: "lib/features/\(featureName)/data/local/\(featureName)_local_data_source.dart",
                contents: FlutterOfflineLocalDataSourceSource(
                    specification: specification,
                    entity: entity,
                    relations: relations,
                    featureName: featureName,
                    typeName: typeName,
                    tableName: tableName,
                    columnNames: columnNames,
                    relationColumnNames: relationColumnNames
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
