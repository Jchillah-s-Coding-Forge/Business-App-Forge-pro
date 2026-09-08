import AppForgeDomain

struct FlutterGeneratedRecordDisplaySources {
    let specification: ProjectSpecification

    func files() -> [GeneratedFile] {
        guard specification.screens.contains(where: {
            $0.kind == .list || $0.kind == .detail
        }) else {
            return []
        }

        return [
            FlutterGeneratedRecordDisplaySource().file()
        ]
    }
}
