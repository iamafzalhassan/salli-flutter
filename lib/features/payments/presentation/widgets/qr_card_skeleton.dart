import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/skeleton.dart';
import 'qr_card.dart';

class QrCardSkeleton extends StatelessWidget {
  const QrCardSkeleton({super.key});

  static const double _footerWidth = 120;
  static const double _nameWidth = 140;
  static const double _phoneWidth = 96;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.xl), color: context.colors.surface),
    child: const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Skeleton.text(textStyle: AppTextStyles.title, width: _nameWidth),
          SizedBox(height: AppSpacing.xxs),
          Skeleton.text(textStyle: AppTextStyles.label, width: _phoneWidth),
          SizedBox(height: AppSpacing.xl),
          Skeleton(height: QrCard.codeSize, width: QrCard.codeSize),
          SizedBox(height: AppSpacing.lg),
          Skeleton.text(textStyle: AppTextStyles.overline, width: _footerWidth),
        ],
      ),
    ),
  );
}
