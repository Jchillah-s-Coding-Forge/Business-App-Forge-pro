import AppForgeDomain

struct FlutterGeneratedFormPickerFieldsSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_picker_fields.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import 'package:flutter/material.dart';

        import '../domain/domain_values.dart';
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
            final minimum = spec.rangeMinimum ?? 0.0;
            final maximum = spec.rangeMaximum ?? 100.0;
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
                      if (spec.valueKind == GeneratedFormValueKind.integer) {
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
            if (spec.valueKind == GeneratedFormValueKind.integer) {
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
              case GeneratedFormControl.datePicker:
                await _pickDate(context);
              case GeneratedFormControl.timePicker:
                await _pickTime(context);
              case GeneratedFormControl.dateTimePicker:
                await _pickDateTime(context);
              default:
                return;
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
            final current = value is DateTime ? value! as DateTime : DateTime.now();
            final selected = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(current),
            );
            if (selected != null) {
              onChanged(
                DateTime(
                  current.year,
                  current.month,
                  current.day,
                  selected.hour,
                  selected.minute,
                ),
              );
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
              if (spec.control == GeneratedFormControl.datePicker) {
                return MaterialLocalizations.of(context).formatMediumDate(current);
              }
              if (spec.control == GeneratedFormControl.timePicker) {
                return MaterialLocalizations.of(context).formatTimeOfDay(
                  TimeOfDay.fromDateTime(current),
                );
              }
              final localizations = MaterialLocalizations.of(context);
              return '${localizations.formatMediumDate(current)} '
                  '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(current))}';
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
                      _displayValue(),
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
              valueKind: spec.valueKind,
              currentValue: value,
            );
            if (selected != null) {
              onChanged(selected);
            }
          }

          String _displayValue() {
            final current = value;
            if (current == null) {
              return 'Not selected';
            }
            if (current is DomainFileValue) {
              return current.uri.toString();
            }
            if (current is DomainImageValue) {
              return current.uri.toString();
            }
            if (current is DomainColorValue) {
              return current.hex;
            }
            if (current is DomainLocationValue) {
              return '${current.latitude}, ${current.longitude}';
            }
            return current.toString();
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
