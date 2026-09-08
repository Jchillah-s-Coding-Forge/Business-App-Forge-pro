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
        let featureName = FlutterDartNaming.snakeCase(entity.identity.code)
        let entityType = FlutterDartNaming.typeName(entity.identity.code)
        let escapedScreenID = FlutterDartEscaping.singleQuoted(screen.id)
        let escapedTitle = FlutterDartEscaping.singleQuoted(screen.identity.label)

        return FlutterGeneratedText.lines(
            wrapperDeclarationLines(
                typeName: typeName,
                featureName: featureName,
                entityType: entityType
            )
                + buildMethodLines(
                    screenID: escapedScreenID,
                    title: escapedTitle
                )
                + editMapperLines(entityType: entityType)
                + initialValuesMethodLines(entityType: entityType)
                + fieldSpecDeclarationLines()
        )
    }

    func wrapperDeclarationLines(
        typeName: String,
        featureName: String,
        entityType: String
    ) -> [String] {
        [
            "import 'package:flutter/material.dart';",
            "",
            "import '../../../../core/domain/domain_values.dart';",
            "import '../../../../core/presentation/generated_entity_form_screen.dart';",
            "import '../../../../core/presentation/generated_form_contract.dart';",
            "import '../../domain/entities/\(featureName).dart';",
            "",
            "class \(typeName) extends StatelessWidget {",
            "  const \(typeName)({",
            "    super.key,",
            "    required this.onSubmit,",
            "    this.record,",
            "    this.initialValues = const <String, Object?>{},",
            "    this.submitLabel = 'Save',",
            "    this.externalValuePicker,",
            "    this.errorMessageBuilder,",
            "  });",
            "",
            "  final GeneratedIdentifiedFormSubmit onSubmit;",
            "  final DomainRecord<\(entityType)>? record;",
            "  final Map<String, Object?> initialValues;",
            "  final String submitLabel;",
            "  final GeneratedExternalValuePicker? externalValuePicker;",
            "  final GeneratedFormErrorMessageBuilder? errorMessageBuilder;",
            ""
        ]
    }

    func buildMethodLines(
        screenID: String,
        title: String
    ) -> [String] {
        [
            "  @override",
            "  Widget build(BuildContext context) {",
            "    final recordValues = record == null",
            "        ? const <String, Object?>{}",
            "        : _initialValuesFor(record!.value);",
            "    final effectiveInitialValues = Map<String, Object?>.unmodifiable(",
            "      <String, Object?>{",
            "        ...recordValues,",
            "        ...initialValues,",
            "      },",
            "    );",
            "",
            "    return GeneratedEntityFormScreen(",
            "      screenId: '\(screenID)',",
            "      title: '\(title)',",
            "      fields: _fields,",
            "      initialValues: effectiveInitialValues,",
            "      submitLabel: submitLabel,",
            "      externalValuePicker: externalValuePicker,",
            "      errorMessageBuilder: errorMessageBuilder,",
            "      onSubmit: (values) => onSubmit(",
            "        recordId: record?.recordId,",
            "        values: values,",
            "      ),",
            "    );",
            "  }",
            ""
        ]
    }

    func editMapperLines(entityType: String) -> [String] {
        let mapperLines = [
            "  static \(entityType) applyEditValues({",
            "    required DomainRecord<\(entityType)> record,",
            "    required Map<String, Object?> values,",
            "  }) {",
            "    final current = record.value;",
            "    return \(entityType)("
        ] + editEntityArgumentLines() + [
            "    );",
            "  }",
            ""
        ]

        return mapperLines
            + requiredEditValueHelperLines()
            + optionalEditValueHelperLines()
    }

    func requiredEditValueHelperLines() -> [String] {
        [
            "  static T _requiredEditValue<T>(",
            "    Map<String, Object?> values,",
            "    String fieldId,",
            "  ) {",
            "    if (!values.containsKey(fieldId)) {",
            "      throw StateError(",
            "        'Missing normalized edit value for $fieldId.',",
            "      );",
            "    }",
            "    final value = values[fieldId];",
            "    if (value is T) {",
            "      return value;",
            "    }",
            "    throw StateError(",
            "      'Invalid normalized edit value for $fieldId.',",
            "    );",
            "  }",
            ""
        ]
    }

    func optionalEditValueHelperLines() -> [String] {
        [
            "  static T? _optionalEditValue<T>(",
            "    Map<String, Object?> values,",
            "    String fieldId,",
            "  ) {",
            "    if (!values.containsKey(fieldId)) {",
            "      throw StateError(",
            "        'Missing normalized edit value for $fieldId.',",
            "      );",
            "    }",
            "    final value = values[fieldId];",
            "    if (value == null) {",
            "      return null;",
            "    }",
            "    if (value is T) {",
            "      return value;",
            "    }",
            "    throw StateError(",
            "      'Invalid normalized edit value for $fieldId.',",
            "    );",
            "  }",
            ""
        ]
    }

    func editEntityArgumentLines() -> [String] {
        let visibleFieldIDs = Set(screen.visibleFieldIDs)
        let fieldLines = entity.fields
            .sorted(by: Self.fieldSort)
            .map { field in
                let member = FlutterDartNaming.memberName(
                    field.identity.code
                )
                let value: String
                if visibleFieldIDs.contains(field.id) {
                    let helper = field.isRequired
                        ? "_requiredEditValue"
                        : "_optionalEditValue"
                    let type = editValueType(field)
                    let fieldID = FlutterDartEscaping.singleQuoted(field.id)
                    value = "\(helper)<\(type)>(values, '\(fieldID)')"
                } else {
                    value = "current.\(member)"
                }
                return "      \(member): \(value),"
            }

        let relationLines = specification.relations
            .filter { $0.sourceEntityID == entity.id }
            .sorted(by: Self.relationSort)
            .map { relation in
                let member = FlutterDartNaming.memberName(
                    relation.identity.code
                )
                return "      \(member): current.\(member),"
            }

        return fieldLines + relationLines
    }

    func editValueType(_ field: FieldDefinition) -> String {
        let type = FlutterDartNaming.dartType(for: field)
        guard !field.isRequired, type.hasSuffix("?") else {
            return type
        }
        return String(type.dropLast())
    }

    func initialValuesMethodLines(
        entityType: String
    ) -> [String] {
        [
            "  static Map<String, Object?> _initialValuesFor(",
            "    \(entityType) value,",
            "  ) {",
            "    return <String, Object?>{"
        ] + initialValueLines() + [
            "    };",
            "  }",
            ""
        ]
    }

    func fieldSpecDeclarationLines() -> [String] {
        [
            "  static const List<GeneratedFormFieldSpec> _fields =",
            "      <GeneratedFormFieldSpec>["
        ] + fieldSpecLines() + [
            "    ];",
            "}"
        ]
    }

    func initialValueLines() -> [String] {
        let fields = Dictionary(
            uniqueKeysWithValues: entity.fields.map { ($0.id, $0) }
        )
        return screen.visibleFieldIDs.compactMap { fieldID in
            guard let field = fields[fieldID] else {
                return nil
            }
            let escapedID = FlutterDartEscaping.singleQuoted(field.id)
            let member = FlutterDartNaming.memberName(field.identity.code)
            return "      '\(escapedID)': value.\(member),"
        }
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

    static func fieldSort(
        _ lhs: FieldDefinition,
        _ rhs: FieldDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }

    static func relationSort(
        _ lhs: RelationDefinition,
        _ rhs: RelationDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }

    func optional(_ value: Int?) -> String {
        value.map { String($0) } ?? "null"
    }

    func optional(_ value: Double?) -> String {
        value.map { String($0) } ?? "null"
    }
}

private struct FormValidationBounds {
    let minimumLength: Int?
    let maximumLength: Int?
    let minimumValue: Double?
    let maximumValue: Double?
    let patterns: [String]
}
