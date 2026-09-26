import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';
import 'app_text_field.dart';

class TextEntrySheet extends StatefulWidget {
  const TextEntrySheet({super.key, required this.maxLength, required this.confirmLabel, required this.hint, this.initialValue = '', required this.title});

  final int maxLength;

  final String confirmLabel;
  final String hint;
  final String initialValue;
  final String title;

  @override
  State<TextEntrySheet> createState() => _TextEntrySheetState();
}

class _TextEntrySheetState extends State<TextEntrySheet> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(autofocus: true, controller: _controller, hint: widget.hint, maxLength: widget.maxLength, onSubmitted: (_) => _submit()),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: widget.confirmLabel, onPressed: _submit),
      ],
    ),
  );
}
