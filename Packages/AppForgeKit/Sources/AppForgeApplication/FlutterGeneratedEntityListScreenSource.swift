struct FlutterGeneratedEntityListScreenSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_entity_list_screen.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import 'package:flutter/material.dart';

        import '../domain/domain_values.dart';

        enum GeneratedListValueKind {
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

        typedef GeneratedListLoader<T> =
            Future<List<DomainRecord<T>>> Function();

        typedef GeneratedListRecordSelected<T> =
            void Function(DomainRecord<T> record);

        typedef GeneratedListFieldsBuilder<T> =
            List<GeneratedListFieldValue> Function(T value);

        typedef GeneratedListErrorMessageBuilder =
            String Function(Object error);

        class GeneratedListFieldValue {
          const GeneratedListFieldValue({
            required this.label,
            required this.valueKind,
            required this.value,
          });

          final String label;
          final GeneratedListValueKind valueKind;
          final Object? value;
        }

        class GeneratedEntityListScreen<T> extends StatefulWidget {
          const GeneratedEntityListScreen({
            super.key,
            required this.title,
            required this.loadRecords,
            required this.fieldsFor,
            this.onRecordSelected,
            this.emptyMessage = 'No records available.',
            this.errorMessageBuilder,
          });

          final String title;
          final GeneratedListLoader<T> loadRecords;
          final GeneratedListFieldsBuilder<T> fieldsFor;
          final GeneratedListRecordSelected<T>? onRecordSelected;
          final String emptyMessage;
          final GeneratedListErrorMessageBuilder? errorMessageBuilder;

          @override
          State<GeneratedEntityListScreen<T>> createState() =>
              _GeneratedEntityListScreenState<T>();
        }

        class _GeneratedEntityListScreenState<T>
            extends State<GeneratedEntityListScreen<T>> {
          late Future<List<DomainRecord<T>>> _records;

          @override
          void initState() {
            super.initState();
            _records = widget.loadRecords();
          }

          @override
          void didUpdateWidget(GeneratedEntityListScreen<T> oldWidget) {
            super.didUpdateWidget(oldWidget);
            if (oldWidget.loadRecords != widget.loadRecords) {
              _reload();
            }
          }

          @override
          Widget build(BuildContext context) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.title)),
              body: FutureBuilder<List<DomainRecord<T>>>(
                future: _records,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return _errorState(snapshot.error!);
                  }

                  final records = snapshot.data ?? <DomainRecord<T>>[];
                  if (records.isEmpty) {
                    return Center(child: Text(widget.emptyMessage));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _recordCard(records[index]);
                    },
                  );
                },
              ),
            );
          }

          Widget _errorState(Object error) {
            final message = widget.errorMessageBuilder?.call(error) ??
                'Unable to load records.';
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          Widget _recordCard(DomainRecord<T> record) {
            final fields = widget.fieldsFor(record.value);
            return Card(
              key: ValueKey<String>(record.recordId),
              child: InkWell(
                onTap: widget.onRecordSelected == null
                    ? null
                    : () => widget.onRecordSelected!(record),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: fields.isEmpty
                        ? const <Widget>[Text('No visible fields')]
                        : fields
                            .map(
                              (field) =>
                                  _GeneratedListFieldLine(field: field),
                            )
                            .toList(growable: false),
                  ),
                ),
              ),
            );
          }

          void _reload() {
            setState(() {
              _records = widget.loadRecords();
            });
          }
        }

        class _GeneratedListFieldLine extends StatelessWidget {
          const _GeneratedListFieldLine({required this.field});

          final GeneratedListFieldValue field;

          @override
          Widget build(BuildContext context) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      field.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(_displayValue(field)),
                  ),
                ],
              ),
            );
          }
        }

        String _displayValue(GeneratedListFieldValue field) {
          final value = field.value;
          if (value == null) {
            return '—';
          }

          switch (field.valueKind) {
            case GeneratedListValueKind.boolean:
              return value as bool ? 'Yes' : 'No';
            case GeneratedListValueKind.date:
              return (value as DateTime)
                  .toUtc()
                  .toIso8601String()
                  .split('T')
                  .first;
            case GeneratedListValueKind.dateTime:
              return (value as DateTime).toUtc().toIso8601String();
            case GeneratedListValueKind.time:
              return (value as DateTime)
                  .toUtc()
                  .toIso8601String()
                  .substring(11, 16);
            case GeneratedListValueKind.file:
              return (value as DomainFileValue).uri.toString();
            case GeneratedListValueKind.image:
              return (value as DomainImageValue).uri.toString();
            case GeneratedListValueKind.color:
              return (value as DomainColorValue).hex;
            case GeneratedListValueKind.location:
              final location = value as DomainLocationValue;
              return '${location.latitude}, ${location.longitude}';
            case GeneratedListValueKind.string:
            case GeneratedListValueKind.integer:
            case GeneratedListValueKind.decimal:
            case GeneratedListValueKind.email:
            case GeneratedListValueKind.phone:
            case GeneratedListValueKind.url:
            case GeneratedListValueKind.currency:
            case GeneratedListValueKind.percentage:
            case GeneratedListValueKind.enumeration:
              return value.toString();
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
