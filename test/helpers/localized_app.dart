import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salli/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileAssetLoader extends AssetLoader {
  static const String _directory = 'assets/translations';

  const FileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async => jsonDecode(File('$_directory/${locale.languageCode}.json').readAsStringSync()) as Map<String, dynamic>;
}

Future<void> pumpLocalized(WidgetTester tester, Widget child, {ThemeData? theme}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      assetLoader: const FileAssetLoader(),
      fallbackLocale: const Locale('en'),
      path: FileAssetLoader._directory,
      saveLocale: false,
      supportedLocales: const [Locale('en')],
      useOnlyLangCode: true,
      child: Builder(
        builder: (context) => MaterialApp(
          home: Scaffold(body: Center(child: child)),
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          theme: theme ?? AppTheme.dark,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
