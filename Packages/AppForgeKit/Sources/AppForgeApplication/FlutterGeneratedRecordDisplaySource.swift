import AppForgeDomain

struct FlutterGeneratedRecordDisplaySource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_record_display.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import '../domain/domain_values.dart';

        enum GeneratedRecordValueKind {
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

        class GeneratedRecordFieldValue {
          const GeneratedRecordFieldValue({
            required this.label,
            required this.valueKind,
            required this.value,
          });

          final String label;
          final GeneratedRecordValueKind valueKind;
          final Object? value;
        }

        String generatedRecordDisplayValue(
          GeneratedRecordFieldValue field,
        ) {
          final value = field.value;
          if (value == null) {
            return '—';
          }

          switch (field.valueKind) {
            case GeneratedRecordValueKind.boolean:
              return value as bool ? 'Yes' : 'No';
            case GeneratedRecordValueKind.date:
              return (value as DateTime)
                  .toUtc()
                  .toIso8601String()
                  .split('T')
                  .first;
            case GeneratedRecordValueKind.dateTime:
              return (value as DateTime).toUtc().toIso8601String();
            case GeneratedRecordValueKind.time:
              return (value as DateTime)
                  .toUtc()
                  .toIso8601String()
                  .substring(11, 16);
            case GeneratedRecordValueKind.file:
              return (value as DomainFileValue).uri.toString();
            case GeneratedRecordValueKind.image:
              return (value as DomainImageValue).uri.toString();
            case GeneratedRecordValueKind.color:
              return (value as DomainColorValue).hex;
            case GeneratedRecordValueKind.location:
              final location = value as DomainLocationValue;
              return '${location.latitude}, ${location.longitude}';
            case GeneratedRecordValueKind.string:
            case GeneratedRecordValueKind.integer:
            case GeneratedRecordValueKind.decimal:
            case GeneratedRecordValueKind.email:
            case GeneratedRecordValueKind.phone:
            case GeneratedRecordValueKind.url:
            case GeneratedRecordValueKind.currency:
            case GeneratedRecordValueKind.percentage:
            case GeneratedRecordValueKind.enumeration:
              return value.toString();
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
