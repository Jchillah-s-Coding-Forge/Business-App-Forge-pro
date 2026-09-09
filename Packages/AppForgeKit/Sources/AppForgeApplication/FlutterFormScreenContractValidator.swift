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
            try validateMaterializableControls(
                screen: screen,
                entity: entity,
                presentations: presentations
            )
            try validateCreateFlow(
                screen: screen,
                entity: entity,
                specification: specification
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

    func validateMaterializableControls(
        screen: ScreenDefinition,
        entity: EntityDefinition,
        presentations: [String: [FieldPresentationDefinition]]
    ) throws {
        let fields = Dictionary(
            uniqueKeysWithValues: entity.fields.map { ($0.id, $0) }
        )

        for fieldID in screen.visibleFieldIDs {
            guard let field = fields[fieldID] else {
                continue
            }
            let control = FlutterFormRenderingSupport.control(
                for: field,
                presentations: presentations
            )
            if field.dataType == .location {
                if control != .locationPicker {
                    throw FlutterRendererError.unsupportedFormControl(
                        screenID: screen.id,
                        fieldID: field.id,
                        control: control
                    )
                }
            }
        }
    }

    func validateCreateFlow(
        screen: ScreenDefinition,
        entity: EntityDefinition,
        specification: ProjectSpecification
    ) throws {
        guard specification.offline.isEnabled else {
            throw FlutterRendererError.formScreenRequiresOfflinePersistence(
                screenID: screen.id
            )
        }

        let protectedNavigationExists = specification.navigation.items.contains {
            $0.screenID == screen.id && !$0.allowedRoleIDs.isEmpty
        }
        if !screen.allowedRoleIDs.isEmpty || protectedNavigationExists {
            throw FlutterRendererError.formScreenRequiresRoleEvaluation(
                screenID: screen.id
            )
        }

        let visibleFieldIDs = Set(screen.visibleFieldIDs)
        for field in entity.fields {
            let isMissingRequiredField = field.isRequired
                && field.defaultValue == nil
                && !visibleFieldIDs.contains(field.id)
            if isMissingRequiredField {
                throw FlutterRendererError.formScreenMissingRequiredField(
                    screenID: screen.id,
                    fieldID: field.id
                )
            }
            let needsExternalPicker = field.isRequired
                && visibleFieldIDs.contains(field.id)
                && FlutterFormRenderingSupport.usesExternalValuePicker(field)
            if needsExternalPicker {
                throw FlutterRendererError.formScreenRequiresExternalValuePicker(
                    screenID: screen.id,
                    fieldID: field.id
                )
            }
        }

        let requiredRelations = specification.relations.filter {
            $0.sourceEntityID == entity.id && $0.isRequired
        }
        for relation in requiredRelations {
            throw FlutterRendererError.formScreenRequiresRelationPicker(
                screenID: screen.id,
                relationID: relation.id
            )
        }
    }
}
