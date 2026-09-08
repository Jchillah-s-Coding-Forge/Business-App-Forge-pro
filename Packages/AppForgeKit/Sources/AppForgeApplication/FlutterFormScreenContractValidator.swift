import AppForgeDomain

struct FlutterFormScreenContractValidator {
    func validate(
        _ specification: ProjectSpecification
    ) throws {
        let presentations = FlutterFormRenderingSupport.presentationsByField(
            specification.fieldPresentations
        )
        var paths: [String: String] = [:]

        for screen in FlutterFormRenderingSupport.formScreens(in: specification) {
            let entity = try FlutterFormRenderingSupport.entity(
                for: screen,
                in: specification
            )

            let path = try FlutterFormRenderingSupport.outputPath(
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

            try validatePresentationAmbiguity(
                screen: screen,
                presentations: presentations
            )
        }
    }
}

private extension FlutterFormScreenContractValidator {
    func validatePresentationAmbiguity(
        screen: ScreenDefinition,
        presentations: [String: [FieldPresentationDefinition]]
    ) throws {
        for fieldID in screen.visibleFieldIDs {
            guard let matches = presentations[fieldID],
                  matches.count > 1
            else {
                continue
            }
            throw FlutterRendererError.ambiguousFieldPresentation(
                screenID: screen.id,
                fieldID: fieldID,
                firstPresentationID: matches[0].id,
                secondPresentationID: matches[1].id
            )
        }
    }
}
