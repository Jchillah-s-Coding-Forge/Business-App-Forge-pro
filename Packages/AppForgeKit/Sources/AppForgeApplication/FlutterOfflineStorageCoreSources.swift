import AppForgeDomain

struct FlutterOfflineStorageCoreSources {
    let specification: ProjectSpecification
    let packageName: String

    func files() throws -> [GeneratedFile] {
        let statements = try FlutterSQLiteSchema(
            specification: specification
        ).createStatements()

        return [
            GeneratedFile(
                relativePath: "lib/core/storage/app_database.dart",
                contents: appDatabase()
            ),
            GeneratedFile(
                relativePath: "lib/core/storage/database_migrations.dart",
                contents: databaseMigrations(statements: statements)
            )
        ]
    }

    private func appDatabase() -> String {
        FlutterGeneratedText.lines([
            "import 'package:path/path.dart' as p;",
            "import 'package:sqflite/sqflite.dart';",
            "",
            "import 'database_migrations.dart';",
            "",
            "class AppDatabase {",
            "  AppDatabase({this.databaseName = '\(packageName).db'});",
            "",
            "  final String databaseName;",
            "  Database? _database;",
            "",
            "  Future<Database> get database async {",
            "    return _database ??= await _open();",
            "  }",
            "",
            "  Future<Database> _open() async {",
            "    final root = await getDatabasesPath();",
            "    return openDatabase(",
            "      p.join(root, databaseName),",
            "      version: DatabaseMigrations.schemaVersion,",
            "      onCreate: (db, _) => DatabaseMigrations.create(db),",
            "      onUpgrade: (db, oldVersion, newVersion) =>",
            "          DatabaseMigrations.upgrade(",
            "        db,",
            "        fromVersion: oldVersion,",
            "        toVersion: newVersion,",
            "      ),",
            "    );",
            "  }",
            "",
            "  Future<void> close() async {",
            "    final current = _database;",
            "    _database = null;",
            "    await current?.close();",
            "  }",
            "}",
            ""
        ])
    }

    private func databaseMigrations(
        statements: [String]
    ) -> String {
        let statementLines = statements.map { statement in
            "    '\(FlutterDartEscaping.singleQuoted(statement))',"
        }

        return FlutterGeneratedText.lines(
            [
                "import 'package:sqflite/sqflite.dart';",
                "",
                "abstract final class DatabaseMigrations {",
                "  static const schemaVersion = 1;",
                "",
                "  static const createStatements = <String>["
            ]
                + statementLines
                + [
                    "  ];",
                    "",
                    "  static Future<void> create(DatabaseExecutor db) async {",
                    "    for (final statement in createStatements) {",
                    "      await db.execute(statement);",
                    "    }",
                    "  }",
                    "",
                    "  static Future<void> upgrade(",
                    "    DatabaseExecutor db, {",
                    "    required int fromVersion,",
                    "    required int toVersion,",
                    "  }) async {",
                    "    if (toVersion > schemaVersion) {",
                    "      throw StateError('Unsupported database schema version');",
                    "    }",
                    "    if (fromVersion < 1 && toVersion >= 1) {",
                    "      await create(db);",
                    "    }",
                    "  }",
                    "}",
                    ""
                ]
        )
    }
}
