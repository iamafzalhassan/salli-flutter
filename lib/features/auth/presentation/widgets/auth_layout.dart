import 'package:flutter/material.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/fill_scroll_view.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, this.canGoBack = true, required this.subtitle, required this.title, required this.child, required this.footer});

  final bool canGoBack;

  final String subtitle;
  final String title;

  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: FillScrollView(
        children: [
          SizedBox(
            height: AppSpacing.touchTarget,
            child: Align(alignment: Alignment.centerLeft, child: canGoBack ? const AppBackButton() : null),
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: AppMotion.base,
            layoutBuilder: (current, previous) => Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
            child: Column(
              key: ValueKey(title),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.headline),
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle, style: AppTextStyles.body.copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          child,
          const Spacer(),
          const SizedBox(height: AppSpacing.xl),
          footer,
        ],
      ),
    ),
  );
}
