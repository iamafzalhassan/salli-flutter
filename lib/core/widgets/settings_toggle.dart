import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import 'app_card.dart';
import 'app_loader.dart';
import 'app_switch.dart';

class SettingsToggle extends StatelessWidget {
  const SettingsToggle({super.key, this.isBusy = false, required this.value, required this.subtitle, required this.title, required this.icon, this.onChanged});

  final bool isBusy;
  final bool value;

  final String subtitle;
  final String title;

  final IconData icon;

  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: AppSpacing.iconSm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          isBusy ? const AppLoader() : AppSwitch(onChanged: onChanged, value: value),
        ],
      ),
    );
  }
}
