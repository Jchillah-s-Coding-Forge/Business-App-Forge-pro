import AppForgeDomain

struct FlutterListScreenContractValidator {
    func validate(
        _ specification: ProjectSpecification
    ) throws {
        var paths: [String: String] = [:]

        for screen in FlutterListRenderingSupport.listScreens(
            in: specification
        ) {
            let entity = try FlutterListRenderingSupport.entity(
                for: screen,
                in: specification
            )
            let path = try FlutterListRenderingSupport.outputPath(
                for: screen,
                entity: entity
            )
            if let firstDefinitionID = paths[path] {
                throw FlutterRendererError.generatedOutputPathCollision(
                    firstDefinitionID: firstDefinitionID,
                    secondDefinitionID: screen.id,
                    path: path
                )
            }
            paths[path] = screen.id
        }
    }
}
