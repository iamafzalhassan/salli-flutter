import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/lkr_format.dart';
import '../../../../core/utils/phone_number.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/phone_field.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../../core/widgets/tile_skeleton.dart';
import '../../domain/entities/reload_kind.dart';
import '../../domain/entities/reload_plan.dart';
import '../cubits/reload_cubit.dart';
import '../cubits/reload_state.dart';

class ReloadPage extends StatefulWidget {
  const ReloadPage({super.key});

  @override
  State<ReloadPage> createState() => _ReloadPageState();
}

class _ReloadPageState extends State<ReloadPage> {
  static const double _amountSkeletonWidth = 88;
  static const double _chipSkeletonWidth = 96;

  static const int _megabytesPerGigabyte = 1024;
  static const int _skeletonChips = 6;
  static const int _skeletonRows = 4;

  static const String _separator = ' · ';

  final TextEditingController _controller = TextEditingController();

  List<Widget> _chips(ReloadState state) {
    final ownPhone = state.ownPhone;
    return [
      if (ownPhone != null) AppChip(icon: Icons.person_rounded, isSelected: state.phone == ownPhone, label: context.tr(LocaleKeys.reloadMyNumber), onPressed: () => _useNumber(ownPhone)),
      for (final recent in state.recents)
        if (recent.phone != ownPhone) AppChip(isSelected: state.phone == recent.phone, label: recent.phone.display, onPressed: () => _useNumber(recent.phone)),
    ];
  }

  void _useNumber(PhoneNumber phone) {
    _controller.text = phone.national;
    unawaited(context.read<ReloadCubit>().numberChosen(phone));
  }

  List<Widget> _offers(ReloadState state) {
    final cubit = context.read<ReloadCubit>();
    final catalog = state.catalog;
    final symbol = context.tr(LocaleKeys.currencySymbol);
    if (state.isLoadingCatalog || catalog == null) {
      if (state.kind == null) {
        return [
          Wrap(
            runSpacing: AppSpacing.sm,
            spacing: AppSpacing.sm,
            children: [for (var index = 0; index < _skeletonChips; index++) const Skeleton(radius: AppRadius.pill, height: AppSpacing.touchTarget, width: _chipSkeletonWidth)],
          ),
        ];
      }
      return [
        for (var index = 0; index < _skeletonRows; index++)
          const TileSkeleton(
            hasLeading: false,
            trailing: Skeleton.text(textStyle: AppTextStyles.amount, width: _amountSkeletonWidth),
          ),
      ];
    }
    final kind = state.kind;
    if (kind == null) {
      return [
        Wrap(
          runSpacing: AppSpacing.sm,
          spacing: AppSpacing.sm,
          children: [
            for (final amount in catalog.amounts) AppChip(label: LkrFormat.withSymbol(amount, symbol), onPressed: () => cubit.amountChosen(amount)),
            AppChip(icon: Icons.dialpad_rounded, label: context.tr(LocaleKeys.reloadOtherAmount), onPressed: cubit.otherAmount),
          ],
        ),
      ];
    }
    final plans = catalog.plansOf(kind);
    if (plans.isEmpty) return [StatusMessage(body: context.tr(LocaleKeys.reloadNoPlans), icon: Icons.inventory_2_rounded, title: context.tr('${LocaleKeys.reloadKindPrefix}.${kind.name}'))];
    return [
      for (final (index, plan) in plans.indexed)
        Entrance(
          index: index,
          child: AppListTile(
            onPressed: () => cubit.planChosen(plan),
            subtitle: _planLine(plan),
            title: plan.name,
            trailing: Text(LkrFormat.withSymbol(plan.amount, symbol), maxLines: 1, style: AppTextStyles.amount),
          ),
        ),
    ];
  }

  String _planLine(ReloadPlan plan) {
    final dataMb = plan.dataMb;
    final minutes = plan.minutes;
    return [
      if (dataMb != null)
        dataMb >= _megabytesPerGigabyte ? context.tr(LocaleKeys.reloadDataGb, args: [(dataMb / _megabytesPerGigabyte).toStringAsFixed(dataMb % _megabytesPerGigabyte == 0 ? 0 : 1)]) : context.tr(LocaleKeys.reloadDataMb, args: ['$dataMb']),
      if (minutes != null) context.tr(LocaleKeys.reloadMinutes, args: ['$minutes']),
      context.tr(LocaleKeys.reloadValidity, args: ['${plan.validityDays}']),
    ].join(_separator);
  }

  Future<void> _open(ReloadState state) async {
    final cubit = context.read<ReloadCubit>();
    final draft = state.draft;
    if (draft != null) {
      await context.push<void>(AppRoutes.payReview, extra: draft);
    } else {
      await context.push<void>(AppRoutes.payAmount, extra: state.recipient);
    }
    if (mounted) cubit.clearResult();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ReloadCubit, ReloadState>(
    builder: (context, state) {
      final cubit = context.read<ReloadCubit>();
      final phone = state.phone;
      final chips = _chips(state);
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            physics: const BouncingScrollPhysics(),
            children: [
              PageHeader(title: context.tr(LocaleKeys.reloadTitle)),
              const SizedBox(height: AppSpacing.xl),
              PhoneField(autofocus: false, carrier: phone?.carrier, controller: _controller, isEnabled: true, onChanged: (input) => unawaited(cubit.phoneChanged(input)), onSubmitted: () {}),
              if (chips.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (index, chip) in chips.indexed) ...[if (index > 0) const SizedBox(width: AppSpacing.sm), chip],
                    ],
                  ),
                ),
              ],
              FailureText(failure: state.failure),
              const SizedBox(height: AppSpacing.xl),
              if (phone == null)
                StatusMessage(body: context.tr(LocaleKeys.reloadEnterNumber), icon: Icons.phone_android_rounded, title: context.tr(LocaleKeys.reloadTitle))
              else ...[
                AppSegmentedControl<ReloadKind?>(
                  onChanged: cubit.kindSelected,
                  options: [
                    (null, context.tr(LocaleKeys.reloadAmounts)),
                    for (final kind in const [ReloadKind.data, ReloadKind.voice, ReloadKind.combo]) (kind, context.tr('${LocaleKeys.reloadKindPrefix}.${kind.name}')),
                  ],
                  selected: state.kind,
                ),
                const SizedBox(height: AppSpacing.lg),
                ..._offers(state),
              ],
            ],
          ),
        ),
      );
    },
    listener: (context, state) {
      final ownPhone = state.ownPhone;
      if (state.hasResult) {
        unawaited(_open(state));
      } else if (ownPhone != null && _controller.text.isEmpty && state.phone == ownPhone) {
        _controller.text = ownPhone.national;
      }
    },
    listenWhen: (previous, current) => (current.hasResult && !previous.hasResult) || current.phone != previous.phone,
  );
}
