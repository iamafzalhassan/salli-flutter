import 'package:flutter/material.dart';

import '../errors/failure.dart';
import '../localization/failure_message.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';

class FailureText extends StatelessWidget {
  const FailureText({super.key, this.failure, this.textAlign = TextAlign.start});

  final Failure? failure;

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;
    return AnimatedSize(
      alignment: Alignment.topCenter,
      curve: AppMotion.standard,
      duration: AppMotion.base,
      child: AnimatedSwitcher(
        duration: AppMotion.fast,
        child: failure == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(failure),
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    context.failureMessage(failure),
                    style: AppTextStyles.label.copyWith(color: context.colors.danger),
                    textAlign: textAlign,
                  ),
                ),
              ),
      ),
    );
  }
}
