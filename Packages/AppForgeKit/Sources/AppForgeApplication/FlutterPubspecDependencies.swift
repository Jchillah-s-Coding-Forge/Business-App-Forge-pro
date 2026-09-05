import AppForgeDomain

struct FlutterPubspecDependencies {
    let specification: ProjectSpecification

    func runtimeLines() -> [String] {
        var dependencies: [String] = []

        switch specification.flutterStateManagement {
        case .riverpod:
            dependencies.append("flutter_riverpod: ^3.3.2")
        case .blocCubit:
            dependencies.append("flutter_bloc: ^9.1.1")
        case nil:
            break
        }

        if specification.offline.isEnabled {
            dependencies += [
                "path: 1.9.1",
                "sqflite: 2.4.2+1"
            ]
        }

        return dependencies
            .sorted()
            .map { "  \($0)" }
    }
}
