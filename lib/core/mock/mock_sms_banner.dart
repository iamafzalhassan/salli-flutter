import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/locale_keys.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/theme_context.dart';
import '../widgets/app_pressable.dart';
import 'mock_sms_inbox.dart';

class MockSmsBanner extends StatefulWidget {
  const MockSmsBanner({super.key, required this.inbox, required this.child});

  final MockSmsInbox inbox;

  final Widget child;

  @override
  State<MockSmsBanner> createState() => _MockSmsBannerState();
}

class _MockSmsBannerState extends State<MockSmsBanner> {
  static const Duration _visibleFor = Duration(seconds: 8);

  static const Offset _hiddenOffset = Offset(0, -1.5);

  bool _isVisible = false;

  MockSms? _message;

  Timer? _hideTimer;

  void _onMessage() {
    final message = widget.inbox.value;
    if (message == null) return;
    unawaited(HapticFeedback.mediumImpact());
    _hideTimer?.cancel();
    _hideTimer = Timer(_visibleFor, _hide);
    setState(() {
      _isVisible = true;
      _message = message;
    });
  }

  void _hide() {
    _hideTimer?.cancel();
    if (mounted) setState(() => _isVisible = false);
  }

  @override
  void initState() {
    super.initState();
    widget.inbox.addListener(_onMessage);
  }

  @override
  void dispose() {
    widget.inbox.removeListener(_onMessage);
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = _message;
    return Stack(
      children: [
        widget.child,
        if (message != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: AnimatedSlide(
                  curve: _isVisible ? AppMotion.emphasized : AppMotion.exit,
                  duration: AppMotion.slow,
                  offset: _isVisible ? Offset.zero : _hiddenOffset,
                  child: Material(
                    type: MaterialType.transparency,
                    child: AppPressable(
                      onPressed: _hide,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.border, width: AppSpacing.hairline),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          color: colors.surfaceRaised,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                              height: AppSpacing.touchTarget,
                              width: AppSpacing.touchTarget,
                              child: Icon(Icons.sms_rounded, color: colors.onAccent, size: AppSpacing.iconSm),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(LocaleKeys.mockSmsSender),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.overline.copyWith(color: colors.textSecondary),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(message.body, style: AppTextStyles.label.copyWith(color: colors.textPrimary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
