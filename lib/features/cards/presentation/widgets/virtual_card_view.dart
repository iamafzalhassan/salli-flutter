import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/entities/card_secrets.dart';
import '../../domain/entities/virtual_card.dart';

class VirtualCardView extends StatelessWidget {
  const VirtualCardView({super.key, this.secrets, required this.card});

  static const double aspectRatio = 1.586;
  static const double _frozenOpacity = 0.55;

  static const int _dateDigits = 2;
  static const int _groupSize = 4;
  static const int _yearModulo = 100;

  static const String _mask = '••••';

  final CardSecrets? secrets;

  final VirtualCard card;

  static String _grouped(String number) => [for (var start = 0; start < number.length; start += _groupSize) number.substring(start, (start + _groupSize).clamp(0, number.length))].join(' ');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final secrets = this.secrets;
    final ink = colors.onAccent;
    final number = secrets == null ? [_mask, _mask, _mask, card.last4].join(' ') : _grouped(secrets.number);
    final expiry = '${card.expiryMonth.toString().padLeft(_dateDigits, '0')}/${(card.expiryYear % _yearModulo).toString().padLeft(_dateDigits, '0')}';
    return RepaintBoundary(
      child: AnimatedOpacity(
        duration: AppMotion.base,
        opacity: card.isFrozen ? _frozenOpacity : 1,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.xl), color: colors.accent),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(LocaleKeys.appName),
                        maxLines: 1,
                        style: AppTextStyles.headline.copyWith(color: ink, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (card.isFrozen) ...[Icon(Icons.ac_unit_rounded, color: ink, size: AppSpacing.iconSm), const SizedBox(width: AppSpacing.xs)],
                    Text(
                      card.network.toUpperCase(),
                      maxLines: 1,
                      style: AppTextStyles.title.copyWith(color: ink, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Spacer(),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Text(
                      number,
                      key: ValueKey(number),
                      maxLines: 1,
                      style: AppTextStyles.title.copyWith(color: ink, fontFeatures: AppTextStyles.tabular, letterSpacing: AppSpacing.xxs),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.holderName.isEmpty ? context.tr(LocaleKeys.cardHolderFallback) : card.holderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(color: ink),
                      ),
                    ),
                    Text(
                      expiry,
                      maxLines: 1,
                      style: AppTextStyles.label.copyWith(color: ink, fontFeatures: AppTextStyles.tabular),
                    ),
                    if (secrets != null) ...[
                      const SizedBox(width: AppSpacing.lg),
                      Text(
                        context.tr(LocaleKeys.cardCvv, args: [secrets.cvv]),
                        maxLines: 1,
                        style: AppTextStyles.label.copyWith(color: ink, fontFeatures: AppTextStyles.tabular),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
