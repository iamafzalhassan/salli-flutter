import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_keys.dart';
import '../network/network_status.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.status, required this.child});

  static const Offset _hiddenOffset = Offset(0, -1);

  final NetworkStatus status;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.base;
    return Stack(
      children: [
        child,
        Positioned(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: ListenableBuilder(
              builder: (context, _) => IgnorePointer(
                ignoring: !status.isOffline,
                child: AnimatedSlide(
                  curve: AppMotion.emphasized,
                  duration: duration,
                  offset: status.isOffline ? Offset.zero : _hiddenOffset,
                  child: AnimatedOpacity(
                    duration: duration,
                    opacity: status.isOffline ? 1 : 0,
                    child: Semantics(
                      liveRegion: true,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.warning, width: AppSpacing.hairline),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          color: colors.surfaceRaised,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off_rounded, color: colors.warning, size: AppSpacing.iconSm),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                context.tr(LocaleKeys.networkOffline),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.label.copyWith(color: colors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              listenable: status,
            ),
          ),
        ),
      ],
    );
  }
}
