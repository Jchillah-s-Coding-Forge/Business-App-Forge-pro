import AppForgeDomain

struct FlutterGeneratedFormContractSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_contract.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import '../domain/domain_values.dart';

        enum GeneratedFormValueKind {
          string,
          integer,
          decimal,
          boolean,
          date,
          dateTime,
          time,
          email,
          phone,
          url,
          currency,
          percentage,
          enumeration,
          file,
          image,
          color,
          location,
        }

        enum GeneratedFormControl {
          textField,
          textArea,
          numericField,
          stepper,
          slider,
          checkbox,
          switchToggle,
          radioGroup,
          segmented,
          select,
          comboBox,
          autocomplete,
          datePicker,
          timePicker,
          dateTimePicker,
          filePicker,
          imagePicker,
          colorPicker,
          locationPicker,
        }

        typedef GeneratedFormSubmit = Future<void> Function(
          Map<String, Object?> values,
        );

        typedef GeneratedIdentifiedFormSubmit = Future<void> Function({
          required String? recordId,
          required Map<String, Object?> values,
        });

        typedef GeneratedExternalValuePicker = Future<Object?> Function({
          required String screenId,
          required String fieldId,
          required GeneratedFormValueKind valueKind,
          required Object? currentValue,
        });

        typedef GeneratedFormErrorMessageBuilder = String Function(
          Object error,
          StackTrace stackTrace,
        );

        class GeneratedChoiceOption {
          const GeneratedChoiceOption({
            required this.value,
            required this.label,
          });

          final String value;
          final String label;
        }

        class GeneratedFormFieldSpec {
          const GeneratedFormFieldSpec({
            required this.id,
            required this.label,
            required this.valueKind,
            required this.control,
            required this.isRequired,
            this.options = const <GeneratedChoiceOption>[],
            this.minimumLength,
            this.maximumLength,
            this.minimumValue,
            this.maximumValue,
            this.patterns = const <String>[],
            this.rangeMinimum,
            this.rangeMaximum,
          });

          final String id;
          final String label;
          final GeneratedFormValueKind valueKind;
          final GeneratedFormControl control;
          final bool isRequired;
          final List<GeneratedChoiceOption> options;
          final int? minimumLength;
          final int? maximumLength;
          final double? minimumValue;
          final double? maximumValue;
          final List<String> patterns;
          final double? rangeMinimum;
          final double? rangeMaximum;

          bool get isNumeric {
            switch (valueKind) {
              case GeneratedFormValueKind.integer:
              case GeneratedFormValueKind.decimal:
              case GeneratedFormValueKind.currency:
              case GeneratedFormValueKind.percentage:
                return true;
              default:
                return false;
            }
          }

          Object? get fallbackInitialValue {
            switch (control) {
              case GeneratedFormControl.checkbox:
              case GeneratedFormControl.switchToggle:
                return false;
              case GeneratedFormControl.stepper:
                return valueKind == GeneratedFormValueKind.integer
                    ? (minimumValue ?? 0).round()
                    : minimumValue ?? 0.0;
              case GeneratedFormControl.slider:
                return valueKind == GeneratedFormValueKind.integer
                    ? (rangeMinimum ?? 0).round()
                    : rangeMinimum ?? 0.0;
              default:
                return null;
            }
          }

          String? validate(Object? value) {
            if (isRequired && _isEmpty(value)) {
              return '$label is required.';
            }
            if (value == null || (value is String && value.trim().isEmpty)) {
              return null;
            }

            final typeError = _validateType(value);
            if (typeError != null) {
              return typeError;
            }

            final numericError = _validateNumber(value);
            if (numericError != null) {
              return numericError;
            }

            if (value is String) {
              if (minimumLength != null && value.length < minimumLength!) {
                return '$label is too short.';
              }
              if (maximumLength != null && value.length > maximumLength!) {
                return '$label is too long.';
              }
              for (final pattern in patterns) {
                try {
                  if (!RegExp(pattern).hasMatch(value)) {
                    return '$label has an invalid format.';
                  }
                } on FormatException {
                  return '$label has an invalid validation pattern.';
                }
              }
            }

            if (options.isNotEmpty) {
              final selected = value is bool ? value.toString() : '$value';
              if (!options.any((option) => option.value == selected)) {
                return '$label has an invalid selection.';
              }
            }

            return null;
          }

          String? _validateType(Object value) {
            final isValid = switch (valueKind) {
              GeneratedFormValueKind.string ||
              GeneratedFormValueKind.email ||
              GeneratedFormValueKind.phone ||
              GeneratedFormValueKind.url ||
              GeneratedFormValueKind.enumeration => value is String,
              GeneratedFormValueKind.integer ||
              GeneratedFormValueKind.decimal ||
              GeneratedFormValueKind.currency ||
              GeneratedFormValueKind.percentage => true,
              GeneratedFormValueKind.boolean => value is bool,
              GeneratedFormValueKind.date ||
              GeneratedFormValueKind.dateTime ||
              GeneratedFormValueKind.time => value is DateTime,
              GeneratedFormValueKind.file => value is DomainFileValue,
              GeneratedFormValueKind.image => value is DomainImageValue,
              GeneratedFormValueKind.color => value is DomainColorValue,
              GeneratedFormValueKind.location => value is DomainLocationValue,
            };
            return isValid ? null : '$label has an invalid value.';
          }

          String? _validateNumber(Object value) {
            if (!isNumeric) {
              return null;
            }

            final num? parsed;
            if (valueKind == GeneratedFormValueKind.integer) {
              parsed = value is int ? value : int.tryParse(value.toString());
            } else {
              parsed = value is num
                  ? value
                  : double.tryParse(value.toString());
            }
            if (parsed == null) {
              return '$label must be a number.';
            }

            final number = parsed.toDouble();
            if (minimumValue != null && number < minimumValue!) {
              return '$label must be at least $minimumValue.';
            }
            if (maximumValue != null && number > maximumValue!) {
              return '$label must be at most $maximumValue.';
            }
            return null;
          }

          Object? normalize(Object? value) {
            if (value == null) {
              return null;
            }
            switch (valueKind) {
              case GeneratedFormValueKind.integer:
                return value is int ? value : int.tryParse(value.toString());
              case GeneratedFormValueKind.decimal:
              case GeneratedFormValueKind.currency:
              case GeneratedFormValueKind.percentage:
                return value is double
                    ? value
                    : value is num
                    ? value.toDouble()
                    : double.tryParse(value.toString());
              case GeneratedFormValueKind.boolean:
                if (value is bool) {
                  return value;
                }
                return switch (value.toString()) {
                  'true' => true,
                  'false' => false,
                  _ => value,
                };
              default:
                return value;
            }
          }

          bool _isEmpty(Object? value) {
            if (value == null) {
              return true;
            }
            if (value is String) {
              return value.trim().isEmpty;
            }
            return false;
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
