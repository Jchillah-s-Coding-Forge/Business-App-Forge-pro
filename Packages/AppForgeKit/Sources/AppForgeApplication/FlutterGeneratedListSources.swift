import AppForgeDomain

struct FlutterGeneratedListSources {
    let specification: ProjectSpecification

    func files() throws -> [GeneratedFile] {
        let screens = FlutterListRenderingSupport.listScreens(
            in: specification
        )
        guard !screens.isEmpty else {
            return []
        }

        var result = [
            FlutterGeneratedEntityListScreenSource().file()
        ]
        for screen in screens {
            let entity = try FlutterListRenderingSupport.entity(
                for: screen,
                in: specification
            )
            try result.append(
                FlutterGeneratedListScreenSource(
                    screen: screen,
                    entity: entity
                ).file()
            )
        }
        return result
    }
}
