import AppForgeDomain

struct FlutterGeneratedFormScreenSource {
    let specification: ProjectSpecification
    let screen: ScreenDefinition
    let entity: EntityDefinition

    func file() throws -> GeneratedFile {
        try GeneratedFile(
            relativePath: FlutterFormRenderingSupport.outputPath(
                for: screen,
                entity: entity
            ),
            contents: content()
        )
    }
}

private extension FlutterGeneratedFormScreenSource {
    func content() throws -> String {
        let typeName = try FlutterFormRenderingSupport.typeName(for: screen)
        let escapedScreenID = FlutterDartEscaping.singleQuoted(screen.id)
        let escapedTitle = FlutterDartEscaping.singleQuoted(screen.identity.label)

        return FlutterGeneratedText.lines([
            "import 'package:flutter/material.dart';",
            "",
            "import '../../../../core/presentation/generated_entity_form_screen.dart';",
            "import '../../../../core/presentation/generated_form_contract.dart';",
            "",
            "class \(typeName) extends StatelessWidget {",
            "  const \(typeName)({",
            "    super.key,",
            "    required this.onSubmit,",
            "    this.initialValues = const <String, Object?>{},",
            "    this.submitLabel = 'Save',",
            "    this.externalValuePicker,",
            "    this.errorMessageBuilder,",
            "  });",
            "",
            "  final GeneratedFormSubmit onSubmit;",
            "  final Map<String, Object?> initialValues;",
            "  final String submitLabel;",
            "  final GeneratedExternalValuePicker? externalValuePicker;",
            "  final GeneratedFormErrorMessageBuilder? errorMessageBuilder;",
            "",
            "  @override",
            "  Widget build(BuildContext context) {",
            "    return GeneratedEntityFormScreen(",
            "      screenId: '\(escapedScreenID)',",
            "      title: '\(escapedTitle)',",
            "      fields: _fields,",
            "      initialValues: initialValues,",
            "      submitLabel: submitLabel,",
            "      externalValuePicker: externalValuePicker,",
            "      errorMessageBuilder: errorMessageBuilder,",
            "      onSubmit: onSubmit,",
            "    );",
            "  }",
            "",
            "  static const List<GeneratedFormFieldSpec> _fields =",
            "      <GeneratedFormFieldSpec>["
        ] + fieldSpecLines() + [
            "    ];",
            "}"
        ])
    }

    func fieldSpecLines() -> [String] {
        let fields = Dictionary(
            uniqueKeysWithValues: entity.fields.map { ($0.id, $0) }
        )
        let presentations = FlutterFormRenderingSupport.presentationsByField(
            specification.fieldPresentations
        )
        return screen.visibleFieldIDs.flatMap { fieldID -> [String] in
            guard let field = fields[fieldID] else {
                return []
            }
            return fieldSpecLines(
                field,
                presentations: presentations
            )
        }
    }

    func fieldSpecLines(
        _ field: FieldDefinition,
        presentations: [String: [FieldPresentationDefinition]]
    ) -> [String] {
        let control = FlutterFormRenderingSupport.control(
            for: field,
            presentations: presentations
        )
        let range = FlutterFormRenderingSupport.numericRange(
            for: field,
            presentations: presentations
        )
        let bounds = validationBounds(field.validationRules)
        let options = choiceOptions(for: field, control: control)
        let escapedID = FlutterDartEscaping.singleQuoted(field.id)
        let escapedLabel = FlutterDartEscaping.singleQuoted(field.identity.label)

        var lines = [
            "        GeneratedFormFieldSpec(",
            "          id: '\(escapedID)',",
            "          label: '\(escapedLabel)',",
            "          valueKind: GeneratedFormValueKind.\(field.dataType.rawValue),",
            "          control: GeneratedFormControl.\(control.rawValue),",
            "          isRequired: \(field.isRequired),",
            "          options: <GeneratedChoiceOption>["
        ]
        lines += options.flatMap { option in
            [
                "            GeneratedChoiceOption(",
                "              value: '\(FlutterDartEscaping.singleQuoted(option.value))',",
                "              label: '\(FlutterDartEscaping.singleQuoted(option.label))',",
                "            ),"
            ]
        }
        lines += [
            "          ],",
            "          minimumLength: \(optional(bounds.minimumLength)),",
            "          maximumLength: \(optional(bounds.maximumLength)),",
            "          minimumValue: \(optional(bounds.minimumValue)),",
            "          maximumValue: \(optional(bounds.maximumValue)),",
            "          patterns: <String>["
        ]
        lines += bounds.patterns.map {
            "            '\(FlutterDartEscaping.singleQuoted($0))',"
        }
        lines += [
            "          ],",
            "          rangeMinimum: \(optional(range?.minimum)),",
            "          rangeMaximum: \(optional(range?.maximum)),",
            "        ),"
        ]
        return lines
    }

    func choiceOptions(
        for field: FieldDefinition,
        control: FieldControl
    ) -> [(value: String, label: String)] {
        if field.dataType == .boolean {
            if control == .radioGroup || control == .segmented {
                return [
                    (value: "false", label: "No"),
                    (value: "true", label: "Yes")
                ]
            }
        }
        return field.options.map { ($0.value, $0.label) }
    }

    func validationBounds(
        _ rules: [FieldValidationRule]
    ) -> FormValidationBounds {
        var minimumLengths: [Int] = []
        var maximumLengths: [Int] = []
        var minimumValues: [Double] = []
        var maximumValues: [Double] = []
        var patterns: [String] = []

        for rule in rules {
            switch rule {
            case let .minimumLength(value):
                minimumLengths.append(value)
            case let .maximumLength(value):
                maximumLengths.append(value)
            case let .minimumValue(value):
                minimumValues.append(value)
            case let .maximumValue(value):
                maximumValues.append(value)
            case let .pattern(value):
                patterns.append(value)
            }
        }

        return FormValidationBounds(
            minimumLength: minimumLengths.max(),
            maximumLength: maximumLengths.min(),
            minimumValue: minimumValues.max(),
            maximumValue: maximumValues.min(),
            patterns: patterns.sorted()
        )
    }

    func optional(_ value: Int?) -> String {
        value.map(String.init) ?? "null"
    }

    func optional(_ value: Double?) -> String {
        value.map(String.init) ?? "null"
    }
}

private struct FormValidationBounds {
    let minimumLength: Int?
    let maximumLength: Int?
    let minimumValue: Double?
    let maximumValue: Double?
    let patterns: [String]
}
