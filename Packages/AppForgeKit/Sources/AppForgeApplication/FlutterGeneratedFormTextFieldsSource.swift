import AppForgeDomain

struct FlutterGeneratedFormTextFieldsSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_text_fields.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import 'package:flutter/material.dart';

        import 'generated_form_contract.dart';

        class GeneratedTextField extends StatelessWidget {
          const GeneratedTextField({
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
            return TextFormField(
              key: ValueKey<String>('generated-form-${spec.id}'),
              initialValue: value?.toString() ?? '',
              minLines: spec.control == GeneratedFormControl.textArea ? 3 : 1,
              maxLines: spec.control == GeneratedFormControl.textArea ? 5 : 1,
              keyboardType: spec.isNumeric
                  ? TextInputType.numberWithOptions(
                      decimal:
                          spec.valueKind != GeneratedFormValueKind.integer,
                      signed: true,
                    )
                  : _keyboardType(),
              textInputAction:
                  spec.control == GeneratedFormControl.textArea
                  ? TextInputAction.newline
                  : TextInputAction.next,
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              onChanged: onChanged,
            );
          }

          TextInputType _keyboardType() {
            switch (spec.valueKind) {
              case GeneratedFormValueKind.email:
                return TextInputType.emailAddress;
              case GeneratedFormValueKind.phone:
                return TextInputType.phone;
              case GeneratedFormValueKind.url:
                return TextInputType.url;
              default:
                return TextInputType.text;
            }
          }
        }

        class GeneratedStepperField extends StatelessWidget {
          const GeneratedStepperField({
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
            final current = _currentValue();
            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Decrease ${spec.label}',
                    onPressed: () => onChanged(_nextValue(current, -1)),
                    icon: const Icon(Icons.remove),
                  ),
                  Expanded(
                    child: Text(
                      _displayValue(current),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Increase ${spec.label}',
                    onPressed: () => onChanged(_nextValue(current, 1)),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            );
          }

          double _currentValue() {
            final raw = value;
            if (raw is num) {
              return raw.toDouble();
            }
            return double.tryParse(raw?.toString() ?? '') ??
                spec.minimumValue ??
                0;
          }

          Object _nextValue(double current, int direction) {
            var next = current + direction;
            if (spec.minimumValue != null && next < spec.minimumValue!) {
              next = spec.minimumValue!;
            }
            if (spec.maximumValue != null && next > spec.maximumValue!) {
              next = spec.maximumValue!;
            }
            if (spec.valueKind == GeneratedFormValueKind.integer) {
              return next.round();
            }
            return next;
          }

          String _displayValue(double value) {
            if (spec.valueKind == GeneratedFormValueKind.integer) {
              return value.round().toString();
            }
            return value.toString();
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
