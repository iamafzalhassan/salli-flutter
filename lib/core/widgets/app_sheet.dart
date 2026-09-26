import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

Future<T?> showAppSheet<T>(BuildContext context, {required Widget child}) => showModalBottomSheet<T>(
  backgroundColor: Colors.transparent,
  builder: (context) => AppSheet(child: child),
  context: context,
  isScrollControlled: true,
  sheetAnimationStyle: MediaQuery.disableAnimationsOf(context) ? AnimationStyle.noAnimation : AppMotion.sheet,
);

class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        color: colors.surface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), color: colors.border),
                height: AppSpacing.xs,
                width: AppSpacing.sheetHandle,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            child,
            const SizedBox(height: AppSpacing.screenPadding),
          ],
        ),
      ),
    );
  }
}
