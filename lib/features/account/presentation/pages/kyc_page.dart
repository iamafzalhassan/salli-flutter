import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/gender.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../../../../core/widgets/success_mark.dart';
import '../../../../core/widgets/summary_row.dart';
import '../../../../core/widgets/upper_case_formatter.dart';
import '../../domain/entities/kyc_step.dart';
import '../cubits/kyc_cubit.dart';
import '../cubits/kyc_state.dart';

class KycPage extends StatefulWidget {
  const KycPage({super.key});

  static const int _defaultAgeYears = 25;
  static const int _imageQuality = 70;
  static const int _maxNicLength = 12;
  static const int _oldestYear = 1920;
  static const int _steps = 5;

  static final RegExp _nicCharacters = RegExp('[0-9VvXx]');

  @override
  State<KycPage> createState() => _KycPageState();
}

class _KycPageState extends State<KycPage> {
  final ImagePicker _picker = ImagePicker();

  List<Widget> _stepContent(KycState state) {
    final colors = context.colors;
    final cubit = context.read<KycCubit>();
    final dateOfBirth = state.dateOfBirth;
    return switch (state.step) {
      KycStep.intro => [
        const Center(
          child: IconAvatar(icon: Icons.verified_user_rounded, size: AppSpacing.iconHero),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(context.tr(LocaleKeys.kycIntroTitle), style: AppTextStyles.headline, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(LocaleKeys.kycIntroBody),
          style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final (icon, key) in const [(Icons.badge_rounded, LocaleKeys.kycIntroNic), (Icons.photo_camera_front_rounded, LocaleKeys.kycIntroSelfie), (Icons.lock_rounded, LocaleKeys.kycIntroPrivacy)])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: colors.accentInk, size: AppSpacing.iconMd),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(context.tr(key), style: AppTextStyles.body)),
              ],
            ),
          ),
      ],
      KycStep.details => [
        Text(context.tr(LocaleKeys.kycDetailsTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(hint: context.tr(LocaleKeys.kycFullNameHint), icon: Icons.person_rounded, onChanged: cubit.fullNameChanged),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          hint: context.tr(LocaleKeys.kycNicHint),
          icon: Icons.badge_rounded,
          inputFormatters: [const UpperCaseFormatter(), FilteringTextInputFormatter.allow(KycPage._nicCharacters)],
          maxLength: KycPage._maxNicLength,
          onChanged: cubit.nicChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsRow(icon: Icons.cake_rounded, onPressed: () => unawaited(_chooseDate(dateOfBirth)), title: context.tr(LocaleKeys.accountDateOfBirth), value: dateOfBirth == null ? null : context.dateLabel(dateOfBirth)),
        const SizedBox(height: AppSpacing.md),
        AppSegmentedControl<Gender?>(
          onChanged: (gender) {
            if (gender != null) cubit.genderChanged(gender);
          },
          options: [for (final gender in Gender.values) (gender, context.tr('${LocaleKeys.genderPrefix}.${gender.name}'))],
          selected: state.gender,
        ),
        FailureText(failure: state.failure),
      ],
      KycStep.nicFront || KycStep.nicBack => [
        Center(
          child: IconAvatar(icon: state.step == KycStep.nicFront ? Icons.badge_rounded : Icons.flip_rounded, size: AppSpacing.iconHero),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(context.tr(state.step == KycStep.nicFront ? LocaleKeys.kycNicFrontTitle : LocaleKeys.kycNicBackTitle), style: AppTextStyles.headline, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(LocaleKeys.kycNicPhotoBody),
          style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
      KycStep.selfie => [
        const Center(
          child: IconAvatar(icon: Icons.face_retouching_natural_rounded, size: AppSpacing.iconHero),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(context.tr(LocaleKeys.kycSelfieTitle), style: AppTextStyles.headline, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(LocaleKeys.kycSelfieBody, args: [context.tr('${LocaleKeys.kycChallengePrefix}.${state.challenge}')]),
          style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (state.isCheckingLiveness) ...[
          const SizedBox(height: AppSpacing.xl),
          const Center(child: AppLoader()),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(LocaleKeys.kycCheckingLiveness),
            style: AppTextStyles.label.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ],
      KycStep.review => [
        Text(context.tr(LocaleKeys.kycReviewTitle), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.md),
        SummaryRow(label: context.tr(LocaleKeys.accountName), value: state.fullName.trim()),
        SummaryRow(label: context.tr(LocaleKeys.accountNic), value: state.nicInput),
        if (dateOfBirth != null) SummaryRow(label: context.tr(LocaleKeys.accountDateOfBirth), value: context.dateLabel(dateOfBirth)),
        SummaryRow(label: context.tr(LocaleKeys.kycDocuments), value: context.tr(LocaleKeys.kycDocumentsReady)),
        const SizedBox(height: AppSpacing.md),
        Text(context.tr(LocaleKeys.kycSimulatedNote), style: AppTextStyles.caption.copyWith(color: colors.textSecondary)),
        FailureText(failure: state.failure),
      ],
      KycStep.submitted => [
        const SizedBox(height: AppSpacing.xxl),
        const Center(child: SuccessMark()),
        const SizedBox(height: AppSpacing.xl),
        Text(context.tr(LocaleKeys.kycSubmittedTitle), style: AppTextStyles.headline, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(LocaleKeys.kycSubmittedBody),
          style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    };
  }

  Future<void> _chooseDate(DateTime? current) async {
    final cubit = context.read<KycCubit>();
    final now = DateTime.now();
    final date = await showDatePicker(context: context, firstDate: DateTime(KycPage._oldestYear), initialDate: current ?? DateTime(now.year - KycPage._defaultAgeYears), lastDate: now);
    if (date != null && mounted) cubit.dateOfBirthChanged(date);
  }

  (String, VoidCallback?) _action(KycState state) {
    final cubit = context.read<KycCubit>();
    return switch (state.step) {
      KycStep.intro => (context.tr(LocaleKeys.kycStart), cubit.start),
      KycStep.details => (context.tr(LocaleKeys.commonContinue), cubit.confirmDetails),
      KycStep.nicFront => (context.tr(LocaleKeys.kycTakePhoto), () => unawaited(_captureNic(isFront: true))),
      KycStep.nicBack => (context.tr(LocaleKeys.kycTakePhoto), () => unawaited(_captureNic(isFront: false))),
      KycStep.selfie => (context.tr(LocaleKeys.kycTakeSelfie), state.isCheckingLiveness ? null : () => unawaited(_captureSelfie())),
      KycStep.review => (context.tr(LocaleKeys.kycSubmit), () => unawaited(cubit.submit())),
      KycStep.submitted => (context.tr(LocaleKeys.resultDone), () => context.pop()),
    };
  }

  Future<void> _captureSelfie() async {
    final cubit = context.read<KycCubit>();
    final bytes = await _capture(isSelfie: true);
    if (bytes != null && mounted) await cubit.selfieCaptured(bytes);
  }

  Future<void> _captureNic({required bool isFront}) async {
    final cubit = context.read<KycCubit>();
    final bytes = await _capture(isSelfie: false);
    if (bytes == null || !mounted) return;
    if (isFront) {
      cubit.nicFrontCaptured(bytes);
    } else {
      cubit.nicBackCaptured(bytes);
    }
  }

  Future<List<int>?> _capture({required bool isSelfie}) async {
    try {
      final image = await _picker.pickImage(imageQuality: KycPage._imageQuality, preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear, source: ImageSource.camera);
      return await image?.readAsBytes();
    } on PlatformException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<KycCubit, KycState>(
    builder: (context, state) {
      final colors = context.colors;
      final cubit = context.read<KycCubit>();
      final (label, onPressed) = _action(state);
      final stepIndex = state.step.index;
      final isInProgress = state.step != KycStep.intro && state.step != KycStep.submitted;
      return PopScope(
        canPop: !isInProgress,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) cubit.back();
        },
        child: Scaffold(
          body: SafeArea(
            child: FillScrollView(
              children: [
                PageHeader(onBack: isInProgress ? cubit.back : null, title: context.tr(LocaleKeys.kycTitle)),
                if (isInProgress) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.tr(LocaleKeys.kycStepOf, args: ['$stepIndex', '${KycPage._steps}']),
                    maxLines: 1,
                    style: AppTextStyles.overline.copyWith(color: colors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AnimatedSwitcher(
                  duration: AppMotion.base,
                  child: Column(key: ValueKey(state.step), crossAxisAlignment: CrossAxisAlignment.stretch, children: _stepContent(state)),
                ),
                const Spacer(),
                const SizedBox(height: AppSpacing.xl),
                AppButton(isLoading: state.isSubmitting, label: label, onPressed: onPressed),
              ],
            ),
          ),
        ),
      );
    },
  );
}
