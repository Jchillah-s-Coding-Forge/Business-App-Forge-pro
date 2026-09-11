import AppForgeDomain

struct FlutterGeneratedFormCreateMappingSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_create_mapping.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        enum GeneratedFormCreateMappingFailure {
          missingValue,
          invalidType,
        }

        class GeneratedFormCreateMappingException implements Exception {
          const GeneratedFormCreateMappingException({
            required this.fieldId,
            required this.failure,
          });

          final String fieldId;
          final GeneratedFormCreateMappingFailure failure;

          @override
          String toString() =>
              'Generated form create mapping failed for $fieldId: ${failure.name}.';
        }

        abstract final class GeneratedFormCreateMapping {
          static T requiredValue<T>(
            Map<String, Object?> values,
            String fieldId,
          ) {
            if (!values.containsKey(fieldId)) {
              throw GeneratedFormCreateMappingException(
                fieldId: fieldId,
                failure: GeneratedFormCreateMappingFailure.missingValue,
              );
            }
            final value = values[fieldId];
            if (value is! T) {
              throw GeneratedFormCreateMappingException(
                fieldId: fieldId,
                failure: GeneratedFormCreateMappingFailure.invalidType,
              );
            }
            return value;
          }

          static T? optionalValue<T>(
            Map<String, Object?> values,
            String fieldId,
          ) {
            if (!values.containsKey(fieldId)) {
              throw GeneratedFormCreateMappingException(
                fieldId: fieldId,
                failure: GeneratedFormCreateMappingFailure.missingValue,
              );
            }
            final value = values[fieldId];
            if (value == null) {
              return null;
            }
            if (value is! T) {
              throw GeneratedFormCreateMappingException(
                fieldId: fieldId,
                failure: GeneratedFormCreateMappingFailure.invalidType,
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
