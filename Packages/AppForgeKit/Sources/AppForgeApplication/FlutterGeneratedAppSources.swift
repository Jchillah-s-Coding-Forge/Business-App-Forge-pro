import AppForgeDomain

struct FlutterGeneratedAppSources {
    let specification: ProjectSpecification
    let packageName: String

    func files() throws -> [GeneratedFile] {
        let routes = try FlutterGeneratedCreateRoutes.make(
            specification: specification
        )
        var result = try [
            GeneratedFile(
                relativePath: "lib/app.dart",
                contents: appContent(routes: routes)
            ),
            FlutterGeneratedAppHomeSource().file(),
            GeneratedFile(
                relativePath: "test/app_smoke_test.dart",
                contents: smokeTestContent(routes: routes)
            )
        ]
        if !routes.isEmpty {
            try result.append(
                FlutterGeneratedAppDependenciesSource(
                    routes: routes
                ).file()
            )
        }
        return result
    }
}

private extension FlutterGeneratedAppSources {
    func appContent(
        routes: [FlutterGeneratedCreateRoute]
    ) throws -> String {
        routes.isEmpty
            ? emptyAppContent
            : try interactiveAppContent(routes: routes)
    }

    var emptyAppContent: String {
        FlutterGeneratedText.lines([
            "import 'package:flutter/material.dart';",
            "",
            "import 'core/presentation/generated_app_home.dart';",
            "",
            "class App extends StatelessWidget {",
            "  const App({super.key});",
            "",
            "  @override",
            "  Widget build(BuildContext context) {",
            "    return MaterialApp(",
            "      debugShowCheckedModeBanner: false,",
            "      title: '\(escapedDisplayName)',",
            "      theme: ThemeData(useMaterial3: true),",
            "      home: const GeneratedAppHome(",
            "        title: '\(escapedDisplayName)',",
            "        destinations: <GeneratedAppDestination>[],",
            "      ),",
            "    );",
            "  }",
            "}",
            ""
        ])
    }

    func interactiveAppContent(
        routes: [FlutterGeneratedCreateRoute]
    ) throws -> String {
        var lines = interactiveImports(routes: routes) + [
            "",
            "class App extends StatefulWidget {",
            "  const App({super.key});",
            "",
            "  @override",
            "  State<App> createState() => _AppState();",
            "}",
            "",
            "class _AppState extends State<App> {",
            "  late final AppDependencies _dependencies;",
            "",
            "  @override",
            "  void initState() {",
            "    super.initState();",
            "    _dependencies = AppDependencies.production();",
            "  }",
            "",
            "  @override",
            "  void dispose() {",
            "    unawaited(_dependencies.close());",
            "    super.dispose();",
            "  }",
            "",
            "  @override",
            "  Widget build(BuildContext context) {",
            "    return MaterialApp(",
            "      debugShowCheckedModeBanner: false,",
            "      title: '\(escapedDisplayName)',",
            "      theme: ThemeData(useMaterial3: true),",
            "      home: GeneratedAppHome(",
            "        title: '\(escapedDisplayName)',",
            "        destinations: <GeneratedAppDestination>["
        ]
        for route in routes {
            lines += try destinationLines(route)
        }
        lines += [
            "        ],",
            "      ),",
            "    );",
            "  }",
            "}",
            ""
        ]
        return FlutterGeneratedText.lines(lines)
    }

    func interactiveImports(
        routes: [FlutterGeneratedCreateRoute]
    ) -> [String] {
        var imports = [
            "import 'dart:async';",
            "",
            "import 'package:flutter/material.dart';",
            "",
            "import 'core/bootstrap/app_dependencies.dart';",
            "import 'core/presentation/generated_app_home.dart';"
        ]
        let screenImports = routes.map { route in
            let feature = FlutterDartNaming.snakeCase(
                route.entity.identity.code
            )
            let screen = FlutterDartNaming.snakeCase(
                route.screen.identity.code
            )
            return "import 'features/\(feature)/presentation/screens/\(screen)_form_screen.dart';"
        }
        imports += screenImports.sorted()
        return imports
    }

    func destinationLines(
        _ route: FlutterGeneratedCreateRoute
    ) throws -> [String] {
        let screenType = try FlutterFormRenderingSupport.typeName(
            for: route.screen
        )
        let title = FlutterDartEscaping.singleQuoted(route.label)
        let singular = FlutterDartEscaping.singleQuoted(
            route.entity.identity.singularLabel
        )
        return [
            "          GeneratedAppDestination(",
            "            title: '\(title)',",
            "            subtitle: 'Create and save \(singular) offline.',",
            "            builder: (routeContext) => \(screenType)(",
            "              onSubmit: ({",
            "                required String? recordId,",
            "                required Map<String, Object?> values,",
            "              }) async {",
            "                if (recordId != null) {",
            "                  throw StateError('Create flow received an existing record.');",
            "                }",
            "                await _dependencies.\(route.propertyName).create(values);",
            "                if (routeContext.mounted) {",
            "                  Navigator.of(routeContext).pop(true);",
            "                }",
            "              },",
            "            ),",
            "          ),"
        ]
    }

    func smokeTestContent(
        routes: [FlutterGeneratedCreateRoute]
    ) -> String {
        routes.isEmpty
            ? emptySmokeTestContent
            : interactiveSmokeTestContent(firstRoute: routes[0])
    }

    var emptySmokeTestContent: String {
        FlutterGeneratedText.lines([
            "import 'package:flutter_test/flutter_test.dart';",
            "import 'package:\(packageName)/app.dart';",
            "",
            "void main() {",
            "  testWidgets('explains when no create flows are configured', (tester) async {",
            "    await tester.pumpWidget(const App());",
            "",
            "    expect(find.text('\(escapedDisplayName)'), findsOneWidget);",
            "    expect(find.text('No create flows are configured.'), findsOneWidget);",
            "    expect(find.text('Generated with AppForge Pro'), findsNothing);",
            "  });",
            "}",
            ""
        ])
    }

    func interactiveSmokeTestContent(
        firstRoute: FlutterGeneratedCreateRoute
    ) -> String {
        let routeTitle = FlutterDartEscaping.singleQuoted(firstRoute.label)
        let screenTitle = FlutterDartEscaping.singleQuoted(
            firstRoute.screen.identity.label
        )
        return FlutterGeneratedText.lines([
            "import 'package:flutter/material.dart';",
            "import 'package:flutter_test/flutter_test.dart';",
            "import 'package:\(packageName)/app.dart';",
            "",
            "void main() {",
            "  testWidgets('opens the generated create flow', (tester) async {",
            "    await tester.pumpWidget(const App());",
            "",
            "    expect(find.text('\(routeTitle)'), findsOneWidget);",
            "    expect(find.text('Generated with AppForge Pro'), findsNothing);",
            "    await tester.tap(find.text('\(routeTitle)'));",
            "    await tester.pumpAndSettle();",
            "",
            "    expect(find.text('\(screenTitle)'), findsOneWidget);",
            "    expect(find.byType(BackButton), findsOneWidget);",
            "  });",
            "}",
            ""
        ])
    }

    var escapedDisplayName: String {
        let displayName = specification.design.appDisplayName
            ?? specification.identity.name
        return FlutterDartEscaping.singleQuoted(displayName)
    }
}
