import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_refresh_view.dart';
import '../../../../core/widgets/app_segmented_control.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/failure_text.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/status_message.dart';
import '../../../payments/domain/entities/payment_draft.dart';
import '../../domain/entities/money_request.dart';
import '../../domain/entities/requests_tab.dart';
import '../cubits/requests_cubit.dart';
import '../cubits/requests_state.dart';
import '../widgets/request_tile.dart';
import '../widgets/request_tile_skeleton.dart';
import '../widgets/split_tile.dart';
import '../widgets/split_tile_skeleton.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  static const int _skeletonRows = 3;

  static List<Widget> _content(BuildContext context, RequestsState state) {
    final cubit = context.read<RequestsCubit>();
    if (state.status == RequestsStatus.loading) {
      return [for (var index = 0; index < _skeletonRows; index++) state.tab == RequestsTab.splits ? const SplitTileSkeleton() : const RequestTileSkeleton()];
    }
    if (state.status == RequestsStatus.failure) {
      return [StatusMessage(actionLabel: context.tr(LocaleKeys.commonRetry), body: context.failureMessage(state.failure!), icon: Icons.cloud_off_rounded, onAction: cubit.load, title: context.tr(LocaleKeys.commonErrorTitle))];
    }
    return switch (state.tab) {
      RequestsTab.incoming when state.incoming.isEmpty => [StatusMessage(body: context.tr(LocaleKeys.requestsNoIncoming), icon: Icons.call_received_rounded, title: context.tr(LocaleKeys.requestsIncoming))],
      RequestsTab.incoming => [
        for (final (index, request) in state.incoming.indexed)
          Entrance(
            index: index,
            child: RequestTile(actions: request.isPending ? _incomingActions(context, request, state.isBusy) : const [], request: request),
          ),
      ],
      RequestsTab.outgoing when state.outgoing.isEmpty => [StatusMessage(body: context.tr(LocaleKeys.requestsNoOutgoing), icon: Icons.call_made_rounded, title: context.tr(LocaleKeys.requestsOutgoing))],
      RequestsTab.outgoing => [
        for (final (index, request) in state.outgoing.indexed)
          Entrance(
            index: index,
            child: RequestTile(actions: request.isPending ? _outgoingActions(context, request, state.isBusy) : const [], request: request),
          ),
      ],
      RequestsTab.splits when state.splits.isEmpty => [StatusMessage(body: context.tr(LocaleKeys.requestsNoSplits), icon: Icons.call_split_rounded, title: context.tr(LocaleKeys.requestsSplits))],
      RequestsTab.splits => [
        for (final (index, split) in state.splits.indexed)
          Entrance(
            index: index,
            child: SplitTile(split: split),
          ),
      ],
    };
  }

  static List<Widget> _incomingActions(BuildContext context, MoneyRequest request, bool isBusy) {
    final cubit = context.read<RequestsCubit>();
    return [
      AppButton(label: context.tr(LocaleKeys.requestsDecline), onPressed: isBusy ? null : () => unawaited(cubit.decline(request)), variant: AppButtonVariant.secondary),
      AppButton(label: context.tr(LocaleKeys.requestsPay), onPressed: isBusy ? null : () => cubit.pay(request)),
    ];
  }

  static List<Widget> _outgoingActions(BuildContext context, MoneyRequest request, bool isBusy) {
    final cubit = context.read<RequestsCubit>();
    return [
      AppButton(label: context.tr(LocaleKeys.requestsCancel), onPressed: isBusy ? null : () => unawaited(cubit.cancel(request)), variant: AppButtonVariant.secondary),
      AppButton(label: context.tr(LocaleKeys.requestsRemind), onPressed: isBusy ? null : () => unawaited(cubit.remind(request))),
    ];
  }

  static Future<void> _open(BuildContext context, PaymentDraft draft) async {
    final cubit = context.read<RequestsCubit>();
    await context.push<void>(AppRoutes.payReview, extra: draft);
    if (!context.mounted) return;
    cubit.clearDraft();
    await cubit.load();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<RequestsCubit, RequestsState>(
    builder: (context, state) {
      final cubit = context.read<RequestsCubit>();
      return Scaffold(
        body: SafeArea(
          child: AppRefreshView(
            onRefresh: cubit.load,
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              PageHeader(title: context.tr(LocaleKeys.requestsTitle)),
              const SizedBox(height: AppSpacing.xl),
              AppSegmentedControl<RequestsTab>(
                onChanged: cubit.tabSelected,
                options: [(RequestsTab.incoming, context.tr(LocaleKeys.requestsIncoming)), (RequestsTab.outgoing, context.tr(LocaleKeys.requestsOutgoing)), (RequestsTab.splits, context.tr(LocaleKeys.requestsSplits))],
                selected: state.tab,
              ),
              FailureText(failure: state.actionFailure),
              const SizedBox(height: AppSpacing.lg),
              ..._content(context, state),
            ],
          ),
        ),
      );
    },
    listener: (context, state) => unawaited(_open(context, state.draft!)),
    listenWhen: (previous, current) => current.draft != null && previous.draft == null,
  );
}
