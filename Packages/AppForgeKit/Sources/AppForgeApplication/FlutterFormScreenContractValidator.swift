import AppForgeDomain

struct FlutterFormScreenContractValidator {
    func validate(
        _ specification: ProjectSpecification
    ) throws {
        let entities = Dictionary(
            uniqueKeysWithValues: specification.entities.map {
                ($0.id, $0)
            }
        )
        let presentations = presentationsByField(
            specification.fieldPresentations
        )
        var paths: [String: String] = [:]

        for screen in formScreens(specification.screens) {
            guard let entityID = screen.entityID,
                  let entity = entities[entityID]
            else {
                throw FlutterRendererError.formScreenRequiresEntity(
                    screenID: screen.id
                )
            }

            let path = try outputPath(
                screen: screen,
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
    func formScreens(
        _ screens: [ScreenDefinition]
    ) -> [ScreenDefinition] {
        screens
            .filter { $0.kind == .form }
            .sorted(by: Self.screenSort)
    }

    func outputPath(
        screen: ScreenDefinition,
        entity: EntityDefinition
    ) throws -> String {
        let featureName = FlutterDartNaming.snakeCase(
            entity.identity.code
        )
        let screenName = FlutterDartNaming.snakeCase(
            screen.identity.code
        )
        let typeName = FlutterDartNaming.typeName(
            screen.identity.code
        ) + "FormScreen"

        guard FlutterDartNaming.isUsableIdentifier(screenName),
              FlutterDartNaming.isUsableIdentifier(typeName)
        else {
            throw FlutterRendererError.invalidGeneratedIdentifier(
                definitionID: screen.id,
                code: screen.identity.code
            )
        }

        return "lib/features/\(featureName)"
            + "/presentation/screens/"
            + "\(screenName)_form_screen.dart"
    }

    func presentationsByField(
        _ presentations: [FieldPresentationDefinition]
    ) -> [String: [FieldPresentationDefinition]] {
        var result: [String: [FieldPresentationDefinition]] = [:]

        for presentation in presentations {
            guard case let .field(fieldID) = presentation.target else {
                continue
            }
            result[fieldID, default: []].append(presentation)
        }

        for fieldID in result.keys {
            result[fieldID]?.sort { $0.id < $1.id }
        }
        return result
    }

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

    static func screenSort(
        _ lhs: ScreenDefinition,
        _ rhs: ScreenDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}
