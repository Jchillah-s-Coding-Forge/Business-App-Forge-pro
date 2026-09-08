import AppForgeDomain

struct FlutterGeneratedDetailSources {
    let specification: ProjectSpecification

    func files() throws -> [GeneratedFile] {
        let screens = FlutterDetailRenderingSupport.detailScreens(
            in: specification
        )
        guard !screens.isEmpty else {
            return []
        }

        var result = [
            FlutterGeneratedEntityDetailScreenSource().file()
        ]
        for screen in screens {
            let entity = try FlutterDetailRenderingSupport.entity(
                for: screen,
                in: specification
            )
            try result.append(
                FlutterGeneratedDetailScreenSource(
                    screen: screen,
                    entity: entity
                ).file()
            )
        }
        return result
    }
}
