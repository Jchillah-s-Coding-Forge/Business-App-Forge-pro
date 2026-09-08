import AppForgeDomain

struct FlutterGeneratedFormChoiceFieldsSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_choice_fields.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import 'package:flutter/material.dart';

        import 'generated_form_contract.dart';

        class GeneratedBooleanField extends StatelessWidget {
          const GeneratedBooleanField({
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
            final initialValue = value;
            final current = initialValue is bool ? initialValue : false;
            if (spec.control == GeneratedFormControl.checkbox) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(spec.label),
                value: current,
                onChanged: onChanged,
              );
            }
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(spec.label),
              value: current,
              onChanged: onChanged,
            );
          }
        }

        class GeneratedChoiceField extends StatelessWidget {
          const GeneratedChoiceField({
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
            return switch (spec.control) {
              GeneratedFormControl.radioGroup => _radioGroup(),
              GeneratedFormControl.segmented => _segmented(),
              GeneratedFormControl.comboBox => _comboBox(),
              GeneratedFormControl.autocomplete => _autocomplete(),
              _ => _select(),
            };
          }

          Widget _radioGroup() {
            final current = _selectedValue();
            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              child: RadioGroup<String>(
                groupValue: current,
                onChanged: (next) => onChanged(_outputValue(next)),
                child: Column(
                  children: spec.options
                      .map(
                        (option) => RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(option.label),
                          value: option.value,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            );
          }

          Widget _segmented() {
            final current = _selectedValue();
            final selected = current == null
                ? <String>{}
                : <String>{current};
            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              child: SegmentedButton<String>(
                emptySelectionAllowed: current == null || !spec.isRequired,
                segments: spec.options
                    .map(
                      (option) => ButtonSegment<String>(
                        value: option.value,
                        label: Text(option.label),
                      ),
                    )
                    .toList(growable: false),
                selected: selected,
                onSelectionChanged: (selection) {
                  onChanged(
                    _outputValue(selection.isEmpty ? null : selection.first),
                  );
                },
              ),
            );
          }

          Widget _select() {
            return DropdownButtonFormField<String>(
              initialValue: _selectedValue(),
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              items: spec.options
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option.value,
                      child: Text(option.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (next) => onChanged(_outputValue(next)),
            );
          }

          Widget _comboBox() {
            return DropdownMenu<String>(
              initialSelection: _selectedValue(),
              label: Text(spec.label),
              expandedInsets: EdgeInsets.zero,
              dropdownMenuEntries: spec.options
                  .map(
                    (option) => DropdownMenuEntry<String>(
                      value: option.value,
                      label: option.label,
                    ),
                  )
                  .toList(growable: false),
              onSelected: (next) => onChanged(_outputValue(next)),
            );
          }

          Widget _autocomplete() {
            final initial = _selectedValue() ?? '';
            return Autocomplete<String>(
              initialValue: TextEditingValue(text: initial),
              optionsBuilder: (textEditingValue) {
                final query = textEditingValue.text.toLowerCase();
                return spec.options
                    .where(
                      (option) =>
                          query.isEmpty ||
                          option.label.toLowerCase().contains(query) ||
                          option.value.toLowerCase().contains(query),
                    )
                    .map((option) => option.value);
              },
              displayStringForOption: (candidate) {
                return spec.options
                    .firstWhere((option) => option.value == candidate)
                    .label;
              },
              onSelected: (next) => onChanged(_outputValue(next)),
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: spec.label,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (raw) {
                    final exact = spec.options.where(
                      (option) =>
                          option.label == raw || option.value == raw,
                    );
                    if (exact.isEmpty) {
                      onChanged(null);
                    } else {
                      onChanged(_outputValue(exact.first.value));
                    }
                  },
                  onSubmitted: (_) => onFieldSubmitted(),
                );
              },
            );
          }

          String? _selectedValue() {
            final current = value;
            final candidate = current is bool
                ? current.toString()
                : current?.toString();
            if (candidate == null) {
              return null;
            }
            return spec.options.any((option) => option.value == candidate)
                ? candidate
                : null;
          }

          Object? _outputValue(String? selected) {
            if (selected == null) {
              return null;
            }
            if (spec.valueKind == GeneratedFormValueKind.boolean) {
              return selected == 'true';
            }
            return selected;
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
