import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/avatar.dart';
import '../../domain/entities/payee.dart';

class PayeeTile extends StatelessWidget {
  const PayeeTile({super.key, required this.payee, required this.onPressed, this.trailing});

  final Payee payee;

  final VoidCallback onPressed;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPressable(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Avatar(name: payee.name),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payee.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    payee.phone.display,
                    maxLines: 1,
                    style: AppTextStyles.caption.copyWith(color: colors.textSecondary, fontFeatures: AppTextStyles.tabular),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            trailing ?? Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: AppSpacing.iconSm),
          ],
        ),
      ),
    );
  }
}
