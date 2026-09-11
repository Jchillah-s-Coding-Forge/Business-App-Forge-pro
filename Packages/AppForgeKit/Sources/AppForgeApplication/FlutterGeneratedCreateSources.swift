import AppForgeDomain

struct FlutterGeneratedCreateSources {
    let specification: ProjectSpecification

    func files() throws -> [GeneratedFile] {
        let routes = try FlutterGeneratedCreateRoutes.make(
            specification: specification
        )
        guard !routes.isEmpty else {
            return []
        }

        var result = [
            FlutterGeneratedRecordIDSource().file(),
            FlutterGeneratedFormCreateMappingSource().file()
        ]
        for route in routes {
            try result.append(
                FlutterGeneratedFormCreateMapperSource(
                    screen: route.screen,
                    entity: route.entity
                ).file()
            )
            try result.append(
                FlutterFormCreateViewModelSource(
                    screen: route.screen,
                    entity: route.entity
                ).file()
            )
        }
        return result
    }
}
