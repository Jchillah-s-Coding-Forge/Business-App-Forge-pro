import AppForgeDomain

struct FlutterGeneratedFormEditMappingSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_edit_mapping.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        enum GeneratedFormEditMappingFailure {
          missingValue,
          invalidType,
        }

        class GeneratedFormEditMappingException implements Exception {
          const GeneratedFormEditMappingException({
            required this.fieldId,
            required this.failure,
          });

          final String fieldId;
          final GeneratedFormEditMappingFailure failure;

          @override
          String toString() =>
              'Generated form edit mapping failed for $fieldId: ${failure.name}.';
        }

        abstract final class GeneratedFormEditMapping {
          static T requiredValue<T>(
            Map<String, Object?> values,
            String fieldId,
          ) {
            if (!values.containsKey(fieldId)) {
              throw GeneratedFormEditMappingException(
                fieldId: fieldId,
                failure: GeneratedFormEditMappingFailure.missingValue,
              );
            }

            final value = values[fieldId];
            if (value is! T) {
              throw GeneratedFormEditMappingException(
                fieldId: fieldId,
                failure: GeneratedFormEditMappingFailure.invalidType,
              );
            }
            return value;
          }

          static T? optionalValue<T>(
            Map<String, Object?> values,
            String fieldId,
          ) {
            if (!values.containsKey(fieldId)) {
              throw GeneratedFormEditMappingException(
                fieldId: fieldId,
                failure: GeneratedFormEditMappingFailure.missingValue,
              );
            }

            final value = values[fieldId];
            if (value == null) {
              return null;
            }
            if (value is! T) {
              throw GeneratedFormEditMappingException(
                fieldId: fieldId,
                failure: GeneratedFormEditMappingFailure.invalidType,
              );
            }
            return value;
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
