import AppForgeDomain

struct FlutterGeneratedEntityDetailScreenSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_entity_detail_screen.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import 'package:flutter/material.dart';

        import '../domain/domain_values.dart';
        import 'generated_record_display.dart';

        typedef GeneratedDetailEdit<T> =
            void Function(DomainRecord<T> record);

        typedef GeneratedDetailFieldsBuilder<T> =
            List<GeneratedRecordFieldValue> Function(T value);

        class GeneratedEntityDetailScreen<T> extends StatelessWidget {
          const GeneratedEntityDetailScreen({
            super.key,
            required this.title,
            required this.record,
            required this.fieldsFor,
            this.onEdit,
            this.emptyMessage = 'No visible fields',
          });

          final String title;
          final DomainRecord<T> record;
          final GeneratedDetailFieldsBuilder<T> fieldsFor;
          final GeneratedDetailEdit<T>? onEdit;
          final String emptyMessage;

          @override
          Widget build(BuildContext context) {
            final fields = fieldsFor(record.value);

            return Scaffold(
              appBar: AppBar(
                title: Text(title),
                actions: onEdit == null
                    ? null
                    : <Widget>[
                        IconButton(
                          onPressed: () => onEdit!(record),
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit',
                        ),
                      ],
              ),
              body: SafeArea(
                child: ListView(
                  key: ValueKey<String>(record.recordId),
                  padding: const EdgeInsets.all(16),
                  children: fields.isEmpty
                      ? <Widget>[
                          Center(child: Text(emptyMessage)),
                        ]
                      : fields
                          .map(
                            (field) =>
                                _GeneratedDetailFieldLine(field: field),
                          )
                          .toList(growable: false),
                ),
              ),
            );
          }
        }

        class _GeneratedDetailFieldLine extends StatelessWidget {
          const _GeneratedDetailFieldLine({required this.field});

          final GeneratedRecordFieldValue field;

          @override
          Widget build(BuildContext context) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(generatedRecordDisplayValue(field)),
                ],
              ),
            );
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
