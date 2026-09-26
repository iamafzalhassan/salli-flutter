import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/skeleton.dart';

class ProfileCardSkeleton extends StatelessWidget {
  const ProfileCardSkeleton({super.key});

  static const double _nameFactor = 0.6;
  static const double _phoneFactor = 0.4;

  @override
  Widget build(BuildContext context) => const AppCard(
    child: Row(
      children: [
        Skeleton.circle(size: AppSpacing.iconHero),
        SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(
                widthFactor: _nameFactor,
                child: Skeleton.text(textStyle: AppTextStyles.title),
              ),
              SizedBox(height: AppSpacing.xs),
              FractionallySizedBox(
                widthFactor: _phoneFactor,
                child: Skeleton.text(textStyle: AppTextStyles.label),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
