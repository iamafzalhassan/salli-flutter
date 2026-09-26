import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_keys.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/page_indicator.dart';
import '../cubits/onboarding_cubit.dart';
import '../cubits/onboarding_state.dart';
import '../widgets/welcome_slide.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const List<WelcomeSlide> _slides = [
    WelcomeSlide(bodyKey: LocaleKeys.welcomeScanBody, icon: Icons.qr_code_scanner_rounded, titleKey: LocaleKeys.welcomeScanTitle),
    WelcomeSlide(bodyKey: LocaleKeys.welcomeSendBody, icon: Icons.bolt_rounded, titleKey: LocaleKeys.welcomeSendTitle),
    WelcomeSlide(bodyKey: LocaleKeys.welcomeSecureBody, icon: Icons.shield_rounded, titleKey: LocaleKeys.welcomeSecureTitle),
  ];

  final PageController _controller = PageController();

  int _page = 0;

  bool get _isLastPage => _page == _slides.length - 1;

  double get _position => (_controller.hasClients ? _controller.page : null) ?? _page.toDouble();

  void _skip() => unawaited(_controller.animateToPage(_slides.length - 1, curve: AppMotion.emphasized, duration: AppMotion.slow));

  void _onPageChanged(int page) => setState(() => _page = page);

  void _next() {
    if (_isLastPage) {
      unawaited(context.read<OnboardingCubit>().complete());
    } else {
      unawaited(_controller.nextPage(curve: AppMotion.emphasized, duration: AppMotion.slow));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<OnboardingCubit, OnboardingState>(
    builder: (context, state) => Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: SizedBox(
                height: AppSpacing.controlHeight,
                child: Row(
                  children: [
                    const Spacer(),
                    AnimatedOpacity(
                      duration: AppMotion.base,
                      opacity: _isLastPage ? 0 : 1,
                      child: AppPressable(
                        onPressed: _isLastPage ? null : _skip,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(context.tr(LocaleKeys.commonSkip), maxLines: 1, style: AppTextStyles.label.copyWith(color: context.colors.textSecondary)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView(controller: _controller, onPageChanged: _onPageChanged, children: _slides),
            ),
            RepaintBoundary(
              child: ListenableBuilder(
                builder: (context, child) => PageIndicator(count: _slides.length, position: _position),
                listenable: _controller,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.screenPadding, left: AppSpacing.screenPadding, right: AppSpacing.screenPadding),
              child: AppButton(isLoading: state == OnboardingState.completing, label: context.tr(_isLastPage ? LocaleKeys.commonGetStarted : LocaleKeys.commonNext), onPressed: _next),
            ),
          ],
        ),
      ),
    ),
    listener: (context, state) => context.go(AppRoutes.signIn),
    listenWhen: (previous, current) => current == OnboardingState.completed,
  );
}
