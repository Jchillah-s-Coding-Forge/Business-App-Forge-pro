import AppForgeDomain

struct FlutterGeneratedFormContractSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_contract.dart",
            contents: content
        )
    }

    private var content: String {
        """
        typedef GeneratedFormSubmit = Future<void> Function(
          Map<String, Object?> values,
        );

        typedef GeneratedExternalValuePicker = Future<Object?> Function({
          required String screenId,
          required String fieldId,
          required Object? currentValue,
        });

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
          final String valueKind;
          final String control;
          final bool isRequired;
          final List<GeneratedChoiceOption> options;
          final int? minimumLength;
          final int? maximumLength;
          final double? minimumValue;
          final double? maximumValue;
          final List<String> patterns;
          final double? rangeMinimum;
          final double? rangeMaximum;

          String? validate(Object? value) {
            if (isRequired && _isEmpty(value)) {
              return '$label is required.';
            }
            if (value == null || (value is String && value.isEmpty)) {
              return null;
            }

            if (valueKind == 'integer' || valueKind == 'double') {
              final text = value.toString().trim();
              final parsed = valueKind == 'integer'
                  ? int.tryParse(text)
                  : double.tryParse(text);
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
              if (options.isNotEmpty &&
                  !options.any((option) => option.value == value)) {
                return '$label has an invalid selection.';
              }
            }

            return null;
          }

          Object? normalize(Object? value) {
            if (value == null) {
              return null;
            }
            if (valueKind == 'integer') {
              return value is int ? value : int.tryParse(value.toString());
            }
            if (valueKind == 'double') {
              return value is double
                  ? value
                  : double.tryParse(value.toString());
            }
            return value;
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
}
