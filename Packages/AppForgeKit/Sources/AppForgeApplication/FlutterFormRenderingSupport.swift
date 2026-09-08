import AppForgeDomain

enum FlutterFormRenderingSupport {
    static func formScreens(
        in specification: ProjectSpecification
    ) -> [ScreenDefinition] {
        specification.screens
            .filter { $0.kind == .form }
            .sorted(by: screenSort)
    }

    static func entity(
        for screen: ScreenDefinition,
        in specification: ProjectSpecification
    ) throws -> EntityDefinition {
        guard let entityID = screen.entityID,
              let entity = specification.entities.first(where: { $0.id == entityID })
        else {
            throw FlutterRendererError.formScreenRequiresEntity(
                screenID: screen.id
            )
        }
        return entity
    }

    static func typeName(for screen: ScreenDefinition) throws -> String {
        let typeName = FlutterDartNaming.typeName(
            screen.identity.code
        ) + "FormScreen"
        guard FlutterDartNaming.isUsableIdentifier(typeName) else {
            throw FlutterRendererError.invalidGeneratedIdentifier(
                definitionID: screen.id,
                code: screen.identity.code
            )
        }
        return typeName
    }

    static func outputPath(
        for screen: ScreenDefinition,
        entity: EntityDefinition
    ) throws -> String {
        let featureName = FlutterDartNaming.snakeCase(
            entity.identity.code
        )
        let screenName = FlutterDartNaming.snakeCase(
            screen.identity.code
        )
        guard FlutterDartNaming.isUsableIdentifier(featureName),
              FlutterDartNaming.isUsableIdentifier(screenName)
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

    static func presentationsByField(
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

    static func control(
        for field: FieldDefinition,
        presentations: [String: [FieldPresentationDefinition]]
    ) -> FieldControl {
        presentations[field.id]?.first?.control
            ?? defaultControl(for: field.dataType)
    }

    static func numericRange(
        for field: FieldDefinition,
        presentations: [String: [FieldPresentationDefinition]]
    ) -> NumericRange? {
        presentations[field.id]?.first?.numericRange
    }

    static func defaultControl(
        for dataType: FieldDataType
    ) -> FieldControl {
        defaultControls[dataType] ?? .textField
    }

    private static let defaultControls: [FieldDataType: FieldControl] = [
        .string: .textField,
        .email: .textField,
        .phone: .textField,
        .url: .textField,
        .integer: .numericField,
        .decimal: .numericField,
        .currency: .numericField,
        .percentage: .numericField,
        .boolean: .switchToggle,
        .date: .datePicker,
        .dateTime: .dateTimePicker,
        .time: .timePicker,
        .enumeration: .select,
        .file: .filePicker,
        .image: .imagePicker,
        .color: .colorPicker,
        .location: .locationPicker
    ]

    private static func screenSort(
        _ lhs: ScreenDefinition,
        _ rhs: ScreenDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}
