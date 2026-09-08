struct FlutterGeneratedFormPickerFieldsSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_picker_fields.dart",
            contents: content
        )
    }

    private var content: String {
        """
        import 'package:flutter/material.dart';

        import 'generated_form_contract.dart';

        class GeneratedSliderField extends StatelessWidget {
          const GeneratedSliderField({
            super.key,
            required this.spec,
            required this.value,
            required this.onChanged,
          });

          final GeneratedFormFieldSpec spec;
          final Object? value;
          final ValueChanged<Object?> onChanged;

          @override
          Widget build(BuildContext context) {
            final minimum = spec.rangeMinimum ?? 0;
            final maximum = spec.rangeMaximum ?? 100;
            final raw = value is num ? (value! as num).toDouble() : minimum;
            final current = raw.clamp(minimum, maximum).toDouble();

            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_displayValue(current)),
                  Slider(
                    value: current,
                    min: minimum,
                    max: maximum,
                    onChanged: (next) {
                      if (spec.valueKind == 'integer') {
                        onChanged(next.round());
                      } else {
                        onChanged(next);
                      }
                    },
                  ),
                ],
              ),
            );
          }

          String _displayValue(double value) {
            if (spec.valueKind == 'integer') {
              return value.round().toString();
            }
            return value.toStringAsFixed(2);
          }
        }

        class GeneratedTemporalField extends StatelessWidget {
          const GeneratedTemporalField({
            super.key,
            required this.spec,
            required this.value,
            required this.onChanged,
          });

          final GeneratedFormFieldSpec spec;
          final Object? value;
          final ValueChanged<Object?> onChanged;

          @override
          Widget build(BuildContext context) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_displayValue(context)),
                  ),
                  TextButton(
                    onPressed: () => _pick(context),
                    child: const Text('Choose'),
                  ),
                  if (!spec.isRequired && value != null)
                    IconButton(
                      tooltip: 'Clear ${spec.label}',
                      onPressed: () => onChanged(null),
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
            );
          }

          Future<void> _pick(BuildContext context) async {
            switch (spec.control) {
              case 'datePicker':
                await _pickDate(context);
              case 'timePicker':
                await _pickTime(context);
              case 'dateTimePicker':
                await _pickDateTime(context);
            }
          }

          Future<void> _pickDate(BuildContext context) async {
            final current = value is DateTime ? value! as DateTime : DateTime.now();
            final selected = await showDatePicker(
              context: context,
              initialDate: current,
              firstDate: DateTime(1900),
              lastDate: DateTime(2200),
            );
            if (selected != null) {
              onChanged(selected);
            }
          }

          Future<void> _pickTime(BuildContext context) async {
            final current = value is TimeOfDay
                ? value! as TimeOfDay
                : TimeOfDay.now();
            final selected = await showTimePicker(
              context: context,
              initialTime: current,
            );
            if (selected != null) {
              onChanged(selected);
            }
          }

          Future<void> _pickDateTime(BuildContext context) async {
            final current = value is DateTime ? value! as DateTime : DateTime.now();
            final date = await showDatePicker(
              context: context,
              initialDate: current,
              firstDate: DateTime(1900),
              lastDate: DateTime(2200),
            );
            if (!context.mounted || date == null) {
              return;
            }
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(current),
            );
            if (time == null) {
              return;
            }
            onChanged(
              DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              ),
            );
          }

          String _displayValue(BuildContext context) {
            final current = value;
            if (current is DateTime) {
              if (spec.control == 'datePicker') {
                return MaterialLocalizations.of(context).formatMediumDate(current);
              }
              return current.toLocal().toString();
            }
            if (current is TimeOfDay) {
              return current.format(context);
            }
            return 'Not selected';
          }
        }

        class GeneratedExternalPickerField extends StatelessWidget {
          const GeneratedExternalPickerField({
            super.key,
            required this.screenId,
            required this.spec,
            required this.value,
            required this.onChanged,
            required this.picker,
          });

          final String screenId;
          final GeneratedFormFieldSpec spec;
          final Object? value;
          final ValueChanged<Object?> onChanged;
          final GeneratedExternalValuePicker? picker;

          @override
          Widget build(BuildContext context) {
            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value?.toString() ?? 'Not selected',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: picker == null ? null : _pick,
                    child: const Text('Choose'),
                  ),
                  if (!spec.isRequired && value != null)
                    IconButton(
                      tooltip: 'Clear ${spec.label}',
                      onPressed: () => onChanged(null),
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
            );
          }

          Future<void> _pick() async {
            final selected = await picker!(
              screenId: screenId,
              fieldId: spec.id,
              currentValue: value,
            );
            if (selected != null) {
              onChanged(selected);
            }
          }
        }
        """
            + "\n"
    }
}
