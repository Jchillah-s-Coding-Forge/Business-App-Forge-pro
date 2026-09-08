import AppForgeDomain

struct FlutterDetailScreenContractValidator {
    func validate(
        _ specification: ProjectSpecification
    ) throws {
        var paths: [String: String] = [:]

        for screen in FlutterDetailRenderingSupport.detailScreens(
            in: specification
        ) {
            let entity = try FlutterDetailRenderingSupport.entity(
                for: screen,
                in: specification
            )
            let path = try FlutterDetailRenderingSupport.outputPath(
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
