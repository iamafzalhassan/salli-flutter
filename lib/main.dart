import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'core/di/injector.dart';
import 'core/localization/app_language.dart';
import 'core/security/runtime_guard.dart';
import 'core/security/screen_protection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  EasyLocalization.logger.enableBuildModes = [];
  await EasyLocalization.ensureInitialized();
  await Hive.initFlutter();
  await configureDependencies();
  unawaited(injector<RuntimeGuard>().start());
  unawaited(injector<ScreenProtection>().start());
  runApp(EasyLocalization(fallbackLocale: AppLanguage.english.locale, path: AppLanguage.translationsPath, supportedLocales: AppLanguage.locales, useOnlyLangCode: true, child: const SalliApp()));
}
