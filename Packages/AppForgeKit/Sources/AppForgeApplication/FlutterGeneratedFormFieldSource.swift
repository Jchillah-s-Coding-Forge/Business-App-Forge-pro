import AppForgeDomain
struct FlutterGeneratedFormFieldSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_form_field.dart",
            contents: content
        )
    }

    private var content: String {
        """
        import 'package:flutter/material.dart';

        import 'generated_form_choice_fields.dart';
        import 'generated_form_contract.dart';
        import 'generated_form_picker_fields.dart';
        import 'generated_form_text_fields.dart';

        class GeneratedFormField extends StatelessWidget {
          const GeneratedFormField({
            super.key,
            required this.screenId,
            required this.spec,
            required this.value,
            required this.onChanged,
            required this.externalValuePicker,
          });

          final String screenId;
          final GeneratedFormFieldSpec spec;
          final Object? value;
          final ValueChanged<Object?> onChanged;
          final GeneratedExternalValuePicker? externalValuePicker;

          @override
          Widget build(BuildContext context) {
            return FormField<Object?>(
              key: ValueKey<String>('generated-form-field-${spec.id}'),
              initialValue: value,
              validator: spec.validate,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              builder: (state) {
                void didChange(Object? next) {
                  state.didChange(next);
                  onChanged(next);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _control(state.value, didChange),
                    if (state.errorText case final error?)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          }

          Widget _control(
            Object? currentValue,
            ValueChanged<Object?> didChange,
          ) {
            switch (spec.control) {
              case GeneratedFormControl.textField:
              case GeneratedFormControl.textArea:
              case GeneratedFormControl.numericField:
                return GeneratedTextField(
                  spec: spec,
                  value: currentValue,
                  onChanged: didChange,
                );
              case GeneratedFormControl.stepper:
                return GeneratedStepperField(
                  spec: spec,
                  value: currentValue,
                  onChanged: didChange,
                );
              case GeneratedFormControl.slider:
                return GeneratedSliderField(
                  spec: spec,
                  value: currentValue,
                  onChanged: didChange,
                );
              case GeneratedFormControl.checkbox:
              case GeneratedFormControl.switchToggle:
                return GeneratedBooleanField(
                  spec: spec,
                  value: currentValue,
                  onChanged: didChange,
                );
              case GeneratedFormControl.radioGroup:
              case GeneratedFormControl.segmented:
              case GeneratedFormControl.select:
              case GeneratedFormControl.comboBox:
              case GeneratedFormControl.autocomplete:
                return GeneratedChoiceField(
                  spec: spec,
                  value: currentValue,
                  onChanged: didChange,
                );
              case GeneratedFormControl.datePicker:
              case GeneratedFormControl.timePicker:
              case GeneratedFormControl.dateTimePicker:
                return GeneratedTemporalField(
                  spec: spec,
                  value: currentValue,
                  onChanged: didChange,
                );
              case GeneratedFormControl.filePicker:
              case GeneratedFormControl.imagePicker:
              case GeneratedFormControl.colorPicker:
              case GeneratedFormControl.locationPicker:
                return GeneratedExternalPickerField(
                  screenId: screenId,
                  spec: spec,
                  value: currentValue,
                  onChanged: didChange,
                  picker: externalValuePicker,
                );
            }
          }
        }
        """
            + "\n"
    }
}
