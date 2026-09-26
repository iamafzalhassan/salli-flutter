import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/app_config.dart';
import 'core/di/injector.dart';
import 'core/localization/locale_keys.dart';
import 'core/mock/mock_sms_banner.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'core/widgets/privacy_shield.dart';
import 'features/settings/domain/entities/app_theme_mode.dart';
import 'features/settings/presentation/cubits/appearance_cubit.dart';

class SalliApp extends StatelessWidget {
  const SalliApp({super.key});

  static Widget _shell(BuildContext context, Widget? child) {
    final content = child ?? const SizedBox.shrink();
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTextStyles.maxTextScale,
      child: PrivacyShield(
        screenProtection: injector(),
        child: OfflineBanner(
          status: injector(),
          child: injector<AppConfig>().usesMockApi ? MockSmsBanner(inbox: injector(), child: content) : content,
        ),
      ),
    );
  }

  static ThemeMode _themeModeOf(AppThemeMode mode) => switch (mode) {
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.system => ThemeMode.system,
  };

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: injector<AppearanceCubit>(),
    child: BlocBuilder<AppearanceCubit, AppThemeMode>(
      builder: (context, themeMode) => MaterialApp.router(
        builder: _shell,
        darkTheme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        onGenerateTitle: (context) => context.tr(LocaleKeys.appName),
        routerConfig: injector<AppRouter>().config,
        supportedLocales: context.supportedLocales,
        theme: AppTheme.light,
        themeMode: _themeModeOf(themeMode),
      ),
    ),
  );
}
