import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/date_labels.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/fill_scroll_view.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/settings_row.dart';
import '../cubits/profile_setup_cubit.dart';
import '../cubits/profile_setup_state.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  static const int _maxNameLength = 60;
  static const int _minAgeYears = 16;
  static const int _oldestYear = 1920;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();

  Future<void> _chooseDate(DateTime? current) async {
    final cubit = context.read<ProfileSetupCubit>();
    final now = DateTime.now();
    final latest = DateTime(now.year - ProfileSetupPage._minAgeYears, now.month, now.day);
    final date = await showDatePicker(context: context, firstDate: DateTime(ProfileSetupPage._oldestYear), initialDate: current ?? latest, lastDate: latest);
    if (date != null && mounted) cubit.dateOfBirthChanged(date);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ProfileSetupCubit, ProfileSetupState>(
    builder: (context, state) {
      final cubit = context.read<ProfileSetupCubit>();
      final dateOfBirth = state.dateOfBirth;
      return Scaffold(
        body: SafeArea(
          child: FillScrollView(
            children: [
              PageHeader(title: context.tr(LocaleKeys.accountEdit)),
              const SizedBox(height: AppSpacing.xl),
              if (state.isLoading)
                const Center(child: AppLoader())
              else ...[
                AppTextField(controller: _nameController, hint: context.tr(LocaleKeys.accountNameHint), icon: Icons.person_rounded, maxLength: ProfileSetupPage._maxNameLength, onChanged: cubit.displayNameChanged),
                const SizedBox(height: AppSpacing.md),
                SettingsRow(
                  icon: Icons.cake_rounded,
                  onPressed: () => unawaited(_chooseDate(dateOfBirth)),
                  title: context.tr(LocaleKeys.accountDateOfBirth),
                  value: dateOfBirth == null ? context.tr(LocaleKeys.accountNotSet) : context.dateLabel(dateOfBirth),
                ),
                FailureText(failure: state.failure),
              ],
              const Spacer(),
              AppButton(isLoading: state.isSaving, label: context.tr(LocaleKeys.commonSave), onPressed: state.isLoading ? null : () => unawaited(cubit.save())),
            ],
          ),
        ),
      );
    },
    listener: (context, state) {
      if (state.isSaved) {
        context.pop();
      } else if (_nameController.text.isEmpty && state.displayName.isNotEmpty) {
        _nameController.text = state.displayName;
      }
    },
    listenWhen: (previous, current) => (current.isSaved && !previous.isSaved) || (previous.isLoading && !current.isLoading),
  );
}
