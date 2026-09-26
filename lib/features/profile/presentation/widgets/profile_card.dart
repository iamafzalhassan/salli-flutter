import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../domain/entities/profile.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      child: Row(
        children: [
          Avatar(name: profile.displayName, size: AppSpacing.iconHero),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName ?? context.tr(LocaleKeys.profileFallbackName), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  profile.phone.display,
                  maxLines: 1,
                  style: AppTextStyles.label.copyWith(color: colors.textSecondary, fontFeatures: AppTextStyles.tabular),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
