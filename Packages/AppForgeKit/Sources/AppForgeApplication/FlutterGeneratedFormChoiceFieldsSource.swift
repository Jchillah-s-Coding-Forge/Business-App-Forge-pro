struct FlutterGeneratedFormChoiceFieldsSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_choice_fields.dart",
            contents: content
        )
    }

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
            final current = value as bool? ?? false;
            if (spec.control == 'checkbox') {
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
              'radioGroup' => _radioGroup(),
              'segmented' => _segmented(),
              'comboBox' => _comboBox(),
              'autocomplete' => _autocomplete(),
              _ => _select(),
            };
          }

          Widget _radioGroup() {
            final current = value?.toString();
            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              child: Column(
                children: spec.options
                    .map(
                      (option) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(option.label),
                        value: option.value,
                        groupValue: current,
                        onChanged: onChanged,
                      ),
                    )
                    .toList(growable: false),
              ),
            );
          }

          Widget _segmented() {
            final current = value?.toString();
            final selected = current == null
                ? <String>{}
                : <String>{current};
            return InputDecorator(
              decoration: InputDecoration(
                labelText: spec.label,
                border: const OutlineInputBorder(),
              ),
              child: SegmentedButton<String>(
                emptySelectionAllowed: !spec.isRequired,
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
                  onChanged(selection.isEmpty ? null : selection.first);
                },
              ),
            );
          }

          Widget _select() {
            return DropdownButtonFormField<String>(
              value: value?.toString(),
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
              onChanged: onChanged,
            );
          }

          Widget _comboBox() {
            return DropdownMenu<String>(
              initialSelection: value?.toString(),
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
              onSelected: onChanged,
            );
          }

          Widget _autocomplete() {
            final initial = value?.toString() ?? '';
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
              onSelected: onChanged,
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
                      onChanged(exact.first.value);
                    }
                  },
                  onSubmitted: (_) => onFieldSubmitted(),
                );
              },
            );
          }
        }
        """
            + "\n"
    }
}
