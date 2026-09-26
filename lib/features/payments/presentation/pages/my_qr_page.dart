import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/amount_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_share.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/app_text_button.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/status_message.dart';
import '../../domain/entities/payment_limits.dart';
import '../cubits/my_qr_cubit.dart';
import '../cubits/my_qr_state.dart';
import '../widgets/qr_card.dart';
import '../widgets/qr_card_skeleton.dart';

class MyQrPage extends StatefulWidget {
  const MyQrPage({super.key});

  @override
  State<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<MyQrPage> {
  static const double _fullBrightness = 1;

  static const String _imageName = 'salli-qr.png';
  static const String _imageType = 'image/png';

  final GlobalKey _cardKey = GlobalKey();

  Future<void> _changeAmount() async {
    final cubit = context.read<MyQrCubit>();
    final amount = await showAppSheet<Money>(
      context,
      child: AmountSheet(confirmLabel: context.tr(LocaleKeys.myQrSetAmount), initial: cubit.state.amount, limit: PaymentLimits.perPayment, title: context.tr(LocaleKeys.myQrAmountTitle)),
    );
    if (amount != null && mounted) cubit.amountChanged(amount);
  }

  Future<void> _share(String text) async {
    final boundary = _cardKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    final image = await boundary.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null || !mounted) return;
    await shareContent(
      context,
      files: [XFile.fromData(bytes.buffer.asUint8List(), mimeType: _imageType, name: _imageName)],
      text: text,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(ScreenBrightness.instance.setApplicationScreenBrightness(_fullBrightness).onError<PlatformException>((_, _) {}));
  }

  @override
  void dispose() {
    unawaited(ScreenBrightness.instance.resetApplicationScreenBrightness().onError<PlatformException>((_, _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<MyQrCubit, MyQrState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<MyQrCubit>();
      final profile = state.profile;
      final payload = state.payload;
      final name = profile?.displayName ?? profile?.phone.display ?? '';
      return Scaffold(
        body: SafeArea(
          child: FillScrollView(
            children: [
              PageHeader(title: context.tr(LocaleKeys.myQrTitle)),
              const Spacer(),
              const SizedBox(height: AppSpacing.xl),
              if (state.isLoading) ...[
                const QrCardSkeleton(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.tr(LocaleKeys.myQrBody),
                  style: AppTextStyles.body.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ] else if (profile == null || payload == null)
                StatusMessage(
                  actionLabel: context.tr(LocaleKeys.commonRetry),
                  body: context.failureMessage(state.failure ?? const Failure.unknown()),
                  icon: Icons.qr_code_2_rounded,
                  onAction: cubit.load,
                  title: context.tr(LocaleKeys.commonErrorTitle),
                )
              else ...[
                RepaintBoundary(
                  key: _cardKey,
                  child: QrCard(amount: state.amount, name: name, payload: payload, phone: profile.phone.display),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.tr(LocaleKeys.myQrBody),
                  style: AppTextStyles.body.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              const SizedBox(height: AppSpacing.xl),
              if (profile != null && payload != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: AppButton(label: context.tr(state.amount == null ? LocaleKeys.myQrAddAmount : LocaleKeys.myQrChangeAmount), onPressed: () => unawaited(_changeAmount()), variant: AppButtonVariant.secondary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        label: context.tr(LocaleKeys.myQrShare),
                        onPressed: () => unawaited(_share(context.tr(LocaleKeys.myQrShareText, args: [name]))),
                      ),
                    ),
                  ],
                ),
                if (state.amount != null)
                  Center(
                    child: AppTextButton(label: context.tr(LocaleKeys.myQrRemoveAmount), onPressed: () => cubit.amountChanged(null)),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
