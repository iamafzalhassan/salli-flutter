import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/category_icons.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/icon_avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tile_skeleton.dart';
import '../../domain/entities/payee.dart';
import '../../domain/entities/recipient.dart';
import '../cubits/send_cubit.dart';
import '../cubits/send_state.dart';
import '../widgets/payee_tile.dart';

class SendPage extends StatelessWidget {
  const SendPage({super.key});

  static const int _skeletonRows = 4;

  static List<Widget> _recents(BuildContext context, SendState state) {
    final cubit = context.read<SendCubit>();
    if (state.isLoadingRecents) {
      return [for (var index = 0; index < _skeletonRows; index++) const TileSkeleton()];
    }
    if (state.recents.isEmpty) return [StatusMessage(body: context.tr(LocaleKeys.sendNoRecents), icon: Icons.people_alt_rounded, title: context.tr(LocaleKeys.sendRecent))];
    return [
      for (final (index, payee) in state.recents.indexed)
        Entrance(
          index: index,
          child: PayeeTile(onPressed: () => cubit.select(payee), payee: payee),
        ),
    ];
  }

  static Future<void> _open(BuildContext context, Payee payee) async {
    final cubit = context.read<SendCubit>();
    await context.push<void>(AppRoutes.payAmount, extra: PersonRecipient(payee));
    if (!context.mounted) return;
    cubit.clearSelection();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<SendCubit, SendState>(
    builder: (context, state) {
      final cubit = context.read<SendCubit>();
      final phone = state.phone;
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            physics: const BouncingScrollPhysics(),
            children: [
              PageHeader(title: context.tr(LocaleKeys.sendTitle)),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                autofocus: true,
                hint: context.tr(LocaleKeys.sendPhoneHint),
                icon: Icons.phone_iphone_rounded,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.phone,
                maxLength: PhoneNumber.maxInputDigits,
                onChanged: cubit.queryChanged,
                onSubmitted: (_) => unawaited(cubit.submit()),
              ),
              FailureText(failure: state.failure),
              AnimatedSize(
                alignment: Alignment.topCenter,
                curve: AppMotion.standard,
                duration: AppMotion.base,
                child: phone == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: PayeeTile(
                          onPressed: cubit.submit,
                          payee: Payee(phone: phone),
                          trailing: state.isLookingUp ? const AppLoader() : null,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppListTile(
                leading: IconAvatar(icon: CategoryIcons.of('bank'), isAccent: false),
                onPressed: () => unawaited(context.push<void>(AppRoutes.bankTransfer)),
                subtitle: context.tr(LocaleKeys.sendBankBody),
                title: context.tr(LocaleKeys.sendBank),
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: context.tr(LocaleKeys.sendRecent)),
              const SizedBox(height: AppSpacing.sm),
              ..._recents(context, state),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => unawaited(_open(context, state.selected!)),
    listenWhen: (previous, current) => current.selected != null && current.selected != previous.selected,
  );
}
