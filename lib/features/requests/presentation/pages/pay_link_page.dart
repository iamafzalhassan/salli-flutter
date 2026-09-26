import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/failure_message.dart';
import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/status_message.dart';
import '../cubits/pay_link_cubit.dart';
import '../cubits/pay_link_state.dart';

class PayLinkPage extends StatelessWidget {
  const PayLinkPage({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<PayLinkCubit, PayLinkState>(
    builder: (context, state) {
      final failure = state.failure;
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                const PageHeader(onBack: null),
                const Spacer(),
                if (state.isInvalid)
                  StatusMessage(body: context.tr(LocaleKeys.payLinkInvalidBody), icon: Icons.link_off_rounded, title: context.tr(LocaleKeys.payLinkInvalidTitle))
                else if (failure != null)
                  StatusMessage(
                    actionLabel: context.tr(LocaleKeys.commonRetry),
                    body: context.failureMessage(failure),
                    icon: Icons.link_off_rounded,
                    onAction: context.read<PayLinkCubit>().load,
                    title: context.tr(LocaleKeys.commonErrorTitle),
                  )
                else
                  const AppLoader(),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    },
    listener: (context, state) {
      final draft = state.draft;
      if (draft != null) {
        context.pushReplacement(AppRoutes.payReview, extra: draft);
      } else {
        context.pushReplacement(AppRoutes.payAmount, extra: state.recipient);
      }
    },
    listenWhen: (previous, current) => (current.draft != null || current.recipient != null) && previous.draft == null && previous.recipient == null,
  );
}
