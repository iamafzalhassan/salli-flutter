import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/kyc_status.dart';
import '../../domain/entities/verification.dart';

class VerificationCard extends StatelessWidget {
  const VerificationCard({super.key, required this.verification, this.onVerify});

  final Verification verification;

  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reason = verification.rejectionReason;
    final (icon, color) = switch (verification.status) {
      KycStatus.verified => (Icons.verified_rounded, colors.success),
      KycStatus.pending => (Icons.hourglass_top_rounded, colors.warning),
      KycStatus.rejected => (Icons.error_rounded, colors.danger),
      KycStatus.notStarted => (Icons.shield_rounded, colors.textSecondary),
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppSpacing.iconMd),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(context.tr('${LocaleKeys.kycStatusPrefix}.${verification.status.name}'), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyStrong),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(switch (verification.status) {
              KycStatus.verified => LocaleKeys.accountVerifiedBody,
              KycStatus.pending => LocaleKeys.accountPendingBody,
              KycStatus.rejected => reason == null ? LocaleKeys.accountRejectedBody : '${LocaleKeys.kycRejectionPrefix}.$reason',
              KycStatus.notStarted => LocaleKeys.accountNotStartedBody,
            }),
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          ),
          if (verification.canSubmit && onVerify != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: context.tr(verification.status == KycStatus.rejected ? LocaleKeys.accountTryAgain : LocaleKeys.accountVerify), onPressed: onVerify),
          ],
        ],
      ),
    );
  }
}
