import AppForgeDomain

struct FlutterGeneratedEntityFormScreenSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_entity_form_screen.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import 'package:flutter/foundation.dart';
        import 'package:flutter/material.dart';

        import 'generated_form_contract.dart';
        import 'generated_form_field.dart';

        class GeneratedEntityFormScreen extends StatefulWidget {
          const GeneratedEntityFormScreen({
            super.key,
            required this.screenId,
            required this.title,
            required this.fields,
            required this.onSubmit,
            this.initialValues = const <String, Object?>{},
            this.submitLabel = 'Save',
            this.externalValuePicker,
            this.errorMessageBuilder,
          });

          final String screenId;
          final String title;
          final List<GeneratedFormFieldSpec> fields;
          final GeneratedFormSubmit onSubmit;
          final Map<String, Object?> initialValues;
          final String submitLabel;
          final GeneratedExternalValuePicker? externalValuePicker;
          final GeneratedFormErrorMessageBuilder? errorMessageBuilder;

          @override
          State<GeneratedEntityFormScreen> createState() =>
              _GeneratedEntityFormScreenState();
        }

        class _GeneratedEntityFormScreenState
            extends State<GeneratedEntityFormScreen> {
          late GlobalKey<FormState> _formKey;
          late Map<String, Object?> _values;
          bool _isSubmitting = false;
          String? _submissionError;

          @override
          void initState() {
            super.initState();
            _formKey = GlobalKey<FormState>();
            _values = _initialValues();
          }

          @override
          void didUpdateWidget(GeneratedEntityFormScreen oldWidget) {
            super.didUpdateWidget(oldWidget);
            if (oldWidget.screenId != widget.screenId ||
                !mapEquals(oldWidget.initialValues, widget.initialValues)) {
              _formKey = GlobalKey<FormState>();
              _values = _initialValues();
              _submissionError = null;
            }
          }

          @override
          Widget build(BuildContext context) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.title)),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth < 600
                        ? 16.0
                        : 32.0;
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        24,
                        horizontalPadding,
                        32,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final spec in widget.fields) ...[
                                  GeneratedFormField(
                                    screenId: widget.screenId,
                                    spec: spec,
                                    value: _values[spec.id],
                                    externalValuePicker:
                                        widget.externalValuePicker,
                                    onChanged: (next) {
                                      _values[spec.id] = next;
                                      if (_submissionError != null) {
                                        setState(() => _submissionError = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_submissionError case final message?) ...[
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      message,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                FilledButton.icon(
                                  onPressed: _isSubmitting ? null : _submit,
                                  icon: _isSubmitting
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _isSubmitting
                                        ? 'Saving…'
                                        : widget.submitLabel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }

          Map<String, Object?> _initialValues() {
            final result = Map<String, Object?>.of(widget.initialValues);
            for (final field in widget.fields) {
              if (!result.containsKey(field.id)) {
                final fallback = field.fallbackInitialValue;
                if (fallback != null) {
                  result[field.id] = fallback;
                }
              }
            }
            return result;
          }

          Future<void> _submit() async {
            FocusManager.instance.primaryFocus?.unfocus();
            final isValid = _formKey.currentState?.validate() ?? false;
            if (!isValid || _isSubmitting) {
              return;
            }

            setState(() {
              _isSubmitting = true;
              _submissionError = null;
            });

            final normalized = <String, Object?>{
              for (final field in widget.fields)
                field.id: field.normalize(_values[field.id]),
            };
            final snapshot = Map<String, Object?>.unmodifiable(normalized);

            try {
              await widget.onSubmit(snapshot);
            } catch (error, stackTrace) {
              if (mounted) {
                setState(() {
                  _submissionError = widget.errorMessageBuilder?.call(
                        error,
                        stackTrace,
                      ) ??
                      'Your changes could not be saved. Please try again.';
                });
              }
            } finally {
              if (mounted) {
                setState(() => _isSubmitting = false);
              }
            }
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
