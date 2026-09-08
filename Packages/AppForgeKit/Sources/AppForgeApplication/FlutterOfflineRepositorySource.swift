struct FlutterOfflineRepositorySource {
    let featureName: String
    let typeName: String

    func content() -> String {
        FlutterGeneratedText.lines([
            "import '../../../../core/domain/domain_values.dart';",
            "",
            "import '../../domain/entities/\(featureName).dart';"
            "import '../../domain/repositories/\(featureName)_repository.dart';",
            "import '../local/\(featureName)_local_data_source.dart';",
            "",
            "class \(typeName)RepositoryImpl implements \(typeName)Repository {",
            "  const \(typeName)RepositoryImpl(this._local);",
            "",
            "  final \(typeName)LocalDataSource _local;",
            "",
            "  @override",
            "  Future<List<DomainRecord<\(typeName)>>> fetchAll() =>",
            "      _local.fetchAll();",
            "",
            "  @override",
            "  Future<void> save({",
            "    required String recordId,",
            "    required \(typeName) value,",
            "  }) =>",
            "      _local.save(recordId: recordId, value: value);",
            "",
            "  @override",
            "  Future<void> delete(String recordId) => _local.delete(recordId);",
            "}",
            ""
        ])
    }
}
